// Generated 2026-09-13 13:21 UTC by build_migrations.py from db_export/schema.json
// Do not edit by hand; re-run the generator instead.
// Run with:  mongosh "<connection string>" <this file>

// Permission first: every retrieval narrows to what the asking
// user may see before it ranks anything, so allowed_roles leads
// every compound index rather than trailing it.

db.ceo_briefing.createIndex({ allowed_roles: 1 });
db.ceo_conclusions.createIndex({ allowed_roles: 1 });
db.ceo_narrative.createIndex({ allowed_roles: 1 });
db.column_catalog.createIndex({ allowed_roles: 1 });
db.file_index.createIndex({ allowed_roles: 1 });
db.glossary.createIndex({ allowed_roles: 1 });
db.guide_sections.createIndex({ allowed_roles: 1 });
db.headline_kpis.createIndex({ allowed_roles: 1 });
db.source_documents.createIndex({ allowed_roles: 1 });
db.tab_relationships.createIndex({ allowed_roles: 1 });

// Retrieval fields.
db.source_documents.createIndex({ allowed_roles: 1, property_key: 1 });
db.source_documents.createIndex({ folder: 1 });
db.source_documents.createIndex({ allowed_roles: 1, source_file: 1, chunk_index: 1 });
db.ceo_narrative.createIndex({ section: 1 });
db.file_index.createIndex({ file: 1 });
db.column_catalog.createIndex({ column_name: 1 });

// Keyword half of hybrid retrieval (section 6.5). Mongo
// allows one text index per collection, so only the embedded
// collections get one.
db.ceo_conclusions.createIndex({ text: "text" }, { name: "ix_ceo_conclusions_fulltext" });
db.ceo_narrative.createIndex({ text: "text" }, { name: "ix_ceo_narrative_fulltext" });
db.glossary.createIndex({ text: "text" }, { name: "ix_glossary_fulltext" });
db.guide_sections.createIndex({ text: "text" }, { name: "ix_guide_sections_fulltext" });
db.source_documents.createIndex({ text: "text" }, { name: "ix_source_documents_fulltext" });
db.tab_relationships.createIndex({ text: "text" }, { name: "ix_tab_relationships_fulltext" });

// Runtime.
db.users.createIndex({ email: 1 }, { unique: true });
db.conversations.createIndex({ user_id: 1, updated_at: -1 });
db.audit_logs.createIndex({ ts: -1 });
db.audit_logs.createIndex({ user_id: 1, ts: -1 });
db.audit_logs.createIndex({ left_our_cloud: 1, ts: -1 });
db.ingested_files.createIndex({ sha256: 1 }, { unique: true, sparse: true });
db.ingested_files.createIndex({ file: 1 });

// ---- Atlas Vector Search ----
// Run once the `embedding` field is populated (text-embedding-3-small,
// 1536 dimensions - see EMBEDDING_DIMS in build_migrations.py).
//
// allowed_roles, sensitivity and property_key are declared as `filter` fields
// so the permission scope applies INSIDE the vector search rather than after
// it. Post-filtering a top-k result set both shrinks the answer and puts a
// security boundary in the wrong place. This is the Mongo half of what
// 003_enable_rls.sql does on the Postgres side.
db.ceo_conclusions.createSearchIndex(
  {
  "name": "vector_index",
  "type": "vectorSearch",
  "definition": {
    "fields": [
      {
        "type": "vector",
        "path": "embedding",
        "numDimensions": 1536,
        "similarity": "cosine"
      },
      {
        "type": "filter",
        "path": "allowed_roles"
      },
      {
        "type": "filter",
        "path": "sensitivity"
      },
      {
        "type": "filter",
        "path": "department"
      }
    ]
  }
}
);
db.ceo_narrative.createSearchIndex(
  {
  "name": "vector_index",
  "type": "vectorSearch",
  "definition": {
    "fields": [
      {
        "type": "vector",
        "path": "embedding",
        "numDimensions": 1536,
        "similarity": "cosine"
      },
      {
        "type": "filter",
        "path": "allowed_roles"
      },
      {
        "type": "filter",
        "path": "sensitivity"
      },
      {
        "type": "filter",
        "path": "department"
      }
    ]
  }
}
);
db.glossary.createSearchIndex(
  {
  "name": "vector_index",
  "type": "vectorSearch",
  "definition": {
    "fields": [
      {
        "type": "vector",
        "path": "embedding",
        "numDimensions": 1536,
        "similarity": "cosine"
      },
      {
        "type": "filter",
        "path": "allowed_roles"
      },
      {
        "type": "filter",
        "path": "sensitivity"
      },
      {
        "type": "filter",
        "path": "department"
      }
    ]
  }
}
);
db.guide_sections.createSearchIndex(
  {
  "name": "vector_index",
  "type": "vectorSearch",
  "definition": {
    "fields": [
      {
        "type": "vector",
        "path": "embedding",
        "numDimensions": 1536,
        "similarity": "cosine"
      },
      {
        "type": "filter",
        "path": "allowed_roles"
      },
      {
        "type": "filter",
        "path": "sensitivity"
      },
      {
        "type": "filter",
        "path": "department"
      }
    ]
  }
}
);
db.source_documents.createSearchIndex(
  {
  "name": "vector_index",
  "type": "vectorSearch",
  "definition": {
    "fields": [
      {
        "type": "vector",
        "path": "embedding",
        "numDimensions": 1536,
        "similarity": "cosine"
      },
      {
        "type": "filter",
        "path": "allowed_roles"
      },
      {
        "type": "filter",
        "path": "sensitivity"
      },
      {
        "type": "filter",
        "path": "department"
      },
      {
        "type": "filter",
        "path": "property_key"
      },
      {
        "type": "filter",
        "path": "folder"
      }
    ]
  }
}
);
db.tab_relationships.createSearchIndex(
  {
  "name": "vector_index",
  "type": "vectorSearch",
  "definition": {
    "fields": [
      {
        "type": "vector",
        "path": "embedding",
        "numDimensions": 1536,
        "similarity": "cosine"
      },
      {
        "type": "filter",
        "path": "allowed_roles"
      },
      {
        "type": "filter",
        "path": "sensitivity"
      },
      {
        "type": "filter",
        "path": "department"
      }
    ]
  }
}
);
