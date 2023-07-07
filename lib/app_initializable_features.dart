import 'package:better_launch/initializable_feature.dart';
import 'package:better_launch/initializable_feature_label.dart';

final class FirebaseInitializableFeature extends InitializableFeature<String> {
  const FirebaseInitializableFeature()
      : super(
          label: const InitializableFeatureLabel.firebase(),
          importance: InitializableFeatureImportance.required,
        );

  @override
  Future<String> initialize() {
    print('INITIALIZE $label');
    return Future.delayed(const Duration(seconds: 4), () => 'initialized');
  }
}

final class FirebaseDynamicLinksInitializableFeature
    extends InitializableFeature<String> {
  const FirebaseDynamicLinksInitializableFeature()
      : super(
          label: const InitializableFeatureLabel.firebaseDynamicLinks(),
          importance: InitializableFeatureImportance.required,
        );

  @override
  Future<String> initialize() {
    print('INITIALIZE $label');
    return Future.delayed(const Duration(seconds: 2), () => 'initialized');
  }
}

final class SentryInitializableFeature extends InitializableFeature<String> {
  const SentryInitializableFeature()
      : super(
          label: const InitializableFeatureLabel.sentry(),
          importance: InitializableFeatureImportance.required,
        );

  @override
  Future<String> initialize() async {
    print('INITIALIZE $label');
    return Future.delayed(const Duration(seconds: 2), () => 'initialized');
  }
}

final class DummyFeature0 extends InitializableFeature<int> {
  const DummyFeature0()
      : super(
          label: const InitializableFeatureLabel.dummy0(),
          importance: InitializableFeatureImportance.optional,
        );

  @override
  Future<int> initialize() {
    print('INITIALIZE $label');
    return Future.delayed(const Duration(seconds: 1), () => 100);
  }
}

final class DummyFeature1 extends InitializableFeature<int> {
  const DummyFeature1()
      : super(
          label: const InitializableFeatureLabel.dummy1(),
          importance: InitializableFeatureImportance.optional,
        );

  @override
  Future<int> initialize() {
    print('INITIALIZE $label');
    return Future.delayed(const Duration(seconds: 2), () => 101);
  }
}

final class DummyFeature2 extends InitializableFeature<int> {
  const DummyFeature2()
      : super(
          label: const InitializableFeatureLabel.dummy2(),
          importance: InitializableFeatureImportance.optional,
        );

  @override
  Future<int> initialize() {
    print('INITIALIZE $label');
    return Future.delayed(const Duration(seconds: 2), () => 102);
  }
}

final class DummyFeature3 extends InitializableFeature<int> {
  const DummyFeature3()
      : super(
          label: const InitializableFeatureLabel.dummy3(),
          importance: InitializableFeatureImportance.optional,
        );

  @override
  Future<int> initialize() {
    print('INITIALIZE $label');
    return Future.delayed(const Duration(seconds: 2), () => 102);
  }
}
