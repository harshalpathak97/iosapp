# LinkedIn Scraper Backend

Backend service for the QR Visitor Registration iPad app. Resolves a LinkedIn profile URL into `{ name, title, company }` so the iPad can register visitors who aren't pre-loaded in the local `attendees.json`.

## Honest warnings

- LinkedIn actively blocks scraping. The session-cookie + Puppeteer-stealth approach used here works for low-volume use (event registration with a few dozen scans), but you should expect:
  - The `li_at` cookie to be invalidated periodically -- you'll have to refresh it
  - Rate limiting after bursts of scrapes -- the scraper adds a 2-5s random delay between calls
  - The LinkedIn account whose cookie you use to potentially get flagged. **Use a dedicated, throwaway account.**
- This is a ToS violation. Use at your own risk for legitimate event-registration use cases.

## Setup

Requires Node.js 18+.

```bash
cd backend
cp .env.example .env
# Edit .env -- see comments inside for how to get the LinkedIn cookie
npm install
npm start
```

The server will listen on port 3000 by default.

### Getting the `li_at` cookie

1. Log into [linkedin.com](https://www.linkedin.com) in Chrome with a dedicated account.
2. Open DevTools (Cmd-Opt-I), go to **Application** > **Cookies** > `https://www.linkedin.com`.
3. Find the cookie named `li_at` and copy its **Value**.
4. Paste into `LINKEDIN_LI_AT_COOKIE=` in your `.env` file.

## API

### `GET /health`

```
200 OK
{ "ok": true, "hasCookie": true }
```

### `POST /scrape`

```
Authorization: Bearer <API_SHARED_SECRET>
Content-Type: application/json

{ "linkedinURL": "https://www.linkedin.com/in/foo" }
```

Successful response:
```json
{
  "name": "Jane Doe",
  "title": "VP of Engineering",
  "company": "Acme Corp",
  "headline": "VP of Engineering at Acme Corp",
  "linkedinURL": "https://www.linkedin.com/in/foo",
  "cached": false
}
```

Error responses:
- `400` -- malformed request body
- `401` -- missing/wrong `Authorization` header, OR LinkedIn session expired
- `404` -- profile not accessible
- `429` -- LinkedIn rate-limited
- `500` -- scraper failure (selectors stale, network, etc.)

## Quick test

```bash
curl -X POST http://localhost:3000/scrape \
  -H "Authorization: Bearer your-shared-secret" \
  -H "Content-Type: application/json" \
  -d '{"linkedinURL":"https://www.linkedin.com/in/williamhgates"}'
```

## Connecting from the iPad app

In the iPad app, go to **Settings** > **LinkedIn Scraper Backend**:
- **Backend URL**: `http://<your-machine-LAN-IP>:3000` for local dev, or the public HTTPS URL of a deployed instance
- **Shared Secret**: the same `API_SHARED_SECRET` from your `.env`

For production, deploy this behind HTTPS (Caddy, Nginx, or a platform like Fly.io / Render). The iPad app prefers HTTPS; HTTP requires an App Transport Security exception in `Info.plist`.

## Caching

Results are cached in-memory for 24 hours per LinkedIn URL (normalized). Restart clears the cache. If you need persistence or multi-instance caching, swap `cache.js` for Redis.

## Selector drift

LinkedIn changes its DOM regularly. If the scraper starts returning empty names or wrong fields, update the selectors in `scraper.js` (`scrapeLinkedInProfile` -> `page.evaluate`). The OpenGraph `<meta>` fallback is more stable than CSS selectors, so the scraper falls back to it when the primary selectors fail.
