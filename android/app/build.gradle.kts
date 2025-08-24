plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Plugin do Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gestorfy"
    compileSdk = 35
    ndkVersion = "27.0.12077973" // Versão recomendada pelo erro anterior

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.gestorfy"
        minSdk = 23 // firebase_auth exige minSdk 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}


