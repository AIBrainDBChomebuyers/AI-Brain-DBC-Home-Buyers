// The only place the frontend talks to the API.
//
// The access token goes on every request and the roles are never sent from
// here - the backend reads them out of the verified token. A role in a
// request body would be a client asserting its own permissions.
let getToken = async () => null;

export function configureAuth(tokenProvider) { getToken = tokenProvider; }

async function request(path, options = {}) {
  const token = await getToken();
  const res = await fetch(`/api${path}`, {
    ...options,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error ?? `request failed: ${res.status}`);
  }
  return res.json();
}

export const api = {
  health: () => request('/health'),
  listProperties: (params = {}) =>
    request(`/properties?${new URLSearchParams(params)}`),
  getProperty: (key) => request(`/properties/${encodeURIComponent(key)}`),
  ask: (message, conversationId) =>
    request('/chat', {
      method: 'POST',
      body: JSON.stringify({ message, conversation_id: conversationId }),
    }),
};
