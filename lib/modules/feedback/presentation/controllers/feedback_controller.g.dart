// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedbackRepositoryHash() =>
    r'95ad089678c0ac856015236cf51be63a7723626b';

/// See also [feedbackRepository].
@ProviderFor(feedbackRepository)
final feedbackRepositoryProvider =
    AutoDisposeProvider<IFeedbackRepository>.internal(
      feedbackRepository,
      name: r'feedbackRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedbackRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedbackRepositoryRef = AutoDisposeProviderRef<IFeedbackRepository>;
String _$feedbackStatsHash() => r'acf39488e4acb6877b8f04718c53d08d9e808069';

/// See also [feedbackStats].
@ProviderFor(feedbackStats)
final feedbackStatsProvider = AutoDisposeFutureProvider<FeedbackStats>.internal(
  feedbackStats,
  name: r'feedbackStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedbackStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FeedbackStatsRef = AutoDisposeFutureProviderRef<FeedbackStats>;
String _$feedbackControllerHash() =>
    r'a429ebd82a62ddb45a1abdde1b64c1daa67b20be';

/// See also [FeedbackController].
@ProviderFor(FeedbackController)
final feedbackControllerProvider =
    AutoDisposeNotifierProvider<FeedbackController, FeedbackFormState>.internal(
      FeedbackController.new,
      name: r'feedbackControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$feedbackControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FeedbackController = AutoDisposeNotifier<FeedbackFormState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
