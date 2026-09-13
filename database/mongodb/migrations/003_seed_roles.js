// Generated 2026-09-13 16:17 UTC by build_migrations.py from db_export/schema.json
// Do not edit by hand; re-run the generator instead.
// Run with:  mongosh "<connection string>" <this file>

// Section 9's access table, as data. Upsert so re-running is harmless.

db.roles.updateOne({ _id: "executive" }, { $set: {"label": "Owners / Executives", "description": "Full access across all departments."} }, { upsert: true });
db.roles.updateOne({ _id: "acquisitions" }, { $set: {"label": "Acquisitions", "description": "Acquisition, property, comparable sales, deal and relevant financial data."} }, { upsert: true });
db.roles.updateOne({ _id: "construction" }, { $set: {"label": "Construction", "description": "Projects, scopes, contractors, vendors, budgets, historical construction costs."} }, { upsert: true });
db.roles.updateOne({ _id: "property_management" }, { $set: {"label": "Property Management", "description": "Rentals, tenants, maintenance, property information."} }, { upsert: true });
db.roles.updateOne({ _id: "accounting" }, { $set: {"label": "Accounting", "description": "Authorized financial and accounting information."} }, { upsert: true });
db.roles.updateOne({ _id: "va" }, { $set: {"label": "VAs / Other", "description": "Only information required for their specific responsibilities."} }, { upsert: true });

print("roles: " + db.roles.countDocuments({}));
