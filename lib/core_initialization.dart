import 'package:better_launch/core_initialization_result.dart';

CoreInitializationResult performCoreInitialization() {
  try {
    // TODO добавить что-то
    return const CoreInitializationResult.successful();
  } on Object {
    return const CoreInitializationResult.unsuccessful();
  }
}
