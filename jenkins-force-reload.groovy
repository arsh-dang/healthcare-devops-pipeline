// JENKINS CACHE CLEARING SCRIPT
// Run this in Jenkins Script Console: Jenkins Dashboard → Manage Jenkins → Script Console

// Method 1: Clear all pipeline caches
Jenkins.instance.getAllItems().each { item ->
    if (item instanceof org.jenkinsci.plugins.workflow.job.WorkflowJob) {
        println "Clearing cache for pipeline: ${item.name}"
        try {
            item.setDefinition(null)
            item.save()
            println "✅ Successfully cleared cache for: ${item.name}"
        } catch (Exception e) {
            println "❌ Failed to clear cache for ${item.name}: ${e.message}"
        }
    }
}

// Method 2: Force reload specific pipeline (replace 'healthcare-app' with your job name)
def jobName = 'healthcare-app'  // Change this to your actual job name
def job = Jenkins.instance.getItem(jobName)
if (job && job instanceof org.jenkinsci.plugins.workflow.job.WorkflowJob) {
    println "Forcing reload for job: ${jobName}"
    try {
        job.setDefinition(null)
        job.save()
        println "✅ Successfully forced reload for: ${jobName}"
    } catch (Exception e) {
        println "❌ Failed to reload ${jobName}: ${e.message}"
    }
} else {
    println "❌ Job '${jobName}' not found or not a pipeline job"
}

println "\\n🎉 Cache clearing completed!"
println "Now reconfigure your pipeline job:"
println "1. Go to job → Configure"
println "2. Under Pipeline section:"
println "   - Definition: Pipeline script from SCM"
println "   - SCM: Git"
println "   - Repository URL: https://github.com/arsh-dang/healthcare-devops-pipeline.git"
println "   - Script Path: Jenkinsfile"
println "3. Save and run a new build"
