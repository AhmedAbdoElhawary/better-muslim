import 'dart:async';
import 'dart:io';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/network/download.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// android's notification for a download I started: its bar, pause, resume and cancel, from a
/// foreground service so it goes on in the background (spec 026). ios has none
class DownloadNotice {
  DownloadNotice._(this._id, this._texts, this._resume, this._digits);

  static const _channel = MethodChannel('better_muslim/downloads');

  /// past the alerts' ids, they share the notification ids
  static const _firstId = 4000000;
  static const _every = Duration(milliseconds: 500);

  static final _live = <int, DownloadNotice>{};
  static var _listening = false;

  final int _id;
  final Map<String, String> _texts;
  final Future<void> Function() _resume;
  final String Function(String text) _digits;

  var _pausing = false;
  var _cancelling = false;
  var _running = true;
  DateTime? _sent;

  /// the .part the loop writes, a cancel while paused deletes it
  String? part;

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  /// true when it finished, false when it was paused from the notification. a cancel or a failure
  /// is rethrown. the title is read in the app's language, the app may be closed by then
  static Future<bool> run({
    required String key,
    required String Function(AppLocalizations l10n, bool arabic) title,
    required AppSettings? settings,
    required Future<void> Function() resume,
    required Future<void> Function(DownloadNotice notice) job,
  }) async {
    final locale = AppLocalizations.localeOf(settings?.language);
    final l10n = await AppLocalizations.load(locale);
    final name = title(l10n, locale.languageCode == 'ar');
    final notice = DownloadNotice._(
      _firstId + (key.hashCode & 0xffff),
      {
        'title': name,
        'channel': l10n.tr(StringsManager.downloads, const {}),
        'pause': l10n.tr(StringsManager.pause, const {}),
        'resume': l10n.tr(StringsManager.resume, const {}),
        'cancel': l10n.tr(StringsManager.cancel, const {}),
        'paused': l10n.tr(StringsManager.downloadPaused, const {}),
        'size': l10n.tr(StringsManager.downloadSize, const {}),
        'failed': l10n.tr(StringsManager.downloadCouldNot, {'name': name}),
      },
      resume,
      (text) => formatDigitsIn(
        text,
        language: locale.languageCode,
        digits: settings?.digits ?? Digits.eastern,
      ),
    );
    _live[notice._id] = notice;
    notice._show(null, null);
    try {
      await job(notice);
      notice._end();
      return true;
    } on Object catch (error) {
      switch (error) {
        case DownloadException(failure: DownloadFailure.paused):
          notice._running = false;
          notice._show(notice._done, notice._total, paused: true);
          return false;
        case DownloadException(failure: DownloadFailure.cancelled):
          notice._end();
        default:
          notice._end(failed: true);
      }
      rethrow;
    }
  }

  /// from the loop, each chunk. throws when the notification asked to pause or cancel
  void progress(int done, int? total) => _report(done, total, sized: true);

  /// for a download of several files, the share of all of them, with no size
  void share(double value) => _report((value * _parts).round(), _parts, sized: false);

  static const _parts = 1000;

  int? _done;
  int? _total;
  var _sized = false;

  void _report(int done, int? total, {required bool sized}) {
    if (_cancelling) throw const DownloadException(DownloadFailure.cancelled);
    if (_pausing) throw const DownloadException(DownloadFailure.paused);
    _done = done;
    _total = total;
    _sized = sized;
    final now = DateTime.now();
    if (_sent != null && now.difference(_sent!) < _every && done != total) return;
    _sent = now;
    _show(done, total);
  }

  /// the bar in thousandths, null while the size is unknown
  void _show(int? done, int? total, {bool paused = false}) {
    final known = done != null && total != null && total > 0;
    String megabytes(int bytes) => '${(bytes / 1000000).round()}';
    _call('show', {
      'id': _id,
      'title': _texts['title'],
      'channel': _texts['channel'],
      'progress': known ? done * 1000 ~/ total : null,
      'percent': known ? _digits('${done * 100 ~/ total}%') : null,
      'text': paused
          ? _texts['paused']
          : known && _sized
          ? _digits(
              _texts['size']!
                  .replaceAll('{done}', megabytes(done))
                  .replaceAll('{total}', megabytes(total)),
            )
          : null,
      'paused': paused,
      'pause': _texts['pause'],
      'resume': _texts['resume'],
      'cancel': _texts['cancel'],
    });
  }

  void _end({bool failed = false}) {
    _live.remove(_id);
    _call('end', {'id': _id, if (failed) 'failed': _texts['failed']});
  }

  Future<void> _action(String action) async {
    switch (action) {
      case 'pause':
        _pausing = true;
      case 'resume' when !_running:
        _live.remove(_id);

        /// its own run shows how it went, the button's reply shouldn't wait minutes for it
        unawaited(_resume().catchError((Object _) {}));
      case 'cancel' when _running:
        _cancelling = true;
      case 'cancel':
        if (part case final path? when File(path).existsSync()) File(path).deleteSync();
        _end();
    }
  }

  /// a notification is never worth failing a download for, and the tests have no android side
  void _call(String method, Map<String, Object?> arguments) {
    if (!_android) return;
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler((call) async {
        final arguments = call.arguments as Map<Object?, Object?>;
        final (id, action) = (arguments['id']! as int, arguments['action']! as String);
        final notice = _live[id];

        /// the app was gone, so was the download
        if (notice == null) return _channel.invokeMethod<void>('end', {'id': id});
        await notice._action(action);
      });
    }
    _channel.invokeMethod<void>(method, arguments).catchError((_) {});
  }
}
