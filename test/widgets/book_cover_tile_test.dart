import 'dart:convert';

import 'package:booknote/models/models.dart';
import 'package:booknote/theme.dart';
import 'package:booknote/widgets/book_cover_tile.dart';
import 'package:booknote/widgets/framed_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// 1×1-PNG; für die Prüfung der Anpassung (fit) muss nichts dekodiert werden.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Book _book({String title = 'Der Zauberberg', String? author = 'Thomas Mann'}) {
  final t = DateTime.utc(2026, 9, 1);
  return Book(
    id: 'b',
    title: title,
    author: author,
    createdAt: t,
    updatedAt: t,
  );
}

SliverConstraints _constraints(double width) => SliverConstraints(
  axisDirection: AxisDirection.down,
  growthDirection: GrowthDirection.forward,
  userScrollDirection: ScrollDirection.idle,
  scrollOffset: 0,
  precedingScrollExtent: 0,
  overlap: 0,
  remainingPaintExtent: 800,
  crossAxisExtent: width,
  crossAxisDirection: AxisDirection.right,
  viewportMainAxisExtent: 800,
  remainingCacheExtent: 800,
  cacheOrigin: 0,
);

void main() {
  group('CoverGridDelegate', () {
    const delegate = CoverGridDelegate(textHeight: 50);

    test(
      'Cover-Fläche ist in jeder Zelle Hochformat 3:4, Text kommt darunter',
      () {
        final layout = delegate.getLayout(_constraints(360));
        final tile = layout.getGeometryForChildIndex(0);
        expect(tile.crossAxisExtent, closeTo(112, 0.01)); // (360 − 2·12) / 3
        expect(tile.mainAxisExtent, closeTo(112 * 4 / 3 + 50, 0.01));
      },
    );

    test('Spaltenzahl folgt der Breite wie bei maxCrossAxisExtent 140', () {
      int columns(double w) => (delegate.getLayout(
        _constraints(w),
      ) as SliverGridRegularTileLayout).crossAxisCount;
      expect(columns(300), 2);
      expect(columns(360), 3);
      expect(columns(600), 4);
      expect(columns(30), 1);
    });

    test('höhere Schrift → höhere Zellen (Relayout)', () {
      expect(
        delegate.shouldRelayout(const CoverGridDelegate(textHeight: 60)),
        isTrue,
      );
      expect(
        delegate.shouldRelayout(const CoverGridDelegate(textHeight: 50)),
        isFalse,
      );
    });
  });

  group('FramedCover', () {
    Widget host(Widget child) => MaterialApp(
      theme: BooknoteTheme.light(),
      home: Scaffold(body: SizedBox(width: 100, height: 150, child: child)),
    );

    testWidgets('zeigt das Cover ganz (contain), nie beschnitten', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FramedCover(
            image: MemoryImage(_pixel),
            fallback: const Text('Ersatz'),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
      expect(find.text('Ersatz'), findsNothing);
    });

    testWidgets('gleichmäßige Fläche hinter dem Cover (Kartenfarbe)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FramedCover(
            image: MemoryImage(_pixel),
            fallback: const Text('Ersatz'),
          ),
        ),
      );
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(FramedCover),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(
        decoration.color,
        BooknoteTheme.light().colorScheme.surfaceContainerLow,
      );
    });

    testWidgets('ohne Bild: Ersatz füllt die Fläche', (tester) async {
      await tester.pumpWidget(
        host(const FramedCover(image: null, fallback: Text('Ersatz'))),
      );
      expect(find.text('Ersatz'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('BookCoverTile im Raster', () {
    Future<void> pumpGrid(
      WidgetTester tester,
      List<Book> books, {
      double textScale = 1,
    }) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: BooknoteTheme.light(),
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(360, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) => GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: CoverGridDelegate(
                    textHeight: BookCoverTile.textBlockHeight(context),
                  ),
                  itemCount: books.length,
                  itemBuilder: (_, i) =>
                      BookCoverTile(book: books[i], noteCount: i),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'Buch ohne Cover: Titel + Autor, ohne Überlauf auch bei sehr langem Titel',
      (tester) async {
        await pumpGrid(tester, [
          _book(),
          _book(
            title: 'Ein außergewöhnlich langer Buchtitel, der garantiert über mehrere Zeilen umbricht und in keine Kachel passt',
            author: 'Autorin mit einem sehr langen Namen',
          ),
          _book(author: null),
        ]);
        expect(tester.takeException(), isNull);
        expect(find.text('Thomas Mann'), findsOneWidget);
      },
    );

    testWidgets('Cover-Fläche ist immer gleich hoch – egal, wie viele Zeilen '
        'Text darunter stehen', (tester) async {
      await pumpGrid(tester, [
        _book(),
        _book(author: null),
        _book(title: 'Kurz'),
        _book(title: 'Sehr langer Titel ' * 8),
      ]);
      // Gemessen wird die Cover-Fläche (der Rahmen), nicht die Zelle: Ein
      // `Expanded`-Cover bekam früher mehr Höhe, wenn darunter weniger Text
      // stand (1 Zeile Titel, kein Autor …).
      final heights = {
        for (final tile in tester.widgetList(find.byType(BookCoverTile)))
          tester
              .getSize(
                find.descendant(
                  of: find.byWidget(tile),
                  matching: find.byType(FramedCover),
                ),
              )
              .height
              .toStringAsFixed(2),
      };
      expect(tester.widgetList(find.byType(FramedCover)), hasLength(4));
      expect(heights, hasLength(1));
    });

    testWidgets('bei großer Systemschrift kein Überlauf', (tester) async {
      await pumpGrid(tester, [_book(), _book(title: 'Kurz')], textScale: 1.6);
      expect(tester.takeException(), isNull);
    });
  });
}
