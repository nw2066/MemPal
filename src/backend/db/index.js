import neo4j from 'neo4j-driver'
import dotenv from 'dotenv'

dotenv.config();

const driver = neo4j.driver(
  process.env.NEO4J_URI,
  neo4j.auth.basic(
    process.env.NEO4J_USERNAME,
    process.env.NEO4J_PASSWORD
  )
)

// Connection verification (temporary code)
async function verifyConnection() {
  const session = driver.session();

  try {
    const query = 'RETURN "Connection successful" AS message';
    const result = await session.run(query);
    const message = result.records[0].get('message');
    console.log('Neo4j Connection Verification:', message);
  } catch (err) {
    console.error('Neo4j Connection Failed:', err);
  } finally {
    await session.close();
  }
}

// Run the verification when this file is loaded
// You can comment this out or remove it later
verifyConnection().catch((err) => console.error('Error during verification:', err));

export default driver
