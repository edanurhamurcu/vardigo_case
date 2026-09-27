const express = require('express');
const { errors, sendOk } = require('../utils/http');

function authRouter(db) {
  const router = express.Router();

  // POST /auth/login  { "role": "employer" | "worker" }
  router.post('/login', (req, res) => {
    const role = req.body && req.body.role;
    if (role !== 'employer' && role !== 'worker') {
      throw errors.validation('role "employer" veya "worker" olmalı');
    }
    const user = db.state.users.find((u) => u.role === role);
    sendOk(res, { token: user.token, role: user.role, name: user.name });
  });

  return router;
}

module.exports = { authRouter };
