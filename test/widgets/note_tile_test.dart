import 'package:booknote/models/models.dart';
import 'package:booknote/widgets/note_tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 9, 5, 10, 0);
  Note note({String? page, String? position, AppLanguage? language}) => Note(
    id: '1',
    sourceId: 'b',
    page: page,
    position: position,
    text: 'x',
    rawTranscript: 'x',
    language: language ?? AppLanguage.german,
    createdAt: t0,
    updatedAt: t0,
  );

  test('Deutsch: "S. 47 (oben)"', () {
    expect(
      noteLocationLabel(note(page: '47', position: 'oben')),
      'S. 47 (oben)',
    );
  });

  test('Englisch: "p. 47 (top)"', () {
    expect(
      noteLocationLabel(
        note(page: '47', position: 'top', language: AppLanguage.english),
      ),
      'p. 47 (top)',
    );
  });

  test('ohne Seite: nur Position oder Hinweistext', () {
    expect(noteLocationLabel(note(position: 'oben')), 'oben');
    expect(noteLocationLabel(note()), 'Ohne Seitenangabe');
  });
}
