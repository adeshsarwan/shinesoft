import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.flixotv.ignia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.flixotv.ignia"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 14
        versionName = "1.1.3"
    }

    // flavorDimensions += "platform"

    // productFlavors {
    //     create("mobile") {
    //         dimension = "platform"
    //         versionNameSuffix = "-mobile"
    //         resValue("string", "app_name", "Flixo TV")
    //     }
    //     create("tv") {
    //         dimension = "platform"
    //         versionNameSuffix = "-tv"
    //         resValue("string", "app_name", "Flixo TV")
    //     }
    // }

    // Per-ABI APKs: use `flutter build apk --split-per-abi` (see build_apks.sh).
    // Do not declare splits.abi here — when split-per-abi is off, the Flutter plugin
    // sets ndk.abiFilters and AGP rejects having both.

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled   = true   // R8 code shrinking
            isShrinkResources = true   // remove unused resources
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled   = false
            isShrinkResources = false
        }
    }

    // ── Bundle configuration for AAB generation ────────────────────────────
    bundle {
        language {
            // Enable language split
            enableSplit = true
        }
        density {
            // Enable density split
            enableSplit = true
        }
        abi {
            // Enable ABI split
            enableSplit = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Align with google_mobile_ads plugin; ensures latest client is packaged in the APK.
    implementation("com.google.android.gms:play-services-ads:24.9.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}
