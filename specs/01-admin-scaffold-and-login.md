# SPEC 01 — Admin web app scaffold, admin-only login and navigation shell

> **Status:** Approved
> **Depends on:** Backend SPEC 00 (`fresh-keep_backend/specs/00-admin-enablement.md` — admin login, bootstrap admin, CORS)
> **Date:** 2026-10-01
> **Objective:** Create the web-only `fresh_keep_admin` Flutter project where an ADMIN account can log in, keep a tab-scoped session, and reach an authenticated navigation shell whose sections are placeholders for later specs.

---

## Scope

**In:**

- **Project setup:**
  - New project `fresh_keep/fresh_keep_admin`, package `fresh_keep_admin`, created with `flutter create --platforms web`. Browser tab title and web manifest name: "Fresh Keep Admin".
  - `git init` on `main` with an initial commit; no remote.
  - `CLAUDE.md` with the mobile app's architecture rules (Clean Architecture, BLoC/Cubit, `get_it`, `equatable`, past-tense events) and a pointer to the backend's `agents/api_contract.md`.
  - `.agents/skills/{spec,spec-impl,flutter-expert}` copied from `fresh_keep_frontend`, plus `skills-lock.json` and `.claude/skills/*` symlinks.
  - `specs/.spec-config.yml` with `AutoCreateBranch: false`.
- **Stack:** `dio`, `flutter_bloc`, `go_router`, `fpdart`, `equatable`, `get_it`, `jwt_decoder`, `web` (for `sessionStorage`). Same SDK constraint as mobile.
- **Config:** `Env.apiBaseUrl` from `--dart-define=API_BASE_URL`, default `http://localhost:8082`. The dev server always runs on port 5050 (`flutter run -d chrome --web-port 5050`); a VS Code launch config and README document this.
- **URLs:** path-style via `usePathUrlStrategy()`.
- **Shared errors:** one sealed `AdminFailure` hierarchy in `lib/core/errors/failures.dart`, with a single `DioException → AdminFailure` mapper in `lib/core/network/`.
- **Login page** (`/login`):
  - Email and password fields with on-submit validation (required, email format, password 8–20). No register link.
  - Calls `POST /api/v1/auth/login`.
  - Decodes the JWT and requires `ROLE_ADMIN` in `roles`. Otherwise the token is discarded, nothing is stored, and the page shows "This account doesn't have admin access."
  - Error copy for 400, 401 ("Invalid email or password"), 403 (disabled account), 500 and network failures.
- **Session:**
  - JWT stored in `window.sessionStorage` behind a `SessionStorage` interface, so tests can use a fake. It survives reloads and is cleared when the tab closes.
  - At startup, a missing or expired token (checked via `exp`) means unauthenticated.
- **Auth interceptor:**
  - Attaches `Authorization: Bearer <token>` to every request.
  - On a `401` from any endpoint other than `/login`, it clears the session and moves `AuthBloc` to `Unauthenticated` with the session-expired flag.
  - The login page then shows "Your session has expired. Please log in again."
- **Routing** (`go_router`):
  - Routes: `/splash` while the session is resolved, then `/login`, then the shell routes `/dashboard`, `/users`, `/products`, `/receipts` and `/admins`.
  - An unauthenticated visit to a protected URL redirects to `/login?from=<original path+query>`. After login the admin returns there, or lands on `/dashboard` if there is no `from`.
  - An authenticated visit to `/login` redirects to `/dashboard`, and so does any unknown path.
- **Shell:**
  - A `NavigationRail` with Dashboard, Users, Products, Receipts and Admins. Labels show at ≥ 1000px and icons only at 600–999px. Below 600px, a centered "Please use a larger screen" notice replaces the shell.
  - A top bar with the admin email and a Logout button. Logout clears the session and goes to `/login`, with no backend call.
  - Each section shows a "Coming in SPEC 0N" placeholder.
- **Tests:** repository (fake HTTP adapter, as in mobile), blocs, the 401 interceptor, router redirect logic, and widget tests for the login page and the shell.

