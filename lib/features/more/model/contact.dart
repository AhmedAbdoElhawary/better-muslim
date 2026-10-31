/// where people reach me from CONTACT, a null row isn't shown (FR-044)
class Contact {
  const Contact({
    this.email,
    this.developerName,
    this.website,
    this.appStoreUrl,
    this.playStoreUrl,
  });

  final String? email;
  final String? developerName;

  /// https only, the system channel refuses anything else
  final String? website;
  final String? appStoreUrl;
  final String? playStoreUrl;

  static const mine = Contact(
    email: "elhawarydev@gmail.com",
    developerName: "Ahmed Abdo Elhawary",
    website: "https://www.linkedin.com/in/ahmedabdoelhawary/",
    // TODO(ahmed): the App Store link once the app is listed, Rate and Share on iOS use it.
    appStoreUrl: null,
    playStoreUrl: "https://play.google.com/store/apps/details?id=com.elhawary.bettermuslim",
  );
}
