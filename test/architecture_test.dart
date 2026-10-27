import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// the one place each thing is built, so the rule that bans it skips that folder
const _theme = 'lib/core/resources/';
const _adaptive = 'lib/core/widgets/adaptive/';

/// the handoff's sky painter draws white stars and exact geometry from the mockup
const _skyPainter = 'lib/features/home/view/widgets/sky_header_painter.dart';

/// the adhan screen is always dark, 4.03 gives its own literal colors
const _adhanColors = 'lib/features/notifications/presentation/view/adhan_colors.dart';

/// the share card's fixed backgrounds look the same in every theme
const _shareColors = 'lib/core/widgets/share/share_options.dart';

/// the adhan screen keeps emerald's sky in every theme (TOKENS.md)
const _adhanSky = 'lib/features/notifications/presentation/view/widgets/adhan_sky.dart';

/// the app root copies the data once, nothing below it rebuilds for it
const _appRoot = 'lib/core/app/app.dart';

/// recitation audio is the one download the constitution allows (VIII)
const _recitationFiles = 'lib/features/quran/data/recitation_files.dart';

/// a layer may not import the layers listed for it
const _forbiddenLayers = {
  'domain': {'data', 'presentation'},
  'data': {'presentation'},
  'model': {'view_model', 'view'},
  'view_model': {'view'},
};

const _mvvm = {'model', 'view_model', 'view'};
const _clean = {'data', 'domain', 'presentation'};

final _rules = [
  _Rule(
    'colors come from context.getColor(ThemeEnum.x)',
    RegExp(r'\bColors\.|\bColor\(0x|\bColor\.from(ARGB|RGBO)\('),
    allowedIn: [_theme, _skyPainter, _adhanColors, _shareColors],
  ),
  _Rule(
    'ColorManager is read only by the theme files',
    RegExp(r'\bColorManager\.'),
    allowedIn: [_theme],
  ),
  _Rule(
    'text goes through LightText, RegularText, MediumText, SemiBoldText, BoldText',
    RegExp(r'\bText(\.rich)?\(|\bTextStyle\('),
    allowedIn: [_theme, _adaptive],
  ),
  _Rule(
    'text comes from StringsManager keys, not string literals',
    RegExp(r'''\b(LightText|RegularText|MediumText|SemiBoldText|BoldText)\(\s*r?['"]'''),
  ),
  _Rule(
    'spacing goes through the adaptive paddings and RSizedBox',
    RegExp(
      r'\b(Padding|RPadding|SizedBox)\(|\bSizedBox\.(square|fromSize)\(|\bEdgeInsets(Directional)?\.(?!zero\b)',
    ),
    allowedIn: [_adaptive],
  ),
  _Rule(
    'sizes come from SpaceManager, RadiusManager, SizeManager, FontSizeManager, not raw numbers',
    RegExp(
      r'\b(padding|horizontal|vertical|start|end|top|bottom|left|right|width|height|size|radius|fontSize'
      r'|iconSize|letterSpacing|spacing|runSpacing|mainAxisSpacing|crossAxisSpacing)\s*:\s*-?(?!0+(\.0+)?(?![\d.]))\d'
      r'|\b(BorderRadius|Radius)\.circular\(\s*\d'
      r'|\bRSizedBox\.(vertical|horizontal|square)\(\s*\d'
      r'|\bREdgeInsets(Directional)?\.all\(\s*\d'
      r'|\b\d+(\.\d+)?\.(w|h|r|sp)\b',
    ),
    allowedIn: [_theme, _adaptive],
  ),
  _Rule(
    'MediaQuery.of rebuilds on any change, use MediaQuery.sizeOf, paddingOf...',
    RegExp(r'\bMediaQuery\.of\('),
    allowedIn: [_appRoot],
  ),
  _Rule(
    "the live sky is the theme's, themeSky(id), only the adhan screen keeps emerald's",
    RegExp(r'\bbmSkyQiyamEmerald\b'),
    allowedIn: [_theme, _adhanSky],
  ),

  /// buildModalBarrier is the route's own override
  _Rule(
    'widgets are classes, not build functions',
    RegExp(r'\bWidget\s+_?build(?!ModalBarrier\b)[A-Z]\w*\('),
  ),
  _Rule(
    'no shared_preferences, use drift or flutter_secure_storage',
    RegExp(r'package:shared_preferences/'),
  ),
  _Rule(
    'no geocoding, place names come from the GeoNames list in the app',
    RegExp(r'package:geocoding/'),
  ),
  _Rule(
    'no network in the app, it is offline-first (FR-025)',
    RegExp(r'package:(http|dio)/|\bHttpClient\('),
    allowedIn: [_recitationFiles],
  ),
  _Rule(
    'icons come from BmIcon, never Material or Cupertino icons',
    RegExp(r'\b(Icons|CupertinoIcons)\.'),
  ),
];

