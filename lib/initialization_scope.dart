import 'package:better_launch/app.dart';
import 'package:better_launch/app_initialization_bloc.dart';
import 'package:better_launch/async_data.dart';
import 'package:better_launch/initializable_feature.dart';
import 'package:better_launch/initializable_feature_label.dart';
import 'package:better_launch/initializable_feature_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class InitializationInheritedScope
    extends InheritedModel<InitializableFeatureLabel> {
  const InitializationInheritedScope({
    required this.appFeaturesWrappers,
    required super.child,
    super.key,
  });

  final Map<InitializableFeatureLabel, InitializableFeatureWrapper>
      appFeaturesWrappers;

  @override
  bool updateShouldNotify(InitializationInheritedScope oldWidget) {
    return oldWidget.appFeaturesWrappers != appFeaturesWrappers;
  }

  @override
  bool updateShouldNotifyDependent(
    InitializationInheritedScope oldWidget,
    Set<InitializableFeatureLabel> dependencies,
  ) {
    for (final label in InitializableFeatureLabel.values) {
      if (dependencies.contains(label)) {
        if (oldWidget.appFeaturesWrappers[label]?.result !=
            appFeaturesWrappers[label]?.result) {
          return true;
        }
      }
    }

    return false;
  }
}

class InitializationScope extends StatefulWidget {
  const InitializationScope({
    required this.allFeaturesLabels,
    required this.featuresRelations,
    required this.child,
    super.key,
  });

  final Set<InitializableFeatureLabel> allFeaturesLabels;
  final Map<InitializableFeatureLabel, Set<InitializableFeatureLabel>>
      featuresRelations;
  final Widget child;

  @override
  InitializationScopeState createState() => InitializationScopeState();

  static InitializationScopeState of(BuildContext context) {
    final state = context.findAncestorStateOfType<InitializationScopeState>();
    assert(
      state != null,
      '$InitializationScopeState was not found above "${context.widget}" widget',
    );

    return state!;
  }

  static InitializableFeatureWrapper featureStatusOf(
    BuildContext context,
    InitializableFeatureLabel label,
  ) {
    final scope = InheritedModel.inheritFrom<InitializationInheritedScope>(
      context,
      aspect: label,
    );
    assert(
      scope != null,
      '$InitializationInheritedScope was not found above "${context.widget}" widget',
    );

    return scope!.appFeaturesWrappers[label]!;
  }

  static void reinitializeFeature(
    BuildContext context,
    InitializableFeatureLabel label, {
    bool force = false,
  }) {
    return of(context).reinitializeFeature(label, force: force);
  }

  /// Единая ручка для вызова полной инициализации приложения.
  static void finishInitialization(
    BuildContext context, {
    bool includeOptional = true,
  }) {
    final appInitializationBloc = of(context)._appInitializationBloc;
    final appInitializationInProgress = appInitializationBloc.state.maybeMap(
      orElse: () => false,
      inProgress: (_) => true,
    );
    if (appInitializationInProgress) return;

    var requiredFeaturesNotInitialized = false;
    for (final entry in of(context)._initializableFeaturesWrappers.entries) {
      final isFeatureInitialized = entry.value.result.maybeMap(
        orElse: () => false,
        completed: (_) => true,
      );

      if (entry.value.feature.importance ==
          InitializableFeatureImportance.required) {
        requiredFeaturesNotInitialized &= !isFeatureInitialized;
      }
    }
    if (requiredFeaturesNotInitialized) return;

    // Инициализируем только неинициализированные фичи.
    final featuresToInitialize = <InitializableFeature>{};
    for (final entry in of(context)._initializableFeaturesWrappers.entries) {
      final feature = entry.value.feature;
      if (!includeOptional &&
          feature.importance != InitializableFeatureImportance.required) {
        continue;
      }

      final result = entry.value.result;
      final needToInitialize = result.maybeMap(
        orElse: () => false,
        notInitialized: (_) => true,
        failed: (_) => true,
      );
      if (!needToInitialize) continue;

      featuresToInitialize.add(feature);
    }
    appInitializationBloc.add(AppInitializationEvent.performInitialization(
      isFullInitialization: true,
      allFeatures: of(context)._allFeatures,
      featuresRelations: of(context)._featuresRelations,
      featuresToInitialize: featuresToInitialize,
    ));
  }
}

