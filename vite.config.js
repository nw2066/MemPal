import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path';

console.log('Vite build NODE_ENV:', process.env.NODE_ENV)

export default defineConfig({
  root: './src/renderer',
  build: {
    outDir: '../../dist/renderer',
    emptyOutDir: true, 
  },
  base: './',
  resolve: {
    alias: {
      '@backend': path.resolve(__dirname, './src/backend'),
    },
  },
  plugins: [react()]
})