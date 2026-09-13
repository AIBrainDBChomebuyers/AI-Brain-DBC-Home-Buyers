import { useEffect, useState } from 'react';
import { api } from '../api/client.js';

export function PropertiesPage() {
  const [rows, setRows] = useState([]);
  const [error, setError] = useState(null);

  useEffect(() => {
    api.listProperties({ limit: 50 })
      .then((r) => setRows(r.results))
      .catch((e) => setError(e.message));
  }, []);

  if (error) return <p className="error">{error}</p>;
  return (
    <main>
      <h1>Properties</h1>
      <table>
        <thead>
          <tr><th>Address</th><th>County</th><th>Status</th><th>Strategy</th></tr>
        </thead>
        <tbody>
          {rows.map((r) => (
            <tr key={r.property_key}>
              <td>{r.canonical_address}</td>
              <td>{r.property_county}</td>
              <td>{r.deal_status}</td>
              <td>{r.exit_strategy}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  );
}
