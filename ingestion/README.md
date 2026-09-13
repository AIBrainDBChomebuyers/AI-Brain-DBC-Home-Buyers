# Ingestion

Nothing runs here yet. The pipeline that produces `../database/` lives
outside this project, in:

    ../../Data Retrieval/extraction_tool/

It reads the source PDFs and spreadsheets in `Data Retrieval/` and writes the
JSON this application loads. Its own README describes how; the short version
is `client_review/rebuild_all.sh`, which rebuilds the workbooks, the database
export and the migrations, then runs three test suites over the result.

To bring new data across after that:

    npm run db:sync     # copy the export into database/
    npm run db:load     # upsert it into both stores

This directory is where that pipeline moves when it is folded into the
application — as a service that watches for new documents rather than a
script somebody remembers to run. Until then it stays where it is, because
it is working and the move would buy nothing.
