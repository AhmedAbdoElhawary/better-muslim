import 'package:drift/drift.dart';

/// a date with no zone, so a logged prayer never moves a day when the phone's zone changes (R2)
class CivilDate extends TypeConverter<DateTime, String> {
  const CivilDate();

  @override
  DateTime fromSql(String fromDb) {
    final [year, month, day] = fromDb.split('-').map(int.parse).toList();
    return DateTime(year, month, day);
  }

  @override
  String toSql(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
