plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.tennismanagement.tennis_management"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Habilitar BuildConfig para usar buildConfigField en flavors
    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.tennismanagement.tennis_management"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ============================================================================
    // FLAVORS CONFIGURATION
    // ============================================================================
    // Configuración de flavors para soportar múltiples ambientes
    // - dev: Desarrollo local (backend localhost)
    // - prod: Producción (backend Render)
    
    flavorDimensions += "environment"
    
    productFlavors {
        create("dev") {
            dimension = "environment"
            // Temporalmente sin suffix para que funcione con google-services.json
            // applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            
            // Nombre de la app en el dispositivo
            resValue("string", "app_name", "Tennis DEV")
            
            // Configuraciones adicionales para desarrollo
            buildConfigField("String", "ENVIRONMENT", "\"development\"")
            buildConfigField("String", "API_BASE_URL", "\"http://10.0.2.2:3000/api\"")
        }
        
        create("prod") {
            dimension = "environment"
            
            // Nombre de la app en el dispositivo
            resValue("string", "app_name", "Tennis Management")
            
            // Configuraciones adicionales para producción
            buildConfigField("String", "ENVIRONMENT", "\"production\"")
            buildConfigField("String", "API_BASE_URL", "\"https://tenismanagment.onrender.com/api\"")
        }
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
