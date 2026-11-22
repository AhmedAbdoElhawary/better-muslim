# Motion spec

Live demos: `design/05 Motion.dc.html` (click a demo to replay; Tweaks: speed 0.25×, reduce motion).
Tokens: `lib/theme/bm_motion.dart`. Haptics: `lib/theme/bm_haptics.dart`.

The app doesn't run the ambient loops in this file (Living Sky, twinkle, prayer glow, sun, adhan
halo, Qibla breathing). They all stand still, as under reduce motion. Only loaders repeat. Home's
sky events (row 17) are the one thing that moves on its own, short and spaced out, and not a loop.

## Tiers
- **Ambient** (time-driven, never touch): Living Sky, countdown tick, prayer glow. 4–8 s loops and 300 ms ticks. Curves: breathe, standard. No haptics. Render at 30 fps inside a RepaintBoundary; pause when off-screen, app in background, or Low Power Mode / Battery Saver.
- **Responsive** (touch/sensor): mark prayed, Qibla needle, tasbih bead, page turn, ayah follow, bottom sheet, tab switch. 150–380 ms. Start on the first frame after input; always interruptible. A new input **retargets** a running spring from its current position and velocity; never queue.
- **Ceremonial**: launch, sky change, adhan reveal, day complete, Qibla aligned, set complete. 520–1800 ms. One at a time. Priority: adhan > completions (08, 10, 12) > responsive > ambient. A higher tier pauses lower ones; ambient resumes with a 300 ms fade. If two ceremonies collide (fifth prayer marked as the Isha adhan starts) the adhan plays and Day complete shows on return to the Prayer tab. No animation ever blocks input; ceremonial overlays dismiss on any tap; launch skips to Home as soon as data is ready.

## The 17 animations
| # | Name | Screen | Trigger | Duration | Curve / spring | Reduce motion | Flutter |
|---|---|---|---|---|---|---|---|
| 01 | App launch | Splash | Cold start, until Home first frame | 1200 ms | sacred · decelerate | Logo fades in, 300 ms. No sun rise. | flutter_native_splash → AnimationController(1200 ms) with staggered Interval curves |
| 02 | Living Sky | Home | While Home is visible | 6000 ms loop | breathe | Static gradient for the current sky state | CustomPainter on a Ticker inside RepaintBoundary; paused via AppLifecycleListener |
| 03 | Sky change | Home, widgets | Prayer time boundary | 1800 ms | sacred | 300 ms crossfade | TweenAnimationBuilder<BmSkyStops>, lerping gradient stops |
| 04 | Countdown tick | Home | Every second | 300 ms | standard | Instant digit swap | AnimatedSwitcher per digit with SlideTransition; Timer aligned to the wall clock |
| 05 | Prayer glow | Home card | Final 10 min before a prayer | 6000 ms loop | breathe | Static glow at 50% | AnimationController.repeat(reverse: true) driving BoxShadow |
| 06 | Adhan reveal | Adhan, full screen | Prayer time in foreground, or notification tap | 520 ms + 520 ms text (300 ms offset) | decelerate | 300 ms fade | ClipPath with a circle-reveal clipper; FadeTransition + SlideTransition for text |
| 07 | Mark prayed | Prayer | Tap check | 380 ms (+220 ms check) | spring.snappy · standard | Fill crossfade, 150 ms | SpringSimulation for scale; PathMetric.extractPath for the check stroke |
| 08 | Day complete | Prayer | Fifth prayer marked | 1400 ms | standard · spring.gentle | Star fades in, 300 ms | Staggered controller; ScaleTransition driven by SpringSimulation |
| 09 | Qibla needle | Qibla | Heading update (low-pass filtered) | ≈1030 ms settle | spring.needle | Standard 300 ms, no overshoot | Compass stream → SpringSimulation on angle; shortest path across 0°/360° |
| 10 | Qibla aligned | Qibla | Within ±3° for 400 ms | 900 ms × 2 | decelerate | Color change only | AnimatedContainer border + ScaleTransition ring; once per alignment |
| 11 | Tasbih bead | Tasbih | Tap anywhere | 380 ms | spring.snappy | Beads step instantly; counter swaps | SpringSimulation on strip offset; a new tap retargets from current velocity |
| 12 | Set complete | Tasbih | Count reaches 33, 99 or target | 300 ms ring + 700 ms burst | standard · decelerate | Ring fills, no burst | TweenAnimationBuilder on sweep angle; 8-particle CustomPainter |
| 13 | Page turn | Quran reader | Swipe or edge tap | 300 ms | standard | 150 ms crossfade | PageView(reverse: true) for RTL order; 30% parallax in a custom transformer |
| 14 | Ayah follow | Quran reader | Recitation timing cue | 300 ms | standard | Highlight jumps | AnimatedPositioned over line rects from the QCF glyph layout |
| 15 | Bottom sheet | Global | Open picker or settings; dismiss | ≈520 ms in · 300 ms out | spring.gentle · accelerate | 150 ms fade in place | showModalBottomSheet with sheetAnimationStyle; SpringSimulation on drag release |
| 16 | Tab switch | Root navigation | Tab tap | 300 ms | standard (shared axis) | 150 ms crossfade | NavigationBar + IndexedStack; FadeThroughTransition (animations package) |
| 17 | Sky event | Home | Every 6–10 s, random, while Home shows its sky, and 1 s after a tap on the sky, around the tap | 720–1840 ms | sin fade | None | One CustomPainter per event, at most 3 at once. Any sky: star burst, shooting star, glint, rare rock, in the sun's color by day. A glint leaves the sun, or the three stars by night. Each streak picks its own angle, length and speed. Stops on another tab or route, in the background and once the sky has scrolled away, a tap still waiting is dropped. None with reduce motion |

