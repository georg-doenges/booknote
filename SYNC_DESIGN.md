# Booknote — Abzug vs. Bibliotheksdatei (Merge-Design)

Spezifikation für Baustein F2. Abgestimmt mit dem Nutzer; offene Punkte sind als
solche markiert. Deferred-Teile stehen in `BACKLOG.md`.

## 1. Zwei getrennte Dinge

| | **Abzug** (Baustein F1, fertig) | **Bibliotheksdatei** (Baustein F2) |
|---|---|---|
| Zweck | Notizen lesen / weitergeben / woanders einkleben | Datengrundlage der App, Abgleich zwischen Geräten |
| Format | Markdown **oder** Text, wählbar | eigenes JSON, nah an der internen Struktur |
| Richtung | nur **raus** (Momentaufnahme) | **rein und raus** (Merge) |
| Inhalt | nur sichtbare Notizen, keine Grabsteine | alle Quellen + Notizen + **Grabsteine** + Meta |
| Ebenen | Buch / Autor / ganze Bibliothek | immer die ganze Bibliothek |
| Ablage | Share-Sheet | Share-Sheet; später Google Drive automatisch |

Die beiden dürfen im Code und in der UI **nicht** vermischt werden. „Exportieren"
= Abzug. „Bibliothek sichern / abgleichen" = Bibliotheksdatei.

## 2. Dateiformat `booknote-library.json`

```jsonc
{
  "format": "booknote-library",
  "formatVersion": 1,
  "exportedAt": 1757181600000,        // epoch ms UTC
  "masterGeneration": 0,              // siehe §4
  "sources": [
    { "id": "<uuid>", "sourceType": "book", "title": "...", "author": "...",
      "coverUrl": "...", "createdAt": 1757000000000, "updatedAt": 1757100000000 }
  ],
  "notes": [
    { "id": "<uuid>", "sourceId": "<uuid>", "page": "47", "position": "oben",
      "text": "...", "rawTranscript": "...",
      "createdAt": 1757000000000, "updatedAt": 1757100000000 }
  ],
  "deleted": [
    { "id": "<uuid>", "type": "source", "deletedAt": 1757150000000 },
    { "id": "<uuid>", "type": "note",   "deletedAt": 1757150000000 }
  ]
}
```

- Zeitstempel überall epoch-ms UTC (wie in der DB, `dbNow()`).
- `formatVersion` erlaubt spätere Änderungen ohne Bruch.

## 3. Grabsteine (Tombstones)

### Schema v3

Neue Tabelle:

```sql
CREATE TABLE tombstones (
  entity_id   TEXT PRIMARY KEY,          -- UUID, geräteübergreifend eindeutig
  entity_type TEXT NOT NULL,             -- 'source' | 'note'
  deleted_at  INTEGER NOT NULL           -- epoch ms UTC
);
```

Migration in `AppDatabase._onUpgrade` (v2 → v3): `CREATE TABLE IF NOT EXISTS`.
Abgesichert durch `migration_test.dart`.

### Delete-Pfade

In derselben Transaktion wie das Löschen der Zeile(n):

- `SqliteNoteRepository.delete(id)` → zusätzlich `INSERT OR REPLACE INTO
  tombstones` für die Notiz.
- `SqliteBookRepository.delete(id)` → vorher `SELECT id FROM notes WHERE
  source_id = ?`, dann Grabstein fürs Buch **und** je einen für jede kaskadierte
  Notiz.
- `InMemory*`-Repos führen zur Parität eine Grabstein-Liste im `InMemoryStore`.

