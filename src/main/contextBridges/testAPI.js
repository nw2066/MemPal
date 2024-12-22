import { contextBridge, ipcRenderer } from 'electron';

export function registerTestApi() {
    contextBridge.exposeInMainWorld('api', {
      ping: async () => ipcRenderer.invoke('ping'),
    });
  }