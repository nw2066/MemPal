import React, { useState } from 'react';

const BasicQueryComp = () => {
  const [query, setQuery] = useState('');
  const [result, setResult] = useState(null);

  const executeQuery = async () => {
    try {
      const response = await window.api.runQuery(query);
      setResult(response);
    } catch (err) {
      console.error('Query execution error:', err);
      setResult({ error: err.message });
    }
  };

  return (
    <div>
      <textarea
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Enter your Cypher query here"
      ></textarea>
      <button onClick={executeQuery}>Run Query</button>
      <pre>{JSON.stringify(result, null, 2)}</pre>
    </div>
  );
};

export default BasicQueryComp;