# Booknote — Projektspezifikation

Eine niederschwellige App zum Erfassen von Lesenotizen per Sprache. Ziel: beim Lesen mit minimaler Reibung (App öffnen → Buch antippen → sprechen) Anmerkungen, Zitate und Gedanken zu Büchern festhalten. Android-first, aber iOS-fähig gebaut.

**Name der App:** **Booknote** (großes B, Singular). Technischer Flutter-Projektname: `booknote` (kleingeschrieben, ohne Leerzeichen — Flutter-Konvention). Der auf dem Homescreen angezeigte Name ist „Booknote".

---

## 1. Kernprinzip

Die App muss **schnell und niederschwellig** sein. Der wichtigste Pfad ist:

**App öffnen → Bibliothek sehen → Buch antippen → sprechen → Notiz gespeichert.**

Alles andere (Export, Verwaltung, Bearbeiten) darf ruhig ein paar Schritte mehr brauchen. Der Aufnahme-Flow darf es nicht.

---

## 2. Technischer Stack

- **Framework:** Flutter (Android-first; iOS soll ohne Architektur-Umbau möglich sein — siehe Abschnitt 3a).
- **Sprache:** Dart
- **Storage (Stufe 1):** Lokal auf dem Gerät via SQLite (`sqflite`). Die Datenzugriffsschicht liegt hinter einem Repository-Interface, damit Cloud-Sync später nachrüstbar ist, ohne die UI anzufassen (siehe 3b).
- **Speech-to-Text:** OpenAI Whisper API (`whisper-1`), pay-per-use, kein Abo. Nutzer hinterlegt eigenen API-Key.
- **Cover-Abruf:** Google Books API als Primärquelle, Open Library Covers API als Fallback. Nutzer wählt aus mehreren Treffern aus.
- **Export:** Markdown (pro Buch eine `.md`-Datei).

**Plattformneutralität:** Alle gewählten Pakete müssen sowohl auf Android als auch iOS laufen. Die oben genannten (`sqflite`, `record`, `http`, `flutter_secure_storage`, `share_plus`) erfüllen das. Keine Android-only-Bibliothek für Kernfunktionen.

---

## 3. Architektur-Vorgaben

Der Code soll so aufgebaut sein, dass sich Storage, Export und Notiz-Quellen später erweitern lassen, ohne die Kernlogik anzufassen:

1. **Storage:** Repository-Pattern. `NoteRepository` und `BookRepository` als abstrakte Interfaces, mit einer lokalen SQLite-Implementierung. Eine spätere Cloud-Implementierung erfüllt dasselbe Interface.
2. **Export:** Ein `Exporter`-Interface mit einer `MarkdownExporter`-Implementierung. Weitere Formate (JSON etc.) später ergänzbar.
3. **Notiz-Quellen:** Das Datenmodell soll später auch andere Quellen als Bücher zulassen (z.B. YouTube-Videos, Ideen-Notizbücher). Deshalb eine generische `Source`-Entität, von der „Buch" der erste Typ ist. Für Stufe 1 wird nur „Buch" implementiert, aber das Schema sieht `source_type` bereits vor.

### 3a. iOS-Fähigkeit (von Anfang an mitdenken)

Flutter ist plattformübergreifend — dieselbe Codebasis läuft auf Android und iOS. Damit iOS später nicht blockiert ist:
- Nur plattformneutrale Pakete für Kernfunktionen (Audio, HTTP, DB, Secure Storage, Share).
- Keine Annahmen über Android-spezifische Dateipfade; Pfade über `path_provider` beziehen.
- Die **Distribution** auf iOS (Apple-Developer-Account, Signierung) ist ein späteres Thema und berührt den Code nicht. Ziel jetzt: der iOS-Build muss jederzeit technisch möglich bleiben.

### 3b. Cloud-Sync (spätere Stufe, jetzt nur vorbereiten)

