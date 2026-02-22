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
    namespace = "com.buysindostore.app"
    // compileSdk 36 diperlukan oleh androidx.core:core-ktx:1.17.0 (compile-time only, aman)
    compileSdk = 36
    // NDK version untuk 16KB page size alignment support
    // Versi 27.0+ support proper 16KB alignment untuk Android 12+
    ndkVersion = "27.0.12077973"

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
            "com.buysindostore.app"
        }
        applicationId = customPackageName

        // 2. Ambil Nama Aplikasi dari Laravel (-PappName)
        val customAppName = if (project.hasProperty("appName")) {
            project.property("appName").toString()
        } else {
            "Buysindo App"
        }
        resValue("string", "app_name", customAppName)

        // minSdk 31 REQUIRED untuk proper 16KB page size alignment support pada Play Store
        // CRITICAL: minSdk < 31 tidak akan support 16KB alignment dengan optimal
        // Android 12+ (API 31+) fully supported 16KB page size alignment
        minSdk = 31
        // targetSdk 36 REQUIRED untuk 16KB page size support declaration ke Play Store (Android 15+)
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName

        // 16KB page size support - CRITICAL for Android 15+ and Play Store
        // IMPORTANT: Ini adalah deklarasi ke Play Store bahwa app FULLY SUPPORTS 16KB page size
        // Tanpa setting ini dengan benar, Play Store akan menolak atau memberi warning
        ndk {
            // Support both 4KB (armeabi-v7a) dalam 4KB alignment dan 16KB (arm64-v8a) dalam 16KB alignment
            // CRITICAL: BOTH ABIs harus di-list untuk proper 16KB page size support:
            // - armeabi-v7a: untuk backward compatibility Android 6.0+ (4KB page size)
            // - arm64-v8a: untuk Android 15+ (dapat menggunakan 16KB-aligned native libraries)
            abiFilters.clear()
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
        
        // Manifest placeholders for proper app identification
        manifestPlaceholders["appPackage"] = customPackageName
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
    
    // Bundle configuration for proper ABI splits (16KB page size support)
    // CRITICAL: This ensures Play Store gets the right AAB variants per device with proper 16KB alignment
    bundle {
        abi {
            // CRITICAL: Enable ABI splits - Play Store REQUIRES this for 16KB page size support
            // When enabled, Play Store akan generate:
            // 1. APK untuk arm64-v8a devices (dapat use 16KB-aligned native libs di Android 15+)
            // 2. APK untuk armeabi-v7a devices (uses 4KB alignment, backward compatible)
            enableSplit = true
        }
        language {
            // Jangan split bahasa, fokus ke ABI split untuk 16KB support
            enableSplit = false
        }
        density {
            enableSplit = false
        }
        texture {
            enableSplit = false
        }
    }
    
    // 16KB Page Size Support - Packaging Configuration (AGP 8.1+)
    // CRITICAL: Native libraries harus properly aligned untuk arm64-v8a devices
    packaging {
        jniLibs {
            // Modern packaging dengan proper 16KB alignment (WAJIB untuk Play Store Android 15+)
            // useLegacyPackaging = false adalah CRITICAL untuk 16KB page size support
            // Legacy packaging tidak support proper 16KB alignment generator di Android 15+ devices
            useLegacyPackaging = false
            // PENTING: JANGAN exclude native libraries - semua harus included
            // Play Store akan automatically check 16KB alignment support
            pickFirsts.clear()
        }
        resources {
            // Hindari duplicate files yang bisa cause conflicts saat packaging
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/*.kotlin_module",
                "META-INF/versions/**",
                "META-INF/INDEX.LIST"
            )
            // CRITICAL: Keep all native library files untuk proper 16KB page size support
            // pickFirsts ensures no .so files are excluded
            pickFirsts.clear()
            pickFirsts += listOf("lib/**/*.so")
            pickFirsts += listOf("META-INF/proguard/androidx-*.pro")
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
