def get_tools(tool_name) {
  switch(tool_name) { 
    case "inso": 
    sh """mkdir -p ./.tools/
          #curl -L -o inso.tar.xz https://github.com/Kong/insomnia/releases/download/lib%402.4.0/inso-linux-2.4.0.tar.xz
          curl -L -o inso.tar.xz https://github.com/Kong/insomnia/releases/download/lib%402.4.0/inso-macos-2.4.0.zip
          tar -xzvf inso.tar.xz
          mv ./inso ./.tools/inso
          chmod +x ./.tools/inso
    """
    break

    case "deck": 
    sh """mkdir -p ./.tools/
          #curl -L -o deck https://github.com/Kong/deck/releases/download/v1.8.2/deck_1.8.2_linux_amd64.tar.gz
          curl -L -o deck https://github.com/Kong/deck/releases/download/v1.8.2/deck_1.8.2_darwin_arm64.tar.gz
          tar -xzvf deck.tar.xz
          mv ./deck ./.tools/deck
          chmod +x ./.tools/deck
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

            def has_deck = sh script:"ls ./.tools/deck", returnStatus:true
            if (has_inso != 0) {
              get_tools("deck")
            }
          }
        }
      }
    }
  }
}
