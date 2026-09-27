/**
 * Minimal JSON file store.
 *
 * - On first start, seed/seed.json is copied to data/db.json
 *   (relative "USE_NOW_..." dates are resolved at that moment).
 * - Every write is saved atomically (tmp file + rename), so accept/reject
 *   survives restarts and page refreshes.
 */
const fs = require('fs');
const path = require('path');
const { resolveRelativeDate } = require('./utils/time');

const SEED_PATH = path.join(__dirname, '..', 'seed', 'seed.json');
const DEFAULT_DB_PATH = path.join(__dirname, '..', 'data', 'db.json');

function buildInitialState(now = Date.now()) {
  const seed = JSON.parse(fs.readFileSync(SEED_PATH, 'utf8'));
  return {
    users: seed.users,
    candidates: seed.candidates,
    labels: seed.labels,
    job: seed.job,
    offers: seed.offers.map((offer) => ({
      ...offer,
      expiresAt: resolveRelativeDate(offer.expiresAt, now),
      createdAt: new Date(now).toISOString(),
    })),
  };
}

function createDb(dbPath = process.env.DB_PATH || DEFAULT_DB_PATH) {
  let state;

  function save() {
    fs.mkdirSync(path.dirname(dbPath), { recursive: true });
    const tmp = `${dbPath}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(state, null, 2));
    fs.renameSync(tmp, dbPath);
  }

  function reset() {
    state = buildInitialState();
    save();
  }

  /**
   * Runs a mutation and persists it as one unit. If the write fails (disk full,
   * permissions…) the in-memory state is rolled back, so memory and disk never disagree.
   */
  function transaction(mutate) {
    const snapshot = structuredClone(state);
    try {
      const result = mutate(state);
      store.save(); // via the public object so tests can simulate a failing disk
      return result;
    } catch (err) {
      state = snapshot;
      throw err;
    }
  }

  if (fs.existsSync(dbPath)) {
    try {
      state = JSON.parse(fs.readFileSync(dbPath, 'utf8'));
    } catch (err) {
      throw new Error(`${dbPath} okunamadı (${err.message}). Sıfırlamak için: npm run reset`);
    }
  } else {
    reset();
  }

  const store = {
    get state() {
      return state;
    },
    save,
    reset,
    transaction,
  };
  return store;
}

module.exports = { createDb, DEFAULT_DB_PATH };
