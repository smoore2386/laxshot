# Backend Tools Notes

## Dev Environment
- Update this file as the stack is set up
- Primary workspace: `${LACROSSE_APP_PATH}/src/`

## Common Commands
<!-- Populate once stack is chosen -->
<!-- Examples:
- `pnpm dev`          — start local dev server
- `pnpm test`         — run test suite
- `pnpm db:migrate`   — run pending migrations
- `pnpm db:seed`      — seed dev database
- `pnpm lint`         — ESLint + Prettier check
-->

## Environment Variables
- Never hardcode credentials — use `.env` locally, secret manager in prod
- Required vars: `DATABASE_URL`, `JWT_SECRET`, `API_PORT` (update as needed)
- `.env.example` in the repo root is the source of truth for required vars

## Database
- Connection string: `DATABASE_URL` env var
- Migration tool: (update when chosen)
- To inspect schema: (update when chosen)

## API Testing
- Local base URL: `http://localhost:3000` (or update)

## CI/CD Notes
- Update this section when CI is configured