**Out of scope (for future specs):**

- Dashboard metrics and charts (SPEC 02), users (03), products (04), shopping receipts (05), registering new admins (06).
- Production deployment, hosting, and the SPA rewrite rule. A README note only.
- A shared Dart package between the mobile and admin apps.
- "Remember me" or persistent sessions across tab closes, refresh tokens, multi-tab session sync.
- Phone layouts below 600px.
- Theming beyond Material 3 with a teal seed (same as mobile), dark mode, i18n.
- A logout call to the backend. None exists; the JWT is stateless.

---

## Data model

### Shared failures (`lib/core/errors/failures.dart`)

```dart
sealed class AdminFailure { final String message; }
class ValidationFailure extends AdminFailure { }    // 400 — incl. "not found" (backend maps it to 400)
class UnauthorizedFailure extends AdminFailure { }  // 401
class ForbiddenFailure extends AdminFailure { }     // 403
class ServerFailure extends AdminFailure { }        // 5xx
class NetworkFailure extends AdminFailure { }       // no response / timeout / CORS block
class NotAdminFailure extends AdminFailure { }      // login only: token lacks ROLE_ADMIN (client-side)
```

```dart
// lib/core/network/dio_failure_mapper.dart
AdminFailure mapDioException(DioException e); // status → subtype; message = ProblemDetail.detail ?? default copy
```

The auth repository overrides two login messages: 401 becomes "Invalid email or password" and 403 becomes "This account has been disabled."

### Session storage (`lib/core/storage/`)

```dart
abstract class SessionStorage {        // sync — sessionStorage is synchronous
  String? read(String key);
  void write(String key, String value);
  void delete(String key);
}
class WebSessionStorage implements SessionStorage { } // package:web window.sessionStorage
```

Only the JWT is stored, under one key: `fresh_keep_admin.jwt`. Email, accountId and adminId are always read from its claims.

### Session expiry signal (`lib/core/network/`)

```dart
class SessionExpiredNotifier {          // broadcast stream, registered in get_it
  Stream<void> get stream;
  void notify();
}
class AuthInterceptor extends Interceptor { }
// onRequest: attaches Bearer token from SessionStorage
// onError: 401 on any path except /api/v1/auth/login → notifier.notify()
```

### Auth domain (`lib/features/auth/domain/`)

```dart
class Admin extends Equatable {
  final String accountId; // `accountId` claim
  final String adminId;   // `adminId` claim
  final String email;     // `sub` claim
}

abstract class AuthRepository {
  Future<Either<AdminFailure, Admin>> login(String email, String password);
  Admin? currentAdmin();   // stored token present, unexpired, has ROLE_ADMIN → Admin; else clears and returns null
  void logout();           // deletes the stored token
}

class LoginUseCase { }           // → repository.login
class GetCurrentAdminUseCase { } // → repository.currentAdmin
class LogoutUseCase { }          // → repository.logout
```

### Auth data (`lib/features/auth/data/`)

```dart
class LoginRequestModel { final String email, password; Map<String, dynamic> toJson(); }
class LoginResponseModel { final String accountId, email, jwtString; final int expiresIn; factory fromJson(...); }
class AdminModel extends Admin { factory AdminModel.fromJwt(String jwt); } // throws FormatException if a claim is missing
class AuthRemoteDataSource { Future<LoginResponseModel> login(LoginRequestModel); }
class AuthLocalDataSource { String? readToken(); void saveToken(String); void clearToken(); } // over SessionStorage
class AuthRepositoryImpl implements AuthRepository { }
```

### Presentation (`lib/features/auth/presentation/bloc/`)