## In-screen ambient animations (06 Screens, `data-a` attributes)
| data-a | Element | Keyframes | Duration | Repeat | Curve |
|---|---|---|---|---|---|
| sky | Home sky gradient | background offset 0% → 30% (see bmSkyGradient) | 12000 ms | alternate, infinite | breathe |
| glow | Next-prayer card glow (radial, blur 6, inset −18) | opacity .45 → 1, scale .98 → 1.03 | 3000 ms | alternate, infinite | breathe |
| sun | Sun dot | scale 1 → 1.12 | 3000 ms | alternate, infinite | breathe |
| tw | Each star i | opacity .15 → 1, duration 1800 + (i % 7) × 410 ms, delay −(i % 5) × 600 ms | varies | alternate, infinite | breathe |
| halo | Adhan sun halo | opacity .7 → 1, scale .97 → 1.04 | 3000 ms | alternate, infinite | breathe |
| ndl | Qibla needle while turning (sensor jitter stand-in; in the app the needle follows the compass with spring.needle) | rotate 11° → 17° | 2600 ms | alternate | breathe |
| ndlA | Qibla needle when aligned | rotate −0.8° → 0.8° | 2400 ms | alternate | breathe |
| apulse | Aligned ring pulse | scale 1 → 1.16 and opacity .9 → 0 in the first 30%, then hold | 3000 ms | infinite (in the app: 2 pulses only) | decelerate |
| aglow | Aligned accent glow | opacity .6 → 1 | 3000 ms | alternate | breathe |
| strip / cnt | Tasbih per tap | strip translateX 0 → −44 px with spring.snappy; counter scale 1.06 → 1 in 150 ms standard | ≈380 ms | per tap | snappy |
| ring | Prayer ring, tasbih ring | stroke-dashoffset transition | 300 ms | on change | standard |

All of these stop under reduce motion (static, opacity 1, scale 1).

