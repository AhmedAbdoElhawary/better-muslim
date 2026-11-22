import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

/// the store's own rating sheet over the app, false on a phone without the store. the store
/// decides if it shows, so a tap can show nothing. the tests replace it
final reviewProvider = Provider<Future<bool> Function()>(
  (ref) => () async {
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return false;
    await review.requestReview();
    return true;
  },
);
