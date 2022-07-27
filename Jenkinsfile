def get_tools(tool_name) {
  switch(tool_name) { 
    case "inso": 
    sh """mkdir -p ./.tools/
          curl -L -o inso.tar.xz https://github.com/Kong/insomnia/releases/download/lib%402.4.0/inso-linux-2.4.0.tar.xz
          #curl -L -o inso.tar.xz https://github.com/Kong/insomnia/releases/download/lib%402.4.0/inso-macos-2.4.0.zip
          tar xvf inso.tar.xz
          mv ./inso ./.tools/inso
          chmod +x ./.tools/inso
    """
    break

    case "deck": 
    sh """mkdir -p ./.tools/
          curl -L -o deck https://github.com/Kong/deck/releases/download/v1.8.2/deck_1.8.2_linux_amd64.tar.gz
          #curl -L -o deck https://github.com/Kong/deck/releases/download/v1.8.2/deck_1.8.2_darwin_arm64.tar.gz
          tar -xzvf deck.tar.gz
          mv ./deck ./.tools/deck
          chmod +x ./.tools/deck
    """
    break

    default:
    error("Tool " + tool_name + " has no installation candidate")

    return "./.tools/"
  }
}

def list_dir(dir_path) {
    def listOfFolder = sh script: "ls $WORKSPACE/$dir_path", returnStdout: true

    def ret_array=[]
    listOfFolder.split().each { 
        ret_array << it
    }

    return ret_array
}

def LINT_PASSED = false
def INSO_PATH = ""
def DECK_PATH = ""
def API_SPECS = []

