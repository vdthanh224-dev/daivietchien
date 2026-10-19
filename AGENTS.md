# Project instructions

- Production server is deployed on Render through the root `render.yaml` and `Dockerfile`; that Dockerfile copies `server/` into the Render image. For server changes, edit only `server/`; for shared behavior, update `godot_client/` in the same change.
- The Render image currently uses a Deno base image, but `server/` is the Render source. Do not confuse it with the separate `deno-server/` or `deploy_deno/` copies. Render deployment happens through the Render Docker build after commit/push; local checks are only pre-deploy checks and must not be reported as a Render deployment.
- Do not modify `backend/`, `deno-server/`, `deploy_deno/`, or client/backup copies unless the user explicitly asks.
- After fixing a bug, run the relevant pre-deploy server checks and Godot checks again; if another fix is needed, repeat until the checks are clean. Verify the Render deployment separately after commit/push. If Render checks are unavailable, report that they were not verified instead of claiming a pass.
