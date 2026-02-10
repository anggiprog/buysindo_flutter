import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

// Load key.properties untuk signing config
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// Ambil variabel dari Laravel Job (-PversionCode & -PversionName)
val flutterVersionCode = if (project.hasProperty("versionCode")) {
    project.property("versionCode").toString()
} else {
    localProperties.getProperty("flutter.versionCode") ?: "1"
}

val flutterVersionName = if (project.hasProperty("versionName")) {
    project.property("versionName").toString()
} else {
    localProperties.getProperty("flutter.versionName") ?: "1.0.0"
}

android {
    // Namespace default (akan dioverride oleh applicationId di bawah)
    namespace = "com.buysindo.app"
    // compileSdk 36 diperlukan oleh androidx.core:core-ktx:1.17.0 (compile-time only, aman)
    compileSdk = 36
    // NDK version (opsional, biarkan Gradle memilih versi default yang tersedia)
    // ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Mengaktifkan core library desugaring yang diperlukan oleh beberapa AAR (mis. flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
        // Suppress warnings about obsolete options
        freeCompilerArgs += listOf("-Xlint:-options")
    }

    defaultConfig {
        // Determine applicationId from project property or fallback to namespace
        val customPackageName = if (project.hasProperty("appPackage")) {
            project.property("appPackage").toString()
        } else {
            // Keep consistent with the module namespace
            "com.buysindo.app"
        }
        applicationId = customPackageName

        // 2. Ambil Nama Aplikasi dari Laravel (-PappName)
        val customAppName = if (project.hasProperty("appName")) {
            project.property("appName").toString()
        } else {
            "Buysindo App"
        }
        resValue("string", "app_name", customAppName)

        // minSdk 23 = Android 6.0 Marshmallow (sesuai config Android Studio yang berhasil di Redmi 10A)
        minSdk = flutter.minSdkVersion
        // targetSdk 36 untuk Android 16 (sesuai config Android Studio yang berhasil)
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName

        // 16KB page size support (required for Android 15+ devices)
        // Note: abiFilters removed to allow --split-per-abi builds
        // When building fat APK, all supported ABIs will be included
        ndk {
            // Kosongkan untuk mendukung split-per-abi
            // Jika ingin fat APK, uncomment baris di bawah:
            // abiFilters += listOf("armeabi-v7a", "arm64-v8a")
        }
    }

    signingConfigs {
        create("release") {
            // Prioritas 1: Parameter dari Laravel Job
            if (project.hasProperty("ksFile")) {
                val ksFilePath = project.property("ksFile").toString()
                storeFile = file(ksFilePath)
                storePassword = project.property("ksPass").toString()
                keyAlias = if (project.hasProperty("ksAlias")) {
                    project.property("ksAlias").toString()
                } else {
                    "buysindo"
                }
                keyPassword = project.property("ksPass").toString()
            }
            // Prioritas 2: Dari key.properties (untuk local build)
            else if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
            // Enable v1 dan v2 signing untuk kompatibilitas maksimal dengan MIUI/Xiaomi
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            // Menggunakan signingConfig release yang dibuat di atas
            signingConfig = signingConfigs.getByName("release")
            
            isMinifyEnabled = false
            // Ensure resource shrinking is not enabled unless code shrinking (minify) is enabled
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

// Tambahkan blok dependencies untuk coreLibraryDesugaring
dependencies {
    // Versi desugar terbaru kompatibel pada banyak proyek; ganti jika ingin versi lain
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    // Ensure Material Components and AppCompat are present so Theme.MaterialComponents.* is resolved
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}

// Opsional: Memastikan clean berjalan jika diperlukan,
// namun biasanya Laravel Job sudah menjalankan 'flutter clean' secara eksplisit.
