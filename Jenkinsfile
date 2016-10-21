#!groovy


node('dockerslave') {

  stage('Clean environment'){
    deleteDir()
    sh "whoami"
    sh "hostname"
  }

  stage('Checkout github'){
    // Jenkins job names must match github repo names, until we find a better approach
    echo "Test ------------  $env.GIT_URL"
    sh "git clone https://github.com/dtulibrary/$env.JOB_NAME ."
  }

  stage('Build Docker'){
    sh "docker build -t dtu/$env.JOB_NAME ."
  }

  stage('Run tests'){
    sh "docker run -e 'RAILS_ENV=test' dtu/$env.JOB_NAME /bin/bash -c './test.sh'"
  }

  stage('Integration test?'){
    sh "echo I should run  ./itest.sh "
  }
}
