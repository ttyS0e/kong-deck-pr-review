pipeline {
  agent "any"

  stage("Test Stage") {
    steps {
      step("Test") {
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
