import React from 'react';
import ReactDOM from 'react-dom/client';
// This imports the main component from src/App.jsx
import App from './App.jsx'; 

// Renders the App component into the HTML element with id="root"
ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);