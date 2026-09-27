/**
 * Response envelope helpers.
 *
 * success: { ok: true,  data: ... }
 * error:   { ok: false, error: { code, message } }
 */

class AppError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const errors = {
  validation: (message) => new AppError(400, 'VALIDATION', message),
  unauthorized: (message = 'Giriş yapmalısın') => new AppError(401, 'UNAUTHORIZED', message),
  notFound: (code, message) => new AppError(404, code, message),
  conflict: (code, message) => new AppError(409, code, message),
};

function sendOk(res, data, status = 200) {
  res.status(status).json({ ok: true, data });
}

module.exports = { AppError, errors, sendOk };
