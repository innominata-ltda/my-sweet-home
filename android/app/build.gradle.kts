import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

gradle.taskGraph.whenReady {
    val isReleaseRequested = allTasks.any { it.name.contains("Release", ignoreCase = true) }
    if (isReleaseRequested && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "Configuração ausente: 'key.properties' não encontrado na raiz do projeto Android. " +
            "O build de release exige a chave de produção configurada (CA-4.1)."
        )
    }
}

android {
    namespace = "br.com.innominata.mysweethome"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "br.com.innominata.mysweethome"
        minSdk = 29  // Android 10 — RNF-007
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val alias = keystoreProperties.getProperty("keyAlias")
                val pass = keystoreProperties.getProperty("keyPassword")
                val storePath = keystoreProperties.getProperty("storeFile")
                val storePass = keystoreProperties.getProperty("storePassword")

                if (alias.isNullOrBlank() || pass.isNullOrBlank() || storePath.isNullOrBlank() || storePass.isNullOrBlank()) {
                    throw GradleException(
                        "Configuração incompleta em 'key.properties'. " +
                        "Defina keyAlias, keyPassword, storeFile e storePassword (CA-4.1)."
                    )
                }

                keyAlias = alias
                keyPassword = pass
                storeFile = file(storePath)
                storePassword = storePass
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.play:app-update-ktx:2.1.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
