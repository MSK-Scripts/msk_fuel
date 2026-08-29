import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// NUI loads assets from the resource over a file:// style origin, so relative
// paths are mandatory. The build output lands directly in ../html, which is what
// the fxmanifest ui_page points at.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: '../html',
    emptyOutDir: true,
    assetsDir: 'assets',
    chunkSizeWarningLimit: 1500,
  },
})