Wird eine ID neu angelegt, die zufällig einem Grabstein entspricht (praktisch
nur bei „Undelete via Merge"), verliert der Grabstein beim nächsten Merge gegen
die neuere `updatedAt` – kein Sonderfall nötig.

## 4. Abgleichen — `mergeLibrary`, **rein additiv**

Eingabe: lokaler Snapshot + Datei-Snapshot, je `{sources, notes, tombstones,
masterGeneration}`. Ausgabe: gemischter Snapshot – wird **sowohl** in die DB
geschrieben **als auch** (auf Wunsch) als neue Datei.

### 4.1 Master-Kurzschluss (zuerst prüfen)

Jedes Gerät merkt sich `lastConsumedMasterGeneration` (in `AppSettings`, Default 0).

- Ist `datei.masterGeneration > lastConsumedMasterGeneration`:
  → **kein Merge**, sondern `adoptMaster` (§5). `lastConsumedMasterGeneration :=
  datei.masterGeneration`.
- Sonst: normaler Merge (§4.2).

### 4.2 Merge — Vereinigung, nie Datenverlust

**Grundsatz:** Alles, was auf einer der beiden Seiten noch **lebt**, ist danach
dabei. **Löschungen werden nicht übertragen.** Grabsteine werden mitgeführt,
aber **nicht angewendet** – sie wirken erst in `adoptMaster` (§5).

1. `sources` = Vereinigung beider Quell-Listen; bei gleicher ID gewinnt der
   neuere `updatedAt` (Inhaltskonflikt = last-write-wins, **nur** bei Inhalt,
   nicht bei Existenz).
2. `notes` analog; danach fallen Waisen (Buch nicht mehr da) weg.
3. `tombstones` = Vereinigung, jüngster je ID – **aber nur, solange der Eintrag
   nirgends mehr lebt.** Kommt ein Eintrag im Merge wieder zum Leben,
   verschwindet sein Grabstein. → Invariante: *lebendig* und *Grabstein*
   schließen sich aus.
4. **Grabstein-GC** (§6).
5. `masterGeneration` = `max(lokal, datei)`.

Ergebnis ist per Konstruktion ein Superset der lebenden lokalen Daten → die DB
kann gefahrlos komplett ersetzt werden (`LibraryArchive.replaceWith`).

### 4.3 Fälle (zur Kontrolle)

| Situation | Merge-Ergebnis |
|---|---|
| nur auf A vorhanden | Union → bleibt |
| auf A gelöscht, auf B noch da | **kommt zurück** (Merge löscht nie) |
| dieselbe Notiz auf A und B bearbeitet | spätere Wall-Clock gewinnt (nur Inhalt) |
| auf beiden gelöscht, nirgends mehr da | Grabstein bleibt (für spätere `adoptMaster`) |

## 5. „Als Vorlage (Master) setzen" + `adoptMaster`

### 5.1 Setzen (Gerät A)

- `masterGeneration := lokale masterGeneration + 1`
- schreibt die Datei mit dem **aktuellen lokalen Stand unverändert** (inkl.
  seiner Grabsteine, kein vorheriger Merge)
- hält die neue Generation lokal fest (`replaceWith` + `lastConsumedMasterGeneration`)
- teilt die Datei

Praxis: erst normal abgleichen, dann in Ruhe konsolidieren/aufräumen, dann „Als
Vorlage setzen".

### 5.2 Übernehmen (`adoptMaster(local, master)`, Gerät B)

Der Master ist **verbindlich für alles, was er kennt**:

- **`master.sources` / `master.notes` gewinnen** – auch gegen einen neueren
  lokalen Stand derselben ID.
- **`master.tombstones` werden angewendet:** entsprechende lokale Einträge
  fallen weg. **Nur so werden Löschungen übertragen.**
- Lokale Einträge, deren ID der Master **nie gesehen hat** (weder lebendig noch
  als Grabstein), **bleiben** – sie sind auf B neu dazugekommen.
- Danach Waisen-Filter, Grabstein-Invariante (§4.2.3), GC.
- `masterGeneration := master.masterGeneration`.

### 5.3 Grenze (dokumentieren, nicht lösen)

Setzen zwei Geräte ohne zwischenzeitlichen Abgleich „Master", gewinnt die
zuletzt in Drive geschriebene Datei; der andere Master-Push geht verloren. Für
eine private App ok.

## 6. Grabstein-Aufräumen (GC)

- `AppSettings.sync`: `tombstoneGcEnabled` (Default **true**), `tombstoneGcDays`
  (Default **120**).
- In `mergeLibrary` **und** `adoptMaster` werden Grabsteine älter als
  `now - tombstoneGcDays` verworfen, wenn eingeschaltet.
- Risiko: Gerät > gcDays offline mit lebendem Eintrag, der anderswo per Master
  gelöscht wurde → beim späten `adoptMaster` fehlt der Grabstein → Eintrag gilt
  als „auf B neu" und bleibt (Wiederauferstehung). Deshalb abschaltbar. Für zwei
  regelmäßig genutzte Geräte irrelevant.

## 7. Ablauf ohne Google Drive (jetzt baubar)

- **Sichern / Als Master setzen:** Datei ins Temp-Verzeichnis, Share-Sheet →
  Nutzer legt sie in Drive/Files ab.
- **Abgleichen:** `file_picker` → Nutzer wählt die Datei → App liest, merged
  (oder Master-Kurzschluss), schreibt DB. Danach **Hinweis + Button
  „Aktualisierte Bibliotheksdatei sichern"**, damit der gemischte Stand zurück
  nach Drive kommt.
- Automatisches Lesen/Zurückschreiben der Drive-Datei = späterer Schritt
  (`google_sign_in` + Drive-API, OAuth-Consent). → `BACKLOG.md`.

## 8. Neue Bausteine im Code (F2)

```
lib/
  models/
    library_snapshot.dart   LibrarySnapshot, Tombstone, JSON <-> Modell
  services/
    library_merge.dart      mergeLibrary(local, incoming, {now, gc}) -> merged   (rein, getestet)
  repositories/sqlite/
    library_archive.dart    LibraryArchive: readSnapshot(), replaceWith(snapshot)
  services/
    library_sync.dart       Datei schreiben/teilen, Datei wählen+parsen, Merge fahren, DB ersetzen
```

- `AppSettings` bekommt: `tombstoneGcEnabled`, `tombstoneGcDays`,
  `lastConsumedMasterGeneration`.
- `file_picker` als neue Abhängigkeit (plattformneutral).
- Tests: `library_merge_test.dart` (alle Fälle §4.3, GC, Master-Kurzschluss),
  `library_snapshot_test.dart` (JSON-Roundtrip), Migration v2→v3.

### Unterteilung

- **F2a:** Schema v3 + Grabsteine + `LibrarySnapshot`/JSON + `mergeLibrary` +
  `LibraryArchive` + „Sichern" / „Abgleichen (Datei wählen)" + Re-Save-Hinweis.
- **F2b:** „Als Master setzen" + `masterGeneration` + Kurzschluss + GC-Felder in
  `AppSettings` (Werte vorerst über Defaults, UI kommt mit der Settings-Seite).

## 9. UI-Prinzip (Nutzerwunsch: clean)

- Die Hauptflächen (Bibliothek, Buchdetail) bleiben schlank. Kein Wust an
  Optionen.
- Alles Detaillierte hinter **einem** „Einstellungen"-Knopf, auf **einer**
  klaren, verständlichen Seite (kommt separat, siehe `BACKLOG.md` „Settings-
  Seite"). Bis dahin sitzen die Sync-Aktionen im Overflow-Menü der Bibliothek
  („Bibliothek sichern / abgleichen …").
