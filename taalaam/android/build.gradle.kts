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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Force all Android library plugin subprojects to compile against SDK 36.
// file_picker and others hardcode compileSdk=34 in their own build scripts,
// which is too low for flutter_plugin_android_lifecycle (requires >= 36).
// gradle.afterProject fires AFTER each project's build script runs, so it
// correctly overrides whatever the plugin set.
gradle.afterProject {
    if (project != rootProject) {
        @Suppress("DEPRECATION")
        (project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension)
            ?.compileSdkVersion(36)
    }
}

// Force all plugin subprojects to compile with Kotlin language version 2.0.
// posthog_flutter 4.x declares languageVersion 1.6 which KGP 2.2+ rejects.
subprojects {
    project.plugins.withId("org.jetbrains.kotlin.android") {
        project.tasks
            .withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java)
            .configureEach {
                compilerOptions {
                    languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
                    apiVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
                }
            }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
