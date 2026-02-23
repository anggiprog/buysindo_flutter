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

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

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
    namespace = "com.buysindostore.app"
    compileSdk = 36 // Android 15 (Vanilla Ice Cream)

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf("-Xlint:-options")
    }

    defaultConfig {
        applicationId = if (project.hasProperty("appPackage")) {
            project.property("appPackage").toString()
        } else {
            "com.buysindostore.app"
        }

        val customAppName = if (project.hasProperty("appName")) {
            project.property("appName").toString()
        } else {
            "Buysindo App"
        }
        resValue("string", "app_name", customAppName)

        minSdk = 31 // Android 12+ (Wajib untuk 16KB support yang stabil)
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName

        ndk {
            // HANYA sertakan arm64-v8a untuk 16KB. 
            // Play Store akan memproses armeabi-v7a secara terpisah via bundle split.
            abiFilters.clear()
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
        }
    }

    signingConfigs {
        create("release") {
            if (project.hasProperty("ksFile")) {
                storeFile = file(project.property("ksFile").toString())
                storePassword = project.property("ksPass").toString()
                keyAlias = if (project.hasProperty("ksAlias")) project.property("ksAlias").toString() else "buysindo"
                keyPassword = project.property("ksPass").toString()
            } else if (keystorePropertiesFile.exists()) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    
    bundle {
        abi {
            // CRITICAL: Harus true agar Play Store bisa mengemas biner 16KB secara benar per-perangkat
            enableSplit = true
        }
    }
    
    packaging {
        jniLibs {
            // CRITICAL: Harus false agar .so files tidak dikompresi (Uncompressed)
            useLegacyPackaging = false
            
            // Hapus arsitektur yang tidak mendukung 16KB secara native di Play Store
            excludes.addAll(listOf(
                "lib/x86_64/**",
                "lib/x86/**"
            ))
        }
        resources {
            excludes += listOf(
                "META-INF/*.kotlin_module",
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE*",
                "META-INF/NOTICE*"
            )
            pickFirsts.clear()
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}