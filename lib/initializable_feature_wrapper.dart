import 'package:better_launch/async_data.dart';
import 'package:better_launch/initializable_feature.dart';
import 'package:equatable/equatable.dart';

final class InitializableFeatureWrapper<F extends InitializableFeature>
    with EquatableMixin {
  final F feature;
  final AsyncData result;

  const InitializableFeatureWrapper({
    required this.feature,
    required this.result,
  });

  InitializableFeatureWrapper<F> copyWith({
    AsyncData? result,
  }) {
    return InitializableFeatureWrapper(
      feature: feature,
      result: result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [feature, result];
}
