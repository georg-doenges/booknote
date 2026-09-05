import 'package:flutter/material.dart';

import '../models/models.dart';

/// Cover-Kachel für das Bibliotheks-Grid. Ohne Cover: Platzhalter mit Titel.
class BookCoverTile extends StatelessWidget {
  const BookCoverTile({
    super.key,
    required this.book,
    this.onTap,
    this.onLongPress,
  });

  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: scheme.surfaceContainerHighest,
                  child: book.coverUrl == null
                      ? _Placeholder(title: book.title)
                      : Image.network(
                          book.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _Placeholder(title: book.title),
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, color: scheme.onPrimaryContainer, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