Sync gehört **nicht** in Stufe 1, wird aber architektonisch vorbereitet. Ziellösung ist **Supabase** (Backend-as-a-Service auf PostgreSQL-Basis): bietet Cloud-DB, Nutzer-Login und Mehrgeräte-Sync out of the box, und das lokale SQLite-Schema lässt sich fast 1:1 übertragen. Google Drive als Sync-Speicher wurde erwogen und verworfen (OAuth-Aufwand, Konfliktbehandlung bei gleichzeitigem Zugriff fragil).

Konsequenz für jetzt: Das Repository-Interface so schneiden, dass eine `SupabaseRepository`-Implementierung später nahtlos danebentreten kann (klare CRUD-Methoden, keine SQLite-Details nach außen sichtbar).

Vorgeschlagene Ordnerstruktur:

```
lib/
  models/          # Book, Note, Source
  repositories/    # abstrakte Interfaces + SQLite-Implementierungen
  services/        # WhisperService, CoverService (GoogleBooks + OpenLibrary), NoteParser
  export/          # Exporter-Interface + MarkdownExporter
  screens/         # LibraryScreen, RecordingScreen, BookDetailScreen, SettingsScreen
  widgets/         # wiederverwendbare UI-Komponenten
  main.dart
```

---

## 4. Datenmodell

**Source** (generisch, für spätere Erweiterung)
- `id` (INTEGER, PK)
- `source_type` (TEXT) — in Stufe 1 immer `"book"`
- `title` (TEXT)
- `cover_url` (TEXT, nullable)
- `created_at` (INTEGER, Unix-Timestamp)

**Note**
- `id` (INTEGER, PK)
- `source_id` (INTEGER, FK → Source)
- `page` (TEXT, nullable) — z.B. "47" oder "47f."
- `position` (TEXT, nullable) — "oben" / "mitte" / "unten" / "Zeile 10"
- `text` (TEXT) — der eigentliche Notiztext
- `raw_transcript` (TEXT) — der ungeparste Whisper-Output (Sicherung, falls Parsing danebenliegt)
- `created_at` (INTEGER, Unix-Timestamp)

Hinweis für späteren Sync: IDs so wählen, dass sie geräteübergreifend eindeutig bleiben können (z.B. Vorbereitung auf UUIDs statt reiner Autoincrement-Integers). Für Stufe 1 genügt lokal Autoincrement, aber die Umstellbarkeit im Hinterkopf behalten.

---

## 5. Sprach-Parsing

Nach der Whisper-Transkription wird der Text regelbasiert (kein LLM nötig) geparst:

**Konvention:**
- Eine Notiz beginnt **immer** mit einer Seitenangabe: `"Seite <Zahl>"`.
- Optional folgt eine Position: `"oben"`, `"mitte"`, `"unten"`, oder `"Zeile <Zahl>"`.
- Alles danach ist der Notiztext.

**Beispiele:**
- „Seite 47 oben, hier argumentiert der Autor dass…" → `page=47, position=oben, text="hier argumentiert der Autor dass…"`
- „Seite 12, schöne Metapher über das Meer" → `page=12, position=null, text="schöne Metapher über das Meer"`
- „Seite 88 folgende Mitte, der Konflikt eskaliert" → `page=88f., position=mitte, text="der Konflikt eskaliert"`

**Robustheit:**
- Notiz **ohne** erkennbare Seitenangabe wird trotzdem gespeichert (`page=null`), damit nichts verloren geht.
- Der vollständige, ungeparste Transkript-Text wird **immer** in `raw_transcript` gespeichert.
- Der Parser soll Zahlen als Wort ("siebenundvierzig") und als Ziffer ("47") tolerieren. Whisper gibt meist Ziffern aus, aber eine einfache deutsche Wort-zu-Zahl-Erkennung ist wünschenswert.
- "folgende" / "f." / "ff." nach der Seitenzahl soll erkannt und an die Seite angehängt werden.

