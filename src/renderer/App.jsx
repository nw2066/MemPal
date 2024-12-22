import React, { useEffect, useState } from 'react';

const App = () => {
  const [response, setResponse] = useState('');

  const testPing = () => {
    if (window.api && typeof window.api.ping === 'function') {
      const result = window.api.ping();
      setResponse(result);
    } else {
      setResponse('API not available or ping function not found');
    }
  };

  return (
    <div>
      <h1>Electron + React App</h1>
      <button onClick={testPing}>Test Ping</button>
      <p>Ping Response: {response}</p>
    </div>
  );
};

export default App;
