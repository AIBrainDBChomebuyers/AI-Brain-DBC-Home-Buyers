import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    // The API is same-origin in production; proxying in development keeps
    // the frontend's fetch paths identical in both.
    proxy: { '/api': { target: 'http://localhost:4000', changeOrigin: true } },
  },
});
