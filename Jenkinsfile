pipeline {
  agent "any"

  stages {
    stage("Test Stage") {
      steps {
        script {
          if (env.BRANCH_NAME.startsWith('PR')) {
            sh "echo this is a PR"
          } else {
            sh "echo this is NOT a PR"
          }
        }
      }
    }
  }
}
