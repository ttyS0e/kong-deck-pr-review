def install_inso() {
  sh "mkdir -p ./.programs/ && npm install --prefix ./.programs/ insomnia-inso"
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

            def has_inso = sh script:"which inso", returnStatus:true
            if (has_inso != 0) {
              install_inso()
              sh "ls -la .programs/"
              sh "ls -la .programs/*"
            }
          }
        }
      }
    }
  }
}
