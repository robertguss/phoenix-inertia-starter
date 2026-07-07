# GitHub repository settings

These are the one-time repository settings for publishing this template. They are
manual GitHub steps (not automatable from the repo) — apply them once, in the
repo's **Settings**.

## Required

- **Visibility: Public.** This is an open-source reference template.
- **Template repository: on.** Settings → General → check *Template repository*.
  Lets people click *Use this template* / `gh repo create --template`.
- **License: MIT.** Already committed as `LICENSE`.
- **Dependabot: on.** `.github/dependabot.yml` is committed; ensure Dependabot
  alerts + security updates are enabled under Settings → Advanced Security.

## Recommended

- **Restrict who can create PRs / branches** to collaborators — this is a
  read-only template (`CONTRIBUTING.md` says so), so drive-by PRs are noise.
- **Actions permissions:** allow the pinned actions used by the workflows. The
  workflows only need `contents: read`.
- **Branch protection on the default branch:** require the `mix precommit` (CI)
  and both `birth-matrix` legs to pass before merge.
- **Issues: off.** `CONTRIBUTING.md` states the template accepts no issues, PRs,
  or support requests — turn Issues off to match that read-only "fork it" posture.
