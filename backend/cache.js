const { LRUCache } = require('lru-cache');

const cache = new LRUCache({
  max: 1000,
  ttl: 1000 * 60 * 60 * 24, // 24 hours
});

function normalizeLinkedInURL(url) {
  let normalized = String(url || '').toLowerCase().trim();
  normalized = normalized.replace(/^https?:\/\//, '');
  normalized = normalized.replace(/^www\./, '');
  const queryIdx = normalized.indexOf('?');
  if (queryIdx !== -1) normalized = normalized.slice(0, queryIdx);
  while (normalized.endsWith('/')) normalized = normalized.slice(0, -1);
  return normalized;
}

function get(url) {
  return cache.get(normalizeLinkedInURL(url));
}

function set(url, value) {
  cache.set(normalizeLinkedInURL(url), value);
}

module.exports = { get, set, normalizeLinkedInURL };
