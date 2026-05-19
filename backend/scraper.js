const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

puppeteer.use(StealthPlugin());

let browserPromise = null;

async function getBrowser() {
  if (browserPromise) return browserPromise;
  browserPromise = puppeteer.launch({
    headless: 'new',
    executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
    ],
  });
  return browserPromise;
}

function randomDelay(minMs, maxMs) {
  const ms = Math.floor(Math.random() * (maxMs - minMs)) + minMs;
  return new Promise((resolve) => setTimeout(resolve, ms));
}

class ScrapeError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

async function scrapeLinkedInProfile(profileURL) {
  const cookie = process.env.LINKEDIN_LI_AT_COOKIE;
  if (!cookie) {
    throw new ScrapeError('Backend missing LINKEDIN_LI_AT_COOKIE env var', 500);
  }

  const browser = await getBrowser();
  const page = await browser.newPage();

  try {
    await page.setUserAgent(
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' +
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );
    await page.setViewport({ width: 1280, height: 800 });

    await page.setCookie({
      name: 'li_at',
      value: cookie,
      domain: '.linkedin.com',
      path: '/',
      secure: true,
      httpOnly: true,
    });

    const response = await page.goto(profileURL, {
      waitUntil: 'domcontentloaded',
      timeout: 30000,
    });

    if (!response) throw new ScrapeError('No response from LinkedIn', 500);

    const status = response.status();
    if (status === 999) throw new ScrapeError('LinkedIn rate-limited the request', 429);
    if (status === 404) throw new ScrapeError('LinkedIn profile not found', 404);
    if (status === 401 || status === 403) {
      throw new ScrapeError('LinkedIn session cookie is invalid or expired', 401);
    }
    if (status >= 400) throw new ScrapeError(`LinkedIn returned status ${status}`, 500);

    // Detect login redirect (LinkedIn often returns 200 but with a login wall)
    const currentURL = page.url();
    if (currentURL.includes('/login') || currentURL.includes('/authwall')) {
      throw new ScrapeError('LinkedIn redirected to login -- session cookie likely invalid', 401);
    }

    await page.waitForSelector('h1', { timeout: 10000 }).catch(() => {});

    const profile = await page.evaluate(() => {
      function textOf(selector) {
        const el = document.querySelector(selector);
        return el ? el.textContent.trim().replace(/\s+/g, ' ') : '';
      }
      function metaContent(property) {
        const el = document.querySelector(`meta[property="${property}"]`);
        return el ? el.getAttribute('content') : '';
      }

      let name =
        textOf('h1.text-heading-xlarge') ||
        textOf('h1.top-card-layout__title') ||
        textOf('h1');

      let headline =
        textOf('div.text-body-medium.break-words') ||
        textOf('h2.top-card-layout__headline') ||
        textOf('.pv-text-details__left-panel .text-body-medium');

      // Fallback to OpenGraph meta
      if (!name) {
        const ogTitle = metaContent('og:title');
        if (ogTitle) name = ogTitle.split('|')[0].split(' - ')[0].trim();
      }
      if (!headline) {
        const ogDesc = metaContent('og:description');
        if (ogDesc) headline = ogDesc.trim();
      }

      return { name, headline };
    });

    if (!profile.name) {
      throw new ScrapeError('Could not extract profile name -- selectors may be stale', 500);
    }

    // Parse "Title at Company" from the headline
    let title = '';
    let company = '';
    if (profile.headline) {
      const atIdx = profile.headline.toLowerCase().lastIndexOf(' at ');
      if (atIdx !== -1) {
        title = profile.headline.slice(0, atIdx).trim();
        company = profile.headline.slice(atIdx + 4).trim();
      } else {
        title = profile.headline.trim();
      }
    }

    // Politeness delay to avoid burst patterns
    await randomDelay(2000, 5000);

    return {
      name: profile.name,
      title: title,
      company: company,
      headline: profile.headline,
      linkedinURL: profileURL,
    };
  } finally {
    await page.close().catch(() => {});
  }
}

async function shutdown() {
  if (browserPromise) {
    const browser = await browserPromise;
    await browser.close().catch(() => {});
    browserPromise = null;
  }
}

module.exports = { scrapeLinkedInProfile, ScrapeError, shutdown };
