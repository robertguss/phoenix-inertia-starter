import "vite/modulepreload-polyfill";
import axios from "axios";
import type { ComponentType } from "react";
import { createInertiaApp } from "@inertiajs/react";
import { createRoot } from "react-dom/client";

// Inertia posts use the CSRF token Phoenix put in the <meta> tag / cookie.
axios.defaults.xsrfHeaderName = "x-csrf-token";

// Eagerly-globbed page modules — Vite resolves these at build time (no dynamic
// template-string import warning). Add a page by dropping a file in js/pages/.
const pages = import.meta.glob<{ default: ComponentType }>("./pages/**/*.tsx");

createInertiaApp({
  resolve: (name) => {
    const page = pages[`./pages/${name}.tsx`];

    if (!page) {
      throw new Error(`Unknown Inertia page: ${name} (add js/pages/${name}.tsx)`);
    }

    return page();
  },
  setup({ el, App, props }) {
    createRoot(el).render(<App {...props} />);
  },
});
