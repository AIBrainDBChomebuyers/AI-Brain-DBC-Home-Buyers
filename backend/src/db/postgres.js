// PostgreSQL access.
//
// The important thing in this file is withRoles(). Every policy in the
// database filters on app.roles, and a connection that has not set it sees
// nothing at all - current_setting returns NULL, the array overlap returns
// NULL, and the row is excluded. That is deliberate: the failure mode is an
// empty result, never someone else's data.
//
// Because the setting is per-session and the pool hands out shared
// connections, it MUST be set with SET LOCAL inside a transaction. A plain
// SET would leak the last user's roles to whoever gets that connection next.
import pg from 'pg';
import { config, ROLES } from '../config/index.js';

export const pool = new pg.Pool(config.postgres);

export class ScopeError extends Error {}

/**
 * Run a query as a user holding `roles`.
 *
 * @param {string[]} roles  the caller's roles, from their verified token
 * @param {(client: pg.PoolClient) => Promise<T>} fn
 * @returns {Promise<T>}
 */
export async function withRoles(roles, fn) {
  if (!Array.isArray(roles) || roles.length === 0) {
    throw new ScopeError('no roles supplied; every query must name its caller');
  }
  const unknown = roles.filter((r) => !ROLES.includes(r));
  if (unknown.length) {
    throw new ScopeError(`unknown role(s): ${unknown.join(', ')}`);
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // Parameterised, so a role string can never terminate the statement.
    await client.query('SELECT set_config($1, $2, true)', ['app.roles', roles.join(',')]);
    const result = await fn(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    throw err;
  } finally {
    client.release();
  }
}

export async function healthcheck() {
  const { rows } = await pool.query('SELECT 1 AS ok');
  return rows[0]?.ok === 1;
}
