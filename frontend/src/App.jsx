import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ChatPage } from './pages/ChatPage.jsx';
import { PropertiesPage } from './pages/PropertiesPage.jsx';

export function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/chat" replace />} />
        <Route path="/chat" element={<ChatPage />} />
        <Route path="/properties" element={<PropertiesPage />} />
      </Routes>
    </BrowserRouter>
  );
}
