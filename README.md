# Booknote

Lesenotizen per Sprache erfassen — **niederschwellig, mit ein paar Klicks.**

Die Idee: Während du liest, hast du Booknote schnell zur Hand. Buch antippen
(oder in Sekunden ein neues anlegen) → kurz reinsprechen, was dir gerade
auffällt → fertig. Kein Tippen, kein Suchen nach Stift und Zettel. Die Notiz
ist sofort da, mit Seitenzahl. Später, in Ruhe, siehst du dir alle Notizen zu
einem Buch an, sortierst, exportierst oder teilst sie.

Für die Spracherkennung braucht Booknote einen eigenen OpenAI-Zugang: das
Konto selbst ist kostenlos, für die Nutzung brauchst du aber ein kleines
Guthaben (ein paar Dollar reichen erfahrungsgemäß sehr lange) — wie das geht,
steht weiter unten.

## Installation (APK)

Das fertige APK zum Installieren gibt es unter
[Releases](../../releases) dieses Repos.

1. APK auf dem Android-Gerät herunterladen und antippen.
2. Android fragt vermutlich nach der Erlaubnis, Apps aus dieser Quelle zu
   installieren — zulassen.
3. App öffnen. Bevor die erste Aufnahme klappt, fehlt noch der API-Schlüssel
   (nächster Abschnitt).

## OpenAI-API-Key einrichten

Booknote schickt deine Sprachaufnahmen zur Umwandlung in Text an OpenAI
(Whisper). Dafür brauchst du einen eigenen Schlüssel — das dauert nur ein
paar Minuten:

1. Auf **[platform.openai.com/api-keys](https://platform.openai.com/api-keys)**
   gehen und ein Konto anlegen (auch per Google-Login möglich), falls noch
   nicht vorhanden.
2. Im Konto unter **Billing** einmalig ein kleines Guthaben aufladen —
   **5 $ reichen erfahrungsgemäß sehr lange** (Sprachumwandlung kostet nur
   Bruchteile eines Cents pro Minute).
3. Auf der API-Keys-Seite **„Create new secret key"** klicken und den Key
   kopieren. Er wird nur **einmal** angezeigt, also gleich sichern.
4. In Booknote: **Einstellungen → API-Schlüssel** → Schlüssel einfügen →
   **Speichern**.

Das war's — ab jetzt kann aufgenommen werden.

## Was Booknote noch kann

- **Automatisches Erkennen von Seite & Position.** „Seite 47 oben, …" wird
  beim Sprechen automatisch in Seitenzahl/Position/Text zerlegt — auf
  Deutsch und Englisch.
- **Cover-Suche** beim Anlegen eines Buchs (Google Books / Open Library).
- **Export** einzelner Bücher, Autoren oder der ganzen Bibliothek als
  Markdown oder Text, zum Weitergeben oder Einkleben in andere Notizen.
- **Eigene Farbschemata** unter Einstellungen → Darstellung.
- **Mehrere Geräte abgleichen.** Geht über eine gemeinsame Bibliotheksdatei,
  ohne eigenen Server — für den Einstieg aber nicht nötig und etwas
  gewöhnungsbedürftig; Details in [SYNC_DESIGN.md](SYNC_DESIGN.md), falls du
  das nutzen willst.

## Für Entwickler: selbst bauen

Voraussetzung ist ein installiertes
[Flutter SDK](https://docs.flutter.dev/get-started/install).

```bash
flutter pub get
flutter run
```

Für ein Release-APK mit eigener, stabiler Signatur (Voraussetzung, damit
Tester spätere Versionen als Update statt Neuinstallation bekommen) siehe
[SIGNING.md](SIGNING.md).

## Weiterführende Dokumentation

- [PROJECT.md](PROJECT.md) — Projektspezifikation (Architektur, Datenmodell,
  Sprach-Parsing, Screens).
- [SYNC_DESIGN.md](SYNC_DESIGN.md) — das Abgleich-Modell zwischen Geräten
  (Abzug vs. Bibliotheksdatei, Merge vs. Master).
- [THEMES.md](THEMES.md) — Format eigener Farbschemata, mitgelieferte Themes.
- [SIGNING.md](SIGNING.md) — Release-Keystore anlegen und Release-APK bauen.
- [PROGRESS.md](PROGRESS.md) — Baustein-für-Baustein-Fortschritt.
- [BACKLOG.md](BACKLOG.md) — Ideen und spätere Ausbaustufen.
