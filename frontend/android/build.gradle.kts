allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir("../../build"))

subprojects {
    val newSubprojectBuildDir = rootProject.layout.buildDirectory.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    if (project.path != ":app") {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
