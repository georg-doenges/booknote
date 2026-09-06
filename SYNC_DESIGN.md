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

## 4. Merge (`mergeLibrary`, reine Funktion)

Eingabe: lokaler Snapshot + Datei-Snapshot, je `{sources, notes, tombstones,
masterGeneration}`. Ausgabe: gemischter Snapshot – wird **sowohl** in die DB
geschrieben **als auch** als neue Datei.

### 4.1 Master-Kurzschluss (zuerst prüfen)

Jedes Gerät merkt sich `lastConsumedMasterGeneration` (in `AppSettings`, Default 0).

- Ist `datei.masterGeneration > lastConsumedMasterGeneration`:
  → **kein Merge**. Die lokale DB wird **komplett durch den Datei-Inhalt
  ersetzt** (inkl. Grabsteine). `lastConsumedMasterGeneration :=
  datei.masterGeneration`. Fertig.
  Begründung: Der Nutzer hat diese Datei bewusst zum „Master" erklärt (§5);
  lokale Extras sollen weichen.
- Sonst: normaler Merge (§4.2).

### 4.2 Normaler Merge — „neuester Fakt gewinnt"

Für jede Eintrags-ID sammeln wir alle bekannten Fakten aus beiden Seiten:

| Fakt | Zeitstempel |
|---|---|
| lebende Quelle | `updatedAt` |
| lebende Notiz | `updatedAt` |
| Grabstein | `deletedAt` |

Pro ID gewinnt der Fakt mit dem **größten Zeitstempel**. Bei exaktem
Gleichstand gewinnt der **Grabstein** (Löschung schlägt Bearbeitung).

Danach:
1. `liveSources` = alle Sieger-Fakten vom Typ Quelle.
2. `liveNotes` = alle Sieger-Fakten vom Typ Notiz, **gefiltert**: Notizen, deren
   `sourceId` nicht unter `liveSources` ist, fallen weg (Waise nach
   Buch-Löschung).
3. `tombstones` = alle Sieger-Fakten vom Typ Grabstein.
4. **Grabstein-GC** (§6): Grabsteine mit `deletedAt < now - gcDays` entfernen,
   falls GC eingeschaltet.
5. `masterGeneration` = `max(lokal, datei)`.

Ergebnis ist per Konstruktion ein Superset der lebenden lokalen Daten → die DB
kann gefahrlos komplett ersetzt werden (`LibraryArchive.replaceWith`).

### 4.3 Fälle (zur Kontrolle)

| Situation | Ergebnis |
|---|---|
| auf A gelöscht, auf B unangetastet | Grabstein neuer → überall weg |
| auf A gelöscht, danach auf B bearbeitet | Bearbeitung neuer → kommt zurück |
| nur auf A neu | Union → bleibt |
| auf beiden gelöscht | bleibt weg |
| dieselbe Notiz auf A und B bearbeitet | spätere Wall-Clock gewinnt, andere Änderung weg (akzeptiert) |

## 5. „Als Master setzen"

Zusätzlich zum normalen „Sichern" (schreibt Datei mit unverändertem
`masterGeneration`) gibt es **„Als Master setzen"**:

- schreibt die Datei mit dem **aktuellen lokalen Stand unverändert** (kein
  vorheriger Merge),
- `masterGeneration := max(lokal, zuletzt gesehene Datei) + 1`,
- setzt lokal `lastConsumedMasterGeneration := neue masterGeneration`.

Praxis: Nutzer macht normalen Abgleich, konsolidiert/editiert in Ruhe, dann
„Als Master setzen". Alle anderen Geräte richten sich beim nächsten Abgleich
per §4.1 danach aus.

**Grenze (dokumentieren, nicht lösen):** Setzen zwei Geräte ohne
zwischenzeitlichen Abgleich „Master", gewinnt die zuletzt in Drive geschriebene
Datei; der andere Master-Push geht verloren. Für eine private App ok.

## 6. Grabstein-Aufräumen (GC)

- `AppSettings`: `tombstoneGcEnabled` (Default **true**), `tombstoneGcDays`
  (Default **120**).
- Beim Merge (Schritt §4.2.4) werden Grabsteine älter als
  `now - tombstoneGcDays` verworfen, wenn `tombstoneGcEnabled`.
- Risiko bei sehr seltenem Abgleich (Gerät > gcDays offline mit lebendem
  Eintrag → Wiederauferstehung). Deshalb abschaltbar.
- GC ist pro Gerät konfiguriert; ein Gerät mit GC aus bringt alte Grabsteine
  wieder in die Datei – harmlos, solange der Eintrag wirklich überall tot ist.

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
