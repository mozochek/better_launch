import 'package:better_launch/initializable_feature_label.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Важность инициализируемой фичи.
enum InitializableFeatureImportance { required, optional }

@immutable
abstract class InitializableFeature<T> with EquatableMixin {
  final InitializableFeatureLabel label;
  final InitializableFeatureImportance importance;

  const InitializableFeature({
    required this.label,
    required this.importance,
  });

  Future<T> initialize();

  @override
  @mustCallSuper
  List<Object?> get props => [label, importance];

  @override
  String toString() {
    return 'InitializableFeature{label: $label, importance: $importance}';
  }
}
