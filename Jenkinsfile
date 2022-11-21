pipeline {
  agent any
  parameters {
      string(name: 'CLUSTER_API_SERVER_ENDPOINT', defaultValue: '', description: '')
  }
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
        checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/lgrsdev/mha-infra']]])
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "awsCredentials", accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            sh 'terraform init'
            sh 'terraform apply -auto-approve'
        }
      }
    }
    stage('push image') {
      steps {
        script {
          docker.withRegistry('https://998833414250.dkr.ecr.us-east-2.amazonaws.com/mha_server', 'ecr:us-east-2:awsCredentials') {
            image.push()
          }
        }
      }
    }
    stage('deploy') {
      steps {
        withKubeConfig([credentialsId: 'eksCredentials', serverUrl: params.CLUSTER_API_SERVER_ENDPOINT]) {
//         withKubeConfig([credentialsId: 'eksCredentials', serverUrl: 'https://03B53F182EF718150C8025A95343875E.gr7.us-east-2.eks.amazonaws.com']) {
          sh 'cat deployment.yaml | sed "s/{{BUILD_ID}}/${BUILD_ID}/g" | kubectl apply -f -'
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