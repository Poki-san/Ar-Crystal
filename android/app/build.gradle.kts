plugins {
    id("com.android.application")
    // Flutter Gradle Plugin подключается после Android и Kotlin плагинов.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.echowear.echo_wear"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.echowear.echo_wear"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            /* Перед публикацией нужно заменить debug-подпись на production key. */
            signingConfig = signingConfigs.getByName("debug")
            /*
             * CameraX запускает WorkManager раньше Flutter. Отключение shrink
             * не позволяет R8 удалить сгенерированный Room класс WorkDatabase,
             * без которого приложение падает при запуске на Android 12.
             */
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
