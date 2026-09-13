import { Router } from 'express';
import { authenticate } from '../middleware/auth.js';
import { auditRequests } from '../middleware/audit.js';
import { health } from './health.js';
import { properties } from './properties.js';
import { chat } from './chat.js';

export const routes = Router();

// Health is deliberately open: a readiness probe cannot hold a token.
routes.use(health);

// Everything else requires an identity, and is recorded.
routes.use(authenticate, auditRequests);
routes.use('/properties', properties);
routes.use('/chat', chat);
