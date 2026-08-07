# Flutter engine
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# App entry points (MainActivity and related)
-keep class com.rtk.salonhub.** { *; }

# Keep annotations (needed by several plugins at runtime)
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature

# WebView interfaces
-keepclassmembers class * { @android.webkit.JavascriptInterface <methods>; }

# Firebase / Google Play services ship their own consumer rules; silence noisy warnings.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**

# Razorpay Checkout SDK
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !method/inlining/
-keepclasseswithmembers class * {
  public void onPayment*(...);
}
