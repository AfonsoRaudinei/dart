import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:soloforte_app/core/contracts/i_report_share_link_publisher.dart';
import 'package:soloforte_app/core/contracts/i_report_share_link_publisher_provider.dart';

part 'report_share_link_provider.g.dart';

@Riverpod(keepAlive: true)
IReportShareLinkPublisher reportShareLinkService(ReportShareLinkServiceRef ref) {
  return ref.watch(reportShareLinkPublisherProvider);
}
