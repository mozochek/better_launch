import 'dart:async';

import 'package:better_launch/async_data.dart';
import 'package:better_launch/feature_completion_handler.dart';
import 'package:better_launch/initializable_feature.dart';
import 'package:better_launch/initializable_feature_label.dart';
import 'package:better_launch/initializable_feature_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppInitializationBloc
    extends Bloc<AppInitializationEvent, AppInitializationState> {
  AppInitializationBloc()
      : super(const AppInitializationState.notInitialized()) {
    on<$AppInitializationEvent$PerformInitialization>(_onPreformInitialization);
  }

  Future<void> _onPreformInitialization(
    $AppInitializationEvent$PerformInitialization event,
    Emitter<AppInitializationState> emit,
  ) async {
    final stopwatch = Stopwatch()..start();

    final featuresRelations =
        <InitializableFeatureLabel, Set<InitializableFeatureLabel>>{};
    // Мапа всех фич, которые должны быть проинициализированы
    final featuresToInitialize =
        <InitializableFeatureLabel, InitializableFeature>{
      for (final feature in event.featuresToInitialize) feature.label: feature,
    };

    for (final entry in featuresToInitialize.entries) {
      final label = entry.key;
      final featureDependencies = event.featuresRelations[label];

      if (featureDependencies != null && featureDependencies.isNotEmpty) {
        for (final dependencyLabel in featureDependencies) {
          if (featuresToInitialize[dependencyLabel] != null) {
            (featuresRelations[label] ??= {}).add(dependencyLabel);
          }
        }
      }
    }

    final featuresCount = featuresToInitialize.length;
    var performingFeaturesWrappers = <InitializableFeatureWrapper>{};
    var initializedFeaturesWrappers = <InitializableFeatureWrapper>{};
    var failedFeaturesWrappers = <InitializableFeatureWrapper>{};
    var completedFeaturesCount = 0;
    var initializedFeaturesCount = 0;
    var failedFeaturesCount = 0;

    void emitProgress() {
      emit(AppInitializationState.inProgress(
        completionRatio: completedFeaturesCount / featuresCount,
        successRatio: initializedFeaturesCount / featuresCount,
        failedRatio: failedFeaturesCount / featuresCount,
        performingFeaturesWrappers: Set.from(performingFeaturesWrappers),
        initializedFeaturesWrappers: Set.from(initializedFeaturesWrappers),
        failedFeaturesWrappers: Set.from(failedFeaturesWrappers),
      ));
    }

    final featuresWithoutDependencies = <InitializableFeature>{};
    // Ключ - лэйбл зависимости, значение - набор лейблов зависимых фич
    final topDownDependencies =
        <InitializableFeatureLabel, Set<InitializableFeatureLabel>>{};
    // Ключ - лейбл зависимой фичи, значение - набор лейблов зависимостей
    final downUpDependencies =
        <InitializableFeatureLabel, Set<InitializableFeatureLabel>>{};
    for (final feature in featuresToInitialize.values) {
      final featureDependencies = featuresRelations[feature.label];

      if (featureDependencies != null && featureDependencies.isNotEmpty) {
        final existsDependencies = featuresRelations[feature.label];

        if (existsDependencies != null && existsDependencies.isNotEmpty) {
          downUpDependencies[feature.label] = {
            ...existsDependencies,
          };
          for (final dependencyLabel in existsDependencies) {
            (topDownDependencies[dependencyLabel] ??= {}).add(feature.label);
          }
          continue;
        }
      }

      featuresWithoutDependencies.add(feature);
    }

    try {
      void onFeatureFailed(InitializableFeatureWrapper failedFeatureWrapper) {
        final failedFeature = failedFeatureWrapper.feature;
        print('FAILED FEATURE "${failedFeature.label.value}"');

        failedFeaturesCount += 1;
        failedFeaturesWrappers.add(failedFeatureWrapper);

        final dependents = topDownDependencies[failedFeature.label];
        if (dependents == null || dependents.isEmpty) return;

        for (final dependentLabel in dependents) {
          final dependencies = downUpDependencies[dependentLabel];
          if (dependencies == null || dependencies.isEmpty) continue;

          dependencies.remove(failedFeature.label);
          topDownDependencies.remove(dependentLabel);
          if (dependencies.isNotEmpty) continue;

          downUpDependencies.remove(dependentLabel);
        }
      }

      await FeatureCompletionHandler().handleFeatures(
        features: featuresWithoutDependencies,
        onFeatureUpdated: (featureWrapper) {
          performingFeaturesWrappers.add(featureWrapper);
          emitProgress();
        },
        onFeatureCompleted: (completedFeatureWrapper) {
          final completedFeature = completedFeatureWrapper.feature;
          performingFeaturesWrappers.removeWhere(
              (w) => w.feature.label.value == completedFeature.label.value);
          completedFeaturesCount += 1;
          completedFeatureWrapper.result.maybeMap(
            orElse: () {
              onFeatureFailed(completedFeatureWrapper);
            },
            completed: (_) {
              print('FEATURE COMPLETED "${completedFeature.label.value}"');
              initializedFeaturesCount += 1;
              initializedFeaturesWrappers.add(completedFeatureWrapper);
            },
          );
          emitProgress();

          final readyToInitializeFeatures = <InitializableFeature<dynamic>>{};

          // Все фичи, которые зависят от completedFeature
          final dependents = topDownDependencies[completedFeature.label];
          if (dependents == null || dependents.isEmpty) return null;

          // Ищем у каждой зависимости список фич, которые должны быть выполнены
          for (final dependentLabel in dependents) {
            final dependencies = downUpDependencies[dependentLabel];
            if (dependencies == null || dependencies.isEmpty) continue;

            // Удаляем выполненную фичу из зависимостей,
            // т.к она была выполнена и больше не блокирует выполнение следующих фичей
            dependencies.remove(completedFeature.label);
            if (dependencies.isNotEmpty) continue;

            downUpDependencies.remove(dependentLabel);
            readyToInitializeFeatures
                .add(featuresToInitialize[dependentLabel]!); // TODO !
          }

          return readyToInitializeFeatures;
        },
        onFeatureFailed: (feature, error, stackTrace) {
          onFeatureFailed(feature);
        },
      );

      final completedWrappers = {
        ...initializedFeaturesWrappers,
        ...failedFeaturesWrappers,
      };
      for (final entry in featuresToInitialize.entries) {
        final label = entry.key;
        final feature = entry.value;

        if (completedWrappers
            .where((w) => w.feature.label.value == label.value)
            .isEmpty) {
          final dependencies = featuresRelations[feature.label];

          failedFeaturesWrappers.add(InitializableFeatureWrapper(
            feature: entry.value,
            result: AsyncData.failed(
              error: DependencyNotInitializedException(
                notInitializedLabel: label,
                allDependenciesLabels: dependencies,
                failedDependenciesLabels: dependencies != null &&
                        dependencies.isNotEmpty
                    ? {
                        ...failedFeaturesWrappers
                            .where(
                                (w) => dependencies.contains(w.feature.label))
                            .map((w) => w.feature.label)
                      }
                    : null,
              ),
              stackTrace: StackTrace.current,
            ),
          ));
        }
      }

      emit(AppInitializationState.completed(
        isFullInitialization: event.isFullInitialization,
        initializedFeaturesWrappers: initializedFeaturesWrappers,
        failedFeaturesWrappers: failedFeaturesWrappers,
      ));
    } on Object catch (e, s) {
      emit(AppInitializationState.failed(error: e, stackTrace: s));

      if (e is Exception) {
        addError(e, s);

        return;
      }

      rethrow;
    } finally {
      stopwatch.stop();
      print('INITIALIZATION COMPLETED FOR ${stopwatch.elapsedMilliseconds} ms');
    }
  }
}

