import { Router } from 'express';
import { healthcheck as pgOk } from '../db/postgres.js';
import { db } from '../db/mongo.js';

export const health = Router();

health.get('/health', async (_req, res) => {
  const checks = { postgres: false, mongodb: false };
  try { checks.postgres = await pgOk(); } catch { /* reported as false */ }
  try { await (await db()).command({ ping: 1 }); checks.mongodb = true; } catch { /* as above */ }
  const ok = Object.values(checks).every(Boolean);
  res.status(ok ? 200 : 503).json({ status: ok ? 'ok' : 'degraded', checks });
});
