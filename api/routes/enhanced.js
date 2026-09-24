import express from 'express';
import { authenticate } from '../middleware/auth.js';
import { anchorFetch, firecrawlScrape, integrationStatus, openRouterChat } from '../services/external-integrations.js';

const router = express.Router();
router.use(authenticate);

router.get('/status', (_req, res) => res.json({ integrations: integrationStatus() }));

router.post('/scrape/firecrawl', async (req, res) => {
  try { return res.json({ provider: 'firecrawl', result: await firecrawlScrape(req.body || {}) }); }
  catch (error) { return res.status(error.status || 502).json({ error: error.message, code: error.code || 'UPSTREAM_ERROR' }); }
});

router.post('/scrape/anchor', async (req, res) => {
  try { return res.json({ provider: 'anchor', result: await anchorFetch(req.body || {}) }); }
  catch (error) { return res.status(error.status || 502).json({ error: error.message, code: error.code || 'UPSTREAM_ERROR' }); }
});

router.post('/ai/chat', async (req, res) => {
  try { return res.json({ provider: 'openrouter', result: await openRouterChat(req.body || {}) }); }
  catch (error) { return res.status(error.status || 502).json({ error: error.message, code: error.code || 'UPSTREAM_ERROR' }); }
});

export default router;
