/// Bloqueia exclusão de fazenda enquanto houver talhão vinculado (campo ou mapa).
void ensureFarmDeletable({required int linkedFieldCount}) {
  if (linkedFieldCount > 0) {
    throw StateError('Remova os talhões antes de excluir a fazenda.');
  }
}
