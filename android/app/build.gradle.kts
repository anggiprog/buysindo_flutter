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
    // NDK r27+ REQUIRED untuk 16KB page size alignment support (Play Store Android 15+ requirement)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Mengaktifkan core library desugaring yang diperlukan oleh beberapa AAR (mis. flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
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

        // minSdk 24 untuk kompatibilitas Android 7.0+ (mayoritas device aktif)
        // 16KB page size support handled by:
        // - NDK 27+ (set di android block)
        // - useLegacyPackaging = false (packaging block)
        // - extractNativeLibs = false (AndroidManifest.xml)
        // - Play Store handles actual 16KB alignment during delivery
        minSdk = 24

        // targetSdk 36 REQUIRED untuk 16KB page size support declaration ke Play Store (Android 15+)
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName

        // 16KB page size support - handled by NDK 27+ and Flutter's build system
        // Note: Don't use ndk.abiFilters with --split-per-abi (Flutter build command handles ABIs)
        // The NDK 27 set at android level + useLegacyPackaging=false ensures 16KB alignment
        
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
    // CRITICAL: Native libraries harus properly aligned untuk arm64-v8a dan armeabi-v7a devices
    packaging {
        jniLibs {
            // Modern packaging dengan proper 16KB alignment (WAJIB untuk Play Store Android 15+)
            // useLegacyPackaging = false adalah CRITICAL untuk 16KB page size support
            // Legacy packaging tidak support proper 16KB alignment generator di Android 15+ devices
            useLegacyPackaging = false
            // PENTING: Support KEDUA arm64-v8a dan armeabi-v7a untuk baseline profile generation
            // Exclude x86 dan x86_64 saja (tidak diperlukan untuk Play Store pada mayoritas devices)
            excludes.clear()
            excludes.addAll(listOf(
                "lib/x86/**",
                "lib/x86_64/**"
            ))
        }
        resources {
            // Hindari duplicate files yang bisa cause conflicts saat packaging
            excludes.clear()
            excludes.addAll(listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/*.kotlin_module",
                "META-INF/versions/**",
                "META-INF/INDEX.LIST",
                "META-INF/MANIFEST.MF",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1"
            ))
            // CRITICAL: Keep all native library files untuk proper 16KB page size support
            // pickFirsts handles duplicate proguard and config files - take first occurrence
            pickFirsts.clear()
            pickFirsts.addAll(listOf(
                "lib/**/*.so",
                "META-INF/proguard/**",
                "META-INF/com.android.tools/**"
            ))
        }
    }
}

flutter {
    source = "../.."
}

// Tambahkan blok dependencies untuk coreLibraryDesugaring
dependencies {
    // Versi desugar 2.1.4+ required oleh flutter_local_notifications 20.x
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Ensure Material Components and AppCompat are present so Theme.MaterialComponents.* is resolved
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}

// ====== FIX: Create missing baseline-prof.txt for ArtProfile compilation ======
// This prevents the "baseline-prof.txt not found" error caused by
// AGP 8.x + desugaring library incompatibility
// The file must be created BEFORE compileReleaseArtProfile runs
tasks.whenTaskAdded {
    if (name == "compileReleaseArtProfile") {
        doFirst {
            // Create the directory structure and file that the task expects
            val baselineDir = file("${project.buildDir}/intermediates/l8_art_profile/release/l8DexDesugarLibRelease")
            if (!baselineDir.exists()) {
                baselineDir.mkdirs()
            }
            val baselineFile = File(baselineDir, "baseline-prof.txt")
            if (!baselineFile.exists()) {
                baselineFile.writeText("# Empty baseline profile - workaround for AGP 8.x + desugaring\n")
                println("[BUILD FIX] Created baseline-prof.txt for ArtProfile compilation")
            }
        }
    }
}