final class FeatureRelationsNode {
  final InitializableFeatureLabel label;
  final Set<InitializableFeatureLabel>? dependencies;

  const FeatureRelationsNode({
    required this.label,
    this.dependencies,
  });

  @override
  String toString() {
    return 'FeatureRelationsNode{label: $label, dependencies: $dependencies}';
  }
}

class InitializationScopeState extends State<InitializationScope> {
  late final Map<InitializableFeatureLabel, InitializableFeature> _allFeatures;
  late final Map<InitializableFeatureLabel, Set<InitializableFeatureLabel>>
      _featuresRelations;
  late final AppInitializationBloc _appInitializationBloc;
  late Map<InitializableFeatureLabel, InitializableFeature>
      _initializableFeatures;
  late Map<InitializableFeatureLabel, InitializableFeatureWrapper>
      _initializableFeaturesWrappers;

  List<Set<InitializableFeatureLabel>>? _getRelationsPathsFor(
    InitializableFeatureLabel label,
    Set<InitializableFeatureLabel> history,
  ) {
    final relations = _featuresRelations[label];
    if (relations == null || relations.isEmpty) return null;

    final paths = <Set<InitializableFeatureLabel>>[];

    for (final dependencyLabel in relations) {
      final dependencyPaths = _getRelationsPathsFor(
        dependencyLabel,
        {...history, label},
      );

      if (dependencyPaths == null) {
        paths.add({dependencyLabel});
      } else {
        for (final dependencyPath in dependencyPaths) {
          paths.add({...dependencyPath, dependencyLabel});
        }
      }
    }

    if (paths.where((element) => element.isEmpty).isNotEmpty) return null;

    return paths;
  }

