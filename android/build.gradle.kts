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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.findByName("android")
        if (android != null) {
            val namespaceProperty = android::class.java.methods.find { it.name == "getNamespace" }
            val setNamespaceMethod = android::class.java.methods.find { it.name == "setNamespace" }
            
            if (namespaceProperty != null && setNamespaceMethod != null) {
                val currentNamespace = namespaceProperty.invoke(android) as? String
                if (currentNamespace == null) {
                    var newNamespace = project.group.toString()
                    if (newNamespace.isEmpty()) {
                        newNamespace = "com.example.${project.name.replace("-", "_")}"
                    } else {
                        newNamespace = "$newNamespace.${project.name.replace("-", "_")}"
                    }
                    if (project.name == "image_gallery_saver") {
                        newNamespace = "com.example.imagegallerysaver"
                    }
                    setNamespaceMethod.invoke(android, newNamespace)
                }
            }
            
            // Force Java compatibility to 17
            val compileOptionsProperty = android::class.java.methods.find { it.name == "getCompileOptions" }
            if (compileOptionsProperty != null) {
                val compileOptions = compileOptionsProperty.invoke(android)
                val setSourceCompatibility = compileOptions::class.java.methods.find { it.name == "setSourceCompatibility" }
                val setTargetCompatibility = compileOptions::class.java.methods.find { it.name == "setTargetCompatibility" }
                
                setSourceCompatibility?.invoke(compileOptions, JavaVersion.VERSION_17)
                setTargetCompatibility?.invoke(compileOptions, JavaVersion.VERSION_17)
            }
        }
    }
    
    // Force Kotlin JVM target to 17
    project.tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}
