// Generated 2026-09-13 13:21 UTC by build_migrations.py from db_export/schema.json
// Do not edit by hand; re-run the generator instead.
// Run with:  mongosh "<connection string>" <this file>

// Passages the chatbot quotes, the small tables it loads whole,
// and the collections the application itself runs on.

// ceo_briefing - 31 documents, fetched whole, from tab 'CEO Briefing'
db.createCollection("ceo_briefing", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// ceo_conclusions - 16 documents, embedded, from tab 'Deal Conclusions'
db.createCollection("ceo_conclusions", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles",
      "text"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      },
      "text": {
        "bsonType": "string"
      },
      "embedding": {
        "bsonType": [
          "array",
          "null"
        ]
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// ceo_narrative - 23 documents, embedded, from tab 'CEO Briefing'
db.createCollection("ceo_narrative", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles",
      "text"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      },
      "text": {
        "bsonType": "string"
      },
      "embedding": {
        "bsonType": [
          "array",
          "null"
        ]
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// column_catalog - 291 documents, fetched whole, from tab 'Column Map'
db.createCollection("column_catalog", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// file_index - 767 documents, fetched whole, from tab 'File Index'
db.createCollection("file_index", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// glossary - 37 documents, embedded, from tab 'Data Dictionary'
db.createCollection("glossary", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles",
      "text"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      },
      "text": {
        "bsonType": "string"
      },
      "embedding": {
        "bsonType": [
          "array",
          "null"
        ]
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// guide_sections - 12 documents, embedded, from tab 'Introduction'
db.createCollection("guide_sections", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles",
      "text"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      },
      "text": {
        "bsonType": "string"
      },
      "embedding": {
        "bsonType": [
          "array",
          "null"
        ]
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// headline_kpis - 17 documents, fetched whole, from tab 'Cover'
db.createCollection("headline_kpis", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// source_documents - 3,728 documents, embedded
db.createCollection("source_documents", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles",
      "text"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      },
      "text": {
        "bsonType": "string"
      },
      "embedding": {
        "bsonType": [
          "array",
          "null"
        ]
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// tab_relationships - 26 documents, embedded, from tab 'Relationships'
db.createCollection("tab_relationships", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "department",
      "sensitivity",
      "allowed_roles",
      "text"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "department": {
        "bsonType": "string"
      },
      "sensitivity": {
        "bsonType": "string"
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      },
      "text": {
        "bsonType": "string"
      },
      "embedding": {
        "bsonType": [
          "array",
          "null"
        ]
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});


// ---- Runtime. Phase 1 does not run without these. ----

// users - Mirrors the Keycloak subject. Keycloak is authoritative for identity; this is the local projection that decides both the Mongo filter and the app.roles value sent to Postgres.
db.createCollection("users", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "email",
      "roles",
      "active"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "email": {
        "bsonType": "string"
      },
      "name": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "department": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "roles": {
        "bsonType": "array",
        "minItems": 1,
        "items": {
          "enum": [
            "executive",
            "acquisitions",
            "construction",
            "property_management",
            "accounting",
            "va"
          ]
        }
      },
      "active": {
        "bsonType": "bool"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// roles - Section 9's table, as data.
db.createCollection("roles", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "label",
      "description"
    ],
    "properties": {
      "_id": {
        "enum": [
          "executive",
          "acquisitions",
          "construction",
          "property_management",
          "accounting",
          "va"
        ]
      },
      "label": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// conversations - Chat history. Phase 2 reads it back as memory.
db.createCollection("conversations", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "user_id",
      "created_at"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "user_id": {
        "bsonType": "string"
      },
      "title": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "messages": {
        "bsonType": "array"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": [
          "date",
          "null"
        ]
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// audit_logs - Append-only. Grant the application insert and find, never update or delete.
db.createCollection("audit_logs", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "ts",
      "user_id",
      "role"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "ts": {
        "bsonType": "date"
      },
      "user_id": {
        "bsonType": "string"
      },
      "role": {
        "bsonType": "string"
      },
      "question": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "model_provider": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "model_name": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "skill_or_agent": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "tools_called": {
        "bsonType": "array"
      },
      "collections_accessed": {
        "bsonType": "array"
      },
      "sql_executed": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "sql_row_count": {
        "bsonType": [
          "int",
          "long",
          "null"
        ]
      },
      "document_ids": {
        "bsonType": "array"
      },
      "external_systems": {
        "bsonType": "array"
      },
      "context_chars_sent": {
        "bsonType": [
          "int",
          "long",
          "null"
        ]
      },
      "max_sensitivity_sent": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "left_our_cloud": {
        "bsonType": "bool"
      },
      "citations": {
        "bsonType": "array"
      },
      "approvals": {
        "bsonType": "array"
      },
      "result": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "latency_ms": {
        "bsonType": [
          "int",
          "long",
          "null"
        ]
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

// ingested_files - Pointer to the binary in MinIO/S3 (section 6.7). The bytes never enter Mongo; only the reference and its scope.
db.createCollection("ingested_files", {
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "_id",
      "file",
      "allowed_roles"
    ],
    "properties": {
      "_id": {
        "bsonType": "string"
      },
      "file": {
        "bsonType": "string"
      },
      "folder": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "object_key": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "bytes": {
        "bsonType": [
          "int",
          "long",
          "null"
        ]
      },
      "content_type": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "sha256": {
        "bsonType": [
          "string",
          "null"
        ]
      },
      "ingested_at": {
        "bsonType": [
          "date",
          "null"
        ]
      },
      "allowed_roles": {
        "bsonType": "array",
        "minItems": 1
      }
    }
  }
},
  validationLevel: "moderate", validationAction: "error"
});

