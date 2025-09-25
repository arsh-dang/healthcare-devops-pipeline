try { new GroovyShell().parse(new File("Jenkinsfile")); println("Jenkinsfile syntax is valid") } catch (Exception e) { println("Syntax error: " + e.message) }
