import 'package:soloforte_app/core/contracts/i_occurrence_access_reader.dart';

import '../data/producer_link_repository.dart';

class OccurrenceAccessReaderAdapter implements IOccurrenceAccessReader {
  const OccurrenceAccessReaderAdapter(this._repository);

  final ProducerLinkRepository _repository;

  @override
  Future<Set<String>> loadActiveClientIds() async {
    final ids = await _repository.loadAuthorizedClientIds();
    return ids.toSet();
  }

  @override
  Future<Map<String, String>> loadLinkedClientNames() {
    return _repository.loadLinkedClientNames();
  }
}
