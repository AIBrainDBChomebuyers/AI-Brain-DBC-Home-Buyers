// Identity. Keycloak is authoritative; this verifies what it issued.
//
// Roles are taken from the verified token and nowhere else. They are never
// read from a header, a query string or a request body, because every
// permission decision downstream - the Postgres session variable, the Mongo
// filter - is made from them.
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { config, ROLES } from '../config/index.js';

const jwks = createRemoteJWKSet(
  new URL(`${config.keycloak.url}/realms/${config.keycloak.realm}/protocol/openid-connect/certs`),
);

export async function authenticate(req, res, next) {
  const header = req.get('authorization') ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'missing bearer token' });

  try {
    const { payload } = await jwtVerify(token, jwks, {
      issuer: `${config.keycloak.url}/realms/${config.keycloak.realm}`,
      audience: config.keycloak.clientId,
    });

    // Keep only roles this system defines. An unrecognised role in a token
    // is dropped rather than passed along - the database would reject it,
    // and a confusing error at the boundary beats one three layers down.
    const claimed = payload.realm_access?.roles ?? [];
    const roles = claimed.filter((r) => ROLES.includes(r));
    if (roles.length === 0) {
      return res.status(403).json({ error: 'no application role assigned' });
    }

    req.user = { id: payload.sub, email: payload.email, name: payload.name, roles };
    return next();
  } catch (err) {
    req.log?.warn({ err: err.message }, 'token rejected');
    return res.status(401).json({ error: 'invalid token' });
  }
}

/** Require one of `allowed` on top of authentication. */
export function requireRole(...allowed) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ error: 'not authenticated' });
    if (!req.user.roles.some((r) => allowed.includes(r))) {
      return res.status(403).json({ error: 'insufficient role' });
    }
    return next();
  };
}
