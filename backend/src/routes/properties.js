import { Router } from 'express';
import { z } from 'zod';
import { withRoles } from '../db/postgres.js';

export const properties = Router();

const listQuery = z.object({
  status: z.string().optional(),
  county: z.string().optional(),
  exit_strategy: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
  offset: z.coerce.number().int().min(0).default(0),
});

// Note there is no permission filter in this SQL. There does not need to be:
// row-level security applies it, so the same statement returns a different
// set of rows for an executive and for a VA. Adding one here would be a
// second place to get it wrong.
properties.get('/', async (req, res, next) => {
  try {
    const q = listQuery.parse(req.query);
    const where = [];
    const params = [];
    for (const [col, val] of [['deal_status', q.status], ['property_county', q.county],
                              ['exit_strategy', q.exit_strategy]]) {
      if (val) { params.push(val); where.push(`${col} = $${params.length}`); }
    }
    params.push(q.limit, q.offset);
    const sql = `SELECT property_key, canonical_address, property_city, property_county,
                        deal_status, exit_strategy, sold_year, purchase_price, sale_price
                 FROM deal_portfolio
                 ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
                 ORDER BY canonical_address
                 LIMIT $${params.length - 1} OFFSET $${params.length}`;
    const rows = await withRoles(req.user.roles, (c) => c.query(sql, params).then((r) => r.rows));
    res.json({ count: rows.length, results: rows });
  } catch (err) { next(err); }
});

properties.get('/:key', async (req, res, next) => {
  try {
    const rows = await withRoles(req.user.roles, (c) =>
      c.query('SELECT * FROM v_deal_full WHERE property_key = $1', [req.params.key])
        .then((r) => r.rows));
    if (!rows.length) return res.status(404).json({ error: 'not found' });
    res.json(rows[0]);
  } catch (err) { next(err); }
});
