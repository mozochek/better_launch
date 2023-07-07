import 'package:better_launch/app_initialization_bloc.dart';
import 'package:better_launch/initializable_feature_label.dart';
import 'package:better_launch/initialization_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final navKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({
    super.key,
  });

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final Set<InitializableFeatureLabel> _allFeaturesLabels;
  late final Map<InitializableFeatureLabel, Set<InitializableFeatureLabel>>
      _featuresRelations;

  @override
  void initState() {
    super.initState();

    _allFeaturesLabels = {...InitializableFeatureLabel.values};
    _featuresRelations = {
      const InitializableFeatureLabel.firebaseDynamicLinks(): {
        const InitializableFeatureLabel.firebase(),
      },
      const InitializableFeatureLabel.dummy0(): {
        const InitializableFeatureLabel.firebaseDynamicLinks(),
      },
      const InitializableFeatureLabel.dummy1(): {
        const InitializableFeatureLabel.dummy0(),
      },
      const InitializableFeatureLabel.dummy2(): {
        const InitializableFeatureLabel.dummy1(),
      },
      const InitializableFeatureLabel.dummy3(): {
        const InitializableFeatureLabel.dummy2(),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        return InitializationScope(
          allFeaturesLabels: _allFeaturesLabels,
          featuresRelations: _featuresRelations,
          // allFeatures: _allFeatures,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    InitializationScope.finishInitialization(context, includeOptional: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppInitializationBloc, AppInitializationState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8.0),
                  BlocBuilder<AppInitializationBloc, AppInitializationState>(
                    builder: (context, state) {
                      final displayedText = state.map<String>(
                        notInitialized: (_) {
                          return 'Инициализация скоро начнётся...';
                        },
                        inProgress: (state) {
                          return 'Инициализация ${(state.completionRatio * 100).round()}%';
                        },
                        completed: (_) {
                          return 'Приложение загружено';
                        },
                        failed: (_) {
                          return 'Приложение не загружено :(';
                        },
                      );

                      return Text(displayedText);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: FeaturesMonitor(),
      ),
    );
  }
}

class FeaturesMonitor extends StatelessWidget {
  const FeaturesMonitor({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: InitializableFeatureLabel.values.length,
      itemBuilder: (context, index) {
        return FeatureMonitorTile(
          featureLabel: InitializableFeatureLabel.values[index],
        );
      },
    );
  }
}

class FeatureMonitorTile extends StatelessWidget {
  const FeatureMonitorTile({
    required this.featureLabel,
    super.key,
  });

  final InitializableFeatureLabel featureLabel;

  @override
  Widget build(BuildContext context) {
    final featureWrapper =
        InitializationScope.featureStatusOf(context, featureLabel);
    final feature = featureWrapper.feature;

    return ListTile(
      leading: featureWrapper.result.maybeMap(
        orElse: () {
          return const SizedBox.square(
            dimension: 24.0,
            child: CircularProgressIndicator(),
          );
        },
        completed: (_) {
          return const Icon(
            Icons.check,
            size: 24.0,
            color: Colors.green,
          );
        },
        failed: (_) {
          return const Icon(
            Icons.close,
            size: 24.0,
            color: Colors.red,
          );
        },
      ),
      title: Text('Фича(${feature.importance.name}): "${feature.label.value}"'),
      subtitle: Text('Статус: ${featureWrapper.result}'),
      trailing: IconButton(
        onPressed: () {
          InitializationScope.reinitializeFeature(context, feature.label);
        },
        icon: const Icon(Icons.update),
      ),
    );
  }
}

class LaunchErrorScreen extends StatelessWidget {
  const LaunchErrorScreen({
    required this.error,
    required this.stackTrace,
    super.key,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      Text('Ошибка: $error'),
                      const SizedBox(height: 16.0),
                      Text('$stackTrace'.trim()),
                    ],
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (_) => false,
                );
              },
              child: const Text('Перезапустить МП'),
            ),
          ],
        ),
      ),
    );
  }
}
