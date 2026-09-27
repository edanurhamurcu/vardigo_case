const { test } = require('node:test');
const assert = require('node:assert/strict');
const { formatRemaining, resolveRelativeDate, isExpired, HOUR, MINUTE } = require('../src/utils/time');

const NOW = Date.UTC(2026, 8, 27, 12, 0, 0);

test('formatRemaining floors hours and minutes', () => {
  const expiresAt = new Date(NOW + 21 * HOUR + 32 * MINUTE + 59 * 1000).toISOString();
  assert.equal(formatRemaining(expiresAt, NOW), '21 saat 32 dakika');
});

test('formatRemaining returns null once expired', () => {
  assert.equal(formatRemaining(new Date(NOW).toISOString(), NOW), null);
  assert.equal(isExpired(new Date(NOW).toISOString(), NOW), true);
});

test('resolveRelativeDate handles seed placeholders and passes ISO dates through', () => {
  assert.equal(resolveRelativeDate('USE_NOW_PLUS_21H32M', NOW), new Date(NOW + 21 * HOUR + 32 * MINUTE).toISOString());
  assert.equal(resolveRelativeDate('USE_NOW_MINUS_02H00M', NOW), new Date(NOW - 2 * HOUR).toISOString());
  assert.equal(resolveRelativeDate('2026-09-20T11:45:00.000Z', NOW), '2026-09-20T11:45:00.000Z');
});
