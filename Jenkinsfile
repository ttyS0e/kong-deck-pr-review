def get_tools(tool_name) {
  switch(tool_name) { 
    case "inso": 
    sh """mkdir -p
          curl -L -o inso.tar.xz https://github.com/Kong/insomnia/releases/download/lib%402.4.0/inso-linux-2.4.0.tar.xz
          tar -xzvf inso.tar.xz
          mv ./inso ./.tools/inso
          chmod +x ./.tools/inso
    """
    break
    
    default:
    error("Tool " + tool_name + " has no installation candidate")
  }
}

pipeline {
  agent "any"

  stages {
    stage("Checkout SCM") {
      environment {
        DO_BUILD = false
      }
      steps {
        checkout scm
      }
    }
    stage("Check Environment") {
      steps {
        script {
          if (env.BRANCH_NAME.startsWith('PR')) {
            sh "echo $PATH"
            sh "echo this is a PR"
            env.DO_BUILD = true

            // Do not accidentally commit the .tools workspace cache
            sh "echo '.tools/' >> .gitignore"

            // Check for or dload inso
            def has_inso = sh script:"ls ./.tools/inso", returnStatus:true
            if (has_inso != 0) {
              get_tools("inso")
            }
          }
        }
      }
    }
  }
}
