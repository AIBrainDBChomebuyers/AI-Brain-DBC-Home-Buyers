// Generated 2026-09-13 16:17 UTC by build_migrations.py from db_export/schema.json
// Do not edit by hand; re-run the generator instead.
// Run with:  mongosh "<connection string>" <this file>

// Destroys all data.
db.users.drop();
db.roles.drop();
db.conversations.drop();
db.audit_logs.drop();
db.ingested_files.drop();
db.ceo_briefing.drop();
db.ceo_conclusions.drop();
db.ceo_narrative.drop();
db.column_catalog.drop();
db.file_index.drop();
db.glossary.drop();
db.guide_sections.drop();
db.headline_kpis.drop();
db.source_documents.drop();
db.tab_relationships.drop();
