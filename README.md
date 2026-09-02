# Apropos

Your repos, playable on your phone. Attach a built web app to a repo's
release, open Apropos, tap the repo, press Run. The app opens *inside*
Apropos. Nothing is installed, nothing is signed, and no desktop is
involved.

Apropos ships its own web build, so it appears in its own list and can run
itself.

![Onboarding, repo list, and install sheet](docs/screenshots/install-sheet.png)

## What it does

- **Runs a release inside itself.** A `.zip` containing `index.html` is
  downloaded, unpacked into the app's container, and served from a
  loopback HTTP server to a web view. A real origin, so `fetch`, absolute
  paths, and client-side routes work in an ordinary static build.
- Signs in with GitHub through the OAuth device flow. No client secret, no
  backend. The token stays in the phone's Keychain.
- Lists your repositories, most recently pushed first, with search and pull
  to refresh.
- Badges each repo with how it can be run: "Runs here" or "iOS build".
- Reads the `.ipa`'s bundle identifier, version, and signature over HTTP
  range requests, so it never downloads the archive to tell you what it is.
- Installs through `itms-services://`, which is the only way iOS lets an app
  install another app.
- Names the reason when it cannot install: no `.ipa`, a simulator-only
  build, a private release asset, an App Store signature, or no manifest
  host.

## Ship a repo you can play with

Attach a built web app to a release. Any `.zip` with an `index.html` works:

```sh
npm run build          # or whatever produces your static site
cd dist && zip -qry ../web.zip . && cd ..
gh release create v1.0.0 web.zip
```

Pull to refresh in Apropos. The repo shows "Runs here", and Run opens it.

## Run it

```sh
brew install xcodegen
cd ios && xcodegen generate && open Apropos.xcodeproj
```

Then follow [docs/DEPLOY-TO-PHONE.md](docs/DEPLOY-TO-PHONE.md) to sign it
with your team and put it on your iPhone.

## Health gate

```sh
verify/verify.sh
```

Regenerates the project, builds with source warnings treated as errors,
runs the unit tests, installs and launches the app on a booted simulator,
then drives the real UI against live GitHub and refreshes
`docs/screenshots/`. The steps that need a GitHub token print `SKIP` and
the reason when there is none.

## Layout

| Path | What it is |
|---|---|
| `ios/` | The iPhone app. `ios/project.yml` is the project source of truth. |
| `verify/` | The health gate, one script per check. |
| `src/` | A Next.js app. It hosts `/api/manifest` for repositories you cannot write to, and a browser demo of the idea. |
| `agent-kit/` | The process this repository is built under. Start at `agent-kit/ROUTING.md`. |
| `docs/` | Architecture, configuration, deployment, and the screenshots the gate regenerates. |

## The web surface

`src/` predates the iOS app and stays as a browser demo. Its one load-bearing
part is `src/app/api/manifest`, which turns query values into the install
manifest iOS reads.

```sh
npm install && npm run dev
```
