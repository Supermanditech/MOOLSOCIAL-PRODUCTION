group = "com.moolsocial.youtube_embedded_player_private_dev"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.3.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.0.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.moolsocial.youtube_embedded_player_private_dev"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        create("profile") {
            initWith(getByName("release"))
        }
    }

    sourceSets {
        getByName("main") {
            java.directories.add("src/main/kotlin")
        }
        getByName("debug") {
            java.directories.add("src/debug/kotlin")
        }
        getByName("profile") {
            java.directories.addAll(listOf(
                "src/profile/kotlin",
                "src/debug/kotlin/com/moolsocial/app/youtube",
            ))
        }
        getByName("release") {
            java.directories.addAll(listOf(
                "src/release/kotlin",
                "src/debug/kotlin/com/moolsocial/app/youtube",
            ))
        }
    }

    defaultConfig {
        minSdk = 24
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
