plugins {
    id("com.android.application")
    id("kotlin-android")
    // Plugin Flutter
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin Google Services (Firebase) dimasukkan di sini untuk Kotlin DSL
    id("com.google.gms.google-services")
}

android {
    namespace = "com.zayyana.siap_gerak"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.zayyana.siap_gerak"
        
        // --- PERUBAHAN PENTING DI SINI ---
        // Firebase butuh minimal sdk 21/23. 
        // Jangan pakai flutter.minSdkVersion, ganti manual ke 23.
        minSdk = flutter.minSdkVersion 
        // ---------------------------------
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
