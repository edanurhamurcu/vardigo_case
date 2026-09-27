const { errors } = require('../utils/http');

/**
 * Reads "Authorization: Bearer <token>" and checks the user's role.
 * Spec: wrong role → 401 (not 403), so both cases return 401.
 */
function requireRole(db, role) {
  return (req, _res, next) => {
    const header = req.headers.authorization || '';
    const [scheme, token] = header.split(' ');
    // Auth scheme names are case-insensitive (RFC 7235).
    if (!scheme || scheme.toLowerCase() !== 'bearer' || !token) {
      throw errors.unauthorized('Authorization: Bearer <token> başlığı gerekli');
    }

    const user = db.state.users.find((u) => u.token === token);
    if (!user) throw errors.unauthorized('Geçersiz token');
    if (user.role !== role) {
      throw errors.unauthorized(`Bu işlem için ${role} rolü gerekli`);
    }

    req.user = user;
    next();
  };
}

module.exports = { requireRole };