pipeline {
    agent "any"

    environment {
        DECK_KONG_ADDR = "http://kong-admin.k3s.jack.local"
        DECK_RBAC_TOKEN = credentials('kong-rbac-token')
        DECK_WORKSPACE = "rb"
    }
    
    stages {
        stage("Check Environment") {
            when {
                anyOf {
                    changeRequest()
                    branch "main"
                }
            }
            steps {
                script {
                    deleteDir()
                    checkout scm

                    // Do not accidentally commit the .tools workspace cache
                    sh "echo '.tools/' >> .gitignore"
                    sh "echo 'kong.yaml' >> .gitignore"
        
                    // Check for or dload inso
                    def has_inso = sh script:"which inso", returnStatus:true
                    if (has_inso != 0) {
                        INSO_PATH = get_tools("inso")
                    }
        
                    def has_deck = sh script:"which deck", returnStatus:true
                    if (has_inso != 0) {
                        DECK_PATH = get_tools("deck")
                    }
                }
            }
        }

        stage("Gather API Specs") {
            when {
                anyOf {
                    changeRequest()
                    branch "main"
                }
            }
            steps {
                script {
                    API_SPECS = list_dir('./api')
                    echo "Processing API Specs: $API_SPECS"
                }
            }
        }

        stage("Lint API Specs") {
            when {
                anyOf {
                    changeRequest()
                }
            }

            steps {
                script {
                    def anyFailure = false
                    API_SPECS.each {
                        // Is there already a review comment on this file?
                        def comment = null
                        for (reviewComment in pullRequest.reviewComments) {
                            if (reviewComment.path == "api/${it}" && reviewComment.user == "ttys0ejenkins") {
                                pullRequest.deleteReviewComment(reviewComment.id)
                            }
                        }

                        def returnCode = sh returnStatus:true, script:"inso lint spec api/${it} > out.txt"
                        
                        if (returnCode > 0) {
                            echo "Spec ${it} failed linting"
                            anyFailure = true

                            def commitId = pullRequest.head
                            def path = "api/${it}"
                            def lineNumber = 1
                            def body = readFile('out.txt').trim()
                            
                            comment = pullRequest.reviewComment(commitId, path, lineNumber, body)
                        }
                        sh "rm -f out.txt"
                    }

                    if (anyFailure) {
                        pullRequest.createStatus(status: 'failure',
                                context: 'continuous-integration/jenkins/pr-merge/lint',
                                description: 'Lint API Specs',
                                targetUrl: "${env.JOB_URL}/testResults")
                        LINT_PASSED = false
                        error("One or more API Specs failed linting")
                    } else {
                        pullRequest.createStatus(status: 'success',
                                context: 'continuous-integration/jenkins/pr-merge/lint',
                                description: 'Lint API Specs',
                                targetUrl: "${env.JOB_URL}/testResults")
                        LINT_PASSED = true
                    }
                }
            }
        }

        stage("Lint API Specs MAIN") {
            when {
                anyOf {
                    branch "main"
                }
            }

            steps {
                script {
                    def anyFailure = false
                    API_SPECS.each {
                        def returnCode = sh returnStatus:true, script:"inso lint spec api/${it} > out.txt"
                        
                        if (returnCode > 0) {
                            echo "Spec ${it} failed linting"
                            anyFailure = true
                        }
                    }

                    if (anyFailure) {
                        error("One or more API Specs failed linting")
                    }

                    LINT_PASSED = true
                }
            }
        }

        stage("Generate Declarative Kongfig") {
            when {
                anyOf {
                    changeRequest()
                }
            }

            steps {
                script {
                    def anyFailure = false
                    API_SPECS.each {
                        // Is there already a review comment on this file?
                        def comment = null
                        for (reviewComment in pullRequest.reviewComments) {
                            if (reviewComment.path == "api/${it}" && reviewComment.user == "ttys0ejenkins") {
                                pullRequest.deleteReviewComment(reviewComment.id)
                            }
                        }

                        def returnCode = sh returnStatus:true, script:"inso generate config api/${it} > api/${it}.kong.yaml"
                        
                        if (returnCode > 0) {
                            echo "Spec ${it} failed generating"
                            anyFailure = true

                            def commitId = pullRequest.head
                            def path = "api/${it}"
                            def lineNumber = 1
                            def body = readFile('out.txt').trim()
                            
                            comment = pullRequest.reviewComment(commitId, path, lineNumber, body)
                        }
                        sh "rm -f out.txt"
                    }
                    
                    if (anyFailure) {
                        pullRequest.createStatus(status: 'failure',
                                context: 'continuous-integration/jenkins/pr-merge/generate',
                                description: 'Generate Declarative Config',
                                targetUrl: "${env.JOB_URL}/testResults")
                        error("One or more API Specs failed to generate config")
                    } else {
                        pullRequest.createStatus(status: 'success',
                                context: 'continuous-integration/jenkins/pr-merge/generate',
                                description: 'Generate Declarative Config',
                                targetUrl: "${env.JOB_URL}/testResults")
                    }
                }
            }
        }

        stage("Generate Declarative Kongfig MAIN") {
            when {
                anyOf {
                    branch "main"
                }
            }

            steps {
                script {
                    def anyFailure = false
                    API_SPECS.each {
                        def returnCode = sh returnStatus:true, script:"inso generate config api/${it} > api/${it}.kong.yaml"
                        
                        if (returnCode > 0) {
                            anyFailure = true
                        }
                        sh "rm -f out.txt"
                    }
                    
                    if (anyFailure) {
                        error("One or more API Specs failed to generate config")
                    }
                }
            }
        }

        stage("Deck Diff") {
            when {
                allOf {
                    changeRequest()
                    expression { LINT_PASSED == true }
                }
            }
            steps {
                script {
                    // Deck diff with all the API Specs
                    def allSpecs = ""
                    API_SPECS.each {
                        allSpecs = allSpecs + " -s api/${it}.kong.yaml"
                    }
                    def deckDiffOutput = sh returnStdout:true, script:"deck --headers Kong-Admin-Token:$DECK_RBAC_TOKEN --workspace $DECK_WORKSPACE --select-tag sample-api diff ${allSpecs}"

                    // Try to find an existing comment from me
                    def existingComment = null
                    for (comment in pullRequest.comments) {
                        if (comment.user == "ttys0ejenkins") {
                            echo "Found existing comment with ID ${comment.id}"
                            existingComment = comment
                            break
                        }
                    }

                    def theComment = "# SUMMARY OF CHANGES\n\n```\n" + deckDiffOutput + "```"
                    if (existingComment == null) {
                        existingComment = pullRequest.comment(theComment)
                    } else {
                        existingComment.body = theComment
                    }
                }
            }
        }

        stage("Deck Sync") {
            when {
                allOf {
                    branch "main"
                    expression { LINT_PASSED == true }
                }
            }
            steps {
                script {
                    // Deck diff with all the API Specs
                    def allSpecs = ""
                    API_SPECS.each {
                        allSpecs = allSpecs + " -s api/${it}.kong.yaml"
                    }
                    sh script:"deck --headers Kong-Admin-Token:$DECK_RBAC_TOKEN --workspace $DECK_WORKSPACE --select-tag sample-api sync ${allSpecs}"
                }
            }
        }

        stage('Portal Sync') {
            when {
                allOf {
                    branch "main"
                    expression { LINT_PASSED == true }
                }
            }
            steps {
                script {
                    // Download portal markup
                    sh 'KONG_ADMIN_URL=$DECK_KONG_ADDR KONG_ADMIN_TOKEN=$DECK_RBAC_TOKEN portal init rb'
                    sh 'KONG_ADMIN_URL=$DECK_KONG_ADDR KONG_ADMIN_TOKEN=$DECK_RBAC_TOKEN portal fetch rb'
                    sh 'rm -rf workspaces/rb/specs ; mkdir -p workspaces/rb/specs'

                    API_SPECS.each {
                        // Set the Kong URL in the servers block
                        sh "sed -i 's/http/https/g' api/${it}"
                        sh "sed -i 's/apps.svc.cluster.local:8080/k3s.jack.local/g' api/${it}"

                        // Add all the API specs
                        sh "cp api/${it} workspaces/rb/specs/${it}"
                    }

                    // Upload the portal markup
                    sh 'KONG_ADMIN_URL=$DECK_KONG_ADDR KONG_ADMIN_TOKEN=$DECK_RBAC_TOKEN portal deploy rb'
                }
            }
        }

        // Download portal markup
        // Add all the API specs
        // Upload the portal markup
    }

    post {
        success {
            script {
                if (env.CHANGE_ID) {
                    try {
                        pullRequest.removeLabel('build_failing')
                    } catch (err) {
                        // hack
                    }
                    try {
                        pullRequest.addLabel('build_passing')
                    } catch (err) {
                        // hack
                    }
                }
            }
        }
        failure {
            script {
                if (env.CHANGE_ID) {
                    try {
                        pullRequest.addLabel('build_failing')
                    } catch (err) {
                        // hack
                    }
                    try {
                        pullRequest.removeLabel('build_passing')
                    } catch (err) {
                        // hack
                    }
                }
            }
        }
    }
}
