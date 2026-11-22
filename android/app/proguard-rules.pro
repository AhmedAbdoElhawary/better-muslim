# R8 removes any class it can't see a reference to. It can't see classes reached by
# reflection, over JNI, or named only in a string, so those are listed here or the
# build passes and the app crashes on a device. Libraries ship their own consumer rules.

# the engine reaches the embedding over JNI
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# the embedding references play core split-install, only present with deferred components.
# if deferred components are ever added, remove this and add the play-core dependency.
-dontwarn com.google.android.play.core.**

# sentry reads class and method names to build an event
-keep class io.sentry.** { *; }
-keepattributes SourceFile,LineNumberTable

# kotlin coroutines internals are reached reflectively
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
-dontwarn kotlinx.coroutines.**

# referenced by transitive deps but never shipped, R8 stops on them otherwise
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# enum values are looked up by name via valueOf()
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# the framework reads CREATOR reflectively
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
