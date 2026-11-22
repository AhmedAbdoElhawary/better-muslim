# 23: Live countdown off screen on Android

**What to build:** When the app leaves the screen, an ongoing notification counts down to the next
prayer, rolls to each next one, and goes away when I open the app again. It replaces the 2-hour
windows. The Prayer countdown switch still turns it off.

**Blocked by:** 21

**Status:** done

- [x] The surface data no longer builds 2-hour windows. The countdown follows the app leaving and
      coming back. `surface_data_test` and `write_surfaces_test` are updated.
- [x] It starts when the app is backgrounded or swiped away and ends when the app is on screen.
- [x] At each prayer it rolls to the next one without the app running.
- [x] A logged prayer still ends its label in prayed, as now.
- [x] It comes back after a reboot the way the adhan alarms do.
- [x] With the switch off, no place or notifications denied, there is none and nothing breaks.
- [x] It uses the theme's dark palette.
