import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// the phone's share sheet, the tests replace it
final shareProvider = Provider<Future<void> Function(ShareParams params)>(
  (ref) =>
      (params) async => SharePlus.instance.share(params),
);
