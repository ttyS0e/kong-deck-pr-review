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

def DO_BUILD  = false
def LINT_PASSED = false
def INSO_PATH = ""
def DECK_PATH = ""
def API_SPECS = []

pipeline {
    agent "any"

    environment {
        DECK_KONG_ADDR = "http://kong-kong-admin.kong.svc.cluster.local:8001"
        DECK_RBAC_TOKEN = credentials('kong-rbac-token')
        DECK_WORKSPACE = "datamgmt"
    }
    
    stages {
        stage("Checkout SCM") {
              when {
                anyOf {
                  changeRequest()
                }
              }
              steps {
                    deleteDir()
                    checkout scm
                    // git credentialsId: 'github-token', url: 'https://github.com/ttyS0e/kong-deck-pr-review.git', branch: 'test'
                    script {
                        DO_BUILD = true
                    }
              }
        }

        stage("Check Environment") {
            when {
                anyOf {
                    expression { DO_BUILD == true }
                }
            }
            steps {
                script {
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
                    expression { DO_BUILD == true }
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
                    expression { DO_BUILD == true }
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
                                context: 'continuous-integration/jenkins/pr-merge/tests',
                                description: 'Lint API Specs',
                                targetUrl: "${env.JOB_URL}/testResults")
                        LINT_PASSED = false
                        error("One or more API Specs failed linting")
                    } else {
                        pullRequest.createStatus(status: 'success',
                                context: 'continuous-integration/jenkins/pr-merge/tests',
                                description: 'Lint API Specs',
                                targetUrl: "${env.JOB_URL}/testResults")
                        LINT_PASSED = true
                    }
                }
            }
        }

        stage("Generate Declarative Kongfig") {
            when {
                anyOf {
                    expression { DO_BUILD == true }
                    expression { LINT_PASSED == true }
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
                                context: 'continuous-integration/jenkins/pr-merge/tests',
                                description: 'Generate Declarative Config',
                                targetUrl: "${env.JOB_URL}/testResults")
                        LINT_PASSED = false
                        error("One or more API Specs failed to generate config")
                    } else {
                        pullRequest.createStatus(status: 'success',
                                context: 'continuous-integration/jenkins/pr-merge/tests',
                                description: 'Generate Declarative Config',
                                targetUrl: "${env.JOB_URL}/testResults")
                        LINT_PASSED = true
                    }
                }
            }
        }

        stage("Deck Diff") {
            when {
                allOf {
                    expression { DO_BUILD == true }
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
                    def deckDiffOutput = sh returnStdout:true, script:"deck --headers Kong-Admin-Token:$DECK_RBAC_TOKEN --workspace $DECK_WORKSPACE diff ${allSpecs}"

                    // Try to find an existing comment from me
                    def existingComment = null
                    for (comment in pullRequest.comments) {
                        if (comment.user == "ttys0ejenkins") {
                            echo "Found existing comment with ID ${comment.id}"
                            existingComment = comment
                            break
                        }
                    }

                    if (existingComment == null) {
                        existingComment = pullRequest.comment("```\n" + deckDiffOutput + "```")
                    } else {
                        existingComment.body = "```\n" + deckDiffOutput + "```"
                    }
                }
            }
        }
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
