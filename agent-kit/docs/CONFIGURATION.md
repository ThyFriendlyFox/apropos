# Configuration

Every knob, in one table, with defaults. Repo Runner has two sources of
configuration: values baked in at build time, and values the user sets in
the app. The in-app value wins.

## Build time — `ios/Secrets.xcconfig`

Gitignored. `verify/lib.sh` creates it from `ios/Secrets.example.xcconfig`
when it is missing, so a fresh clone builds.

| Field | Type | Default | Use |
|---|---|---|---|
| `GITHUB_CLIENT_ID` | string | empty | The OAuth app's client ID, copied into `Info.plist` as `GitHubClientID`. GitHub's device flow needs no client secret, so this is not a credential. |

## In-app — Settings

Stored in `UserDefaults`, except the token.

| Field | Type | Default | Use |
|---|---|---|---|
| `github.client.id.override` | string | unset | Overrides `GITHUB_CLIENT_ID`. Lets a user sign in without rebuilding. |
| `manifest.host` | https URL | unset | An endpoint that turns query values into an install manifest. Only used when the release has no manifest and the account cannot write to the repository. Anything other than `https` is ignored, because iOS refuses it. |

## Not configuration

| Value | Where | Why it is fixed |
|---|---|---|
| OAuth scope | `AppConfig.scope` | `repo read:user` is the narrowest scope that still lists private repositories and their releases. OAuth apps have no finer grain. |
| GitHub access token | Keychain, via `TokenStore` | A credential, not a setting. Sign out clears it. |
| `REPORUNNER_TOKEN` | Launch environment, Debug builds only | A test seam for `verify/`. Release builds do not read it. |

## Behavior rules

- No configuration is required to launch. With no client ID the sign-in
  button opens the client-ID sheet instead of failing.
- A damaged or unreadable value falls back to the default. It never
  crashes the app.
- Signing out clears the token and leaves both settings in place.
