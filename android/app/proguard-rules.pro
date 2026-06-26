# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase / Google Play Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings { *; }
-keepclassmembers class kotlin.Lazy { *; }

# Dio / OkHttp (네트워크)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# flutter_secure_storage (EncryptedSharedPreferences)
-keep class androidx.security.crypto.** { *; }

# 직렬화 관련 (JSON 파싱 보호)
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