```dart
// auth_bloc.dart — app-wide session, drives the router
sealed class AuthEvent { }
class AppStarted extends AuthEvent { }
class LoggedIn extends AuthEvent { final Admin admin; }
class LoggedOut extends AuthEvent { }
class SessionExpired extends AuthEvent { } // added by AuthBloc's own subscription to SessionExpiredNotifier

sealed class AuthState extends Equatable { }
class AuthInitial extends AuthState { }
class Authenticated extends AuthState { final Admin admin; }
class Unauthenticated extends AuthState { final bool sessionExpired; }

// login_bloc.dart — form submission
class LoginSubmitted { final String email, password; }
sealed class LoginState extends Equatable { } // LoginInitial / LoginSubmitting / LoginSuccess(admin) / LoginFailure(message)
```

### Routing and shell (`lib/routes/`, `lib/features/shell/`)

```dart
// lib/routes/redirect.dart — pure function, unit-tested without a widget tree
String? resolveRedirect(AuthState state, Uri location);

// lib/features/shell/presentation/shell_destination.dart
class ShellDestination { final String path, label; final IconData icon; final int comingInSpec; }
const shellDestinations = [ /* /dashboard 02, /users 03, /products 04, /receipts 05, /admins 06 */ ];
```

---

## Implementation plan

1. **Scaffold.** Run `flutter create --platforms web --project-name fresh_keep_admin` inside the existing `fresh_keep_admin/` folder, which already holds `specs/`.
   - Set the title and manifest name to "Fresh Keep Admin" and add the dependencies.
   - Run `git init` and make an initial commit.
   - Manual test: `flutter run -d chrome --web-port 5050` shows the starter app.
2. **Agent setup.**
   - Copy the `.agents/skills/` trio, `skills-lock.json` and the `.claude/skills` symlinks.
   - Write `CLAUDE.md`. `specs/` with this spec and `.spec-config.yml` already exists.
   - Add a README run section and a `.vscode/launch.json` with `--web-port 5050`.
3. **Core.**
   - Add `Env`, `AdminFailure` and `mapDioException`, `SessionStorage` and `WebSessionStorage` (plus an in-memory fake under `test/`), `SessionExpiredNotifier`, `AuthInterceptor` and `DioClient`.
   - Tests cover the mapper's status codes. They also check that the interceptor attaches the token, notifies on a 401 from `/admin/...`, and does not notify on a 401 from `/auth/login`.
4. **Auth domain and data.**
   - Add the entity, repository interface, use cases, models (`AdminModel.fromJwt`), data sources and `AuthRepositoryImpl`.
   - Tests, with a fake HTTP adapter:
     - Login 200 with an admin token stores it and returns `Admin`.
     - Login 200 with a USER-only token returns `NotAdminFailure` and stores nothing.
     - 400, 401, 403, 500 and network errors map with the right copy.
     - `currentAdmin()` returns null and clears the token when it's missing, expired, or lacks `ROLE_ADMIN`.
5. **Blocs.** Add `AuthBloc` (including `SessionExpired` from the notifier) and `LoginBloc`, with bloc tests using hand-written fake use cases.
6. **DI and app wiring.**
   - `setupServiceLocator()` (get_it), `main.dart` with `usePathUrlStrategy()`, and `app.dart` with `MaterialApp.router`, Material 3 and a teal seed.
   - Minimal splash and login placeholders.
   - Manual test: the app boots to `/login`.
7. **Routing.** Add `resolveRedirect` with unit tests over states and URLs (splash, login, `from`, unknown path). Then `GoRouter` with `refreshListenable` on `AuthBloc`.
8. **Login page.** The form, on-submit validation, the submitting spinner, the error SnackBar and the session-expired banner. Widget tests cover the validation messages, the failure copy and the banner.
9. **Shell.**
   - `ShellRoute` with `AdminShell`: the rail with breakpoints, the top bar with the email and Logout, the narrow-screen notice, and placeholder pages.
   - Widget tests: the rail shows labels at 1200px, icons only at 800px, and the notice at 500px. Tapping Users navigates to `/users`, and Logout navigates to `/login`.
