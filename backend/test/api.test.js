// Integration tests for the "MİNİMUM TEST" scenario in specs/03-backend-api.txt
// Run: npm test   (uses Node's built-in test runner + fetch, no extra deps)
const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { createApp } = require('../src/app');
const { createDb } = require('../src/db');

let server;
let baseUrl;
let db;
const dbPath = path.join(os.tmpdir(), `vardigo-test-${process.pid}.json`);

async function call(method, url, { token, body } = {}) {
  const res = await fetch(`${baseUrl}${url}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return { status: res.status, json: await res.json() };
}

async function login(role) {
  const { json } = await call('POST', '/auth/login', { body: { role } });
  return json.data.token;
}

before(async () => {
  fs.rmSync(dbPath, { force: true });
  db = createDb(dbPath);
  server = createApp(db).listen(0);
  await new Promise((resolve) => server.once('listening', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}/api`;
});

after(() => {
  server.close();
  fs.rmSync(dbPath, { force: true });
});

test('login rejects unknown role', async () => {
  const { status, json } = await call('POST', '/auth/login', { body: { role: 'admin' } });
  assert.equal(status, 400);
  assert.equal(json.ok, false);
  assert.equal(json.error.code, 'VALIDATION');
});

test('candidates require employer token', async () => {
  assert.equal((await call('GET', '/candidates')).status, 401);
  const worker = await login('worker');
  assert.equal((await call('GET', '/candidates', { token: worker })).status, 401);
});

test('employer gets 4 candidates, filtered and sorted', async () => {
  const token = await login('employer');

  const all = await call('GET', '/candidates', { token });
  assert.equal(all.status, 200);
  assert.equal(all.json.data.candidates.length, 4);
  assert.equal(all.json.data.totalPerfect, 26);
  assert.equal(all.json.data.candidates[0].id, 'w_merve'); // highest score first

  const perfect = await call('GET', '/candidates?tab=perfect', { token });
  assert.ok(perfect.json.data.candidates.every((c) => c.score >= 80 && c.perfect));

  const near = await call('GET', '/candidates?sort=near', { token });
  assert.equal(near.json.data.candidates[0].id, 'w_ayse'); // 1.2 km

  const bad = await call('GET', '/candidates?sort=abc', { token });
  assert.equal(bad.status, 400);
});

test('POST /offers validates input', async () => {
  const token = await login('employer');

  const empty = await call('POST', '/offers', { token, body: { workerIds: [] } });
  assert.equal(empty.status, 400);

  const unknown = await call('POST', '/offers', { token, body: { workerIds: ['w_nobody'] } });
  assert.equal(unknown.status, 404);
  assert.equal(unknown.json.error.code, 'CANDIDATE_NOT_FOUND');
});

test('full flow: send → list → accept/reject → answered → persisted', async () => {
  const employer = await login('employer');
  const worker = await login('worker');

  const sent = await call('POST', '/offers', {
    token: employer,
    body: { workerIds: ['w_merve', 'w_derya'] },
  });
  assert.equal(sent.status, 201);
  assert.equal(sent.json.data.created.length, 2);
  const [first, second] = sent.json.data.created;

  // Same candidate again while pending → 409
  const dup = await call('POST', '/offers', { token: employer, body: { workerIds: ['w_merve'] } });
  assert.equal(dup.status, 409);
  assert.equal(dup.json.error.code, 'OFFER_EXISTS');

  const pending = await call('GET', '/offers?status=pending', { token: worker });
  const pendingIds = pending.json.data.offers.map((o) => o.id);
  assert.ok(pendingIds.includes(first.id) && pendingIds.includes(second.id));
  assert.ok(pendingIds.includes('o_garson')); // seed offers too
  assert.match(pending.json.data.offers[0].remain, /^\d+ saat \d+ dakika$/);

  assert.equal((await call('POST', `/offers/${first.id}/accept`, { token: worker })).status, 200);
  assert.equal((await call('POST', `/offers/${second.id}/reject`, { token: worker })).status, 200);

  // Answering twice → 409
  const again = await call('POST', `/offers/${first.id}/reject`, { token: worker });
  assert.equal(again.status, 409);
  assert.equal(again.json.error.code, 'OFFER_STATE');

  const answered = await call('GET', '/offers?status=answered', { token: worker });
  assert.equal(answered.json.data.offers.length, 2);

  // "Refresh": reload the store from disk → same state
  const reloaded = createDb(dbPath);
  const statuses = Object.fromEntries(reloaded.state.offers.map((o) => [o.id, o.status]));
  assert.equal(statuses[first.id], 'accepted');
  assert.equal(statuses[second.id], 'rejected');
});

