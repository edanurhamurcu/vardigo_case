const { errors } = require('../utils/http');

const PERFECT_THRESHOLD = 80;
const TABS = ['perfect', 'similar'];
const SORTS = ['recommended', 'near', 'rating'];

const sorters = {
  recommended: (a, b) => b.score - a.score,
  near: (a, b) => a.kmValue - b.kmValue,
  rating: (a, b) => Number(b.rating) - Number(a.rating),
};

/** Seed stores relative paths ("photos/merve.png"); API serves them under /assets. */
function toDto(candidate) {
  return {
    id: candidate.id,
    name: candidate.name,
    rating: candidate.rating,
    attend: candidate.attend,
    km: candidate.km,
    kmValue: candidate.kmValue,
    photo: `/assets/${candidate.photo}`,
    online: candidate.online,
    // perfect is derived from the business rule, not trusted from the seed.
    perfect: candidate.score >= PERFECT_THRESHOLD,
    score: candidate.score,
    expectedPay: candidate.expectedPay,
    payMatches: candidate.payMatches,
  };
}

function listCandidates(db, { tab, sort = 'recommended' } = {}) {
  if (tab !== undefined && !TABS.includes(tab)) {
    throw errors.validation(`tab şunlardan biri olmalı: ${TABS.join(', ')}`);
  }
  if (!SORTS.includes(sort)) {
    throw errors.validation(`sort şunlardan biri olmalı: ${SORTS.join(', ')}`);
  }

  let candidates = db.state.candidates.map(toDto);
  if (tab === 'perfect') candidates = candidates.filter((c) => c.perfect);
  if (tab === 'similar') candidates = candidates.filter((c) => !c.perfect);
  candidates.sort(sorters[sort]);

  return {
    totalPerfect: db.state.labels.totalPerfect,
    totalSimilar: db.state.labels.totalSimilar,
    selectedHint: 1,
    candidates,
  };
}

module.exports = { listCandidates, PERFECT_THRESHOLD };
