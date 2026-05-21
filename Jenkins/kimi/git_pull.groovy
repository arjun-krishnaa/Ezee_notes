#!/usr/bin/env groovy

/**
 * Simple Groovy script to clone or pull code from a Git repository.
 * Usage:
 *   groovy git_pull.groovy <repoUrl> <localDir> [branch]
 * Example:
 *   groovy git_pull.groovy https://github.com/example/repo.git /tmp/repo main
 */

def args = this.args
if (args.length < 2) {
    println "Usage: groovy git_pull.groovy <repoUrl> <localDir> [branch]"
    System.exit(1)
}

String repoUrl = args[0]
File localDir = new File(args[1])
String branch = args.length >= 3 ? args[2] : 'main'

println "Git repo pull script"
println "Repository: ${repoUrl}"
println "Target directory: ${localDir.absolutePath}"
println "Branch: ${branch}"

String runCommand(List<String> command, File workingDir = null) {
    println "Running: ${command.join(' ')}"
    def processBuilder = new ProcessBuilder(command)
    if (workingDir) {
        processBuilder.directory(workingDir)
    }
    processBuilder.redirectErrorStream(true)
    def process = processBuilder.start()
    def output = new StringBuilder()
    process.inputStream.eachLine { line ->
        println line
        output.append(line).append(System.lineSeparator())
    }
    int exitCode = process.waitFor()
    if (exitCode != 0) {
        throw new RuntimeException("Command failed with exit code ${exitCode}: ${command.join(' ')}")
    }
    return output.toString()
}

try {
    if (!localDir.exists()) {
        println "Target directory does not exist. Cloning repository..."
        runCommand(['git', 'clone', '--branch', branch, repoUrl, localDir.absolutePath])
        println "Clone completed."
    } else if (!new File(localDir, '.git').exists()) {
        throw new IllegalStateException("Directory exists but is not a Git repository: ${localDir.absolutePath}")
    } else {
        println "Repository already exists. Fetching updates..."
        runCommand(['git', 'fetch', '--all'], localDir)
        runCommand(['git', 'checkout', branch], localDir)
        runCommand(['git', 'pull', 'origin', branch], localDir)
        println "Pull completed."
    }
    println "Git code pull finished successfully."
} catch (Exception e) {
    System.err.println("Error: ${e.message}")
    System.exit(2)
}
