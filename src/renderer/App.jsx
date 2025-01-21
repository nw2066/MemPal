import React from 'react';
import BasicQueryComp from './components/basicQueryComp';
import GraphComponent from './components/d3CRUD'
import GraphContainer from './components/readOnlyNeo4j/neo4jDataGraphWrapper';

const App = () => {

  return (
    <div>
      <GraphContainer />
    </div>
  );
};

export default App;