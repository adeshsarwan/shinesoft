# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile
# EventBus
-keepattributes *Annotation*
-keepclassmembers class ** {
    @org.greenrobot.eventbus.Subscribe <methods>;
}
-keep enum org.greenrobot.eventbus.ThreadMode { *; }

# Keep `Companion` object fields of serializable classes.
# This avoids serializer lookup through `getDeclaredClasses` as done for named companion objects.
-if @kotlinx.serialization.Serializable class **
-keepclassmembers class <1> {
    static <1>$Companion Companion;
}

# Keep `serializer()` on companion objects (both default and named) of serializable classes.
-if @kotlinx.serialization.Serializable class ** {
    static **$* *;
}
-keepclassmembers class <2>$<3> {
    kotlinx.serialization.KSerializer serializer(...);
}

# Keep `INSTANCE.serializer()` of serializable objects.
-if @kotlinx.serialization.Serializable class ** {
    public static ** INSTANCE;
}
-keepclassmembers class <1> {
    public static <1> INSTANCE;
    kotlinx.serialization.KSerializer serializer(...);
}
-keep class * extends com.google.gson.reflect.TypeToken

-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Keep Retrofit interfaces
-keep interface * implements retrofit2.Call

# Keep your model classes


# Retrofit
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**

# Gson
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**


# Keep all interface methods for Retrofit
#-keep interface com.hdvplayer.hdviddownloader.storyvideosave.adSetStru.QuizAdManege { *; }
# Gson
-keep class com.android.installreferrer.** { *; }
-dontwarn com.android.installreferrer.**

# Keep AIDL interfaces (if any future updates require it)
-keep interface com.android.installreferrer.** { *; }
-dontwarn com.facebook.infer.annotation.Nullsafe$Mode
-dontwarn com.facebook.infer.annotation.Nullsafe
-dontwarn javax.activation.DataSource
-dontwarn javax.mail.internet.MimeMultipart


# Retrofit Generic Models

-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}



# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.facebook.infer.annotation.Nullsafe$Mode
-dontwarn com.facebook.infer.annotation.Nullsafe
-dontwarn javax.activation.DataSource
-dontwarn javax.mail.internet.MimeMultipart

#Let ProGuard rename everything, including activities
-dontskipnonpubliclibraryclasses
-dontskipnonpubliclibraryclassmembers


# FIX for Gson deserialization crash (ClassCastException)



# User Added Rules
-keep class com.snapdrama.shortstream.activity.main.fragment.MyListFragment { *; }
-keep class com.snapdrama.shortstream.activity.main.fragment.ProfileFragment { *; }

# Keep Models
-keep class com.snapdrama.shortstream.model.** { *; }
-keep class com.snapdrama.shortstream.**.model.** { *; }

# Google Authentication
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.api.ApiException { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.snapdrama.shortstream.engineBox.model.** { *; }
-keep class com.snapdrama.shortstream.activity.main.fragment.my_list.model.ContinueWatchingModel { *; }
-keep class com.snapdrama.shortstream.activity.main.fragment.my_list.model.MySubListModel { *; }
-keep class com.snapdrama.shortstream.activity.login.auth.AuthManager { *; }
-keepclassmembers class com.snapdrama.shortstream.activity.login.auth.AuthManager {
    public *;
}
-keep class com.google.firebase.auth.** { *; }
-keep class  com.google.firebase.auth.FirebaseUser { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.signin.internal.** { *; }


-keep class com.stripe.** { *; }
-dontwarn com.stripe.**

-keep class com.stripe.android.paymentsheet.** { *; }


-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

-keep class okhttp3.** { *; }
-dontwarn okhttp3.**


-keep class okio.** { *; }
-dontwarn okio.**


-keep class org.json.** { *; }


-keep class com.github.kittinunf.fuel.** { *; }
-dontwarn com.github.kittinunf.fuel.**

-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**




