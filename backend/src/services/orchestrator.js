// Turns a question into an answer.
//
// Not implemented yet - this is the shape the rest of the system is built
// around, so the seam exists before the work does.
//
// The intended path, per the technical document:
//
//   1. classify   is this a question about figures (Postgres) or about what
//                 a document says (Mongo), or both?
//   2. retrieve   figures via text-to-SQL against the schema comments;
//                 passages via hybrid vector + keyword search
//   3. generate   answer from what came back, citing the source document
//   4. record     what was asked, by whom, and whether it left our cloud
//
// Both retrieval paths take the user's roles. Neither is reachable without
// them: Postgres refuses through RLS, Mongo through the scoped helpers.
export async function answer({ user, message, conversationId }) {
  return {
    conversation_id: conversationId ?? null,
    question: message,
    answer: 'The orchestrator is not implemented yet.',
    citations: [],
    roles_applied: user.roles,
    leftOurCloud: false,
  };
}
