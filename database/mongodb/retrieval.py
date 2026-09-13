"""Scoped MongoDB retrieval for the AI Brain.

Copied into db_export/mongodb/ by build_migrations.py.

Every function here takes ``roles`` - the roles of the user who asked - and
applies them as a filter before anything is read or ranked. That is the whole
point of the module.

Postgres enforces the permission scope itself: RLS applies to every
statement, so a query that forgets to filter returns exactly what a query
that remembers would. The mistake cannot be expressed. MongoDB has no
equivalent - the scope lives in ``allowed_roles`` and applies only because
the caller applies it. On this dataset one forgotten filter exposes 3,172 of
4,946 documents, 1,742 of which mention profit, margin or a five-figure sum.

Atlas Vector Search cannot be fronted by a filtered view either, because
``$vectorSearch`` must run on the collection that owns the index. So the
usual "grant read on a filtered view" answer is not available on the RAG
path, and the guarantee has to live in one place that is hard to bypass.
This is that place.

    from retrieval import scoped_find, vector_search

    docs = scoped_find(db, "source_documents", ["acquisitions"],
                       {"property_key": "144 hobbit"})
    hits = vector_search(db, "source_documents", ["va"], query_vector, limit=8)

Calling ``db.source_documents.find(...)`` directly bypasses all of it.
"""
from __future__ import annotations

from typing import Any, Iterable, Mapping, Sequence

# Section 9. A role outside this set is a bug, not a permission.
ROLES = {
    "executive", "acquisitions", "construction",
    "property_management", "accounting", "va",
}


class ScopeError(ValueError):
    """Raised rather than quietly returning everything, or nothing."""


def _scope(roles: Sequence[str]) -> dict:
    """The filter clause for a caller holding ``roles``.

    An empty or unknown role list raises. Returning a filter that matches
    nothing would look like fail-closed, but a caller that passes no roles
    has a bug, and a query that silently returns zero rows is a bug that
    reaches production disguised as an empty dataset.
    """
    if not roles:
        raise ScopeError("no roles supplied; every read must name its caller")
    unknown = set(roles) - ROLES
    if unknown:
        raise ScopeError(f"unknown role(s): {sorted(unknown)}")
    return {"allowed_roles": {"$in": list(roles)}}


def scoped_find(db, collection: str, roles: Sequence[str],
                query: Mapping[str, Any] | None = None,
                **kwargs) -> Iterable[dict]:
    """``find`` with the caller's scope applied, and no way to drop it.

    An ``allowed_roles`` key in ``query`` is refused rather than merged: the
    only scope that applies is the caller's.
    """
    query = dict(query or {})
    if "allowed_roles" in query:
        raise ScopeError("allowed_roles is set from the caller's roles, "
                         "not from the query")
    query.update(_scope(roles))
    return db[collection].find(query, **kwargs)


def scoped_aggregate(db, collection: str, roles: Sequence[str],
                     pipeline: Sequence[Mapping[str, Any]], **kwargs):
    """``aggregate`` with the scope forced into the first stage.

    Prepending the match rather than appending it means no stage ever sees a
    document the caller may not read. An accumulator over the wrong rows
    leaks the answer even when the rows themselves are dropped afterwards.
    """
    return db[collection].aggregate([{"$match": _scope(roles)}, *pipeline], **kwargs)


def vector_search(db, collection: str, roles: Sequence[str],
                  query_vector: Sequence[float], limit: int = 8,
                  num_candidates: int | None = None,
                  extra_filter: Mapping[str, Any] | None = None,
                  index_name: str = "vector_index") -> list[dict]:
    """Nearest-neighbour search with the scope applied INSIDE the search.

    ``allowed_roles`` is a declared filter field on the vector index, so
    Atlas narrows the candidate set before it ranks. Filtering afterwards
    would be both wrong and slow: wrong because the top-k would be chosen
    from documents the caller cannot read, so the answer quietly loses
    recall, and slow because the index does the work twice.
    """
    scope: dict[str, Any] = _scope(roles)
    if extra_filter:
        if "allowed_roles" in extra_filter:
            raise ScopeError("allowed_roles is set from the caller's roles")
        scope = {"$and": [scope, dict(extra_filter)]}
    stage = {
        "$vectorSearch": {
            "index": index_name,
            "path": "embedding",
            "queryVector": list(query_vector),
            "numCandidates": num_candidates or max(limit * 20, 100),
            "limit": limit,
            "filter": scope,
        }
    }
    project = {"$project": {"embedding": 0,
                            "score": {"$meta": "vectorSearchScore"}}}
    return list(db[collection].aggregate([stage, project]))


def keyword_search(db, collection: str, roles: Sequence[str],
                   text: str, limit: int = 8) -> list[dict]:
    """The keyword half of hybrid retrieval, scoped the same way."""
    query = {"$text": {"$search": text}, **_scope(roles)}
    return list(db[collection]
                .find(query, {"score": {"$meta": "textScore"}})
                .sort([("score", {"$meta": "textScore"})])
                .limit(limit))
