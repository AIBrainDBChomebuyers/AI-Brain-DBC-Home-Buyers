// Append-only record of who asked what.
//
// The audit_logs collection is created with insert and find granted and
// nothing else, so this can add to the record but never revise it. That is
// the point: an audit trail an application can edit is not an audit trail.
import { db } from '../db/mongo.js';

export async function record(entry) {
  const conn = await db();
  await conn.collection('audit_logs').insertOne({
    ts: new Date(),
    ...entry,
  });
}

/** Log every answered request, including which roles were in force. */
export function auditRequests(req, res, next) {
  const started = Date.now();
  res.on('finish', () => {
    if (!req.user) return;
    record({
      user_id: req.user.id,
      roles: req.user.roles,
      method: req.method,
      path: req.originalUrl,
      status: res.statusCode,
      duration_ms: Date.now() - started,
      // Whether the question left our infrastructure - section 6.7 requires
      // this to be answerable per request, not inferred later.
      left_our_cloud: Boolean(res.locals.leftOurCloud),
    }).catch((err) => req.log?.error({ err }, 'audit write failed'));
  });
  next();
}
