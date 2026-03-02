# Management Server Hardening Task List

Purpose: persistent checklist for context retention across sessions.

## Tasks

- [x] Add admin auth guard for management mutation API routes.
- [x] Split `management-server/src/lib/openshift.ts` into focused modules.
- [x] Make student environment creation idempotent (`AlreadyExists` safe).
- [x] Fix NetworkPolicy namespace selector labels in direct-create flow.
- [x] Expand and automate testing scope for destructive and auth-protected routes.
- [x] Run build/tests, then commit and push with a clean working tree.

## Progress Notes

- Created this checklist and started implementation.
- Added token-based mutation auth guard (`MANAGEMENT_API_TOKEN`) for deploy/create/delete/restart APIs.
- Refactored OpenShift logic into modular files under `src/lib/openshift/`.
- Added idempotent create handling by ignoring `AlreadyExists` conflicts.
- Updated NetworkPolicy namespace label selector to `kubernetes.io/metadata.name`.
- Added Vitest test suite for deploy/students/delete/restart route behavior and auth checks.
- Validation complete: `npm --prefix management-server test` and `npm --prefix management-server run build` pass.
- Committed and pushed changes; repository returned to a clean working tree.
