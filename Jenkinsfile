#!/usr/bin/env groovy

@Library('jenkinsPipelineSharedLibrary')
import com.tieto.fs.jenkins.pipeline.steps.utility.*

final boolean IS_MAIN_BRANCH = (env.BRANCH_NAME as String).equals("master")
final String REGISTRY_URL = "https://fs-pcm-docker.maven.etb.tieto.com"
final String REGISTRY_CREDENTIALS = "artifactory-uploader"
final String ARTIFACT_NAME = "tieto/pcm-ansible"

node('infrastructure-build') {
    notifyBitbucket()
    docker.withRegistry(REGISTRY_URL, REGISTRY_CREDENTIALS) {
        String majorVersion = "2"
        String minorVersion = "8"
        String newVersion

        String commitId
        def img

        stage("Checkout") {
            checkout scm
            sshagent(credentials: ['Serviceaccount-ssh-key']) {
	      sh 'git fetch -t'
	    }
            sh "git rev-parse HEAD > .git/commit-id"
            commitId = readFile('.git/commit-id').trim()
            println commitId
        }

        stage('Prepare') {

            try {
                dockerfile = pwd() + "/Dockerfile"
                def file = readFile(dockerfile)
                file.split("\n")[1].trim()

                String shortVersion = "${majorVersion}.${minorVersion}"
                newVersion = calculateNextBuildVersionFromGitTags(shortVersion)
                println "Next delivery will be " + newVersion
            }
            catch (Exception e){
		        currentBuild.result = 'FAILURE'
	            notifyBitbucket()
	            throw e
            }
        }

        stage("Build") {
            try {
                img = docker.build("${ARTIFACT_NAME}:${commitId}")
            }
            catch (Exception e){
		        currentBuild.result = 'FAILURE'
	            notifyBitbucket()
	            throw e
            }
        }

        if (IS_MAIN_BRANCH && currentBuild.resultIsBetterOrEqualTo("SUCCESS")) {
            milestone 1
            stage("Publish") {
                try {
                    img.push newVersion
                    img.push "latest"
                    sh "git tag -a ${newVersion} -m \'${newVersion}\'"
                        sshagent(credentials: ['Serviceaccount-ssh-key']) {
                            sh "git push origin ${newVersion}"
                        }
                }
                catch (Exception e){
		            currentBuild.result = 'FAILURE'
	                notifyBitbucket()
	                throw e
                }
            }
        }
    }
    currentBuild.result = currentBuild.result ?: 'SUCCESS'
    notifyBitbucket()
}
