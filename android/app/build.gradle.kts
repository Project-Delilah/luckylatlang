import java.io.FileInputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.isg32.luckylatlang"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.isg32.luckylatlang"
        minSdk = flutter.minSdkVersion  // Android 5.0+ — explicitly pinned so upgrades can't raise it
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
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
            isShrinkResources = false
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            // ponytail: default debug keystore — no key.properties needed for local builds
        }
    }

    @Suppress("DEPRECATION")
    applicationVariants.all {
        if (buildType.name == "release") {
            outputs.all {
                val out = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
                val abi = out.filters.find { it.filterType == "ABI" }?.identifier ?: "universal"
                val dt = SimpleDateFormat("yyyyMMdd_HHmm").format(Date())
                out.outputFileName = "luckylatlang_${abi}_${dt}-signed.apk"
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
