import { app, BrowserWindow, ipcMain } from 'electron'
import { join } from 'path'
import { fileURLToPath } from 'url'
import { runQuery } from '../backend/services/queryService.js'

// Needed because __dirname is not defined in ES modules by default:
const __filename = fileURLToPath(import.meta.url)
const __dirname = join(__filename, '..')

console.log('NODE_ENV at start:', process.env.NODE_ENV);


// Determine if in development mode (if app is not packaged, it's dev)
const isDev = process.env.NODE_ENV === 'development';

function createWindow() {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      preload: join(__dirname, 'preload.js')
    }
  })

  if (isDev) {
    // If running in dev mode, load the Vite dev server URL
    // Make sure Vite dev server is running at this URL before launching Electron
    win.loadURL('http://localhost:5173')
    console.log('Running in development mode: Loading from Vite dev server');

  } else {
    // If in production mode, load the built files from dist
    win.loadURL(`file://${join(__dirname, '../../dist/renderer/index.html')}`)
    console.log('Running in production mode: Loading from dist/renderer');

  }
}

app.whenReady().then(createWindow)

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

// IPC handler for database queries
ipcMain.handle('db-query', async (event, cypher) => {
  const result = await runQuery(cypher)
  return result
})
