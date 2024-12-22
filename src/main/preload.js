console.log('Preload script loaded'); // Debug log to confirm loading
import { contextBridge, ipcRenderer } from 'electron';

contextBridge.exposeInMainWorld('api', {
  ping: () => 'pong',
});