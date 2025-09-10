# Jenkins Pipeline Fix Guide
# Run this in Jenkins Script Console to clear cached pipeline

# Clear pipeline cache script:
Jenkins.instance.getAllItems().each { item ->
    if (item instanceof org.jenkinsci.plugins.workflow.job.WorkflowJob) {
        println "Clearing cache for: ${item.name}"
        item.setDefinition(null)
        item.save()
    }
}
println "Pipeline cache cleared. Reconfigure your job."
