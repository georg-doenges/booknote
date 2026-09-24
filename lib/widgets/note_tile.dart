import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import 'format.dart';

/// Kurzform der Fundstelle: "S. 47 (oben)" / "p. 47 (top)", "S. 88f.",
/// "Ohne Seitenangabe". Das Präfix richtet sich nach der Sprache der Notiz;
/// [noPage] ist der (übersetzte) Text, wenn weder Seite noch Position da sind.
String noteLocationLabel(Note n, {String noPage = 'Ohne Seitenangabe'}) {
  if (n.page == null) {
    return n.position == null ? noPage : n.position!;
  }
  final pos = n.position == null ? '' : ' (${n.position})';
  return '${pagePrefix(n.language)} ${n.page}$pos';
}

/// Eine Notiz in der Liste (BookDetail) oder als Feedback (Recording).
class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.onTap,
    this.onDelete,
    this.highlight = false,
  });

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = context.l10n;
    final text = note.text.isEmpty ? l.noteNoText : note.text;
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Expanded(
              child: Text(
                noteLocationLabel(note, noPage: l.noteNoPage),
                style: textTheme.labelLarge?.copyWith(
                  color: note.page == null ? scheme.error : scheme.primary,
                ),
              ),
            ),
            Text(
              formatDateTime(
                note.createdAt,
                Localizations.localeOf(context).languageCode,
              ),
              style: textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        subtitle: Text(
          text,
          style: note.text.isEmpty
              ? TextStyle(
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                )
              : null,
        ),
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l.commonDelete,
                onPressed: onDelete,
              ),
      ),
    );
  }
}
