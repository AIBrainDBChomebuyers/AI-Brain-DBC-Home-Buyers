import { useState } from 'react';
import { api } from '../api/client.js';

export function ChatPage() {
  const [messages, setMessages] = useState([]);
  const [draft, setDraft] = useState('');
  const [busy, setBusy] = useState(false);

  async function send(event) {
    event.preventDefault();
    const question = draft.trim();
    if (!question || busy) return;
    setDraft('');
    setMessages((m) => [...m, { role: 'user', text: question }]);
    setBusy(true);
    try {
      const reply = await api.ask(question);
      setMessages((m) => [...m, { role: 'assistant', text: reply.answer, citations: reply.citations }]);
    } catch (err) {
      setMessages((m) => [...m, { role: 'error', text: err.message }]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="chat">
      <h1>DBC AI Brain</h1>
      <ol className="messages">
        {messages.map((m, i) => (
          <li key={i} className={m.role}>{m.text}</li>
        ))}
      </ol>
      <form onSubmit={send}>
        <input
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          placeholder="Ask about a property, a deal, or a number…"
          disabled={busy}
        />
        <button type="submit" disabled={busy || !draft.trim()}>Ask</button>
      </form>
    </main>
  );
}
