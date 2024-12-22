import { ipcMain } from 'electron';
import { ping } from '../../backend/services/testService.js';

export function registerTestHandler() {
    ipcMain.handle('ping', async () => {
      return ping(); // Delegate to the service layer
    });
  }