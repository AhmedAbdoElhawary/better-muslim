/// the three dhikr of 4.08. content, not ui text, so it is not in the arb files
class TasbihDhikr {
  const TasbihDhikr({
    required this.arabic,
    required this.arabicName,
    required this.name,
    required this.meaning,
    required this.target,
  });

  /// with its marks, the big line
  final String arabic;

  /// plain, the chip in the arabic app
  final String arabicName;
  final String name;
  final String meaning;
  final int target;
}

const tasbihDhikr = [
  TasbihDhikr(
    arabic: 'سُبْحَانَ اللَّهِ',
    arabicName: 'سبحان الله',
    name: 'SubhanAllah',
    meaning: 'Glory be to Allah',
    target: 33,
  ),
  TasbihDhikr(
    arabic: 'الْحَمْدُ لِلَّهِ',
    arabicName: 'الحمد لله',
    name: 'Alhamdulillah',
    meaning: 'All praise is due to Allah',
    target: 33,
  ),
  TasbihDhikr(
    arabic: 'اللَّهُ أَكْبَرُ',
    arabicName: 'الله أكبر',
    name: 'Allahu Akbar',
    meaning: 'Allah is the Greatest',
    target: 34,
  ),
];
