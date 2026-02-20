plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.patient_history_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.patient_history_app"
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

dependencies {
    // Import the Firebase BoM (Bill of Materials) to manage Firebase library versions.
    // This ensures all Firebase libraries you use are compatible with each other.
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))

    // Add the Firebase Firestore dependency.
    // When using the BoM, you don't specify the version number for individual Firebase libraries.
    implementation("com.google.firebase:firebase-firestore")

    // You might also need other Firebase dependencies here, for example:
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-analytics")
}


