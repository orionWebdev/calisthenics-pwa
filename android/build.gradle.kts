allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// firebase_auth 6.6.0 übersetzt auf dieser Toolchain nicht: Sein Kotlin-Code
// verweist auf Annotationen aus org.checkerframework, die nicht auf seinem
// Compile-Klassenpfad liegen ("Type annotation class ... is inaccessible").
// Die Ergänzung gehört eigentlich in das Plugin, nicht hierher — bis das dort
// behoben ist, reichen wir sie nach.
//
// Muss VOR dem `evaluationDependsOn(":app")` weiter unten stehen: Danach sind
// die Unterprojekte bereits ausgewertet, und `afterEvaluate` wirft.
subprojects {
    afterEvaluate {
        if (project.name == "firebase_auth") {
            dependencies {
                add("compileOnly", "org.checkerframework:checker-qual:3.53.0")
            }
        }
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
