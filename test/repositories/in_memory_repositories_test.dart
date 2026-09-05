import 'package:booknote/repositories/repositories.dart';

import 'repository_contract.dart';

void main() {
  runRepositoryContract('InMemory', () async {
    final store = InMemoryStore();
    return RepositoryPair(
      InMemoryBookRepository(store),
      InMemoryNoteRepository(store),
      dispose: store.dispose,
    );
  });
}
