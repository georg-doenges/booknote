import 'dart:async';

/// Baut einen „Startwert + bei jeder Änderung neu laden"-Stream.
///
/// Bewusst kein `async*`: Ein `async*`-Generator verarbeitet `cancel()` erst
/// beim nächsten `yield`, hängt aber in `await for` fest → Abbestellen blockiert.
Stream<T> watchStream<T>(Stream<void> changes, T Function() load) =>
    watchStreamAsync(changes, () async => load());

/// Wie [watchStream], aber mit asynchronem Laden (DB-Query).
///
/// Ereignisse werden nicht überholt: Kommt während eines laufenden Ladens eine
/// weitere Änderung, wird danach genau einmal nachgeladen.
Stream<T> watchStreamAsync<T>(Stream<void> changes, Future<T> Function() load) {
  late StreamController<T> ctrl;
  StreamSubscription<void>? sub;
  var loading = false;
  var dirty = false;

  Future<void> reload() async {
    if (loading) {
      dirty = true;
      return;
    }
    loading = true;
    try {
      do {
        dirty = false;
        final value = await load();
        if (!ctrl.isClosed) ctrl.add(value);
      } while (dirty);
    } catch (e, st) {
      if (!ctrl.isClosed) ctrl.addError(e, st);
    } finally {
      loading = false;
    }
  }

  ctrl = StreamController<T>(
    onListen: () {
      reload();
      sub = changes.listen((_) => reload());
    },
    onCancel: () async {
      await sub?.cancel();
      await ctrl.close();
    },
  );
  return ctrl.stream;
}
