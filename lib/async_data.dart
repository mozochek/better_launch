import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

@immutable
sealed class AsyncData<T> {
  const AsyncData();

  const factory AsyncData.notInitialized({
    T? value,
  }) = $AsyncData$NotInitialized;

  const factory AsyncData.inProgress({
    T? value,
  }) = $AsyncData$InProgress;

  const factory AsyncData.completed({
    required T value,
  }) = $AsyncData$Completed;

  const factory AsyncData.failed({
    required Object error,
    required StackTrace stackTrace,
    T? value,
  }) = $AsyncData$Failed;

  T? get value;

  R map<R>({
    required R Function($AsyncData$NotInitialized) notInitialized,
    required R Function($AsyncData$InProgress) inProgress,
    required R Function($AsyncData$Completed) completed,
    required R Function($AsyncData$Failed) failed,
  }) {
    final instance = this;

    return switch (instance) {
      $AsyncData$NotInitialized() => notInitialized(instance),
      $AsyncData$InProgress() => inProgress(instance),
      $AsyncData$Completed() => completed(instance),
      $AsyncData$Failed() => failed(instance),
    };
  }

  R? mapOrNull<R>({
    R Function($AsyncData$NotInitialized)? notInitialized,
    R Function($AsyncData$InProgress)? inProgress,
    R Function($AsyncData$Completed)? completed,
    R Function($AsyncData$Failed)? failed,
  }) {
    final instance = this;

    return switch (instance) {
      $AsyncData$NotInitialized() => notInitialized?.call(instance),
      $AsyncData$InProgress() => inProgress?.call(instance),
      $AsyncData$Completed() => completed?.call(instance),
      $AsyncData$Failed() => failed?.call(instance),
    };
  }

  R maybeMap<R>({
    required R Function() orElse,
    R Function($AsyncData$NotInitialized)? notInitialized,
    R Function($AsyncData$InProgress)? inProgress,
    R Function($AsyncData$Completed)? completed,
    R Function($AsyncData$Failed)? failed,
  }) {
    final instance = this;

    switch (instance) {
      case $AsyncData$NotInitialized():
        if (notInitialized != null) {
          return notInitialized(instance);
        }
      case $AsyncData$InProgress():
        if (inProgress != null) {
          return inProgress(instance);
        }
      case $AsyncData$Completed():
        if (completed != null) {
          return completed(instance);
        }
      case $AsyncData$Failed():
        if (failed != null) {
          return failed(instance);
        }
    }

    return orElse();
  }

  AsyncData<T> snapshot() {
    return map(
      notInitialized: (instance) => AsyncData.notInitialized(
        value: instance.value,
      ),
      inProgress: (instance) => AsyncData.inProgress(value: instance.value),
      completed: (instance) => AsyncData.completed(value: instance.value),
      failed: (instance) => AsyncData.failed(
        error: instance.error,
        stackTrace: instance.stackTrace,
      ),
    );
  }
}

@immutable
@visibleForTesting
final class $AsyncData$NotInitialized<T> extends AsyncData<T> {
  @visibleForTesting
  const $AsyncData$NotInitialized({
    this.value,
  });

  @override
  final T? value;

  @override
  String toString() {
    return '${$AsyncData$NotInitialized}{value: $value}';
  }
}

@immutable
@visibleForTesting
final class $AsyncData$InProgress<T> extends AsyncData<T> {
  @visibleForTesting
  const $AsyncData$InProgress({
    this.value,
  });

  @override
  final T? value;

  @override
  String toString() {
    return '${$AsyncData$InProgress}{value: $value}';
  }
}

@immutable
@visibleForTesting
final class $AsyncData$Completed<T> extends AsyncData<T> {
  @visibleForTesting
  const $AsyncData$Completed({
    required this.value,
  });

  @override
  final T value;

  @override
  String toString() {
    return '${$AsyncData$Completed}{value: $value}';
  }
}

@immutable
@visibleForTesting
final class $AsyncData$Failed<T> extends AsyncData<T> {
  @visibleForTesting
  const $AsyncData$Failed({
    required this.error,
    required this.stackTrace,
    this.value,
  });

  final Object error;
  final StackTrace stackTrace;
  @override
  final T? value;

  @override
  String toString() {
    return '${$AsyncData$Failed}{value: $value, error: $error';
  }
}
