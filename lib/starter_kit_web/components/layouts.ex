defmodule StarterKitWeb.Layouts do
  @moduledoc """
  Root HTML layout for Inertia pages. The React app mounts into `{@inner_content}`
  (Inertia's `<div id="app" data-page=...>`); assets are pulled from the Vite dev
  server in development and the Vite manifest in production via phoenix_vite.
  """
  use StarterKitWeb, :html

  embed_templates "layouts/*"
end
