import React, { useEffect, useRef, useState } from 'react';
import * as d3 from 'd3';

const D3Graph = ({ data }) => {
  const graphRef = useRef(null);
  const [selectedItem, setSelectedItem] = useState(null);
  const [showFullJson, setShowFullJson] = useState(false);

  useEffect(() => {
    if (!data || !Array.isArray(data.nodes) || !Array.isArray(data.links)) return;

    // Extract nodes and links for D3 processing
    const nodes = data.nodes.map((record) => record.n); // Use raw node data
    const links = data.links.map((record) => ({
      source: record.r.startNodeElementId,
      target: record.r.endNodeElementId,
      type: record.r.type,
      raw: record.r,
    }));

    const svg = d3.select(graphRef.current);
    svg.selectAll('*').remove(); // Clear previous render

    const width = 800;
    const height = 600;

    const simulation = d3
      .forceSimulation(nodes)
      .force('link', d3.forceLink(links).id((d) => d.elementId).distance(100))
      .force('charge', d3.forceManyBody().strength(-300))
      .force('center', d3.forceCenter(width / 2, height / 2));

    // Render links (lines)
    const link = svg
      .append('g')
      .selectAll('line')
      .data(links)
      .enter()
      .append('line')
      .style('stroke', '#aaa')
      .style('stroke-width', 2)
      .on('dblclick', (event, d) => {
        setSelectedItem({ ...d, type: 'link' });
        setShowFullJson(false); // Reset collapsible section
      });

    // Render relation type as text over links
    const linkText = svg
      .append('g')
      .selectAll('text')
      .data(links)
      .enter()
      .append('text')
      .text((d) => d.type)
      .attr('font-size', 12)
      .attr('fill', '#555');

    // Render nodes (circles)
    const node = svg
      .append('g')
      .selectAll('circle')
      .data(nodes)
      .enter()
      .append('circle')
      .attr('r', 10)
      .attr('fill', '#69b3a2')
      .on('click', (event, d) => {
        setSelectedItem({ ...d, type: 'node' });
        setShowFullJson(false); // Reset collapsible section
      })
      .call(
        d3
          .drag()
          .on('start', (event, d) => {
            if (!event.active) simulation.alphaTarget(0.3).restart();
            d.fx = d.x;
            d.fy = d.y;
          })
          .on('drag', (event, d) => {
            d.fx = event.x;
            d.fy = event.y;
          })
          .on('end', (event, d) => {
            if (!event.active) simulation.alphaTarget(0);
            d.fx = null;
            d.fy = null;
          })
      );

    const text = svg
      .append('g')
      .selectAll('text')
      .data(nodes)
      .enter()
      .append('text')
      .text((d) => d.labels[0]) // Use raw `labels`
      .attr('x', 15)
      .attr('y', 5);

    simulation.on('tick', () => {
      link
        .attr('x1', (d) => d.source.x)
        .attr('y1', (d) => d.source.y)
        .attr('x2', (d) => d.target.x)
        .attr('y2', (d) => d.target.y);

      linkText
        .attr('x', (d) => (d.source.x + d.target.x) / 2)
        .attr('y', (d) => (d.source.y + d.target.y) / 2);

      node.attr('cx', (d) => d.x).attr('cy', (d) => d.y);

      text.attr('x', (d) => d.x + 15).attr('y', (d) => d.y + 5);
    });
  }, [data]);

  return (
    <div style={{ display: 'flex' }}>
      <svg ref={graphRef} width={800} height={600} style={{ border: '1px solid black' }}></svg>
      {selectedItem && (
        <div style={{ marginLeft: '20px', width: '300px', padding: '10px', border: '1px solid #ccc' }}>
          <h3>Details</h3>
          {selectedItem.type === 'link' ? (
            <>
              <h4>Relationship</h4>
              <p><strong>Type:</strong> {selectedItem.type}</p>
              <p><strong>Properties:</strong></p>
              <pre>{JSON.stringify(selectedItem.raw.properties, null, 2)}</pre>
              <h4>Display/Positional Details</h4>
              <p>
                <strong>Source Node:</strong> {selectedItem.source.elementId || JSON.stringify(selectedItem.source)}
              </p>
              <p>
                <strong>Target Node:</strong> {selectedItem.target.elementId || JSON.stringify(selectedItem.target)}
              </p>
            </>
          ) : (
            <>
              <h4>Node</h4>
              <p><strong>Label:</strong> {selectedItem.labels?.[0]}</p>
              <p><strong>Properties:</strong></p>
              <pre>{JSON.stringify(selectedItem.properties, null, 2)}</pre>
              <h4>Display/Positional Details</h4>
              <p><strong>Position:</strong> x: {selectedItem.x?.toFixed(2)}, y: {selectedItem.y?.toFixed(2)}</p>
              <p><strong>Velocity:</strong> vx: {selectedItem.vx?.toFixed(4)}, vy: {selectedItem.vy?.toFixed(4)}</p>
            </>
          )}
          <div>
            <button
              style={{
                marginTop: '10px',
                padding: '5px',
                border: 'none',
                background: '#007bff',
                color: 'white',
                cursor: 'pointer',
              }}
              onClick={() => setShowFullJson((prev) => !prev)}
            >
              {showFullJson ? 'Hide Full JSON' : 'Show Full JSON'}
            </button>
            {showFullJson && (
              <div style={{ marginTop: '10px', padding: '10px', border: '1px solid #eee', background: '#f9f9f9' }}>
                <h4>Full JSON</h4>
                <pre>{JSON.stringify(selectedItem.raw || selectedItem, null, 2)}</pre>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default D3Graph;
