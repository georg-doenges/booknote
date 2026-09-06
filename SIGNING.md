# Booknote — Release-Signierung (Baustein E)

Debug-Builds (`flutter build apk --debug`) sind mit einem automatischen
Debug-Key signiert – gut für die eigene Entwicklung. Für **Release-APKs zur
Weitergabe an Tester** braucht es einen eigenen, stabilen Keystore, damit alle
Builds dieselbe Signatur haben (Tester bekommen Updates dann ohne
Neuinstallation).

Der Keystore und sein Passwort dürfen **nicht ins Git**. `android/.gitignore`
schließt `key.properties`, `*.jks` und `*.keystore` bereits aus.

## Einmalig: Keystore anlegen

Im Projektordner ausführen (Passwort selbst wählen und merken – geht sonst
unwiederbringlich verloren):

```bash
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android/app/booknote-release.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias booknote
```

`keytool` fragt nach:
- **Keystore-Passwort** (zweimal)
- Vor- und Nachname / Organisation usw. – darf minimal bleiben (z.B. nur
  „Booknote"), einfach durchbestätigen
- **Key-Passwort für „booknote"** – Enter drücken übernimmt das
  Keystore-Passwort (empfohlen: gleich lassen)

Danach liegt `android/app/booknote-release.jks` (nicht im Git).

## Einmalig: `android/key.properties` anlegen

Datei `android/key.properties` mit diesem Inhalt (Passwörter eintragen):

```properties
storePassword=DEIN_KEYSTORE_PASSWORT
keyPassword=DEIN_KEY_PASSWORT
keyAlias=booknote
storeFile=booknote-release.jks
```

`storeFile` ist relativ zu `android/app/`.

## Release-APK bauen

```bash
$env:PATH = "C:\src\flutter\bin;$env:PATH"; flutter build apk --release
```

Ergebnis: `build/app/outputs/flutter-apk/app-release.apk` – signiert, an Tester
weitergebbar (Sideload).

- Ohne `android/key.properties` fällt der Release-Build automatisch auf den
  Debug-Key zurück (`build.gradle.kts`), es bricht also nichts.
- `--split-per-abi` erzeugt kleinere, ABI-spezifische APKs.
- App-Bundle (`flutter build appbundle`) nur nötig, wenn es je in den Play
  Store geht.

## Backup

`booknote-release.jks` **und** die Passwörter sicher sichern (Passwort-Manager).
Ohne sie können bestehende Installationen kein Update mehr bekommen.
