import { ipcMain } from 'electron';
import { ping } from '../../backend/services/testService.js';

import { runQuery } from '../../backend/services/queryService.js';

export function registerQueryHandler() {
  ipcMain.handle('runQuery', async (_, query, params = {}) => {
    try {
      const result = await runQuery(query, params);
      return result.map(record => record.toObject()); // Convert records to plain objects
    } catch (err) {
      console.error('Error executing query:', err);
      throw new Error('Query execution failed');
    }
  });
}