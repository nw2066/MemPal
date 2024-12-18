import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

console.log('Vite build NODE_ENV:', process.env.NODE_ENV)

export default defineConfig({
  root: './src/renderer',
  build: {
    outDir: '../../dist/renderer',
    emptyOutDir: true, 
  },
  base: './',
  plugins: [react()]
})