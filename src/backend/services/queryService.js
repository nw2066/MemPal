import driver from '../db/index.js'

export async function runQuery(cypher, params = {}) {
  const session = driver.session()
  try {
    const result = await session.run(cypher, params)
    return result.records
  } finally {
    await session.close()
  }
}

async function verifyQueryService() {
  try {
    // Test query: Adjust as necessary
    const query = 'RETURN "Query service is working" AS message';
    const result = await runQuery(query);

    if (result.length > 0) {
      const message = result[0].get('message');
      console.log('Query Service Verification:', message);
    } else {
      console.log('Query Service Verification: No results returned.');
    }
  } catch (err) {
    console.error('Query Service Failed:', err);
  }
}

//verifyQueryService().catch((err) => console.error('Error during query verification:', err));
