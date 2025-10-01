plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

/** Evitar clases duplicadas de androidx.activity forzando UNA versión */
configurations.all {
    resolutionStrategy.eachDependency {
        if (requested.group == "androidx.activity") {
            useVersion("1.9.2")
            because("evitar duplicados de androidx.activity(.ktx).R")
        }
    }
}

android {
    namespace = "com.example.incognito_chat"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    defaultConfig {
        applicationId = "com.example.incognito_chat"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["applicationName"] = "io.flutter.app.FlutterApplication"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    buildFeatures {
        viewBinding = true
    }
    dependenciesInfo {
        includeInApk = true
        includeInBundle = true
    }
    buildToolsVersion = "36.0.0"
}

flutter { source = "../.." }