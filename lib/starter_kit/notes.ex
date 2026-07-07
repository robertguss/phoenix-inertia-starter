# DEMO: Example vertical slice (Notes) — `bin/remove_demo` deletes this whole file.
defmodule StarterKit.Notes do
  @moduledoc """
  Demo Notes domain (R23). Exposes the owner-scoped `Note` resource over JSON:API
  and via code interfaces the Inertia controller calls. Removed by `bin/remove_demo`.
  """
  use Ash.Domain,
    otp_app: :starter_kit,
    extensions: [AshJsonApi.Domain]

  # JSON:API CRUD (R13). Mounted under /api/v1 by the ApiRouter; owner policies on
  # the resource keep one user's key from touching another's notes.
  json_api do
    routes do
      base_route "/notes", StarterKit.Notes.Note do
        get :read
        index :read
        post :create
        patch :update
        delete :destroy
      end
    end
  end

  resources do
    resource StarterKit.Notes.Note do
      # Code interfaces (KTD3) the web controller + tests call. Callers pass the
      # signed-in user as `actor:`; policies enforce ownership.
      define(:list_notes, action: :read)
      define(:get_note, action: :read, get_by: :id)
      define(:create_note, action: :create)
      define(:update_note, action: :update)
      define(:destroy_note, action: :destroy)
    end
  end
end
