# Contract: the onboarding routes

In `core/router/app_router.dart`, which may import features.

## Routes

| Path | Page | Transition |
| --- | --- | --- |
| `/onboarding` | `WelcomePage` (features/onboarding): the first screen and 4.10 | none, it is the first route. Its `StepScope` gives the secondary animation for FR-015 |
| `/onboarding/location` | `LocationStepPage` (features/onboarding): 4.11 | step page, 900 ms in, 150 ms out |
| `/onboarding/notifications` | `NotificationsStepPage` (features/notifications): 4.12 | step page |
| `/onboarding/theme` | `ThemePage(onboarding: true)` (features/theme_picker): 4.15 without back | step page |

Each step is pushed from the one before (`context.push`), so the system back and the edge swipe pop
to the previous step (FR-018). The welcome rebuilds when 4.11 pops off it. On `/onboarding` a
`PopScope` lets back leave the app only on the first screen; on 4.10 back sinks the sun to the
first screen.

## Redirect

| Onboarding | Target | Goes to |
| --- | --- | --- |
| not done, or replaying | `/onboarding…` or `/adhan` | stays |
| not done, or replaying | anything else | `/onboarding` |
| done, not replaying | `/onboarding…` | `/` |
| done, not replaying | anything else | stays |

The router listens to `onboardingProvider` and calls `refresh()` on a change.

## Finishing

Apply theme → `themePreview.apply()` → `onboarding.finish()` (writes `onboarded`, clears replay) →
`context.go(Routes.home)`. The shell route's page fades in over 300 ms.

## Step scope

`StepScope(animation, secondaryAnimation)` wraps every step page from the page's
`transitionsBuilder`. `StepReveal(index)` and `StepDots(step)` read it, and are plain without it.

| Slot | Interval of the 900 ms | What |
| --- | --- | --- |
| background | 0 to 0.33 | fade in over the page below |
| 0 | 0.33 to 0.60 | title, with 4.11's icon tile above it: rise 14 pt, fade |
| 1 | 0.40 to 0.67 | body |
| 2 | 0.47 to 0.80 | cards or rows |
| 3 | 0.60 to 1.00 | buttons: rise 14 pt, fade |
| covered | secondary 0 to 0.17 | a step page below fades its content out (150 ms) |
| welcome covered | secondary 0 to 0.33 | the welcome fades out in reverse build order: buttons, tagline, title, stars, mark and horizon (300 ms, FR-015) |

Reduce motion: 300 ms, every slot a fade over the whole of it.
