// MongoDB access.
//
// Postgres enforces the permission scope itself. MongoDB does not - there is
// no row-level security, and a query that forgets to filter on allowed_roles
// returns everything. On this dataset that is 3,172 of 4,946 documents, most
// of which mention profit or a five-figure sum.
//
// Atlas Vector Search cannot be fronted by a filtered view either, because
// $vectorSearch has to run on the collection that owns the index. So the
// guarantee lives here instead, in functions that take the caller's roles as
// a required argument. Nothing else in the application should touch a
// collection directly.
import { MongoClient } from 'mongodb';
import { config, ROLES } from '../config/index.js';

const client = new MongoClient(config.mongo.uri);
let connected = false;

export async function db() {
  if (!connected) { await client.connect(); connected = true; }
  return client.db(config.mongo.db);
}

export class ScopeError extends Error {}

function scope(roles) {
  if (!Array.isArray(roles) || roles.length === 0) {
    throw new ScopeError('no roles supplied; every read must name its caller');
  }
  const unknown = roles.filter((r) => !ROLES.includes(r));
  if (unknown.length) throw new ScopeError(`unknown role(s): ${unknown.join(', ')}`);
  return { allowed_roles: { $in: roles } };
}

/** find(), with the caller's scope applied and no way to drop it. */
export async function scopedFind(collection, roles, query = {}, options = {}) {
  if ('allowed_roles' in query) {
    throw new ScopeError("allowed_roles comes from the caller's roles, not the query");
  }
  const conn = await db();
  return conn.collection(collection).find({ ...query, ...scope(roles) }, options).toArray();
}

/**
 * aggregate(), with the scope forced into the FIRST stage.
 *
 * Prepending rather than appending matters: an accumulator that runs over
 * rows the caller cannot read leaks the answer even when those rows are
 * dropped from the output afterwards.
 */
export async function scopedAggregate(collection, roles, pipeline = [], options = {}) {
  const conn = await db();
  return conn.collection(collection)
    .aggregate([{ $match: scope(roles) }, ...pipeline], options).toArray();
}

/**
 * Nearest-neighbour search with the scope applied INSIDE the search.
 *
 * allowed_roles is a declared filter field on the vector index, so Atlas
 * narrows the candidates before it ranks them. Filtering afterwards would be
 * wrong as well as slow - the top-k would be chosen from documents the
 * caller cannot see, so the answer silently loses recall.
 */
export async function vectorSearch(collection, roles, queryVector, {
  limit = 8, numCandidates, extraFilter, indexName = 'vector_index',
} = {}) {
  let filter = scope(roles);
  if (extraFilter) {
    if ('allowed_roles' in extraFilter) {
      throw new ScopeError("allowed_roles comes from the caller's roles");
    }
    filter = { $and: [filter, extraFilter] };
  }
  const conn = await db();
  return conn.collection(collection).aggregate([
    {
      $vectorSearch: {
        index: indexName,
        path: 'embedding',
        queryVector,
        numCandidates: numCandidates ?? Math.max(limit * 20, 100),
        limit,
        filter,
      },
    },
    { $project: { embedding: 0, score: { $meta: 'vectorSearchScore' } } },
  ]).toArray();
}

export async function close() {
  if (connected) { await client.close(); connected = false; }
}
