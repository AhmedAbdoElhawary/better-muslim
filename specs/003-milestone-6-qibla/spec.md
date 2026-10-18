# Feature Specification: Milestone 6, Qibla

**Feature Branch**: `feature/milestone-6`, cut from where milestone 5 ends

**Created**: 2026-10-17

**Status**: Draft

**Input**: User description: "milstone 6"

Milestone 6 is the Qibla screen (4.05 turning, 4.06 aligned): a dial that turns with the phone, a
needle that springs to the Kaaba marker, the turn instruction, the distance to the Kaaba and the
compass accuracy. The screen itself is built straight from the handoff specs. This spec covers what
the handoff doesn't: where the heading and the position come from, how the bearing and distance
are worked out, when the screen counts as aligned, what it shows when the compass is weak or
missing or there is no location, and how the design scenario reaches the 4.05 and 4.06 values. Like everything
else it works with no internet, and neither the heading nor the position leaves the phone.

## Clarifications

### Session 2026-10-17

- Q: How do I reach Qibla before milestone 9 builds More? → A: A temporary Qibla tile on the More
  placeholder, replaced by the real tile in milestone 9.
- Q: Where does the position come from? → A: The saved location, plus a fresh fix while the screen
  is open when the location is automatic and allowed. The fix is used for the bearing and distance
  only, never saved.
- Q: The copy and look of the weak compass, no compass and no location states? → A: The FR-025
  table and FR-019 to FR-022 as written. The no location state reuses Home's no location copy and
  buttons, since the location sheet exists since milestone 3.
- Q: What does the gear open? → A: The location sheet. It was planned for milestone 10, it already
  exists since milestone 3.
- Q: Dial letters in Arabic? → A: ش ق ج غ in Arabic, N E S W in English, never mirrored.
- Q: How does the design scenario show both states? → A: Qibla from London with the heading frozen
  at 105°, a tap on the dial switches to 119° and back, in the design scenario only.
- Q: Order and branch? → A: Plan and tasks now, built after milestone 5, on `feature/milestone-6`
  cut from where milestone 5 ends.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find the Qibla (Priority: P1)

I open Qibla, hold the phone flat and read "Turn 14° right". I turn, the dial turns with me, the
needle springs towards the Kaaba marker, and when I get close the phone ticks once.

**Why this priority**: Pointing the right way is the whole screen. Everything else on it only
helps me trust the needle.

**Independent Test**: In the design scenario (London, heading 105°) the screen matches 4.05:
"Turn 14° right", "London · Qibla at 119° from north", "4,790 km", "High". On a real phone in a
known place the needle points within 5° of the bearing a reference compass gives.

**Acceptance Scenarios**:

1. **Given** I am in London and the top of the phone faces 105°, **When** the screen opens,
   **Then** the title reads "Turn 14° right" and the needle points 14° right of the top tick, at
   the Kaaba marker.
2. **Given** the screen is open, **When** I turn the phone, **Then** the dial turns with the
   heading at once and the needle follows with spring.needle (Motion 09), always the short way
   across north.
3. **Given** the Qibla is behind me, **When** I read the title, **Then** it names the shorter way
   round, never more than 180°.
4. **Given** the needle is outside ±10°, **When** it comes inside ±10°, **Then** the approach
   haptic fires once.
5. **Given** reduce motion is on, **When** the heading changes, **Then** the needle moves in 300 ms
   with no overshoot.
6. **Given** the app in Arabic, **When** I open the screen, **Then** the copy and digits are Arabic,
   the back arrow points the Arabic way, and the dial, needle and "right/left" are never mirrored.

---

### User Story 2 - Know that I'm facing it (Priority: P1)

When I hold within 3° for a moment the screen says "Facing the Qibla · Hold steady", the ring and
the top tick turn accent, the ring pulses twice and the phone gives one success haptic. If I drift
off, it goes back to telling me which way to turn.

**Why this priority**: The confirmation is what lets me put the phone down and pray without
staring at the needle.

**Independent Test**: In the design scenario switch the heading to 119°: the screen matches 4.06.
With scripted headings in London: 116° held for 399 ms doesn't align, 400 ms does; 123.9° stays
aligned; 124.1° goes back to "Turn 5° left".

**Acceptance Scenarios**:

