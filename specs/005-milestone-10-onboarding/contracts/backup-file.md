# Contract: the backup file

Made by `core/backup/backup_file.dart`, read by the same file. The same bytes on iOS and Android.

## Name

`better-muslim-YYYY-MM-DD.bmbackup`, the date it was made, Western digits.

## Bytes

| Offset | Size | Field | Value |
| --- | --- | --- | --- |
| 0 | 8 | magic | ASCII `BMBACKUP` |
| 8 | 1 | format | 1 |
| 9 | 2 | schema version | the store's `schemaVersion` when made, big endian (6 now) |
| 11 | 8 | payload length | bytes after the header, big endian |
| 19 | n | payload | the backup store (below) |

## Payload (format 1)

A SQLite database made by drift with the app's schema at that version, encrypted by
SQLite3MultipleCiphers:

```sql
pragma cipher = 'chacha20';
pragma kdf_iter = 600000;
pragma hexkey = '<the password as UTF-8 bytes, hex>';
```

The password is never stored anywhere. A later format number means another cipher setup and is
read only by an app that knows it.

## Reading

1. No magic → not a backup.
2. File shorter than 19 + payload length → damaged. Longer → the extra bytes are ignored.
3. Schema version above the app's → newer, update first.
4. The first query with the password fails (SQLite 26) → wrong password.
5. `pragma quick_check` isn't `ok` → damaged.
6. Older schema → drift's migration runs on the temp copy, then it's restored.

Temp files (the payload when writing and reading) live in the temporary folder and are deleted
when the share sheet closes or the restore ends, in every case.
