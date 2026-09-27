const crypto = require('crypto');
const { errors } = require('../utils/http');
const { formatRemaining, isExpired, resolveRelativeDate } = require('../utils/time');

const STATUS_FILTERS = {
  pending: ['pending'],
  answered: ['accepted', 'rejected'],
  expired: ['expired'],
};

/**
 * Spec: "expiresAt geçmişse status otomatik expired (yazarken güncelle)".
 * Called before every read/write so the stored status is always current.
 */
function expireOverdueOffers(db, now = Date.now()) {
  const overdue = (o) => o.status === 'pending' && isExpired(o.expiresAt, now);
  if (!db.state.offers.some(overdue)) return;
  db.transaction((state) => {
    for (const offer of state.offers) {
      if (overdue(offer)) offer.status = 'expired';
    }
  });
}

function toDto(offer, now = Date.now()) {
  return {
    id: offer.id,
    workerId: offer.workerId,
    title: offer.title,
    place: offer.place,
    pay: offer.pay,
    payValue: offer.payValue,
    logo: `/assets/${offer.logo}`,
    district: offer.district,
    when: offer.when,
    status: offer.status,
    remain: offer.status === 'pending' ? formatRemaining(offer.expiresAt, now) : null,
    expiresAt: offer.expiresAt,
    createdAt: offer.createdAt,
  };
}

function listOffers(db, { status = 'pending', workerId } = {}) {
  const statuses = STATUS_FILTERS[status];
  if (!statuses) {
    throw errors.validation(
      `status şunlardan biri olmalı: ${Object.keys(STATUS_FILTERS).join(', ')}`,
    );
  }

  expireOverdueOffers(db);
  const now = Date.now();
  // Newest first; for pending, the soonest-expiring first is more useful.
  const own = db.state.offers.filter((o) => o.workerId === workerId);
  const offers = own
    .filter((o) => statuses.includes(o.status))
    .sort((a, b) =>
      status === 'pending'
        ? new Date(a.expiresAt) - new Date(b.expiresAt)
        : new Date(b.createdAt) - new Date(a.createdAt),
    )
    .map((o) => toDto(o, now));

  const pendingCount = own.filter((o) => o.status === 'pending').length;
  return { pendingCount, offers };
}

/**
 * Another worker's offer is reported as 404 (not 403) so ids can't be probed.
 */
function findOwnOffer(db, id, workerId) {
  const offer = db.state.offers.find((o) => o.id === id && o.workerId === workerId);
  if (!offer) throw errors.notFound('OFFER_NOT_FOUND', 'Teklif bulunamadı');
  return offer;
}

function getOffer(db, id, workerId) {
  expireOverdueOffers(db);
  const offer = findOwnOffer(db, id, workerId);
  return {
    ...toDto(offer),
    city: db.state.job.city,
    note: db.state.job.note,
  };
}

// Case assumptions: one job ("Garson — Zarif Cheff Restaurant") and one demo worker
// account. Candidates (w_*) have no login of their own, so every offer is delivered to
// the demo worker (u_worker); the selected candidate is kept in `candidateId`.
const DEMO_WORKER_ID = 'u_worker';

function createOffers(db, body) {
  const workerIds = body && body.workerIds;

  if (!Array.isArray(workerIds) || workerIds.length === 0) {
    throw errors.validation('En az bir personel seçmelisin (workerIds boş olamaz)');
  }
  if (!workerIds.every((id) => typeof id === 'string' && id.trim() !== '')) {
    throw errors.validation('workerIds yalnızca metin id içermeli');
  }
  const uniqueIds = [...new Set(workerIds)];

  // Validate everything first → all-or-nothing, no half-created offers.
  const unknown = uniqueIds.filter((id) => !db.state.candidates.some((c) => c.id === id));
  if (unknown.length > 0) {
    throw errors.notFound('CANDIDATE_NOT_FOUND', `Bilinmeyen personel: ${unknown.join(', ')}`);
  }

  expireOverdueOffers(db);
  const alreadyPending = uniqueIds.filter((id) =>
    db.state.offers.some((o) => o.candidateId === id && o.status === 'pending'),
  );
  if (alreadyPending.length > 0) {
    const names = alreadyPending
      .map((id) => db.state.candidates.find((c) => c.id === id).name)
      .join(', ');
    throw errors.conflict('OFFER_EXISTS', `Bu personele zaten açık bir talep var: ${names}`);
  }

  const now = Date.now();
  const { job } = db.state;
  const created = uniqueIds.map((candidateId) => ({
    id: `o_${crypto.randomUUID().slice(0, 8)}`,
    workerId: DEMO_WORKER_ID,
    candidateId,
    title: job.title,
    place: job.place,
    pay: job.pay,
    payValue: job.payValue,
    logo: job.logo,
    district: job.district,
    when: job.when,
    status: 'pending',
    expiresAt: resolveRelativeDate(job.expiresIn, now),
    createdAt: new Date(now).toISOString(),
  }));

  db.transaction((state) => {
    state.offers.push(...created);
  });

  return {
    created: created.map((o) => ({ id: o.id, workerId: o.candidateId, status: o.status })),
  };
}

function respondToOffer(db, id, workerId, nextStatus) {
  const offer = findOwnOffer(db, id, workerId);

  expireOverdueOffers(db);
  if (offer.status === 'expired') {
    throw errors.conflict('OFFER_EXPIRED', 'Teklifin süresi doldu');
  }
  if (offer.status !== 'pending') {
    throw errors.conflict('OFFER_STATE', 'Bu teklif zaten yanıtlanmış');
  }

  return db.transaction((state) => {
    // Look the offer up on the live state: a rollback replaces the state object.
    const target = state.offers.find((o) => o.id === offer.id);
    target.status = nextStatus;
    target.respondedAt = new Date().toISOString();
    return toDto(target);
  });
}

module.exports = {
  listOffers,
  getOffer,
  createOffers,
  acceptOffer: (db, id, workerId) => respondToOffer(db, id, workerId, 'accepted'),
  rejectOffer: (db, id, workerId) => respondToOffer(db, id, workerId, 'rejected'),
  expireOverdueOffers,
};
