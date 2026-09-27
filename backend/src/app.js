const path = require('path');
const express = require('express');
const cors = require('cors');
const swaggerUi = require('swagger-ui-express');
const openApiSpec = require('../openapi.json');
const { AppError } = require('./utils/http');
const { authRouter } = require('./routes/auth');
const { candidatesRouter } = require('./routes/candidates');
const { offersRouter } = require('./routes/offers');

function createApp(db) {
  const app = express();

  app.use(cors());
  app.use(express.json());

  // Photos / logos / icons referenced by the API (e.g. /assets/photos/merve.png)
  app.use('/assets', express.static(path.join(__dirname, '..', 'public', 'assets')));

  // Interactive API docs → http://localhost:3000/api/docs
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(openApiSpec));

  const api = express.Router();
  api.get('/health', (_req, res) => res.json({ ok: true, data: { status: 'up' } }));
  api.use('/auth', authRouter(db));
  api.use('/candidates', candidatesRouter(db));
  api.use('/offers', offersRouter(db));
  app.use('/api', api);

  // Unknown route
  app.use((req, res) => {
    res.status(404).json({
      ok: false,
      error: { code: 'NOT_FOUND', message: `${req.method} ${req.path} bulunamadı` },
    });
  });

  // Central error handler → spec's error envelope
  // Express recognises error handlers by their 4 parameters, so _next must stay.
  app.use((err, _req, res, _next) => {
    if (err instanceof AppError) {
      return res.status(err.status).json({
        ok: false,
        error: { code: err.code, message: err.message },
      });
    }
    // Body parser errors (express.json) carry their own 4xx status.
    if (err.type === 'entity.parse.failed') {
      return res.status(400).json({
        ok: false,
        error: { code: 'VALIDATION', message: 'Geçersiz JSON gövdesi' },
      });
    }
    if (err.type === 'entity.too.large') {
      return res.status(413).json({
        ok: false,
        error: { code: 'PAYLOAD_TOO_LARGE', message: 'İstek gövdesi çok büyük' },
      });
    }
    if (Number.isInteger(err.status) && err.status >= 400 && err.status < 500) {
      return res.status(err.status).json({
        ok: false,
        error: { code: 'BAD_REQUEST', message: 'Geçersiz istek' },
      });
    }
    // Unknown errors: log the details, never leak stack traces to the client.
    console.error(err);
    return res.status(500).json({
      ok: false,
      error: { code: 'INTERNAL', message: 'Beklenmeyen bir hata oluştu' },
    });
  });

  return app;
}

module.exports = { createApp };