1. **Given** the difference stays within ±3° for 400 ms without a break, **When** the 400 ms are up,
   **Then** the title is "Facing the Qibla", the subtitle "Hold steady", the ring and top tick turn
   accent, the glow shows, the ring pulses twice (Motion 10) and the success haptic fires once.
2. **Given** I am aligned, **When** the difference moves around within ±5°, **Then** it stays
   aligned with no new pulse and no new haptic.
3. **Given** I am aligned, **When** the difference goes past ±5°, **Then** the turning state comes
   back with its instruction, and aligning again takes another 400 ms within ±3° and fires the
   haptic again.
4. **Given** reduce motion is on, **When** I align, **Then** only the colors change, no pulses and
   no glow loop, and the haptic still fires.

---

### User Story 3 - When the compass can't be trusted (Priority: P2)

Near a laptop or in a car the compass gets confused. The accuracy card tells me, and the hint under
it tells me how to fix it.

**Why this priority**: A confident needle pointing the wrong way is worse than no needle. The
design shows "High" only, the weaker levels need a look and a hint.

**Independent Test**: Feed accuracy levels to the screen: High shows a success dot, Medium a
warning dot, Low an error dot and the calibration hint. Back to High, the normal hint returns.

**Acceptance Scenarios**:

1. **Given** the phone reports its compass accuracy, **When** it changes, **Then** the card shows
   High, Medium or Low with the matching dot.
2. **Given** accuracy is Low, **When** I look at the hint, **Then** it tells me how to calibrate.
3. **Given** accuracy goes back to Medium or High, **When** I look at the hint, **Then** it is
   "Hold your phone flat, away from metal and magnets." again.

---

### User Story 4 - No compass, or no location (Priority: P2)

Some Android phones have no compass. Some people haven't given a location yet. The screen still
helps where it can and says plainly what is missing.

**Why this priority**: Both happen on real phones, and the design shows neither.

**Independent Test**: With no compass the dial stays north up, the needle and Kaaba marker sit at
the bearing, the title says the phone has no compass. With no location the dial turns, there is no
marker or needle, and "Use my location" and "Choose a city instead" open the location sheet.

**Acceptance Scenarios**:

1. **Given** the phone has no compass, **When** I open Qibla, **Then** the dial stays north up, the
   Kaaba marker and the needle sit at the bearing, the subtitle and distance show as usual and the
   accuracy card says the compass is not available.
2. **Given** no location is saved, **When** I open Qibla, **Then** the dial still turns with the
   heading, there is no Kaaba marker, no needle and no distance, and "Use my location" and "Choose
   a city instead" show in place of the hint.
3. **Given** that state, **When** I tap either button, **Then** the location sheet opens the same
   way Home's no location card opens it.
4. **Given** a location arrives while the screen is open, **When** it is saved, **Then** the marker,
   needle, subtitle and distance show at once.

---

### Edge Cases

- Exactly 180° off: the title says "Turn 180° right".
- Difference under 0.5° before the 400 ms are up: the title says "Turn 1° right" or "left", never
  "0°".
- The heading crosses north (359° to 1°): the dial and needle take the short way, nothing spins
  round.
- Jitter on a boundary (±3°, ±5°, ±10°): one haptic per approach and per alignment, never a
  stutter of them.
- Opening the screen already within ±10°: no approach haptic, nothing was entered. Within ±3°: it
  aligns after 400 ms like any other time.
- App to the background or the screen left: the compass stops. Coming back, the screen starts in
  the turning state and aligns again after 400 ms.
- Location changes while the screen is open (new fix, city picked): bearing, distance and subtitle
  update, the marker moves and the needle springs to it.
- Inside Makkah: the bearing changes a lot with a few kilometres, so it is worked out from where
  the phone is, not the saved place.
- Location allowed but no fix yet (indoors, first seconds): the saved location is used until the
  fix comes, then the needle springs to the new bearing.
- Under 1 km from the Kaaba the distance shows in metres.
- A city picked by hand: the Qibla is from that city's point, with no fix.
- The screen turned to landscape: the needle still points the right way.
- The phone held upright: the hint already asks for it flat, there is no tilt warning.
- Text scale 2.0: the title wraps, the page scrolls, nothing is cut.
- Tablets: the phone layout stretched to 480 pt as everywhere else, the dial keeps its size.
- 4,790 km in Arabic: Eastern Arabic digits with the Arabic group separator.