## Haptics
| Event | When | iOS | Android | Flutter | Sound |
|---|---|---|---|---|---|
| Tasbih bead | Every count | Impact .light | CLOCK_TICK | HapticFeedback.lightImpact() | Bead |
| Set complete | 33, 99 or target reached | Notification .success | CONFIRM | mediumImpact() ×2, 80 ms apart | Complete |
| Mark prayed | Check filled | Impact .light | CONFIRM | HapticFeedback.lightImpact() | — |
| Day complete | Fifth prayer marked | Notification .success | CONFIRM | HapticFeedback.mediumImpact() | Complete |
| Qibla approach | Needle enters ±10°, once | Selection | CLOCK_TICK | HapticFeedback.selectionClick() | — |
| Qibla aligned | Within ±3° for 400 ms, once per alignment | Notification .success | CONFIRM | HapticFeedback.mediumImpact() | Aligned |
| Sheet detent | Sheet snaps to a detent on drag release | Selection | SEGMENT_TICK (API 34+) | HapticFeedback.selectionClick() | — |
| Toggle, segmented | Value changes | Selection | CLOCK_TICK | HapticFeedback.selectionClick() | — |
| Page turn | Page settles (off by default) | Selection | CLOCK_TICK | HapticFeedback.selectionClick() | Page |
| Prayer reminder | Pre-prayer notification | System notification | Channel vibration pattern | flutter_local_notifications channel | Reminder |
| None | Living Sky, countdown, sky change, adhan reveal, tabs, sheets opening | — | — | — | — |

## Reduce motion
Flag = `MediaQuery.disableAnimationsOf(context) || prefs.reduceMotion`.
- No travel: translation, scale, rotation and clip reveals become crossfades of 150–300 ms. Springs become standard 300 ms with no overshoot.
- No loops: Living Sky, twinkle and the prayer glow freeze on the current sky state. Sky changes still happen as a 300 ms crossfade.
- Meaning stays: the check still fills, the Qibla dial still turns accent on alignment, and haptics still fire.

## Exact keyframes (source of the demos)
The demo implementation below is the authoritative timing (delays, offsets, keyframe values). `this.SK(spring, from, to, fmt)` samples a mass-1 spring into keyframes; `E.std/dec/acc/br/sac` are the five curves.

