import { contextBridge, ipcRenderer } from 'electron'

contextBridge.exposeInMainWorld('api', {
  fetchData: (query) => ipcRenderer.invoke('db-query', query)
})