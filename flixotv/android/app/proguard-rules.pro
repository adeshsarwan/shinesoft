# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# media_kit / libmpv
-keep class com.alexmercerind.** { *; }
-dontwarn com.alexmercerind.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Google IMA (interactive_media_ads)
-keep class com.google.ads.interactivemedia.** { *; }
-dontwarn com.google.ads.interactivemedia.**

# Firebase Cloud Messaging
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep all annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

# Stripe (flutter_stripe / Payment Sheet)
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-dontwarn kotlinx.parcelize.Parceler$DefaultImpls
-dontwarn kotlinx.parcelize.Parceler
-dontwarn kotlinx.parcelize.Parcelize
-keep class com.stripe.** { *; }
