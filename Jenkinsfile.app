pipeline {
  agent {
    node {
      label 'docker-agent-azure'
    }
  }

  environment {
    DOCKER_HOST = "tcp://172.18.0.2:2375"
    ACR_NAME = 'izieomodevopsacr'
    IMAGE_TAG = 'latest'
    RESOURCE_GROUP = 'devops-rg'
    CLUSTER_NAME = 'devops-aks'

    AZ_CLIENT_ID     = credentials('AZURE_CLIENT_ID')
    AZ_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET')
    AZ_TENANT_ID     = credentials('AZURE_TENANT_ID')
  }

  stages {
    stage('Azure Login & ACR Login') {
      steps {
        sh '''
          az login --service-principal -u $AZ_CLIENT_ID -p $AZ_CLIENT_SECRET --tenant $AZ_TENANT_ID
          az acr login --name $ACR_NAME
        '''
      }
    }

    stage('Build & Push Docker Images') {
      steps {
        script {
          def services = ['frontend', 'adservice', 'checkoutservice']
          for (svc in services) {
            def image = "${ACR_NAME}.azurecr.io/${svc}:${IMAGE_TAG}"
            sh """
              docker build -t ${image} ./microservices/${svc}
              docker push ${image}
            """
          }
        }
      }
    }

    stage('Get AKS Credentials') {
      steps {
        sh 'az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing'
      }
    }

    stage('Deploy to AKS') {
      steps {
        sh 'kubectl apply -f k8s/'
      }
    }
  }

  post {
    success {
      echo "✅ CI/CD pipeline completed!"
    }
    failure {
      echo "❌ Something went wrong during the pipeline."
    }
  }
}
