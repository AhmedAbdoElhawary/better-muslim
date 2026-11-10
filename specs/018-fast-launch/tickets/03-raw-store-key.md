# 03: The store key without the stretch

**What to build:** The store opens with its key as a raw key, so sqlite3mc skips its key
derivation in the app and every background engine. Existing stores are rekeyed once.

**Blocked by:** The store's ms from ticket 01's profile run. Over 30 ms on the CPH2773 builds it,
under closes it.

**Status:** waiting for the number

- [ ] Raw key on open, the old passphrase form rekeyed once and never lost.
- [ ] A test that opens a passphrase store, rekeys it and opens it again with the raw key.
- [ ] An ADR, a future reader would wonder why the key skips the stretch.
