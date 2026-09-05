import 'package:flutter/material.dart';

import '../models/models.dart';

/// Kurzform der Fundstelle: "S. 47 (oben)", "S. 88f.", "Ohne Seite".
String noteLocationLabel(Note n) {
  if (n.page == null) {
    return n.position == null ? 'Ohne Seitenangabe' : n.position!;
  }
  final pos = n.position == null ? '' : ' (${n.position})';
  return 'S. ${n.page}$pos';
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
    final text = note.text.isEmpty ? '(kein Text erkannt)' : note.text;
    return Card(
      color: highlight ? scheme.primaryContainer : null,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          noteLocationLabel(note),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: note.page == null ? scheme.error : scheme.primary,
          ),
        ),
        subtitle: Text(
          text,
          style: note.text.isEmpty
              ? TextStyle(fontStyle: FontStyle.italic, color: scheme.outline)
              : null,
        ),
        trailing: onDelete == null
            ? null
            : IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Löschen',
                onPressed: onDelete,
              ),
      ),
    );
  }
}
