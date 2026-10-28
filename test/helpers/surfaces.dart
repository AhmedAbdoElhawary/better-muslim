import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:flutter/services.dart';

/// records what the app hands the plugin, nothing reaches the phone
class FakeSurfacesChannel extends SurfacesChannel {
  FakeSurfacesChannel({this.error, this.started = true});

  final updates = <({String json, bool force})>[];
  int starts = 0;
  PlatformException? error;
  bool started;

  @override
  Future<void> update(String json, {bool force = false}) async {
    if (error case final error?) throw error;
    updates.add((json: json, force: force));
  }

  @override
  Future<bool> startNow() async {
    starts++;
    return started;
  }
}
