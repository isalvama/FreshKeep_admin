# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

`fresh_keep_admin` is the **web-only** Flutter admin app for Fresh Keep. It talks to the same Spring Boot backend as the mobile app (`../fresh-keep_backend`), but only to the admin-facing endpoints. The user-facing mobile app lives separately in `../fresh_keep_frontend`; the two share no code.

Work is driven by specs in `specs/` (see "Spec workflow" below). SPEC 01 sets up the scaffold, admin-only login, the session and the navigation shell. Later specs fill the shell sections: dashboard (02), users (03), products (04), shopping receipts (05) and registering admins (06).

Only the `web` platform exists. Don't add other platforms.

## Commands

`flutter` in this environment is aliased to `fvm flutter` (Flutter Version Management). In a non-interactive shell, call `fvm flutter` explicitly.

- Install dependencies: `flutter pub get`
- Run the app: `flutter run -d chrome --web-port 5050`. Always use port **5050**: the backend's dev CORS config (`CORS_ALLOWED_ORIGINS`) only allows `http://localhost:5050`.
- Point at another backend: add `--dart-define=API_BASE_URL=https://…` (default `http://localhost:8082`, the backend's dev compose port).
- Static analysis / lint: `flutter analyze` (rules come from `analysis_options.yaml`, which includes `package:flutter_lints/flutter.yaml`)
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/path/to/some_test.dart`
- Format code: `dart format .`
- Build: `flutter build web`

Tests run on the Dart VM, so code that touches browser APIs (`package:web`) must sit behind an interface with an in-memory fake for tests (e.g. `SessionStorage`).

## Backend API contract

The contract lives in the backend repo: `../fresh-keep_backend/agents/api_contract.md`. The relevant sections are **Auth API Contract** (`POST /api/v1/auth/login`, `POST /api/v1/auth/register/admin`, the JWT claims, `ProblemDetail` errors, CORS, bootstrap admin) and **Admin API Contract** (everything under `/api/v1/admin`). Read the relevant section before writing any networking code, so models and error handling match the backend exactly.

Things that are easy to get wrong:

- The JWT `roles` claim carries the `ROLE_` prefix (`["ROLE_ADMIN"]`).
- `expiresIn` in the login response is the raw config value, not a countdown. Use the token's `exp` claim for expiry.
- The backend maps "entity not found" on admin detail endpoints to **400**, not 404.
- Admin paging is **1-based** on both `GET /admin/users` and `GET /admin/products`. (`/products` treats a `page` of `0` as the first page too; its request model still allows `0`.) `GET /admin/products` returns a plain list with no total; `GET /admin/shopping-receipts` returns a page like `/admin/users` (backend SPEC 02).
- Admin login requires backend SPEC 00 (`../fresh-keep_backend/specs/00-admin-enablement.md`). Without it, any admin login returns 500.

## Spec workflow

`.agents/skills/` contains third-party skills installed via `npx skills add` (symlinked into `.claude/skills/`; sources pinned in `skills-lock.json`):

- **spec** / **spec-impl** — `/spec` designs a spec section by section into `specs/NN-slug.md`. `/spec-impl NN` implements an **Approved** spec step by step. `specs/.spec-config.yml` sets `AutoCreateBranch: false`, so `/spec-impl` asks before creating the `spec-NN-slug` branch.
- **flutter-expert** — widget, BLoC, GoRouter, performance and project-structure guidance (`.agents/skills/flutter-expert/references/`).

These came from third-party GitHub sources, not from Anthropic. Review their instructions before relying on them, as with any external dependency.

## Implementation Reference & Standards

### Primary Reference
- **Source of truth**: for all implementation tasks, consult and follow the patterns, code structures and best practices in `.agents/skills/flutter-expert`.
- **Consistency with mobile**: the mobile app (`../fresh_keep_frontend`) is the reference for how this codebase reads: datasources, repository implementations, blocs, and tests with hand-written fakes (no mocking library). Match it unless a spec says otherwise.

### Architecture: Clean Architecture
All code must follow **Clean Architecture** principles, strictly separating concerns into three layers under a feature-first structure (`lib/features/<feature>/`):
1.  **Domain layer** (core): entities, use cases and repository interfaces. Zero dependencies on other layers.
2.  **Data layer**: repository implementations, models (DTOs) and data sources (API). Models must include `toEntity()` and `fromEntity()`, or extend the entity as the mobile app does.
3.  **Presentation layer**: UI (widgets/pages) and state management logic.

Cross-feature code lives in `lib/core/` (config, errors, network, storage, DI) and routing in `lib/routes/`.

### Errors
- One shared sealed hierarchy, `AdminFailure` (`lib/core/errors/failures.dart`), for every feature. Do not create per-feature failure hierarchies.
- Map `DioException`s only through the shared mapper in `lib/core/network/`. Repositories may override the message for specific statuses (as the auth repository does for login 401/403).
- Repositories and use cases return `Either<AdminFailure, T>` (`fpdart`). Never let exceptions cross the domain boundary.

### Session and auth
- The JWT lives in `window.sessionStorage` under `fresh_keep_admin.jwt`, behind the `SessionStorage` interface. Nothing else is stored. Email, accountId and adminId are always derived from the token's claims.
- `AuthInterceptor` attaches the bearer token to every request. On a 401 from anything other than `/api/v1/auth/login`, it fires `SessionExpiredNotifier`, and `AuthBloc` logs out. Features must not handle 401 themselves.
- Only accounts whose token has `ROLE_ADMIN` may hold a session.

### Navigation
- `go_router` with path URLs (`usePathUrlStrategy()`, no `#`). Redirect rules live in the pure function `resolveRedirect` (`lib/routes/redirect.dart`). Keep them there, unit-tested.
- New sections fill an existing shell destination (`shellDestinations`). Don't add top-level navigation outside the shell.
- Layout is desktop-first: labelled rail at ≥ 1000px, icon rail at 600–999px, and a "use a larger screen" notice below 600px.

### State Management: BLoC & Cubit
- **Primary choice: BLoC.** Use BLoC for any logic involving complex events, multiple state transitions, or side effects.
- **Secondary choice: Cubit.** Use a Cubit only for simple, local UI state (e.g. toggles, simple form validation without API calls).
- **Refactoring**: if a Cubit grows in complexity, refactor it into a BLoC immediately.
- **Organization**: place BLoCs/Cubits in `lib/features/<feature>/presentation/bloc/`.

### Coding Style Guidelines
- **Naming**: BLoC events use the past tense (e.g. `LoginSubmitted`, `LoggedOut`).
- **Immutability**: all states are immutable, using `equatable`.
- **Dependency injection**: use `get_it` to provide use cases and repositories to BLoCs.
- **UI separation**: widgets never contain business logic. They only dispatch events and listen to states.
