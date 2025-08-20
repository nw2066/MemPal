# Neo4j + Node.js Starter

## Prerequisites
- [Node.js](https://nodejs.org/) (v18 or later recommended)
- [Neo4j](https://neo4j.com/download/) (Desktop, Aura, or self-hosted)

---

## Setup

1. **Install Neo4j**
   - Download and install Neo4j Desktop, or run a local/remote Neo4j server.
   - Make sure it’s running and note the URI, username, and password.

2. **Configure environment variables**
   - Create a `.env` file in the project root:
     ```env
     NEO4J_URI=bolt://localhost:7687
     NEO4J_USERNAME=neo4j
     NEO4J_PASSWORD=your_password_here
     ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Run the development server**
    ```bash
    npm run dev
    ```