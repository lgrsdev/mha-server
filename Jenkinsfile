String serverUrl = ''
pipeline {
  agent any
  stages {
    stage('clean workspace') {
      steps {
        cleanWs()
      }
    }
    stage('build') {
      steps {
        checkout scm
        script {
          mhaImage = docker.build("mha_server:${env.BUILD_ID}")
        }
      }
    }
    stage('provision infra') {
      steps {
        dir ('infra') {
          checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/lgrsdev/mha-infra']]])
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "awsCredentials", accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
              sh 'terraform init'
              sh 'terraform apply -auto-approve'
          }
        }
      }
    }
    stage('push image') {
      steps {
        script {
          docker.withRegistry('https://998833414250.dkr.ecr.us-east-2.amazonaws.com/mha_server', 'ecr:us-east-2:awsCredentials') {
            mhaImage.push()
          }
        }
      }
    }
    stage('deploy') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "awsCredentials", accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          script {
            url = sh (script: 'aws eks describe-cluster --name mha --query cluster.endpoint --region us-east-2',returnStdout: true).trim()
            serverUrl = url.substring(1, url.length() - 1)
          }
          withKubeConfig([credentialsId: 'eksCredentials', serverUrl: serverUrl]) {
            sh 'cat deployment.yaml | sed "s/{{BUILD_ID}}/${BUILD_ID}/g" | kubectl apply -f -'
          }
        }
      }
    }
  }
  post {
    always {
      cleanWs()
    }
  }
}