```js
d_launch(P, PA, red) {
    const E = this.E;
    this.every(3800, (i, a) => {
      const b = { fill: 'both' };
      if (red) { ['star', 'sun', 'hz', 'word'].forEach(n => a(P(n), [{ opacity: 0 }, { opacity: 1 }], { ...b, duration: 300, delay: 200 })); }
      else {
        a(P('star'), [{ opacity: 0, transform: 'scale(.9)' }, { opacity: 1, transform: 'scale(1)' }], { ...b, duration: 600, easing: E.dec });
        a(P('hz'), [{ transform: 'scaleX(0)' }, { transform: 'scaleX(1)' }], { ...b, duration: 520, delay: 250, easing: E.std });
        a(P('sun'), [{ opacity: 0, transform: 'translateY(0)' }, { opacity: 1, transform: 'translateY(-30px)' }], { ...b, duration: 900, delay: 450, easing: E.sac });
        a(P('word'), [{ opacity: 0, transform: 'translateY(6px)' }, { opacity: 1, transform: 'none' }], { ...b, duration: 520, delay: 800, easing: E.dec });
      }
      a(P('g'), [{ opacity: 1 }, { opacity: 0 }], { duration: 300, delay: 3400, easing: E.acc, fill: 'forwards' });
    });
  }
  d_sky(P, PA, red) {
    if (red) return; const E = this.E;
    this.A(P('lay'), [{ opacity: 0 }, { opacity: 1 }], { duration: 6000, direction: 'alternate', iterations: Infinity, easing: E.br });
    this.A(P('sun'), [{ transform: 'translateX(-30px)' }, { transform: 'translateX(30px)' }], { duration: 12000, direction: 'alternate', iterations: Infinity, easing: E.br });
    PA('tw').forEach((el, i) => this.A(el, [{ opacity: .15 }, { opacity: 1 }], { duration: 1800 + i * 370, delay: i * 240, direction: 'alternate', iterations: Infinity, easing: E.br }));
  }
  d_change(P, PA, red) {
    const L = PA('lay'); let cur = 0, z = 2;
    this.every(3600, i => { if (!i) return; cur = (cur + 1) % 3; const el = L[cur]; this.save(el); el.style.zIndex = ++z; this.A(el, [{ opacity: 0 }, { opacity: 1 }], { duration: red ? 300 : 1800, easing: this.E.sac, commit: true }); });
  }
  d_tick(P, PA, red) {
    const o = P('ones'), t = P('tens'); let n = 0, m = 0;
    this.every(1000, i => {
      if (!i) return; const d = red ? 1 : 300;
      this.A(o, [{ transform: `translateY(${-n * 56}px)` }, { transform: `translateY(${-(n + 1) * 56}px)` }], { duration: d, easing: this.E.std, commit: true }); n++;
      if (n === 10) { n = 0; this.A(t, [{ transform: `translateY(${-m * 56}px)` }, { transform: `translateY(${-(m + 1) * 56}px)` }], { duration: d, easing: this.E.std, commit: true }); m = (m + 1) % 6; }
    });
  }
  d_glow(P, PA, red) {
    if (red) return;
    this.A(P('card'), [{ boxShadow: '0 0 0 1px #1C2C26, 0 0 20px -10px rgba(168,138,82,.12)' }, { boxShadow: '0 0 0 1px #3A4A3F, 0 0 56px -6px rgba(168,138,82,.55)' }], { duration: 3000, direction: 'alternate', iterations: Infinity, easing: this.E.br });
  }
  d_adhan(P, PA, red) {
    const E = this.E;
    this.every(4400, (i, a) => {
      if (red) { a(P('ov'), [{ clipPath: 'circle(150% at 50% 62%)', opacity: 0 }, { clipPath: 'circle(150% at 50% 62%)', opacity: 1 }], { duration: 300, delay: 400, fill: 'both' }); a(P('txt'), [{ opacity: 0 }, { opacity: 1 }], { duration: 300, delay: 550, fill: 'both' }); }
      else { a(P('ov'), [{ clipPath: 'circle(0% at 50% 62%)' }, { clipPath: 'circle(150% at 50% 62%)' }], { duration: 520, delay: 400, easing: E.dec, fill: 'both' }); a(P('txt'), [{ opacity: 0, transform: 'translateY(10px)' }, { opacity: 1, transform: 'none' }], { duration: 520, delay: 700, easing: E.dec, fill: 'both' }); }
      a(P('ov'), [{ opacity: 1 }, { opacity: 0 }], { duration: 300, delay: 3800, easing: E.acc, fill: 'forwards' });
      a(P('txt'), [{ opacity: 1 }, { opacity: 0 }], { duration: 300, delay: 3800, easing: E.acc, fill: 'forwards' });
    });
  }
  d_mark(P, PA, red) {
    const E = this.E, box = P('box'), chk = P('chk');
    this.every(2800, (i, a) => {
      a(box, [{ background: 'transparent', borderColor: '#4C5E57' }, { background: '#A88A52', borderColor: '#A88A52' }], { duration: 150, delay: 700, easing: E.std, fill: 'both' });
      if (red) a(chk, [{ strokeDashoffset: 0, opacity: 0 }, { strokeDashoffset: 0, opacity: 1 }], { duration: 150, delay: 700, fill: 'both' });
      else {
        const [kf, d] = this.SK('snappy', .78, 1, v => ({ transform: `scale(${v})` }));
        a(box, kf, { duration: d, delay: 700, fill: 'both' });
        a(chk, [{ strokeDashoffset: 20 }, { strokeDashoffset: 0 }], { duration: 220, delay: 800, easing: E.std, fill: 'both' });
      }
    });
  }
  d_day(P, PA, red) {
    const E = this.E;
    this.every(4400, (i, a) => {
      PA('dot').forEach((el, j) => { const x = +el.dataset.x; a(el, red ? [{ transform: `translateX(${x}px)`, opacity: 1 }, { transform: `translateX(${x}px)`, opacity: 0 }] : [{ transform: `translateX(${x}px) scale(1)`, opacity: 1 }, { transform: 'translateX(0) scale(.4)', opacity: 0 }], { duration: red ? 300 : 520, delay: 500 + (red ? 0 : j * 40), easing: E.std, fill: 'both' }); });
      if (red) a(P('star'), [{ opacity: 0 }, { opacity: 1 }], { duration: 300, delay: 700, fill: 'both' });
      else {
        const [kf, d] = this.SK('gentle', .5, 1, v => ({ transform: `scale(${v})` }));
        a(P('star'), kf, { duration: d, delay: 950, fill: 'both' });
        a(P('star'), [{ opacity: 0 }, { opacity: 1 }], { duration: 150, delay: 950, fill: 'both' });
        a(P('ring'), [{ transform: 'scale(1)', opacity: .7 }, { transform: 'scale(2)', opacity: 0 }], { duration: 900, delay: 950, easing: E.dec, fill: 'forwards' });
      }
      a(P('cap'), red ? [{ opacity: 0 }, { opacity: 1 }] : [{ opacity: 0, transform: 'translateY(6px)' }, { opacity: 1, transform: 'none' }], { duration: red ? 300 : 520, delay: red ? 800 : 1200, easing: E.dec, fill: 'both' });
    });
  }
  d_needle(P, PA, red) {
    const n = P('ndl'), T = [-48, 26, 0, 62, -14, 0]; let cur = 0;
    this.every(2200, i => {
      const to = T[i % T.length];
      if (red) this.A(n, [{ transform: `rotate(${cur}deg)` }, { transform: `rotate(${to}deg)` }], { duration: 300, easing: this.E.std, commit: true });
      else { const [kf, d] = this.SK('needle', cur, to, v => ({ transform: `rotate(${v}deg)` })); this.A(n, kf, { duration: d, commit: true }); }
      cur = to;
    });
  }
  d_align(P, PA, red) {
    const E = this.E;
    this.every(3200, (i, a) => {
      if (red) a(P('ndl'), [{ transform: 'rotate(9deg)' }, { transform: 'rotate(0)' }], { duration: 300, easing: E.std, fill: 'both' });
      else { const [kf, d] = this.SK('needle', 9, 0, v => ({ transform: `rotate(${v}deg)` })); a(P('ndl'), kf, { duration: d, fill: 'both' }); }
      a(P('dial'), [{ borderColor: '#1C2C26' }, { borderColor: '#4E9C80' }], { duration: 300, delay: 700, easing: E.std, fill: 'both' });
      a(P('lab'), [{ opacity: 0 }, { opacity: 1 }], { duration: 300, delay: 700, easing: E.std, fill: 'both' });
      if (!red) a(P('ring'), [{ transform: 'scale(1)', opacity: 0 }, { transform: 'scale(1)', opacity: .8, offset: .04 }, { transform: 'scale(1.35)', opacity: 0 }], { duration: 900, delay: 700, iterations: 2, easing: E.dec });
    });
  }
  d_bead(P, PA, red) {
    const c = P('cnt'), s = P('strip'); let n = 16; this.save(c);
    this.every(1100, i => {
      if (!i) return; n = n >= 33 ? 1 : n + 1; c.textContent = n;
      if (red) return;
      const [kf, d] = this.SK('snappy', 0, -44, v => ({ transform: `translateX(${v}px)` }));
      this.A(s, kf, { duration: d });
      this.A(c, [{ transform: 'scale(1.06)' }, { transform: 'scale(1)' }], { duration: 150, easing: this.E.std });
    });
  }
  d_set(P, PA, red) {
    const E = this.E;
    this.every(3800, (i, a) => {
      a(P('prog'), [{ strokeDashoffset: 10.3 }, { strokeDashoffset: 0 }], { duration: 300, delay: 600, easing: E.std, fill: 'both' });
      a(P('n32'), [{ opacity: 1 }, { opacity: 0 }], { duration: 150, delay: 600, fill: 'both' });
      a(P('n33'), [{ opacity: 0 }, { opacity: 1 }], { duration: 150, delay: 600, fill: 'both' });
      if (!red) {
        a(P('n33'), [{ transform: 'scale(1)' }, { transform: 'scale(1.1)' }, { transform: 'scale(1)' }], { duration: 300, delay: 900, easing: E.std });
        PA('pt').forEach(el => a(el, [{ transform: 'translate(0,0)', opacity: 0 }, { opacity: 1, offset: .1 }, { transform: `translate(${el.dataset.dx}px,${el.dataset.dy}px)`, opacity: 0 }], { duration: 700, delay: 900, easing: E.dec }));
      }
      a(P('grp'), [{ opacity: 1 }, { opacity: 0 }], { duration: 300, delay: 3400, easing: E.acc, fill: 'forwards' });
    });
  }
  d_page(P, PA, red) {
    const pg = PA('pg'); let cur = 0;
    this.every(2400, i => {
      if (!i) return; const out = pg[cur], inn = pg[1 - cur]; this.save(inn); this.save(out); inn.style.zIndex = 2; out.style.zIndex = 1;
      if (red) { this.A(inn, [{ opacity: 0, transform: 'none' }, { opacity: 1, transform: 'none' }], { duration: 150, commit: true }); this.A(out, [{ opacity: 1 }, { opacity: 0 }], { duration: 150, commit: true }); }
      else { this.A(inn, [{ transform: 'translateX(-130%)', opacity: 1 }, { transform: 'translateX(0)', opacity: 1 }], { duration: 300, easing: this.E.std, commit: true }); this.A(out, [{ transform: 'translateX(0)', opacity: 1 }, { transform: 'translateX(30%)', opacity: 0 }], { duration: 300, easing: this.E.std, commit: true }); }
      cur = 1 - cur;
    });
  }
  d_ayah(P, PA, red) {
    const hl = P('hl'), W = [220, 236, 180, 236, 200, 140]; let cur = 0;
    this.every(1400, i => {
      if (!i) return; const nx = (cur + 1) % 6;
      this.A(hl, [{ transform: `translateY(${39 + cur * 28}px)`, width: W[cur] + 12 + 'px' }, { transform: `translateY(${39 + nx * 28}px)`, width: W[nx] + 12 + 'px' }], { duration: red ? 1 : 300, easing: this.E.std, commit: true });
      cur = nx;
    });
  }
  d_sheet(P, PA, red) {
    const E = this.E;
    this.every(3800, (i, a) => {
      if (red) { a(P('scr'), [{ opacity: 0 }, { opacity: .64 }], { duration: 150, delay: 400, fill: 'both' }); a(P('sh'), [{ transform: 'none', opacity: 0 }, { transform: 'none', opacity: 1 }], { duration: 150, delay: 400, fill: 'both' }); }
      else {
        a(P('scr'), [{ opacity: 0 }, { opacity: .64 }], { duration: 300, delay: 400, easing: E.std, fill: 'both' });
        const [kf, d] = this.SK('gentle', 100, 0, v => ({ transform: `translateY(${v}%)` }));
        a(P('sh'), kf, { duration: d, delay: 400, fill: 'both' });
      }
      a(P('scr'), [{ opacity: .64 }, { opacity: 0 }], { duration: red ? 150 : 300, delay: 2900, easing: E.acc, fill: 'forwards' });
      a(P('sh'), red ? [{ opacity: 1, transform: 'none' }, { opacity: 0, transform: 'none' }] : [{ transform: 'translateY(0)' }, { transform: 'translateY(100%)' }], { duration: red ? 150 : 300, delay: 2900, easing: E.acc, fill: 'forwards' });
    });
  }
  d_tab(P, PA, red) {
    const ind = P('ind'), c = P('cnt'), tl = PA('tl'), N = ['Home', 'Prayer', 'Quran', 'Azkar', 'More']; let cur = 0;
    this.save(c); tl.forEach(t => this.save(t));
    this.every(1700, i => {
      if (!i) return; const nx = (cur + 1) % 5, from = cur;
      this.A(ind, [{ transform: `translateX(${from * 100}%)` }, { transform: `translateX(${nx * 100}%)` }], { duration: red ? 1 : 300, easing: this.E.std, commit: true });
      tl.forEach((t, j) => t.style.color = j === nx ? '#D9C08A' : '#878C82');
      const o = this.A(c, [{ opacity: 1, transform: 'none' }, { opacity: 0, transform: red ? 'none' : 'translateY(-8px)' }], { duration: red ? 75 : 120, easing: this.E.acc, fill: 'forwards', keep: true });
      o.addEventListener('finish', () => { if (!this.anims.includes(o)) return; c.textContent = N[nx]; this.A(c, [{ opacity: 0, transform: red ? 'none' : 'translateY(8px)' }, { opacity: 1, transform: 'none' }], { duration: red ? 75 : 300, easing: this.E.dec, commit: true }); o.cancel(); this.anims.splice(this.anims.indexOf(o), 1); });
      cur = nx;
    });
  }
```
