import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { phoenixVitePlugin } from "phoenix_vite";

// Ported from phoenix_vite's official Vite wiring (KTD2), shaped for React + TS +
// Inertia: Vite emits a manifest into priv/static that Phoenix consumes for
// cache-busting, so no `mix phx.digest` step is needed.
export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
    // Phoenix (:4000) fetches modules from the Vite dev server in development.
    cors: { origin: "http://localhost:4000" },
  },
  build: {
    manifest: true,
    rollupOptions: {
      input: ["js/app.tsx", "css/app.css"],
    },
    outDir: "../priv/static",
    emptyOutDir: true,
  },
  resolve: {
    // `@` -> assets/js, matching tsconfig paths and shadcn's import convention.
    alias: { "@": fileURLToPath(new URL("./js", import.meta.url)) },
  },
  plugins: [
    react(),
    tailwindcss(),
    // Full-page reload when server templates change in dev.
    phoenixVitePlugin({ pattern: /\.(ex|heex)$/ }),
  ],
});