## Requirements *(mandatory)*

### Functional Requirements

**The screen**

- **FR-001**: The Qibla screen MUST match 4.05 (turning) and 4.06 (aligned) as specified in the
  handoff, in dark and light: back, title, gear, instruction, subtitle, dial, needle, top tick, the
  two cards and the hint. Arabic has no PNG, it follows the same tree with the RTL rules.
- **FR-002**: The screen MUST be a pushed page reached from More. Until milestone 9 builds More's
  tiles, a temporary Qibla tile on the More placeholder pushes it.

**Heading**

- **FR-003**: The heading MUST be the direction the top of the phone points, in degrees from true
  north, smoothed so the needle doesn't shake while the phone lies still.
- **FR-004**: Where the phone only gives magnetic north, the heading MUST be corrected by the
  magnetic declination at the position, worked out on the phone with no network.
- **FR-005**: The needle MUST point the right way whatever the screen's rotation.
- **FR-006**: The compass MUST be read only while the Qibla screen is visible and the app is in
  front.

**Position, bearing and distance**

- **FR-007**: The bearing MUST be the great circle direction from the position to the Kaaba
  (21.4225° N, 39.8262° E), from true north. The subtitle shows it rounded to the whole degree with
  the place name: "{city} · Qibla at {deg}° from north".
- **FR-008**: The position MUST come from the saved location (milestone 2). When the location is
  automatic and allowed, a fresh fix MUST be taken while the screen is open and used for the
  bearing and distance only, never saved as the location. A city picked by hand is used as it is,
  with no fix.
- **FR-009**: The distance MUST be the great circle distance to the Kaaba, rounded to 10 km from
  100 km up, to the whole km below 100 km, and to 10 m below 1 km, with the locale's digits and
  group separator.

**Dial and needle**

- **FR-010**: The dial (ticks, letters, Kaaba marker) MUST turn by minus the heading, at once. The
  Kaaba marker sits on the dial at the bearing. The letters are N E S W in English and ش ق ج غ in
  Arabic, and stay upright as the dial turns, like in the PNG.
- **FR-011**: The needle MUST point at bearing minus heading and follow with spring.needle
  (Motion 09), the short way across 0°/360°. A new reading retargets the spring from where it is
  and how fast it moves, never queues. Reduce motion: standard 300 ms, no overshoot.
- **FR-012**: The dial, the needle and "right/left" MUST never mirror in Arabic.

**Instruction**

- **FR-013**: The difference MUST be the shortest signed angle from the heading to the bearing,
  more than −180° and up to 180°. Positive reads "Turn {deg}° right", negative "Turn {deg}° left",
  with the difference rounded and never below 1.
- **FR-014**: The instruction and the alignment MUST use the smoothed heading, not the needle's
  position mid spring.

**Alignment and haptics**

- **FR-015**: The screen MUST become aligned when the difference stays within ±3° for 400 ms
  without a break, and stay aligned until it goes past ±5°.
- **FR-016**: On aligning: title "Facing the Qibla", subtitle "Hold steady", ring and top tick in
  accent, the glow, two ring pulses of 900 ms (Motion 10), the needle's small breathe while
  aligned, and the Qibla aligned haptic once. Reduce motion: colors only, no pulses, glow or
  breathe, the haptic still fires.
- **FR-017**: The approach haptic MUST fire once when the difference comes inside ±10°, and fire
  again only after the difference has gone past ±15°.
- **FR-018**: Both haptics MUST follow the in-app haptics switch.

**Accuracy**

- **FR-019**: The accuracy card MUST show High, Medium or Low from what the phone reports, with a
  success, warning or error dot.
- **FR-020**: At Low the hint MUST change to the calibration hint, at Medium or High it MUST be the
  designed hint.

**No compass, no location**

- **FR-021**: With no compass: the dial north up and still, the Kaaba marker and the needle at the
  bearing, title "No compass on this phone", the subtitle and distance as usual, accuracy "Not
  available", and a hint to line the dial up with north. No haptics.
- **FR-022**: With no location: the dial turns with the heading, no Kaaba marker, no needle, title
  "No location yet", subtitle "The Qibla needs your location or a city.", the distance card shows
  "—", and "Use my location" and "Choose a city instead" in place of the hint. Both open the
  location sheet the way Home's no location card does.