class DependencyNotInitializedException implements Exception {
  final InitializableFeatureLabel notInitializedLabel;
  final Set<InitializableFeatureLabel>? allDependenciesLabels;
  final Set<InitializableFeatureLabel>? failedDependenciesLabels;

  DependencyNotInitializedException({
    required this.notInitializedLabel,
    required this.allDependenciesLabels,
    required this.failedDependenciesLabels,
  });
}

class AppInitializationException implements Exception {
  final Set<InitializableFeatureWrapper> failedFeaturesWrappers;

  AppInitializationException(this.failedFeaturesWrappers);

  @override
  String toString() {
    return 'AppInitializationException{failedFeaturesWrappers: ${failedFeaturesWrappers.map((w) => '"${w.feature.label.value}": ${w.result}').join(', ')}}';
  }
}

@immutable
sealed class AppInitializationEvent {
  const AppInitializationEvent();

  const factory AppInitializationEvent.performInitialization({
    required bool isFullInitialization,
    required Map<InitializableFeatureLabel, InitializableFeature> allFeatures,
    required Map<InitializableFeatureLabel, Set<InitializableFeatureLabel>>
        featuresRelations,
    required Set<InitializableFeature> featuresToInitialize,
  }) = $AppInitializationEvent$PerformInitialization;

  T map<T>({
    required T Function(
      $AppInitializationEvent$PerformInitialization event,
    ) perform,
  }) {
    final instance = this;

    return switch (instance) {
      $AppInitializationEvent$PerformInitialization() => perform(instance),
    };
  }
}

@immutable
@visibleForTesting
final class $AppInitializationEvent$PerformInitialization
    extends AppInitializationEvent {
  @visibleForTesting
  const $AppInitializationEvent$PerformInitialization({
    required this.isFullInitialization,
    required this.allFeatures,
    required this.featuresRelations,
    required this.featuresToInitialize,
  });

  final bool isFullInitialization;
  final Map<InitializableFeatureLabel, InitializableFeature> allFeatures;
  final Map<InitializableFeatureLabel, Set<InitializableFeatureLabel>>
      featuresRelations;
  final Set<InitializableFeature> featuresToInitialize;
}

