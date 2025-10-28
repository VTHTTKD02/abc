plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.todolistappdemo"
    compileSdk = flutter.compileSdkVersion.toInt() // Thường là 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ===== SỬA LẠI TÊN THUỘC TÍNH (cho AGP 8+) =====
        isCoreLibraryDesugaringEnabled = true // <-- THÊM "is" Ở ĐẦU
        // =============================================
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.todolistappdemo"
        multiDexEnabled = true
        minSdk = flutter.minSdkVersion
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

dependencies {
    implementation(kotlin("stdlib-jdk7"))
    // Đảm bảo dòng này cũng dùng cú pháp Kotlin ()
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}