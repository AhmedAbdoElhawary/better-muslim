import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:flutter/services.dart';

/// records what the app hands the plugin, nothing reaches the phone
class FakeSurfacesChannel extends SurfacesChannel {
  FakeSurfacesChannel({this.error});

  final updates = <({String json, bool force})>[];
  PlatformException? error;

  @override
  Future<void> update(String json, {bool force = false}) async {
    if (error case final error?) throw error;
    updates.add((json: json, force: force));
  }
}
