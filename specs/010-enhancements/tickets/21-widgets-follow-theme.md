# 21: Widgets follow the theme

**What to build:** My widgets use the theme I chose and the app's mode, and with Follow sky they
flip at sunrise and maghrib on their own. The live countdown uses the theme's dark palette. The
iOS widgets match their 5.6 trees line by line.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The surface data carries the theme's palette roles for light and dark, the app's mode and
      Follow sky's flip moments. `surface_data_test` and `write_surfaces_test` cover it.
- [x] The iOS widgets and the current Android widgets read their colors from it. Their
      hard-coded colors are gone.
- [x] Changing the theme or the mode updates the widgets right away.
- [x] The live countdown uses the theme's dark palette on both platforms.
- [x] Constitution II and the architecture test's allow list are amended so widgets are no longer
      always dark, with the version bumped as Governance says.
- [x] The iOS small (widget3), medium (widget1) and large (widget2) are checked line by line
      against 5.6 and every difference is fixed.
