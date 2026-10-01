# Fresh Keep Admin

Web-only Flutter admin app for Fresh Keep. It logs in ADMIN accounts against the Fresh Keep backend and gives access to the admin API (`/api/v1/admin`).

## Requirements

- Flutter via [FVM](https://fvm.app) (`fvm flutter …`). The SDK constraint is `^3.9.2`.
- The Fresh Keep backend (`../fresh-keep_backend`) **including SPEC 00** (`specs/00-admin-enablement.md`). Older backends return 500 on every admin login.
- An admin account. On a fresh database, set `ADMIN_BOOTSTRAP_EMAIL` and `ADMIN_BOOTSTRAP_PASSWORD` in the backend's `.env` so it creates the first admin at startup.

## Running

```bash
fvm flutter pub get
fvm flutter run -d chrome --web-port 5050
```

Always use port **5050**. The backend's dev compose allows cross-origin requests only from `http://localhost:5050` (`CORS_ALLOWED_ORIGINS`).

The app calls `http://localhost:8082` by default (the backend's dev compose port). To use another backend:

```bash
fvm flutter run -d chrome --web-port 5050 --dart-define=API_BASE_URL=https://api.example.com
```

VS Code users can run the **fresh_keep_admin (Chrome, port 5050)** launch configuration, which passes the same flags.

## Testing

```bash
fvm flutter analyze
fvm flutter test
```

## Troubleshooting

**"Could not reach the server" on login.** Check these in order:

1. The app runs on port 5050 and the backend's `CORS_ALLOWED_ORIGINS` includes `http://localhost:5050`. A CORS rejection looks exactly like an unreachable server, both in the app and in Dio. The browser console shows the real cause.
2. The backend is running, and `API_BASE_URL` (default `http://localhost:8082`) points at it.

**"Something went wrong" on every admin login.** The backend is missing SPEC 00 (admin login).

## Deployment notes

The app uses path URLs (`/users/…`, no `#`). Any static host must serve `index.html` for every path (an SPA rewrite rule). Without it, reloading a deep link returns 404. Hosting and deployment configuration are not set up yet.
