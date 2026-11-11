# Disable aggressive bytecode optimizations that break Flutter FFI/JNI reflection
-dontoptimize

# =====================================================================
# Flutter Embedding & MainActivity
# =====================================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class br.com.innominata.mysweethome.MainActivity { *; }

# Flutter Deferred Components (Play Core)
-dontwarn com.google.android.play.core.**

-keepattributes InnerClasses
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# =====================================================================
# SQLite / Drift (sqlite3_flutter_libs)
# =====================================================================
-keep class com.simolus3.sqlite3_flutter_libs.** { *; }
-dontwarn com.simolus3.sqlite3_flutter_libs.**
-keep class org.sqlite.** { *; }

# =====================================================================
# Flutter Local Notifications & Gson
# =====================================================================
-dontwarn sun.misc.**

# Prevent ProGuard from stripping interface information from Gson adapters
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8/ProGuard from stripping serialized notification payload fields
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-keep class com.dexterous.flutterlocalnotifications.** { *; }

# =====================================================================
# Flutter Secure Storage & Tink Crypto
# =====================================================================
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# =====================================================================
# Google ML Kit & Google Play Services / Firebase Components
# =====================================================================
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.internal.mlkit_* { *; }
-dontwarn com.google.android.gms.internal.mlkit_*
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# =====================================================================
# Flutter Plugins & Embedding Architecture
# =====================================================================
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.embedding.engine.plugins.activity.ActivityAware { *; }
-keep class * implements io.flutter.embedding.engine.plugins.service.ServiceAware { *; }
-keep class * implements io.flutter.embedding.engine.plugins.broadcastreceiver.BroadcastReceiverAware { *; }
-keep class * implements io.flutter.embedding.engine.plugins.contentprovider.ContentProviderAware { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry$PluginRegistrantCallback { *; }

# =====================================================================
# CameraX & Dart JNI
# =====================================================================
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**
-keep class io.flutter.plugins.camerax.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }

# =====================================================================
# File Picker & Community Plus Plugins
# =====================================================================
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }

-keepclasseswithmembernames class * {
    native <methods>;
}

-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

