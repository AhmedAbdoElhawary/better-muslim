import 'package:better_muslim/bootstrap.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';

/// flutter run --flavor production -t lib/main_prod.dart --dart-define-from-file=dart_define/prod.json
Future<void> main() => bootstrap(FlavorConfig.fromEnvironment());
