const express = require('express');
const { requireRole } = require('../middleware/auth');
const { sendOk } = require('../utils/http');
const { listCandidates } = require('../services/candidateService');

function candidatesRouter(db) {
  const router = express.Router();

  // GET /candidates?tab=perfect|similar&sort=recommended|near|rating
  router.get('/', requireRole(db, 'employer'), (req, res) => {
    const { tab, sort } = req.query;
    sendOk(res, listCandidates(db, { tab, sort }));
  });

  return router;
}

module.exports = { candidatesRouter };
