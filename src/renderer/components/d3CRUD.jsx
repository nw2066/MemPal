import React, { useEffect, useState } from 'react';
import * as d3 from 'd3';

const d3CRUDGraphComponent = () => {
  const [nodes, setNodes] = useState([
    { id: '1', x: 100, y: 100 },
    { id: '2', x: 300, y: 200 },
  ]);
  const [links, setLinks] = useState([{ source: '1', target: '2' }]);
  const [contextMenu, setContextMenu] = useState(null);

  useEffect(() => {
    const svg = d3.select('#graph-svg');

    const updateGraph = () => {
      svg.selectAll('*').remove(); // Clear existing elements

      const linkGroup = svg
        .selectAll('.link')
        .data(links)
        .enter()
        .append('line')
        .attr('class', 'link')
        .attr('x1', (d) => nodes.find((n) => n.id === d.source).x)
        .attr('y1', (d) => nodes.find((n) => n.id === d.source).y)
        .attr('x2', (d) => nodes.find((n) => n.id === d.target).x)
        .attr('y2', (d) => nodes.find((n) => n.id === d.target).y)
        .attr('stroke', '#999')
        .attr('stroke-width', 2);

      const nodeGroup = svg
        .selectAll('.node')
        .data(nodes)
        .enter()
        .append('circle')
        .attr('class', 'node')
        .attr('r', 10)
        .attr('fill', 'steelblue')
        .attr('cx', (d) => d.x)
        .attr('cy', (d) => d.y)
        .call(
          d3
            .drag()
            .on('start', (event, d) => {
              d3.select(event.sourceEvent.target).raise();
            })
            .on('drag', (event, d) => {
              d.x = event.x;
              d.y = event.y;
              setNodes([...nodes]);
            })
        )
        .on('contextmenu', (event, d) => {
            event.preventDefault();
            event.stopPropagation(); // Prevent the canvas handler from firing
            setContextMenu({
              x: event.pageX,
              y: event.pageY,
              node: d,
              type: 'node',
            });
          });

    svg.on('contextmenu', (event) => {
        event.preventDefault();
        setContextMenu({
            x: event.pageX,
            y: event.pageY,
            type: 'canvas',
        });
    });

      const textGroup = svg
        .selectAll('.label')
        .data(nodes)
        .enter()
        .append('text')
        .attr('class', 'label')
        .attr('x', (d) => d.x + 12)
        .attr('y', (d) => d.y - 12)
        .text((d) => d.id)
        .attr('font-size', '10px')
        .attr('fill', '#333');
    };

    updateGraph();
  }, [nodes, links]);

  const handleAddNode = () => {
    const newNodeId = (nodes.length + 1).toString();
    const { x, y } = contextMenu || { x: 200, y: 200 }; // Use context menu coordinates
    const svgRect = document.getElementById('graph-svg').getBoundingClientRect();
    setNodes([...nodes, { id: newNodeId, x: x - svgRect.left, y: y - svgRect.top }]);
    setContextMenu(null);
  };

  const handleDeleteNode = (node) => {
    setNodes(nodes.filter((n) => n.id !== node.id));
    setLinks(links.filter((link) => link.source !== node.id && link.target !== node.id));
    setContextMenu(null);
  };

  const handleAddLink = (source, target) => {
    if (source !== target && !links.find((link) => link.source === source && link.target === target)) {
      setLinks([...links, { source, target }]);
    }
    setContextMenu(null);
  };

  const renderContextMenu = () => {
    if (!contextMenu) return null;
  
    const { x, y, node, type } = contextMenu;
  
    const handleAddLinkFromMenu = (sourceId) => {
      const targetId = document.getElementById('link-target-input')?.value;
      if (targetId && sourceId) {
        handleAddLink(sourceId, targetId);
      }
    };
  
    return (
      <div
        style={{
          position: 'absolute',
          top: y,
          left: x,
          backgroundColor: 'white',
          border: '1px solid #ccc',
          padding: '10px',
          zIndex: 1000,
        }}
      >
        {type === 'canvas' && <button onClick={handleAddNode}>Add Node</button>}
        {type === 'node' && (
          <>
            <button onClick={() => handleDeleteNode(node)}>Delete Node</button>
            <div>
              <input
                id="link-target-input"
                type="text"
                placeholder="Target Node ID"
                style={{ marginRight: '5px' }}
              />
              <button onClick={() => handleAddLinkFromMenu(node.id)}>Add Link</button>
            </div>
          </>
        )}
      </div>
    );
  };

  return (
    <div>
        <h1>Basic d3 graph - right click to modify</h1>
        {renderContextMenu()}
        <svg id="graph-svg" width="800" height="600" style={{ border: '1px solid black' }}></svg>
    </div>
  );
};

export default d3CRUDGraphComponent;
