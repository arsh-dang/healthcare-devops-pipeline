try {
    def file = new File('Jenkinsfile')
    new GroovyShell().parse(file)
    println "SUCCESS: Jenkinsfile syntax is valid"
} catch (Exception e) {
    println "ERROR: Syntax validation failed"
    println "Error: ${e.message}"
    e.printStackTrace()
}
