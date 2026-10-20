import 'dart:async';
import 'dart:ui' as ui;

import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:better_muslim/features/duas/view/widgets/share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// paints the card once off screen with the app's fonts and theme, then shares it as a png.
/// button is the share action's context, ipad anchors the sheet to it
Future<void> shareDua(
  BuildContext button,
  WidgetRef ref, {
  required Dua dua,
  required DuaCategory category,
}) async {
  final share = ref.read(shareProvider);
  final box = button.findRenderObject()! as RenderBox;
  final origin = box.localToGlobal(Offset.zero) & box.size;
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      /// past the screen's end, painted but never seen
      left: MediaQuery.sizeOf(context).width,
      top: 0,
      child: RepaintBoundary(
        key: key,
        child: ShareCard(dua: dua, category: category),
      ),
    ),
  );
  Overlay.of(button).insert(entry);
  final ByteData? png;
  try {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
  } finally {
    entry.remove();
  }
  await share(
    ShareParams(
      files: [XFile.fromData(png!.buffer.asUint8List(), mimeType: 'image/png', name: 'dua.png')],
      sharePositionOrigin: origin,
    ),
  );
}
