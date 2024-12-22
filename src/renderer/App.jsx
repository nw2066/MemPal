import React, { useEffect, useState } from 'react';

const App = () => {
  const [response, setResponse] = useState('');

  const testPing = async () => {
    if (window.api && typeof window.api.ping === 'function') {
      try {
        const result = await window.api.ping(); // Wait for the promise to resolve
        setResponse(result); // Update the state with the response
      } catch (error) {
        console.error('Error calling ping:', error);
        setResponse('Error occurred while calling ping');
      }
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