---

## 6. Screens & Flows

### LibraryScreen (Startbildschirm)
- Wird beim App-Start **direkt** angezeigt.
- Zeigt die Bibliothek als Grid von Buchcovern (scrollbar).
- Bücher ohne Cover bekommen einen Platzhalter mit Titel.
- Antippen eines Buchs → direkt zum **RecordingScreen** dieses Buchs.
- Ein „+"-Button zum Anlegen eines neuen Buchs.
- Zugang zu Settings (API-Key) und Export (Menü / Icon).

### Neues Buch anlegen
- Titel eintippen.
- Die App fragt die **Google Books API** ab und zeigt **mehrere Treffer mit Coverbildern** zur Auswahl an; der Nutzer tippt das passende an. Findet Google Books nichts, wird die **Open Library Covers API** als Fallback abgefragt.
- Cover kann auch leer bleiben (Platzhalter).
- Die Cover-Beschaffung soll als `CoverService` gekapselt sein, sodass „Cover fotografieren + Titel per OCR erkennen" später als **zusätzliche Quelle** angedockt werden kann, ohne den Flow umzubauen. (Das Foto-Feature selbst ist spätere Stufe — siehe Abschnitt 9.)

### RecordingScreen (der wichtigste Screen)
- Großer, gut erreichbarer Aufnahme-Button (tap-to-start / tap-to-stop).
- **Mehrere Aufnahmen pro Sitzung:** Nach dem Speichern bleibt man auf diesem Screen und kann sofort die nächste Notiz aufnehmen. Erst aktives Zurückgehen verlässt den Aufnahmemodus.
- Nach jeder Aufnahme kurzes visuelles Feedback (transkribierter Text + erkannte Seite/Position).
- Fehlerfall (kein API-Key, Netzwerkfehler): klare, freundliche Meldung; Audio möglichst nicht verlieren.

### BookDetailScreen
- Liste aller Notizen zu einem Buch, chronologisch oder nach Seite sortierbar.
- Notizen bearbeiten und löschen.
- Export-Button für dieses Buch (Markdown).

### SettingsScreen
- Eingabefeld für den **OpenAI API-Key** (sicher lokal gespeichert via `flutter_secure_storage`, aktualisierbar).
- Der Key muss eingebbar sein, damit die App an Tester weitergegeben werden kann (jeder nutzt seinen eigenen Key).

---

## 7. Whisper-Integration

Einzige Lösung, bewusst so gewählt (kein Monatsabo, weitergabefähig):
- Nutzer hinterlegt seinen **eigenen OpenAI API-Key** in den Einstellungen.
- Audio wird lokal aufgenommen (`record`-Package), als Datei (m4a/wav) zwischengespeichert.
- POST an `https://api.openai.com/v1/audio/transcriptions`, Modell `whisper-1`, `language=de`, Authorization mit dem hinterlegten Key.
- Antwort-Text → Parser → Speichern.
- Kostenhinweis für den Nutzer: ~$0.006/Minute, kein Abo.

---

---

## 7a. Kosten & Free Tiers

Die App ist im Betrieb praktisch kostenlos — bewusst so gewählt für eine Gelegenheits-App ohne Fixkosten:

- **Whisper (OpenAI):** Einziger Kostenpunkt. Kein Abo, pay-per-use (~$0.006/Minute). Bei gelegentlichen Notizen Cent-Beträge im Monat. Bei weitergegebenen Test-Versionen trägt jeder Tester die Kosten über seinen eigenen Key.
- **Google Books API:** Kostenlos unter normalen Grenzen, keine Kreditkarte. Einfache Titelsuchen funktionieren zum Testen sogar ganz ohne Key; für stabileren Betrieb einen kostenlosen API-Key anlegen (optional, ohne Kreditkarte). Der `CoverService` soll mit und ohne Key funktionieren; falls ein Key genutzt wird, ist er wie der OpenAI-Key in den Einstellungen hinterlegbar.
- **Open Library Covers API (Fallback):** Komplett kostenlos, kein Key nötig. Höfliche Ratenbegrenzung (~100 Cover / 5 Min), für diese App irrelevant.
- **Supabase (späterer Cloud-Sync):** Dauerhaft kostenloser Free Tier, reicht für eine private App locker. Betrifft Stufe 1 noch nicht.