- **FR-023**: These states have no PNG, so they MUST be built only from parts in
  `03 Components.dc.html` and the Qibla screens, and I check them in the app before they count
  as done.

**Gear**

- **FR-024**: The gear MUST open the location sheet. A new place there updates the screen at once.

**Copy and access**

- **FR-025**: Every new string MUST exist in English and Arabic with this wording. The no location
  title and buttons reuse Home's existing "No location yet", "Use my location" and "Choose a city
  instead".

  | Where | English | Arabic |
  | --- | --- | --- |
  | distance card | {distance} km | {distance} كم |
  | distance under 1 km | {distance} m | {distance} م |
  | accuracy | Medium | متوسطة |
  | accuracy | Low | منخفضة |
  | hint at Low | Move your phone in a figure 8 to calibrate the compass. | حرّك هاتفك على شكل الرقم 8 لمعايرة البوصلة. |
  | title, no compass | No compass on this phone | لا توجد بوصلة في هذا الهاتف |
  | accuracy, no compass | Not available | غير متوفرة |
  | hint, no compass | Turn the N on the dial to north to see the Qibla. | وجّه الشمال في القرص نحو الشمال لترى القبلة. |
  | subtitle, no location | The Qibla needs your location or a city. | القبلة تحتاج موقعك أو مدينة. |
  | dial letters | N, E, S, W | ش، ق، ج، غ |
  | dial, for screen readers | Qibla compass | بوصلة القبلة |

- **FR-026**: A screen reader MUST hear the instruction, the bearing, the distance and the
  accuracy, MUST hear "Facing the Qibla" once on aligning, and MUST NOT hear every degree change.
- **FR-027**: Every action MUST be at least 44 x 44, contrast MUST meet WCAG AA in both modes, and
  at text scale 2.0 the page MUST scroll with nothing cut.

**Privacy**

- **FR-028**: The heading and the fresh fix MUST never be stored, never leave the phone and never
  reach crash reports. The screen MUST NOT use the network.

**Design scenario**

- **FR-029**: "Dev · design scenario" MUST show the Qibla from London (51.5074° N, 0.1278° W) with
  the heading frozen at 105° for 4.05, and a tap on the dial switching to 119° for 4.06 and back,
  in the design scenario only, so both can be seen on a phone.

### Key Entities

- **Compass reading**: the smoothed heading from true north and the accuracy level, or none when
  the phone has no compass.
- **Qibla target**: the bearing and the distance to the Kaaba from the position, and the place name
  for the subtitle.
- **Qibla state**: turning (with the difference) or aligned, plus whether the approach haptic is
  armed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In the design scenario the screen is built from the 4.05 and 4.06 trees in dark and
  light.
- **SC-002**: For 20 test places on every continent, both hemispheres, near the date line and
  inside Makkah, the bearing is within 0.5° and the distance within 0.5% of a reference geodesic
  calculation.
- **SC-003**: On a real phone with High accuracy, in a known place, the needle points within 5° of
  a reference compass corrected to true north.
- **SC-004**: Lying still, the needle moves less than 1°. After a 90° turn it settles in about
  1 s (Motion 09, ≈1030 ms).
- **SC-005**: In a scripted run of headings with ±1° jitter on every boundary, each approach and
  each alignment fires its haptic exactly once.
- **SC-006**: The screen works in airplane mode and makes no network request.
- **SC-007**: Leaving the screen or the app stops the compass within 1 s.
- **SC-008**: At text scale 2.0 nothing is cut, every action is at least 44 x 44, contrast meets
  WCAG AA in both modes.

## Assumptions

- The app always uses true north. No true/magnetic setting.
- No tilt warning. The designed hint already asks for the phone flat.
- Distance is in km everywhere, as designed, also in places that use miles.
- The aligned sound in the haptics table comes with "UI sounds" in More (milestone 9), not here.
- The screen doesn't keep the phone awake.
- The Kaaba point is fixed at 21.4225° N, 39.8262° E.
- The location sheet and the offline city search are the ones milestone 3 built, used as they are.
- No tab bar on this screen, as designed.
- More's real Qibla tile and the in-app haptics switch come in milestone 9, this milestone only
  reads the switch.
