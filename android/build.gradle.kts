allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    project.configurations.configureEach {
        exclude(group = "org.tensorflow", module = "tensorflow-lite-gpu")
    }

    if (project.name == "light_compressor_v2") {
        plugins.apply("org.jetbrains.kotlin.android")
    }

    afterEvaluate {
        if (project.name == "tflite_flutter") {
            // tflite_flutter ships Java 1.8 compileOptions without a matching
            // Kotlin jvmTarget, which fails KGP 2.x consistency validation.
            // Pin both to 17, consistent with :app.
            val androidExt =
                project.extensions.getByName("android") as com.android.build.gradle.LibraryExtension
            androidExt.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
            androidExt.compileOptions.targetCompatibility = JavaVersion.VERSION_17

            project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>()
                .configureEach {
                    compilerOptions {
                        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                    }
                }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