## 8. Markdown-Export

Pro Buch eine `.md`-Datei, Struktur etwa:

```markdown
# <Buchtitel>

## Notizen

- **S. 47 (oben):** hier argumentiert der Autor dass…
- **S. 12:** schöne Metapher über das Meer
- **S. 88f. (mitte):** der Konflikt eskaliert
```

Notizen ohne Seitenangabe in eigenem Abschnitt „Ohne Seitenangabe". Export über den Share-Sheet (`share_plus`) oder ins Dateisystem.

---

## 9. Ausbaustufen

### Stufe 1 (jetzt bauen)
- Lokale Speicherung (SQLite hinter Repository-Interface)
- Buch anlegen mit Titel + Cover-Auswahl (Google Books / Open Library)
- Aufnahme-Flow mit Whisper + Parser, mehrere Notizen pro Sitzung
- Notizen anzeigen / bearbeiten / löschen
- Markdown-Export
- Einstellungen (API-Key)
- Android lauffähig, iOS-Build technisch möglich

### Spätere Stufen (jetzt nur architektonisch offenhalten, NICHT bauen)
- **Cloud-Sync über Supabase** (Mehrgeräte, nahtlos weiterarbeiten)
- **iOS-Distribution** (Apple-Developer-Account, Signierung)
- **Cover fotografieren** → Titel per OCR erkennen, Daten automatisch füllen, besseres Cover suchen
- Andere Quellen als Bücher (YouTube-Videos, Ideen-Notizbücher)
- Weitere Export-Formate (JSON etc.)
- On-device / lokales Whisper

Diese Punkte sollen durch die Architektur (Repository-Pattern, generische `Source`-Entität, `CoverService`, `Exporter`-Interface) **möglich bleiben**, aber jetzt nicht implementiert werden.

---

## 10. Arbeitsweise in Claude Code

**Komplexe, tragende Teile zuerst.** Damit das Repository jederzeit sauber an ein anderes Modell übergeben werden kann, liegt die architektonische Denkarbeit vorn:

1. Projekt-Grundgerüst + Ordnerstruktur + Datenmodell
2. **Repository-Interface** (die Abstraktionsschicht — Herzstück für Cloud- und iOS-Fähigkeit)
3. Lokale SQLite-Implementierung dahinter
4. Whisper-Service + Parser (zweite anspruchsvolle Stelle)
5. UI-Schichten: LibraryScreen, RecordingScreen, BookDetailScreen, SettingsScreen
6. CoverService (Google Books + Open Library, Auswahl-UI)
7. Markdown-Export
8. Feinschliff Usability des Aufnahme-Flows

**Git:**
- Gleich zu Beginn ein Git-Repository initialisieren.
- Nach jedem sinnvollen Baustein ein Commit mit aussagekräftiger Nachricht.
- GitHub-Push kann am Ende erfolgen; wichtig ist zunächst eine saubere lokale Historie.

**Übergabe zwischen Modellen:**
- Eine `PROGRESS.md` pflegen (oder einen Statusabschnitt in dieser Datei): „Was ist gebaut, was fehlt, wo steht es gerade." So kann ein Folgemodell den Stand ablesen, statt das ganze Repo zu rekonstruieren.
- Nach jedem größeren Baustein die `PROGRESS.md` aktualisieren.

**Testen:** Nach jedem Block ein lauffähiger Zwischenstand; erst wenn er läuft, kommt der nächste. Getestet wird auf einem echten Android-Gerät per USB.
