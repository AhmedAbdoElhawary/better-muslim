# Contract: the system channel, two more calls

Milestone 9's `better_muslim/system` channel (`specs/004-milestone-9-more/contracts/system-channel.md`)
gets two methods for CONTACT. The three existing ones don't change.

## Method channel `better_muslim/system`

| Method | Arguments | Result |
| --- | --- | --- |
| `mail` | `{"to": String, "subject": String, "body": String}` | `true` when a mail app opened the draft, `false` otherwise |
| `device` | none | `{"model": String, "os": String}`, like `{"model": "iPhone15,2", "os": "iOS 26.1"}` or `{"model": "Google Pixel 8", "os": "Android 16"}` |

No other errors. An unknown method answers not implemented, as now.

## iOS (`ios/Runner/AppDelegate.swift`, `registerSystem`)

- `mail`: a `mailto:` url built with `URLComponents` (the address as the path, `subject` and `body`
  as query items, so spaces and Arabic are encoded), then `UIApplication.shared.open(url)`, the
  completion's success is the result. No `canOpenURL`, so no `LSApplicationQueriesSchemes` entry.
- `device`: `utsname` machine for the model, `"iOS " + UIDevice.current.systemVersion` for the os.

## Android (`MainActivity.configureFlutterEngine`)

- `mail`: `Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))` with `EXTRA_EMAIL` (an array with
  `to`), `EXTRA_SUBJECT` and `EXTRA_TEXT`. `ActivityNotFoundException` → `false`, like `openUrl`. No
  `<queries>` entry needed, nothing is resolved first.
- `device`: `"${Build.MANUFACTURER} ${Build.MODEL}"` (the manufacturer left out when the model
  already starts with it) and `"Android ${Build.VERSION.RELEASE}"`.

## Dart side (`core/system/system_channel.dart`)

- `static Future<bool> mail({required String to, required String subject, required String body})`
- `static Future<({String model, String os})> device()`, empty strings when the phone answers
  nothing.
- Nothing is sent by the app: the draft opens in the mail app and I send it or not
  (constitution VII). `openUrl` stays https only, `mail` is the only way to a `mailto:`.
- Tests mock the channel with `TestDefaultBinaryMessengerBinding`, as the existing ones.

## Who calls it

`features/more/view/widgets/contact_section.dart`:
- Send feedback: `mail(to: Contact.email, subject: tr(feedbackSubject), body: tr(feedbackBody,
  {version, device, os}))`. `false` → the toast "No mail app. Write to {email}".
- Rate: `openUrl(appStoreUrl)` on iOS, `openUrl(playStoreUrl)` on Android.
- Developer: `openUrl(website)`.
- Share: `core/system/share.dart` (share_plus) with the share line and the platform's store link.
