import 'dart:async';
import '../entities/relatorio.dart';

abstract class IReportRepository {
  Future<List<Relatorio>> getAll();
  Future<Relatorio?> getById(String id);
  Future<void> save(Relatorio relatorio);
  Future<void> softDelete(String id);
  Stream<List<Relatorio>> watchAll();
}
