plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Plugin do Firebase
    // Use o id completo do plugin Kotlin Android (forma preferida nas versões recentes)
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.gestorfy"
    // Utilize as versões fornecidas pelo plugin Flutter para manter alinhado ao SDK suportado
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
        applicationId = "com.example.gestorfy"
        // Em Kotlin DSL a sintaxe correta é 'minSdk = 24' ou usar a constante do Flutter
        // minSdk = 24
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
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