10. **End-to-end manual check** against the backend with SPEC 00:
    - The bootstrap admin can log in and lands on `/dashboard`.
    - A reload keeps the session, and closing and reopening the tab lands on `/login`.
    - A USER account is rejected.
    - Opening `/users` while logged out goes to login and then back to `/users`.

---

## Acceptance criteria

### Project

- [ ] `fresh_keep/fresh_keep_admin` exists, has only a `web/` platform folder, and is a git repo on `main` with an initial commit.
- [ ] The browser tab title reads "Fresh Keep Admin".
- [ ] `flutter analyze` reports no issues and `flutter test` passes.
- [ ] `CLAUDE.md`, `specs/.spec-config.yml` (`AutoCreateBranch: false`), `specs/01-admin-scaffold-and-login.md`, and the three skills under `.agents/skills/` exist. The `.claude/skills/*` entries are symlinks to them.
- [ ] `flutter run -d chrome --web-port 5050` starts the app. The README documents that command and `--dart-define=API_BASE_URL`.

### Login

- [ ] Submitting with an empty field, a malformed email, or a password outside 8–20 characters shows an inline error and sends no request.
- [ ] Valid credentials of an ADMIN account navigate to `/dashboard` and store the JWT under `fresh_keep_admin.jwt` in `sessionStorage`.
- [ ] Valid credentials of a USER-only account show "This account doesn't have admin access." and leave `sessionStorage` empty.
- [ ] Wrong credentials (401) show "Invalid email or password".
- [ ] A disabled account (403) shows "This account has been disabled."
- [ ] A 400 shows the backend's `detail`.
- [ ] A 500 shows "Something went wrong. Please try again."
- [ ] An unreachable backend shows "Could not reach the server. Please try again."
- [ ] While a login request is in flight, the submit button is disabled and shows a spinner.
- [ ] The login page has no link to registration.

### Session and routing

- [ ] Reloading the page while logged in stays on the current page without showing login.
- [ ] Closing the tab and opening the app in a new tab lands on `/login`.
- [ ] A stored token that is expired or lacks `ROLE_ADMIN` is cleared at startup, and the app lands on `/login`.
- [ ] Opening `/users?x=1` while logged out redirects to `/login?from=%2Fusers%3Fx%3D1`, and a successful login lands on `/users?x=1`.
- [ ] Logging in without `from` lands on `/dashboard`.
- [ ] Visiting `/login` while logged in redirects to `/dashboard`.
- [ ] An unknown path while logged in redirects to `/dashboard`.
- [ ] URLs contain no `#`.
- [ ] Every request after login carries `Authorization: Bearer <token>`.
- [ ] A `401` from any endpoint other than `/api/v1/auth/login` clears the session, redirects to `/login`, and shows "Your session has expired. Please log in again."
- [ ] A `401` from `/api/v1/auth/login` does not trigger the session-expired flow.

### Shell

- [ ] At ≥ 1000px wide, the rail shows icons with labels for Dashboard, Users, Products, Receipts and Admins.
- [ ] At 600–999px, the rail shows icons only, with tooltips.
- [ ] Below 600px, only the "Please use a larger screen" notice is shown.
- [ ] Selecting a rail item changes the URL to that section's path and highlights it.
- [ ] Loading a section URL directly highlights the matching item.
- [ ] Each section shows "Coming in SPEC 0N" with its spec number (02–06).
- [ ] The top bar shows the logged-in admin's email.
- [ ] Logout clears `sessionStorage` and lands on `/login`. Browser Back afterwards does not show a protected page.

---

## Decisions

