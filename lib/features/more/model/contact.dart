/// where people reach me from CONTACT, a null row isn't shown (FR-044)
class Contact {
  const Contact({
    this.developerName,
    this.website,
    this.appStoreUrl,
    this.playStoreUrl,
    this.privacyPolicyUrl,
  });

  final String? developerName;

  /// https only, the system channel refuses anything else
  final String? website;
  final String? appStoreUrl;
  final String? playStoreUrl;
  final String? privacyPolicyUrl;

  static const mine = Contact(
    developerName: "Ahmed Abdo Elhawary",
    website: "https://www.linkedin.com/in/ahmedabdoelhawary/",
    privacyPolicyUrl: "https://ahmedabdoelhawary.github.io/better-muslim-content/privacy/",
    // TODO(ahmed): the App Store link once the app is listed, Share on iOS waits for it.
    appStoreUrl: null,
    playStoreUrl: "https://play.google.com/store/apps/details?id=com.elhawary.bettermuslim",
  );
}