test('expired offers move to expired tab and cannot be answered', async () => {
  const worker = await login('worker');

  const expired = await call('GET', '/offers?status=expired', { token: worker });
  const ids = expired.json.data.offers.map((o) => o.id);
  assert.ok(ids.includes('o_komi_eski'));

  const res = await call('POST', '/offers/o_komi_eski/accept', { token: worker });
  assert.equal(res.status, 409);
  assert.equal(res.json.error.code, 'OFFER_EXPIRED');
  assert.equal(res.json.error.message, 'Teklifin süresi doldu');
});

test('unknown offer id → 404, wrong role → 401', async () => {
  const worker = await login('worker');
  const employer = await login('employer');
  assert.equal((await call('POST', '/offers/o_yok/accept', { token: worker })).status, 404);
  assert.equal((await call('GET', '/offers/o_yok', { token: worker })).status, 404);
  assert.equal((await call('POST', '/offers/o_garson/accept', { token: employer })).status, 401);
});

test('bearer scheme is case-insensitive', async () => {
  const res = await fetch(`${baseUrl}/candidates`, { headers: { Authorization: 'bearer dev-employer' } });
  assert.equal(res.status, 200);
});

test('a worker cannot see or answer offers of another worker', async () => {
  db.state.users.push({ id: 'u_other', role: 'worker', name: 'Other', token: 'dev-other' });
  const list = await call('GET', '/offers?status=pending', { token: 'dev-other' });
  assert.equal(list.json.data.offers.length, 0);
  assert.equal(list.json.data.pendingCount, 0);
  const res = await call('POST', '/offers/o_barista/accept', { token: 'dev-other' });
  assert.equal(res.status, 404);
  db.state.users.pop();
});

test('malformed JSON → 400, oversized body → 413, both in the error envelope', async () => {
  const bad = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: '{"role": ',
  });
  assert.equal(bad.status, 400);
  assert.equal((await bad.json()).error.code, 'VALIDATION');

  const big = await call('POST', '/auth/login', { body: { role: 'x'.repeat(200 * 1024) } });
  assert.equal(big.status, 413);
  assert.equal(big.json.error.code, 'PAYLOAD_TOO_LARGE');
});

test('failed write rolls back in-memory state (no half-applied accept)', async () => {
  const worker = await login('worker');
  const pending = await call('GET', '/offers?status=pending', { token: worker });
  const target = pending.json.data.offers[0].id;

  const originalSave = db.save;
  db.save = () => { throw new Error('disk full'); };
  const originalError = console.error;
  console.error = () => {};
  try {
    const res = await call('POST', `/offers/${target}/accept`, { token: worker });
    assert.equal(res.status, 500);
    assert.equal(res.json.error.code, 'INTERNAL');
  } finally {
    db.save = originalSave;
    console.error = originalError;
  }

  const offer = db.state.offers.find((o) => o.id === target);
  assert.equal(offer.status, 'pending');
});

test('offer detail includes city and note', async () => {
  const worker = await login('worker');
  const res = await call('GET', '/offers/o_barista', { token: worker });
  assert.equal(res.status, 200);
  assert.equal(res.json.data.city, 'İstanbul');
  assert.ok(res.json.data.note);
});
