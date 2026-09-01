# USE-CASES.md — who this is for and what they do

Every ROADMAP Feature Queue item traces to a case here. A feature with
no case is not built.

## UC-1 — First run on a new phone

A developer installs Repo Runner on their iPhone. They open it and see
one button: Sign in with GitHub. They tap it, approve the device code in
Safari, and land on their repo list. They never type a password into the
app.

## UC-2 — Find the repo among 200

The developer has hundreds of repos. They pull to refresh, type three
letters, and the repo they shipped an hour ago is on screen, sorted by
most recently pushed.

## UC-3 — Know which repos are runnable

Most repos are not apps. The developer scans the list and sees at a
glance which repos have an iOS build attached to a release, without
opening each one.

## UC-4 — Run this morning's build

The developer tapped a repo, sees `v0.4.2` from 20 minutes ago with an
`.ipa` attached, taps Install, and the app appears on the Home Screen.

## UC-5 — Understand a refusal

The build is there but it will not install. The developer needs one
sentence naming the actual reason — private release asset, simulator-only
artifact, or a build not signed for this device — not a spinner that
stops.

## UC-6 — Put it on the phone from Xcode

The developer opens the generated project, sets their team, picks their
iPhone, and runs. A doc names the exact steps and the exact settings.