void main() {
  final packageName = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path)
      .where((path) => path.endsWith('.dart'))
      .where((path) => !path.endsWith('.g.dart') && !path.endsWith('.freezed.dart'))
      .toList();

  /// line comments are dropped so a comment mentioning Colors.red doesn't fail the build
  final contents = {
    for (final path in files) path: File(path).readAsStringSync().replaceAll(RegExp(r'//.*'), ''),
  };

  for (final rule in _rules) {
    test(rule.name, () {
      final violations = <String>[];
      for (final MapEntry(key: path, value: content) in contents.entries) {
        if (rule.allowedIn.any(path.startsWith)) continue;
        for (final match in rule.pattern.allMatches(content)) {
          violations.add(_where(path, content, match.start));
        }
      }
      _expectNone(rule.name, violations);
    });
  }

  test('no golden tests, comparing against the PNGs is too expensive', () {
    final goldens = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart') && file.path != 'test/architecture_test.dart')
        .where((file) => file.readAsStringSync().contains('matchesGoldenFile'))
        .map((file) => file.path)
        .toList();
    _expectNone('no golden tests, comparing against the PNGs is too expensive', goldens);
  });

  test('lib has only main, bootstrap, core and features', () {
    final extra = Directory('lib')
        .listSync()
        .where((entry) => !_name(entry).startsWith('.'))
        .where(
          (entry) =>
              !RegExp(r'^(main(_\w+)?\.dart|bootstrap\.dart|core|features)$')
                  .hasMatch(_name(entry)),
        )
        .map((entry) => entry.path)
        .toList();
    _expectNone('lib has only main, bootstrap, core and features', extra);
  });

  test('every feature is mvvm (model, view_model, view) or clean (data, domain, presentation)', () {
    final features = Directory('lib/features');
    if (!features.existsSync()) return;
    final wrong = <String>[];
    for (final feature in features.listSync().whereType<Directory>()) {
      final entries = feature.listSync().where((entry) => !_name(entry).startsWith('.')).toList();
      final layers = entries.whereType<Directory>().map(_name).toSet();
      final hasLooseFiles = entries.whereType<File>().isNotEmpty;
      final fits = layers.isNotEmpty && (_mvvm.containsAll(layers) || _clean.containsAll(layers));
      if (hasLooseFiles || !fits) wrong.add('${feature.path}  $layers');
    }
    _expectNone(
      'every feature is mvvm (model, view_model, view) or clean (data, domain, presentation)',
      wrong,
    );
  });

  test(
    'imports follow the layers: no feature to feature, no core to feature, no layer upwards',
    () {
      final violations = <String>[];
      for (final MapEntry(key: path, value: content) in contents.entries) {
        for (final match in RegExp(
          r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
          multiLine: true,
        ).allMatches(content)) {
          final target = _resolve(path, match[1]!, packageName);
          if (target == null) continue;
          final from = _featureAndLayer(path);
          final to = _featureAndLayer(target);
          if (to == null) continue;
          final crossFeature = from != null && from.feature != to.feature;
          final coreToFeature =
              path.startsWith('lib/core/') && !path.startsWith('lib/core/router/');
          final upwards =
              from != null &&
              from.feature == to.feature &&
              (_forbiddenLayers[from.layer]?.contains(to.layer) ?? false);
          if (crossFeature || coreToFeature || upwards) {
            violations.add(_where(path, content, match.start));
          }
        }
      }
      _expectNone(
        'imports follow the layers: no feature to feature, no core to feature, no layer upwards',
        violations,
      );
    },
  );
}

class _Rule {
  const _Rule(this.name, this.pattern, {this.allowedIn = const []});
  final String name;
  final RegExp pattern;
  final List<String> allowedIn;
}

void _expectNone(String rule, List<String> violations) {
  if (violations.isEmpty) return;
  fail('$rule\n${violations.join('\n')}');
}

String _where(String path, String content, int index) {
  final line = '\n'.allMatches(content.substring(0, index)).length + 1;
  return '$path:$line  ${content.split('\n')[line - 1].trim()}';
}

String _name(FileSystemEntity entity) => entity.path.split(Platform.pathSeparator).last;

/// turns an import into a lib/ path, null when it points outside this package
String? _resolve(String from, String uri, String packageName) {
  final prefix = 'package:$packageName/';
  if (uri.startsWith(prefix)) return 'lib/${uri.substring(prefix.length)}';
  if (uri.contains(':')) return null;
  return Uri.parse(from).resolve(uri).path;
}

({String feature, String layer})? _featureAndLayer(String path) {
  final parts = path.split('/');
  if (parts.length < 4 || parts[0] != 'lib' || parts[1] != 'features') return null;
  return (feature: parts[2], layer: parts[3]);
}