  // Валидирует отсутствие следующих ситуаций:
  // 1. Фича зависит сама от себя
  // x -> x
  //
  // 2. Две фичи зависят друг от друга
  // x -> y
  // y -> x
  //
  // 3. Фича явно зависит от другой фичи, которая является косвенной зависимостью
  // x -> y -> z - фактические зависимости
  //
  //   -> z - косвенная зависимость(ошибка)
  // x    ^
  //   -> y - прямая зависимость(ок)
  //
  // 4. Обязательная фича зависит от необязательной(обе фичи должны быть обязательными)
  // 5. Зависит от фичи, которой нет
  // TODO 6. Указаны зависимости для фичи, которой нет
  void _createFeaturesRelationsGraph() {
    final relationsNodes = <InitializableFeatureLabel, FeatureRelationsNode>{};

    for (final label in widget.allFeaturesLabels) {
      final featureRelations = _featuresRelations[label];

      if (featureRelations == null) {
        relationsNodes[label] = FeatureRelationsNode(label: label);
        continue;
      }

      // Если у фичи указаны пустые зависимости
      if (featureRelations.isEmpty) {
        throw Exception('Feature $label have empty dependencies!');
      }

      // Если в зависимости фичи указана она же (ситуация 1)
      if (featureRelations.contains(label)) {
        throw Exception('Feature $label depending on itself!');
      }

      final optionalDependencies = <InitializableFeature>{};
      for (final dependencyLabel in featureRelations) {
        // Если фича зависит от фичи, которая не указана в allFeaturesLabels (ситуация 5)
        if (!widget.allFeaturesLabels.contains(dependencyLabel)) {
          throw Exception(
            'Feature $label depends on feature $dependencyLabel which is not exists!',
          );
        }

        final dependencyFeature = _allFeatures[dependencyLabel];
        if (dependencyFeature == null) {
          throw Exception(
            'Feature $dependencyLabel was not created. This is unreachable exception.',
          );
        }
        if (dependencyFeature.importance ==
            InitializableFeatureImportance.optional) {
          optionalDependencies.add(dependencyFeature);
        }
      }

      final feature = _allFeatures[label];
      if (feature == null) {
        throw Exception(
          'Feature $label was not created. This is unreachable exception.',
        );
      }
      // Если обязательная фича зависит от опциональных (ситуация 4)
      if (feature.importance == InitializableFeatureImportance.required &&
          optionalDependencies.isNotEmpty) {
        throw Exception(
          'Feature $label marked as required, but it depends on optional features [${optionalDependencies.map((f) => f.label).join(', ')}]!',
        );
      }

      relationsNodes[label] = FeatureRelationsNode(
        label: label,
        dependencies: Set.from(featureRelations),
      );
    }

    for (final label in widget.allFeaturesLabels) {
      final node = relationsNodes[label];
      if (node == null) throw Exception('Unreachable');

      final nodeDependencies = node.dependencies;
      if (nodeDependencies == null || nodeDependencies.isEmpty) continue;

      // Проверка парных зависимостей (ситуация 2)
      for (final dependencyLabel in nodeDependencies) {
        if (relationsNodes[dependencyLabel]?.dependencies?.contains(label) ??
            false) {
          throw Exception(
            'Feature $label and $dependencyLabel depending on each other!',
          );
        }
      }

      final dependenciesPaths = _getRelationsPathsFor(label, {});
      if (dependenciesPaths == null) continue;

      // Проверка дублирующих (ситуация 3)
      if (dependenciesPaths.length > 1) {
        final allDependencies = {
          for (final dependenciesPath in dependenciesPaths) ...dependenciesPath,
        };

        for (final dependencyLabel in allDependencies) {
          var usageCount = 0;
          final meetInPaths = <Set<InitializableFeatureLabel>>[];
          for (final dependenciesPath in dependenciesPaths) {
            if (dependenciesPath.contains(dependencyLabel)) {
              usageCount += 1;
              meetInPaths.add(dependenciesPath);
            }
          }

          if (usageCount > 1) {
            throw Exception(
              'Feature $dependencyLabel duplicated $usageCount times for same feature $label!\n${meetInPaths.map((p) {
                return '${p.map((l) => '$l').join(' <- ')} <- $label';
              }).join('\n')}',
            );
          }
        }
      }
    }
  }

  List<InitializableFeatureLabel>? _getFeatureDependencies(
    InitializableFeatureLabel label,
  ) {
    final dependencies = _featuresRelations[label];
    if (dependencies == null || dependencies.isEmpty) return null;

    final allDependenciesLabels = <InitializableFeatureLabel>[];
    for (final dependencyLabel in dependencies) {
      final dependency = _initializableFeaturesWrappers[label]?.feature;
      if (dependency != null) {
        allDependenciesLabels.add(dependencyLabel);
      }

      final dependencyDependencies = _featuresRelations[dependencyLabel];
      if (dependencyDependencies == null || dependencyDependencies.isEmpty) {
        continue;
      }

      allDependenciesLabels.addAll(dependencyDependencies);
    }

    return allDependenciesLabels;
  }

  void reinitializeFeature(
    InitializableFeatureLabel label, {
    bool force = false,
  }) {
    // Игнорируем переинициализацию, если фича не найдена
    final wrapper = _initializableFeaturesWrappers[label];
    if (wrapper == null) return;

    final currentResult = wrapper.result;
    final alreadyInitialized = currentResult.maybeMap(
      orElse: () => false,
      completed: (_) => true,
    );
    // Игнорируем переинициализацию, если указан force: false и фича уже проиницализирована
    if (force ? false : alreadyInitialized) {
      return;
    }

    // Ищем зависимости у фичи, которую хотят переинициализировать
    final featureDependenciesLabels = _getFeatureDependencies(label);
    if (featureDependenciesLabels != null &&
        featureDependenciesLabels.isNotEmpty) {
      for (final dependencyLabel in featureDependenciesLabels) {
        final dependencyWrapper =
            _initializableFeaturesWrappers[dependencyLabel];
        if (dependencyWrapper == null) continue;

        final isInitialized = dependencyWrapper.result.maybeMap(
          orElse: () => false,
          completed: (_) => true,
        );

        // Не разрешаем инициализацию, если какая-то зависимость фичи не проинициализирована
        if (!isInitialized) return;
      }
    }

    setState(() {
      _initializableFeaturesWrappers = Map.from(_initializableFeaturesWrappers);
      _initializableFeaturesWrappers[label] = InitializableFeatureWrapper(
        feature: wrapper.feature,
        result: const AsyncData.notInitialized(),
      );
    });
    _appInitializationBloc.add(AppInitializationEvent.performInitialization(
      isFullInitialization: false,
      allFeatures: _allFeatures,
      featuresRelations: _featuresRelations,
      featuresToInitialize: {wrapper.feature},
    ));
  }

  @override
  void initState() {
    super.initState();

    _appInitializationBloc = AppInitializationBloc();
    _allFeatures = {};
    _featuresRelations = Map.from(widget.featuresRelations);
    _initializableFeatures = {};
    _initializableFeaturesWrappers = {};
    for (final label in widget.allFeaturesLabels) {
      final feature = label.toFeature();
      _allFeatures[label] = feature;
      _initializableFeatures[label] = feature;
      _initializableFeaturesWrappers[label] = InitializableFeatureWrapper(
        feature: feature,
        result: const AsyncData.notInitialized(),
      );
    }
    _createFeaturesRelationsGraph();
  }

  @override
  void dispose() {
    _appInitializationBloc.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _appInitializationBloc,
      child: InitializationInheritedScope(
        appFeaturesWrappers: _initializableFeaturesWrappers,
        child: BlocListener<AppInitializationBloc, AppInitializationState>(
          listener: (context, state) {
            state.mapOrNull(
              inProgress: (state) {
                final allWrappers = {
                  ...state.performingFeaturesWrappers,
                  ...state.initializedFeaturesWrappers,
                  ...state.failedFeaturesWrappers
                };
                if (allWrappers.isEmpty) return;

                _initializableFeaturesWrappers = Map.from(
                  _initializableFeaturesWrappers,
                );
                for (final wrapper in allWrappers) {
                  _initializableFeaturesWrappers[wrapper.feature.label] =
                      wrapper;
                }
                setState(() {});
              },
              completed: (state) {
                final allWrappers = {
                  ...state.initializedFeaturesWrappers,
                  ...state.failedFeaturesWrappers,
                };

                print('allWrappers: $allWrappers');

                final failedWrappers = <InitializableFeatureWrapper>{};
                var completedSuccessfully = true;
                _initializableFeaturesWrappers = Map.from(
                  _initializableFeaturesWrappers,
                );
                for (final wrapper in allWrappers) {
                  _initializableFeaturesWrappers[wrapper.feature.label] =
                      wrapper;

                  if (wrapper.feature.importance ==
                      InitializableFeatureImportance.optional) {
                    continue;
                  }

                  wrapper.result.maybeMap(
                    orElse: () {
                      failedWrappers.add(wrapper.copyWith());
                      completedSuccessfully = false;
                    },
                    completed: (_) {
                      // no implementation
                    },
                  );
                }
                setState(() {});
                if (!state.isFullInitialization) return;

                if (completedSuccessfully) {
                  Navigator.pushAndRemoveUntil(
                    navKey.currentContext!,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    navKey.currentContext!,
                    MaterialPageRoute(
                      builder: (_) => LaunchErrorScreen(
                        error: Exception(
                            'Required features was not initialized $failedWrappers'),
                        stackTrace: StackTrace.current,
                      ),
                    ),
                    (_) => false,
                  );
                }
              },
              failed: (state) {
                Navigator.pushAndRemoveUntil(
                  navKey.currentContext!,
                  MaterialPageRoute(
                    builder: (_) => LaunchErrorScreen(
                      error: state.error,
                      stackTrace: state.stackTrace,
                    ),
                  ),
                  (_) => false,
                );
              },
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
