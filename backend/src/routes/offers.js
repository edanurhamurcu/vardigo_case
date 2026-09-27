const express = require('express');
const { requireRole } = require('../middleware/auth');
const { sendOk } = require('../utils/http');
const offers = require('../services/offerService');

function offersRouter(db) {
  const router = express.Router();
  const employer = requireRole(db, 'employer');
  const worker = requireRole(db, 'worker');

  // Employer: send interview requests to selected candidates
  router.post('/', employer, (req, res) => {
    sendOk(res, offers.createOffers(db, req.body), 201);
  });

  // Worker: list offers by tab
  router.get('/', worker, (req, res) => {
    sendOk(res, offers.listOffers(db, { status: req.query.status, workerId: req.user.id }));
  });

  router.get('/:id', worker, (req, res) => {
    sendOk(res, offers.getOffer(db, req.params.id, req.user.id));
  });

  router.post('/:id/accept', worker, (req, res) => {
    sendOk(res, offers.acceptOffer(db, req.params.id, req.user.id));
  });

  router.post('/:id/reject', worker, (req, res) => {
    sendOk(res, offers.rejectOffer(db, req.params.id, req.user.id));
  });

  return router;
}

module.exports = { offersRouter };
