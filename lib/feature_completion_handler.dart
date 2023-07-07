import 'dart:async';

import 'package:better_launch/initializable_feature_label.dart';
import 'package:better_launch/async_data.dart';
import 'package:better_launch/initializable_feature.dart';
import 'package:better_launch/initializable_feature_wrapper.dart';

class FeatureCompletionHandler {
  Future<void> handleFeatures({
    required Iterable<InitializableFeature> features,
    FutureOr<Iterable<InitializableFeature>?> Function(
      InitializableFeatureWrapper<InitializableFeature> wrapper,
    )? onFeatureCompleted,
    FutureOr<void> Function(
      InitializableFeatureWrapper<InitializableFeature> wrapper,
    )? onFeatureUpdated,
    FutureOr<void> Function(
      InitializableFeatureWrapper<InitializableFeature> wrapper,
      Object error,
      StackTrace stackTrace,
    )? onFeatureFailed,
  }) async {
    final results = <InitializableFeatureLabel, AsyncData>{};

    await Future.wait(features.map((f) async {
      try {
        AsyncData result;
        try {
          result = const AsyncData.inProgress();
          onFeatureUpdated?.call(InitializableFeatureWrapper(
            feature: f,
            result: result,
          ));
          final initializationResult = await f.initialize();
          results[f.label] = result;
          result = AsyncData.completed(value: initializationResult);
        } on Object catch (e, s) {
          result = AsyncData.failed(error: e, stackTrace: s);
        }

        final nextFeatures =
            await onFeatureCompleted?.call(InitializableFeatureWrapper(
          feature: f,
          result: result,
        ));
        if (nextFeatures == null || nextFeatures.isEmpty) return;

        return handleFeatures(
          features: nextFeatures,
          onFeatureUpdated: onFeatureUpdated,
          onFeatureCompleted: onFeatureCompleted,
          onFeatureFailed: onFeatureFailed,
        );
      } on Object catch (e, s) {
        onFeatureFailed?.call(
          InitializableFeatureWrapper(
            feature: f,
            result: AsyncData.failed(error: e, stackTrace: s),
          ),
          e,
          s,
        );
      }
    }));
  }
}
