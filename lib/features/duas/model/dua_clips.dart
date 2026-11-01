import 'dart:io';

import 'package:better_muslim/core/database/backup_exclusion.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final duaClipsProvider = Provider<DuaClips>((ref) => DuaClips());

/// hisnmuslim.com's clip of a dua, downloaded on its first listen and kept to play offline
class DuaClips {
  DuaClips({
    Future<Directory> Function()? root,
    Future<Fetched> Function(Uri uri)? fetch,
    Future<void> Function(String path)? exclude,
  }) : _root = root ?? getApplicationSupportDirectory,
       _fetch = fetch ?? fetchUri,
       _exclude = exclude ?? BackupExclusion.exclude;

  static final base = Uri.parse('https://www.hisnmuslim.com/audio/ar/');

  final Future<Directory> Function() _root;
  final Future<Fetched> Function(Uri uri) _fetch;
  final Future<void> Function(String path) _exclude;

  Future<Directory>? _folder;

  Future<Directory> get folder => _folder ??= () async {
    final folder = Directory('${(await _root()).path}/duas');
    if (!folder.existsSync()) {
      await folder.create(recursive: true);
      await _exclude(folder.path);
    }
    return folder;
  }();

  /// throws a DownloadException when it isn't on the phone and can't be fetched
  Future<String> path(Dua dua) async {
    final file = File('${(await folder).path}/${dua.audio}');
    if (!file.existsSync()) {
      await saveVerified(base.resolve(dua.audio!), file, sha256Hex: dua.sha256!, fetch: _fetch);
    }
    return file.path;
  }
}
