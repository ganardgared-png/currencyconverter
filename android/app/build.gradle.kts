plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.smart_expenses_plan.dailyscheduler.pro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // ENABLE CORE LIBRARY DESUGARING
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.smart_expenses_plan.dailyscheduler.pro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ADD MULTIDEX SUPPORT
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")

            // Disable minification to avoid missing classes via R8 and keep features stable.
            isMinifyEnabled = false
            isShrinkResources = false
            // Keep proguard enabled as fallback if needed in future. (already supplied)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Copy release APK to location that Flutter CLI expects
afterEvaluate {
    tasks.named("assembleRelease") {
        finalizedBy("copyReleaseApk")
    }
}

tasks.register("copyReleaseApk") {
    doLast {
        val apkSource = layout.buildDirectory.file("outputs/apk/release/app-release.apk").get().asFile
        // Flutter project root is 2 levels up from build.gradle.kts (android/app/)
        val flutterProjectRoot = File(projectDir.parentFile, "..").canonicalFile
        val flutterBuildDir = File(flutterProjectRoot, "build/app/outputs/flutter-apk")
        flutterBuildDir.mkdirs()
        val apkDest = File(flutterBuildDir, "app-release.apk")
        
        if (apkSource.exists()) {
            apkSource.copyTo(apkDest, overwrite = true)
            println("✓ Copied APK to: ${apkDest.absolutePath}")
        } else {
            println("⚠ Source APK not found at ${apkSource.absolutePath}")
        }
    }
}

// ADD DEPENDENCIES SECTION - USE coreLibraryDesugaring NOT implementation
dependencies {
    // Core library desugaring - MUST use coreLibraryDesugaring configuration
    add("coreLibraryDesugaring", "com.android.tools:desugar_jdk_libs:2.1.4")

    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}