- **Yes:** Separate web-only project `fresh_keep_admin`. Admin and mobile have different users, layouts and dependencies (`image_picker`, `flutter_secure_storage`), and the admin app can deploy independently.
- **No:** An admin feature inside the mobile app. It would ship admin screens to phones and mix UX needs.
- **Yes:** Reuse the mobile stack as-is (Clean Architecture, BLoC, `get_it`, `go_router`, `dio`, `fpdart`, `equatable`, hand-written test fakes), so both apps read the same way.
- **Yes:** JWT in `sessionStorage` behind a `SessionStorage` interface. It survives reloads and is cleared on tab close, which suits a privileged session, and it can be faked in tests.
- **No:** `flutter_secure_storage` on web. It's localStorage plus obfuscation, which adds no real security, and the session would outlive the tab.
- **No:** A memory-only token. A refresh would log the admin out.
- **Yes:** Store only the JWT and derive email, accountId and adminId from its claims. A single source of truth can't go stale.
- **Yes:** Reject non-admin accounts client-side by requiring `ROLE_ADMIN` in `roles`. The backend still enforces 403; this avoids a session where every page fails.
- **Yes:** One shared `AdminFailure` hierarchy and one Dio mapper. Every admin endpoint has the same error set.
- **No:** Per-feature failure hierarchies like mobile. They would be near-identical copies.
- **Yes:** Global 401 handling via an interceptor and `SessionExpiredNotifier`. Every later spec gets session expiry for free.
- **No:** Checking `exp` only at startup. A mid-session expiry would surface as a confusing per-screen error.
- **Yes:** Preserve deep links with `?from=`. Admin URLs get bookmarked and shared.
- **Yes:** Path URL strategy, for clean, shareable URLs. The hosting rewrite rule is deferred to deployment.
- **No:** Hash URLs.
- **Yes:** A sidebar shell with placeholders in this spec. Later specs only fill pages and never touch navigation.
- **Yes:** Desktop-first, usable at ≥ 600px, with a notice below that. It's an admin tool, and phone layouts aren't worth the cost to every later table.
- **No:** A fully responsive layout with a Drawer.
- **Yes:** Dev server pinned to port 5050, matching backend SPEC 00's CORS default.
- **Yes:** `git init` locally; the user adds the remote.
- **Yes:** The same agent setup as mobile (CLAUDE.md and skills), so `/spec` and `/spec-impl` work inside the project.
- **Yes:** No register link on login. Admins are created by other admins (SPEC 06) or by the backend bootstrap.
- **Yes:** This spec is saved into `fresh_keep_admin/specs/` before the Flutter project exists. `flutter create` runs into the existing folder in step 1.

---

## Risks

| Risk | Mitigation |
|---|---|
| A CORS rejection reaches Dio as a response-less error, indistinguishable from "server down" | It maps to `NetworkFailure` ("Could not reach the server"). The README's first troubleshooting item is: is `CORS_ALLOWED_ORIGINS` set, and is the app on port 5050? |
| `WebSessionStorage` uses `package:web` and can't run in VM-based `flutter test` | All logic depends on the `SessionStorage` interface and is tested with the in-memory fake. `WebSessionStorage` is a thin wrapper, verified by the step 10 manual check. |
| Several concurrent requests failing with 401 fire the notifier repeatedly | `AuthBloc` ignores `SessionExpired` when already `Unauthenticated`, so logout and the message happen once. |
| Browser "Duplicate tab" copies `sessionStorage`, so the duplicated tab shares the session | Accepted. It's the same admin in the same browser, and each tab still ends on close. |
| JWT `exp` checks depend on the local clock | This is a soft guard only. The backend rejects truly expired tokens with 401, which the interceptor handles. |
| Path URLs 404 on reload in production without a rewrite rule | Deployment is out of scope. The README notes the required SPA rewrite (all paths serve `index.html`). |
| A backend without SPEC 00 makes admin login return 500 | The 500 copy is shown. The README states that the backend must include SPEC 00. |

---

## What is **not** in this spec

- Dashboard metrics (SPEC 02), users (03), products (04), shopping receipts (05), registering admins (06).
- Production deployment, hosting and rewrite configuration.
- A shared Dart package between the mobile and admin apps.
- Persistent sessions, refresh tokens, multi-tab session sync.
- Phone layouts below 600px, dark mode, i18n.
- A backend logout call.

Each one of those, if it lands, goes in its own spec.
