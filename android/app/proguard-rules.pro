# SoloForte — regras R8/ProGuard (release)

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / Postgrest
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Gson / JSON (dependências transitivas)
-keepattributes Signature
-keepattributes *Annotation*

# Flutter deferred components / Play Core (opcional — app não usa split APKs)
-dontwarn com.google.android.play.core.**