@immutable
sealed class AppInitializationState {
  const AppInitializationState();

  const factory AppInitializationState.notInitialized() =
      $AppInitializationState$NotInitialized;

  const factory AppInitializationState.inProgress({
    required double completionRatio,
    required double successRatio,
    required double failedRatio,
    required Set<InitializableFeatureWrapper> performingFeaturesWrappers,
    required Set<InitializableFeatureWrapper> initializedFeaturesWrappers,
    required Set<InitializableFeatureWrapper> failedFeaturesWrappers,
  }) = $AppInitializationState$InProgress;

  const factory AppInitializationState.completed({
    required bool isFullInitialization,
    required Set<InitializableFeatureWrapper> initializedFeaturesWrappers,
    required Set<InitializableFeatureWrapper> failedFeaturesWrappers,
  }) = $AppInitializationState$Completed;

  const factory AppInitializationState.failed({
    required Object error,
    required StackTrace stackTrace,
  }) = $AppInitializationState$Failed;

  T map<T>({
    required T Function($AppInitializationState$NotInitialized) notInitialized,
    required T Function($AppInitializationState$InProgress) inProgress,
    required T Function($AppInitializationState$Completed) completed,
    required T Function($AppInitializationState$Failed) failed,
  }) {
    final instance = this;

    return switch (instance) {
      $AppInitializationState$NotInitialized() => notInitialized(instance),
      $AppInitializationState$InProgress() => inProgress(instance),
      $AppInitializationState$Completed() => completed(instance),
      $AppInitializationState$Failed() => failed(instance),
    };
  }

  T? mapOrNull<T>({
    T Function($AppInitializationState$NotInitialized)? notInitialized,
    T Function($AppInitializationState$InProgress)? inProgress,
    T Function($AppInitializationState$Completed)? completed,
    T Function($AppInitializationState$Failed)? failed,
  }) {
    final instance = this;

    return switch (instance) {
      $AppInitializationState$NotInitialized() =>
        notInitialized?.call(instance),
      $AppInitializationState$InProgress() => inProgress?.call(instance),
      $AppInitializationState$Completed() => completed?.call(instance),
      $AppInitializationState$Failed() => failed?.call(instance),
    };
  }

  T maybeMap<T>({
    required T Function() orElse,
    T Function($AppInitializationState$NotInitialized)? notInitialized,
    T Function($AppInitializationState$InProgress)? inProgress,
    T Function($AppInitializationState$Completed)? completed,
    T Function($AppInitializationState$Failed)? failed,
  }) {
    final instance = this;

    switch (instance) {
      case $AppInitializationState$NotInitialized():
        if (notInitialized != null) {
          return notInitialized(instance);
        }
      case $AppInitializationState$InProgress():
        if (inProgress != null) {
          return inProgress(instance);
        }
      case $AppInitializationState$Completed():
        if (completed != null) {
          return completed(instance);
        }
      case $AppInitializationState$Failed():
        if (failed != null) {
          return failed(instance);
        }
    }

    return orElse();
  }
}

@immutable
@visibleForTesting
final class $AppInitializationState$NotInitialized
    extends AppInitializationState {
  @visibleForTesting
  const $AppInitializationState$NotInitialized();
}

@immutable
@visibleForTesting
final class $AppInitializationState$InProgress extends AppInitializationState {
  @visibleForTesting
  const $AppInitializationState$InProgress({
    required this.completionRatio,
    required this.successRatio,
    required this.failedRatio,
    required this.performingFeaturesWrappers,
    required this.initializedFeaturesWrappers,
    required this.failedFeaturesWrappers,
  });

  final double completionRatio;
  final double successRatio;
  final double failedRatio;
  final Set<InitializableFeatureWrapper> performingFeaturesWrappers;
  final Set<InitializableFeatureWrapper> initializedFeaturesWrappers;
  final Set<InitializableFeatureWrapper> failedFeaturesWrappers;
}

@immutable
@visibleForTesting
final class $AppInitializationState$Completed extends AppInitializationState {
  @visibleForTesting
  const $AppInitializationState$Completed({
    required this.isFullInitialization,
    required this.initializedFeaturesWrappers,
    required this.failedFeaturesWrappers,
  });

  final bool isFullInitialization;
  final Set<InitializableFeatureWrapper> initializedFeaturesWrappers;
  final Set<InitializableFeatureWrapper> failedFeaturesWrappers;
}

@immutable
@visibleForTesting
final class $AppInitializationState$Failed extends AppInitializationState {
  @visibleForTesting
  const $AppInitializationState$Failed({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}
