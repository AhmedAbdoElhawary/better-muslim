import 'dart:io';

import 'package:better_muslim/core/audio/adhan_files.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phone_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deleteRemoved deletes the removed recordings and keeps the rest', () async {
    final folder = Directory('${usePhoneStorage().path}/adhan')..createSync();
    final removed = [
      for (final name in ['adhan_aaqib_azeez', 'adhan_andrewler', 'adhan_synagda'])
        File('${folder.path}/$name.m4a')..writeAsStringSync('x'),
    ];
    final kept = File('${folder.path}/adhan_other.m4a')..writeAsStringSync('x');

    await AdhanFiles.deleteRemoved();

    expect(removed.where((file) => file.existsSync()), isEmpty);
    expect(kept.existsSync(), isTrue);
  });
}
