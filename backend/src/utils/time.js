const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;

/**
 * Resolves seed placeholders like "USE_NOW_PLUS_21H32M" or "USE_NOW_MINUS_02H00M"
 * into an ISO date relative to `now`. Real ISO strings are returned as-is.
 */
function resolveRelativeDate(value, now = Date.now()) {
  const match = /^USE_NOW_(PLUS|MINUS)_(\d+)H(\d+)M$/.exec(value);
  if (!match) return value;
  const [, sign, hours, minutes] = match;
  const offset = Number(hours) * HOUR + Number(minutes) * MINUTE;
  return new Date(sign === 'PLUS' ? now + offset : now - offset).toISOString();
}

/** "21 saat 32 dakika" — floor(hours) + floor(minutes). Returns null if already expired. */
function formatRemaining(expiresAt, now = Date.now()) {
  const diff = new Date(expiresAt).getTime() - now;
  if (diff <= 0) return null;
  const hours = Math.floor(diff / HOUR);
  const minutes = Math.floor((diff % HOUR) / MINUTE);
  return `${hours} saat ${minutes} dakika`;
}

function isExpired(expiresAt, now = Date.now()) {
  return new Date(expiresAt).getTime() <= now;
}

module.exports = { resolveRelativeDate, formatRemaining, isExpired, HOUR, MINUTE };
