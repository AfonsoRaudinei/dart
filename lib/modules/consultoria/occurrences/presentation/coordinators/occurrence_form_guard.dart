/// Ponte leve entre [OccurrenceCreationSheet] e hosts (ex.: MapBottomSheet).
///
/// O sheet registra [readIsDirty] no mount; o host consulta antes de fechar.
class OccurrenceFormGuard {
  bool Function()? readIsDirty;

  bool get isDirty => readIsDirty?.call() ?? false;

  void reset() {
    readIsDirty = null;
  }
}
