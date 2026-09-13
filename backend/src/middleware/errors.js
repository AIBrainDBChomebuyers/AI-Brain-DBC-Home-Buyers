import { ScopeError as PgScopeError } from '../db/postgres.js';
import { ScopeError as MongoScopeError } from '../db/mongo.js';

export function notFound(req, res) {
  res.status(404).json({ error: 'not found' });
}

// A scope error is a bug in the caller, not a database failure, so it gets a
// 400 rather than a 500 - and the message never includes what the query was
// reaching for.
export function errorHandler(err, req, res, _next) {
  if (err instanceof PgScopeError || err instanceof MongoScopeError) {
    req.log?.warn({ err: err.message }, 'scope error');
    return res.status(400).json({ error: err.message });
  }
  req.log?.error({ err }, 'unhandled error');
  return res.status(500).json({ error: 'internal error' });
}
