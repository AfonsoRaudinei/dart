import 'package:soloforte_app/core/contracts/i_producer_invite_writer.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_repository.dart';

class ProducerInviteWriterAdapter implements IProducerInviteWriter {
  const ProducerInviteWriterAdapter(this._repository);

  final ProducerLinkRepository _repository;

  @override
  Future<ProducerInviteData> createInvite(String clientId) async {
    final invite = await _repository.createInvite(clientId);
    return ProducerInviteData(token: invite.token, expiresAt: invite.expiresAt);
  }
}
