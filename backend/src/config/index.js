// One place that reads the environment, so nothing else has to guess what a
// variable is called or what happens when it is missing.
import 'dotenv/config';

function required(name) {
  const v = process.env[name];
  if (!v) throw new Error(`missing required environment variable: ${name}`);
  return v;
}

export const config = {
  env: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 4000),
  corsOrigin: process.env.CORS_ORIGIN ?? 'http://localhost:5173',
  logLevel: process.env.LOG_LEVEL ?? 'info',

  // The API connects as the APPLICATION role, which holds SELECT and nothing
  // else. Never the owner: the owner has BYPASSRLS, and connecting as it
  // would quietly turn off every permission policy in the database.
  postgres: {
    host: process.env.PGHOST ?? 'localhost',
    port: Number(process.env.PGPORT ?? 5432),
    database: process.env.PGDATABASE ?? 'ai_brain',
    user: process.env.PGUSER ?? 'ai_brain_app',
    password: process.env.PGPASSWORD ?? '',
    max: Number(process.env.PG_POOL_MAX ?? 10),
  },

  mongo: {
    uri: process.env.MONGODB_ATLAS_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017',
    db: process.env.MONGODB_DB ?? 'ai_brain',
  },

  keycloak: {
    url: process.env.KEYCLOAK_URL ?? 'http://localhost:8080',
    realm: process.env.KEYCLOAK_REALM ?? 'dbc',
    clientId: process.env.KEYCLOAK_CLIENT_ID ?? 'ai-brain-api',
  },

  embeddings: {
    model: process.env.EMBEDDING_MODEL ?? 'text-embedding-3-small',
    dimensions: Number(process.env.EMBEDDING_DIMENSIONS ?? 1536),
  },

  requiredInProduction() {
    if (this.env !== 'production') return;
    ['PGPASSWORD', 'KEYCLOAK_CLIENT_SECRET', 'MONGODB_URI'].forEach(required);
  },
};

// Section 9. The single source of truth for what a role may be; anything
// else arriving in a token is a bug, not a permission.
export const ROLES = Object.freeze([
  'executive', 'acquisitions', 'construction',
  'property_management', 'accounting', 'va',
]);
