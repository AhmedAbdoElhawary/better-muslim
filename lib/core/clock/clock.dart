import 'package:flutter_riverpod/flutter_riverpod.dart';

/// every "now" in the app comes from here, so tests and the design scenario can freeze it
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final tickerProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => clock());
});
