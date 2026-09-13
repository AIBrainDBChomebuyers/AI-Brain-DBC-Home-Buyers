// Generated 2026-09-13 16:17 UTC by build_migrations.py from db_export/schema.json
// Do not edit by hand; re-run the generator instead.
// Run with:  mongosh "<connection string>" <this file>

// Search indexes first, then the ordinary ones.
try { db.ceo_conclusions.dropSearchIndex("vector_index"); } catch (e) { print("ceo_conclusions: " + e.message); }
try { db.ceo_narrative.dropSearchIndex("vector_index"); } catch (e) { print("ceo_narrative: " + e.message); }
try { db.glossary.dropSearchIndex("vector_index"); } catch (e) { print("glossary: " + e.message); }
try { db.guide_sections.dropSearchIndex("vector_index"); } catch (e) { print("guide_sections: " + e.message); }
try { db.source_documents.dropSearchIndex("vector_index"); } catch (e) { print("source_documents: " + e.message); }
try { db.tab_relationships.dropSearchIndex("vector_index"); } catch (e) { print("tab_relationships: " + e.message); }
db.ceo_briefing.dropIndexes();
db.ceo_conclusions.dropIndexes();
db.ceo_narrative.dropIndexes();
db.column_catalog.dropIndexes();
db.file_index.dropIndexes();
db.glossary.dropIndexes();
db.guide_sections.dropIndexes();
db.headline_kpis.dropIndexes();
db.source_documents.dropIndexes();
db.tab_relationships.dropIndexes();
db.users.dropIndexes();
db.roles.dropIndexes();
db.conversations.dropIndexes();
db.audit_logs.dropIndexes();
db.ingested_files.dropIndexes();
