import { contextBridge, ipcRenderer } from 'electron';

export function registerApi() {
  contextBridge.exposeInMainWorld('api', {
    runQuery: async (query, params) => ipcRenderer.invoke('runQuery', query, params),
  });
}