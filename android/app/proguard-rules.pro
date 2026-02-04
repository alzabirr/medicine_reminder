# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep notification classes
-keep class com.dexterous.** { *; }
-keep class androidx.work.** { *; }

# Keep timezone database
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Hive
-keep class io.hive.** { *; }
-keepnames class io.hive.** { *; }
-keep class * extends io.hive.TypeAdapter { *; }

# Awesome Notifications
-keep class me.carda.awesome_notifications.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Ignore warnings for missing Play Core classes (deferred components not used)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.**
-ignorewarnings

