# Booknote

**English** · [Deutsch](README.de.md)

Capture reading notes by voice — **quick, with just a few taps.**

The idea: while you read, Booknote is always at hand. Tap a book (or add a new
one in seconds), say what strikes you, done. No typing, no hunting for pen and
paper. The note is there right away, with its page number. Later, at your
leisure, you look through all the notes for a book, sort them, export or share
them.

Booknote speaks **English, Deutsch and Français**: the app follows your phone’s
language (change it under *Settings → App language*), and you can record your
notes in any of the three — set per book, and per recording if you like.

Once you know your way around, switch on **Clean mode** (*Settings → Display*):
it hides the explanations and hints and leaves just the buttons and headings.

For speech recognition Booknote needs your own OpenAI access: the account itself
is free, but using it needs a small credit (a few dollars go a very long way) —
how to set it up is explained below.

> **And because reading should be fun:** Booknote doesn’t have to stay brown.
> How about “Old Library” — parchment, leather and a serif typeface, like an old
> library — or midnight blue with gold? These and more colour schemes are one tap
> away inside the app, see [Colour schemes](#colour-schemes).

## Installation (APK)

The ready-made APK is under
[Releases](https://github.com/georg-doenges/booknote/releases) in this repo.

1. Download the APK on your Android phone and tap it.
2. Android will probably ask for permission to install apps from this source —
   allow it. (If Play Protect warns about an unknown app, choose “Install
   anyway”.)
3. Open the app. Before the first recording works, the API key is still missing
   (next section).

## Setting up your OpenAI API key

Booknote sends your recordings to OpenAI (Whisper) to turn them into text. For
that you need your own key — it only takes a few minutes:

1. Go to **[platform.openai.com/api-keys](https://platform.openai.com/api-keys)**
   and create an account (signing in with Google works too) if you don’t have
   one yet.
2. In your account, under **Billing**, add a small credit once — **$5 is
   plenty for a very long time** (speech-to-text costs only fractions of a cent
   per minute).
3. On the API keys page click **“Create new secret key”** and copy the key. It is
   shown **only once**, so save it right away.
4. In Booknote: **Settings → API keys** → paste the key → **Save**.

That’s it — you can start recording.

## Colour schemes

Under **Settings → Colour schemes → Load colour schemes** (the app needs internet
for this) you see all available schemes; tap **Install** to load one and switch
it on right away. To get back to the default, pick **System / Light / Dark** at
the top under “Display”. New schemes are added over time, and if one has been
revised you’ll see **Update** there. You can also import your own with **From
file …** — the format is described in [THEMES.md](THEMES.md).

## What else Booknote can do

- **Automatic page & position detection.** “Page 47 top, …” is split into
  page / position / text while you speak — in English, German and French.
- **Cover search** when you add a book (Google Books / Open Library).
- **Export** single books, authors or the whole library as Markdown or text, to
  share or paste into other notes.
- **Sync several devices.** Works through a shared library file, no server
  needed — not necessary to get started and a bit unusual; details in
  [SYNC_DESIGN.md](SYNC_DESIGN.md) (German) if you want to use it.

## For developers: building it yourself

You need an installed [Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter run
```

For a release APK with your own stable signature (needed so testers get later
versions as an update instead of a reinstall) see [SIGNING.md](SIGNING.md)
(German).

The app’s texts live in `lib/l10n/app_{de,en,fr}.arb`; after changing them run
`flutter gen-l10n`.

## Further documentation (mostly German)

- [PROJECT.md](PROJECT.md) — project specification (architecture, data model,
  speech parsing, screens).
- [SYNC_DESIGN.md](SYNC_DESIGN.md) — the sync model between devices.
- [THEMES.md](THEMES.md) — colour schemes: catalogue, file format, contributing
  new ones.
- [SIGNING.md](SIGNING.md) — creating the release keystore and building the
  release APK.
- [PROGRESS.md](PROGRESS.md) — build-block by build-block progress.
- [BACKLOG.md](BACKLOG.md) — ideas and later stages.
