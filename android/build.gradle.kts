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

    // Manche Plugin-Module (z.B. file_picker) pinnen ihr compileSdk niedriger
    // als eine transitive Abhängigkeit verlangt (flutter_plugin_android_lifecycle
    // braucht 36). Hebt jedes Android-Modul auf mindestens 36.
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            (ext as com.android.build.gradle.BaseExtension).apply {
                val current =
                    compileSdkVersion?.substringAfter("android-")?.toIntOrNull() ?: 0
                if (current < 36) {
                    compileSdkVersion(36)
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
