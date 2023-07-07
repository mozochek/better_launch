import 'package:flutter/foundation.dart';

sealed class CoreInitializationResult {
  const CoreInitializationResult();

  const factory CoreInitializationResult.successful() =
      $CoreInitializationResult$Successful;

  const factory CoreInitializationResult.unsuccessful() =
      $CoreInitializationResult$Unsuccessful;

  T map<T>({
    required T Function($CoreInitializationResult$Successful) successful,
    required T Function($CoreInitializationResult$Unsuccessful) unsuccessful,
  }) {
    final instance = this;

    return switch (instance) {
      $CoreInitializationResult$Successful() => successful(instance),
      $CoreInitializationResult$Unsuccessful() => unsuccessful(instance),
    };
  }

  T? mapOrNull<T>({
    T Function($CoreInitializationResult$Successful)? successful,
    T Function($CoreInitializationResult$Unsuccessful)? unsuccessful,
  }) {
    final instance = this;

    return switch (instance) {
      $CoreInitializationResult$Successful() => successful?.call(instance),
      $CoreInitializationResult$Unsuccessful() => unsuccessful?.call(instance),
    };
  }

  T maybeMap<T>({
    required T Function() orElse,
    T Function($CoreInitializationResult$Successful)? successful,
    T Function($CoreInitializationResult$Unsuccessful)? unsuccessful,
  }) {
    final instance = this;

    switch (instance) {
      case $CoreInitializationResult$Successful():
        if (successful != null) {
          return successful(instance);
        }
      case $CoreInitializationResult$Unsuccessful():
        if (unsuccessful != null) {
          return unsuccessful(instance);
        }
    }

    return orElse();
  }
}

@immutable
@visibleForTesting
final class $CoreInitializationResult$Successful
    extends CoreInitializationResult {
  @visibleForTesting
  const $CoreInitializationResult$Successful();
}

@immutable
@visibleForTesting
final class $CoreInitializationResult$Unsuccessful
    extends CoreInitializationResult {
  @visibleForTesting
  const $CoreInitializationResult$Unsuccessful();
}
