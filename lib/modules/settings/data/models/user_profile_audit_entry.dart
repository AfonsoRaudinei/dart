// ADR-032 — settings/data/models/user_profile_audit_entry.dart
//
// Modelo de auditoria de alterações no perfil.
// Tabela SQLite: user_profile_edits (append-only — nunca deletar registros).
//
// Cada campo editado = 1 entrada nesta tabela.
// Múltiplos campos na mesma operação = múltiplas entradas com mesmo changedAt.

import 'package:uuid/uuid.dart';

class UserProfileAuditEntry {
  final String id; // UUID v4 gerado localmente
  final String userId; // FK: user_profile_cache.id
  final String fieldChanged; // 'fullName' | 'phone' | 'photoUrl' | 'creaNumber'
  final String? oldValue; // null se campo estava vazio antes
  final String newValue; // valor após a alteração
  final DateTime changedAt; // UTC no banco; local na UI

  const UserProfileAuditEntry({
    required this.id,
    required this.userId,
    required this.fieldChanged,
    this.oldValue,
    required this.newValue,
    required this.changedAt,
  });

  factory UserProfileAuditEntry.create({
    required String userId,
    required String fieldChanged,
    String? oldValue,
    required String newValue,
  }) =>
      UserProfileAuditEntry(
        id: const Uuid().v4(),
        userId: userId,
        fieldChanged: fieldChanged,
        oldValue: oldValue,
        newValue: newValue,
        changedAt: DateTime.now().toUtc(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'field_changed': fieldChanged,
        'old_value': oldValue,
        'new_value': newValue,
        'changed_at': changedAt.toUtc().toIso8601String(),
      };

  factory UserProfileAuditEntry.fromMap(Map<String, dynamic> map) =>
      UserProfileAuditEntry(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        fieldChanged: map['field_changed'] as String,
        oldValue: map['old_value'] as String?,
        newValue: map['new_value'] as String,
        changedAt: DateTime.parse(map['changed_at'] as String).toLocal(),
      );
}
