allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    fun ensureNamespace() {
        val androidExt = extensions.findByName("android") ?: return
        try {
            val getNamespace = androidExt.javaClass.getMethod("getNamespace")
            val currentNamespace = getNamespace.invoke(androidExt) as? String
            if (currentNamespace.isNullOrBlank()) {
                val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                val safeProjectName = project.name.replace('-', '_')
                setNamespace.invoke(androidExt, "com.lumluay.$safeProjectName")
            }
        } catch (_: Exception) {
            // Ignore modules that are not Android plugin projects.
        }
    }

    plugins.withId("com.android.application") { ensureNamespace() }
    plugins.withId("com.android.library") { ensureNamespace() }

    // Force compileSdk >= 34 for all library sub-projects so attributes like
    // android:attr/lStar (introduced in API 31) resolve correctly.
    plugins.withId("com.android.library") {
        val androidExt = extensions.findByName("android") ?: return@withId
        try {
            val getCompile = androidExt.javaClass.getMethod("getCompileSdkVersion")
            val currentCompile = getCompile.invoke(androidExt) as? Int ?: 0
            if (currentCompile < 34) {
                val setCompile = androidExt.javaClass.getMethod("compileSdkVersion", Int::class.java)
                setCompile.invoke(androidExt, 34)
            }
        } catch (_: Exception) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
