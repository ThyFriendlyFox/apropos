# Put Repo Runner on your iPhone

Repo Runner is a normal iOS app. You build it in Xcode and run it on your
own device with your own Apple ID. Nothing here needs a paid developer
account, though a free account limits the app to 7 days before it must be
rebuilt.

## 1. Generate the Xcode project

```sh
brew install xcodegen        # once
cd ios && xcodegen generate
open RepoRunner.xcodeproj
```

`ios/RepoRunner.xcodeproj` is generated and gitignored. `ios/project.yml`
is the source of truth. Re-run `xcodegen generate` after adding a file.

## 2. Set your team

In Xcode, select the **RepoRunner** target → **Signing & Capabilities**:

1. Tick **Automatically manage signing**.
2. Pick your team under **Team**. A personal Apple ID appears here once you
   add it in **Xcode → Settings → Accounts**.
3. Change **Bundle Identifier** if `com.thyfriendlyfox.reporunner` is taken
   by someone else's profile. Any reverse-DNS string works.

## 3. Run on the device

1. Plug in the iPhone, or pair it over Wi-Fi
   (**Window → Devices and Simulators**).
2. Pick it in the run destination menu.
3. Press ⌘R.
4. The first run fails to launch with "Untrusted Developer". On the phone,
   open **Settings → General → VPN & Device Management**, tap your Apple ID,
   and tap **Trust**. Press ⌘R again.

## 4. Sign in

Repo Runner signs in with GitHub's device flow, which needs an OAuth client
ID and no client secret.

1. Open <https://github.com/settings/applications/new>.
2. Name it anything. **Homepage URL** and **Authorization callback URL**
   are both required by the form and neither can be blank, but the device
   flow never uses the callback. `http://localhost` works for both.
3. Register the app, then on its settings page tick **Enable Device Flow**
   and save. Without this GitHub answers `device_flow_disabled`.
4. Copy the **Client ID**.
5. Either paste it into Repo Runner under **Settings → OAuth client ID**, or
   put it in `ios/Secrets.xcconfig` before building:

   ```
   GITHUB_CLIENT_ID = Iv1.0123456789abcdef
   ```

The app asks for the `repo` scope. That is the narrowest OAuth scope that
still lists private repositories and their releases; OAuth apps have no
finer grain. The token is stored in the phone's Keychain.

## 5. What installs and what does not

Repo Runner hands iOS an `itms-services://` URL. That is the only way an
app can install another app. It works when all of these hold:

| Requirement | Why |
|---|---|
| The release has an `.ipa` | A simulator `.app` bundle cannot run on a phone. |
| The repository is public | iOS fetches the build itself and cannot send your token. |
| The build is signed ad-hoc, for development, or enterprise | An App Store signature installs only through the App Store or TestFlight. |
| Your device is in the provisioning profile | Ad-hoc and development profiles list device UDIDs. |

Repo Runner checks the first three before it does anything and names the
one that failed. The fourth is only visible to iOS, which reports it as
"Unable to Install".

### The manifest

iOS reads the build's details from a `manifest.plist` at an https URL.
Repo Runner finds one in this order:

1. A `.plist` already attached to the release.
2. A **manifest host** set in Settings.
3. One it attaches to the release itself, when your account can write to
   that repository. It uploads `manifest.plist` once and reuses it.

For repositories you cannot write to, deploy this project's web app and
paste its endpoint into Settings:

```sh
npx vercel deploy --prod
```

The endpoint is `https://<your-deployment>/api/manifest`. It serves GitHub
release assets only.

## 6. Ship a build your phone can install

From the app repository you want to run:

```sh
xcodebuild -scheme YourApp -configuration Release \
  -archivePath build/YourApp.xcarchive archive
xcodebuild -exportArchive -archivePath build/YourApp.xcarchive \
  -exportOptionsPlist AdHoc.plist -exportPath build
gh release create v1.0.0 build/YourApp.ipa
```

`AdHoc.plist` sets `method` to `ad-hoc` (or `development`) and lists your
team ID. Repo Runner picks the `.ipa` up on the next pull to refresh.
