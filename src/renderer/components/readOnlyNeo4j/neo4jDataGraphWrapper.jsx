import React, { useState , useEffect } from 'react';
import D3Graph from './d3GraphComp';

const GraphContainer = () => {
  const [data, setData] = useState({ nodes: [], links: [] });

  const fetchNodesAndLinks = async () => {
    const nodeQuery = `
      MATCH (n)
      RETURN n
    `;
    const linkQuery = `
      MATCH ()-[r]->()
      RETURN r
    `;

    try {
      // Fetch raw nodes and relationships
      const nodeResult = await window.api.runQuery(nodeQuery);
      const linkResult = await window.api.runQuery(linkQuery);

      setData({ nodes: nodeResult, links: linkResult });
    } catch (err) {
      console.error('Error fetching graph data:', err);
    }
  };

  useEffect(() => {
    console.log('Updated data:', data);
  }, [data]);

  return (
    <div>
      <button onClick={fetchNodesAndLinks}>Load Graph</button>
      <D3Graph data={data} />
    </div>
  );
};

export default GraphContainer;
