require('dotenv').config();

const express = require('express');
const cache = require('./cache');
const { scrapeLinkedInProfile, ScrapeError, shutdown } = require('./scraper');

const PORT = parseInt(process.env.PORT || '3000', 10);
const SHARED_SECRET = process.env.API_SHARED_SECRET;

if (!SHARED_SECRET) {
  console.error('FATAL: API_SHARED_SECRET env var not set. Refusing to start.');
  process.exit(1);
}

const app = express();
app.use(express.json());

function requireAuth(req, res, next) {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Bearer token' });
  }
  const token = auth.slice('Bearer '.length).trim();
  if (token !== SHARED_SECRET) {
    return res.status(401).json({ error: 'Invalid shared secret' });
  }
  next();
}

app.get('/health', (req, res) => {
  res.json({ ok: true, hasCookie: Boolean(process.env.LINKEDIN_LI_AT_COOKIE) });
});

app.post('/scrape', requireAuth, async (req, res) => {
  const { linkedinURL } = req.body || {};
  if (!linkedinURL || typeof linkedinURL !== 'string') {
    return res.status(400).json({ error: 'Body must include { linkedinURL: string }' });
  }
  if (!linkedinURL.toLowerCase().includes('linkedin.com')) {
    return res.status(400).json({ error: 'URL must be a linkedin.com profile' });
  }

  const cached = cache.get(linkedinURL);
  if (cached) {
    console.log(`[cache hit] ${linkedinURL}`);
    return res.json({ ...cached, cached: true });
  }

  try {
    console.log(`[scrape] ${linkedinURL}`);
    const profile = await scrapeLinkedInProfile(linkedinURL);
    cache.set(linkedinURL, profile);
    res.json({ ...profile, cached: false });
  } catch (err) {
    if (err instanceof ScrapeError) {
      console.warn(`[scrape error ${err.status}] ${err.message}`);
      return res.status(err.status).json({ error: err.message });
    }
    console.error('[scrape error 500]', err);
    res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

const server = app.listen(PORT, () => {
  console.log(`LinkedIn scraper backend listening on port ${PORT}`);
});

process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down...');
  server.close();
  await shutdown();
  process.exit(0);
});
process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down...');
  server.close();
  await shutdown();
  process.exit(0);
});
