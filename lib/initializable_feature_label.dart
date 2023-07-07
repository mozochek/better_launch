import 'package:better_launch/app_initializable_features.dart';
import 'package:better_launch/initializable_feature.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class InitializableFeatureLabel with EquatableMixin {
  const InitializableFeatureLabel(this.value);

  final String value;

  const factory InitializableFeatureLabel.firebase() =
      $InitializableFeatureLabel$Firebase;

  const factory InitializableFeatureLabel.firebaseDynamicLinks() =
      $InitializableFeatureLabel$FirebaseDynamicLinks;

  const factory InitializableFeatureLabel.sentry() =
      $InitializableFeatureLabel$Sentry;

  const factory InitializableFeatureLabel.dummy0() =
      $InitializableFeatureLabel$Dummy0;

  const factory InitializableFeatureLabel.dummy1() =
      $InitializableFeatureLabel$Dummy1;

  const factory InitializableFeatureLabel.dummy2() =
      $InitializableFeatureLabel$Dummy2;

  const factory InitializableFeatureLabel.dummy3() =
      $InitializableFeatureLabel$Dummy3;

  @override
  @mustCallSuper
  List<Object?> get props => [value];

  @override
  String toString() {
    return '"$value"';
  }

  InitializableFeature toFeature() {
    return switch (this) {
      $InitializableFeatureLabel$Firebase() =>
        const FirebaseInitializableFeature(),
      $InitializableFeatureLabel$FirebaseDynamicLinks() =>
        const FirebaseDynamicLinksInitializableFeature(),
      $InitializableFeatureLabel$Sentry() => const SentryInitializableFeature(),
      $InitializableFeatureLabel$Dummy0() => const DummyFeature0(),
      $InitializableFeatureLabel$Dummy1() => const DummyFeature1(),
      $InitializableFeatureLabel$Dummy2() => const DummyFeature2(),
      $InitializableFeatureLabel$Dummy3() => const DummyFeature3(),
    } as InitializableFeature;
  }

  static const values = <InitializableFeatureLabel>[
    InitializableFeatureLabel.firebase(),
    InitializableFeatureLabel.firebaseDynamicLinks(),
    InitializableFeatureLabel.sentry(),
    InitializableFeatureLabel.dummy0(),
    InitializableFeatureLabel.dummy1(),
    InitializableFeatureLabel.dummy2(),
    InitializableFeatureLabel.dummy3(),
  ];
}

@immutable
@visibleForTesting
class $InitializableFeatureLabel$Firebase extends InitializableFeatureLabel {
  const $InitializableFeatureLabel$Firebase() : super('firebase');
}

@immutable
@visibleForTesting
class $InitializableFeatureLabel$FirebaseDynamicLinks
    extends InitializableFeatureLabel {
  const $InitializableFeatureLabel$FirebaseDynamicLinks()
      : super('firebase_dynamic_links');
}

@immutable
@visibleForTesting
class $InitializableFeatureLabel$Sentry extends InitializableFeatureLabel {
  const $InitializableFeatureLabel$Sentry() : super('sentry');
}

@immutable
@visibleForTesting
class $InitializableFeatureLabel$Dummy0 extends InitializableFeatureLabel {
  const $InitializableFeatureLabel$Dummy0() : super('dummy0');
}

@immutable
@visibleForTesting
class $InitializableFeatureLabel$Dummy1 extends InitializableFeatureLabel {
  const $InitializableFeatureLabel$Dummy1() : super('dummy1');
}

@immutable
@visibleForTesting
class $InitializableFeatureLabel$Dummy2 extends InitializableFeatureLabel {
  const $InitializableFeatureLabel$Dummy2() : super('dummy2');
}

@immutable
@visibleForTesting
class $InitializableFeatureLabel$Dummy3 extends InitializableFeatureLabel {
  const $InitializableFeatureLabel$Dummy3() : super('dummy3');
}
