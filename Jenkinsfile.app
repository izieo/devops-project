pipeline {
  agent {
    node {
      label 'docker-agent-azure'
    }
  }

  environment {
    ACR_NAME = 'izieomodevopsacr'
    IMAGE_TAG = 'latest'
    RESOURCE_GROUP = 'devops-rg'
    CLUSTER_NAME = 'devops-aks'

    AZ_CLIENT_ID     = credentials('AZURE_CLIENT_ID')
    AZ_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET')
    AZ_TENANT_ID     = credentials('AZURE_TENANT_ID')
  }

  stages {
    stage('Azure Login & ACR Token Login') {
      steps {
        script {
          sh '''
            az login --service-principal -u $AZ_CLIENT_ID -p $AZ_CLIENT_SECRET --tenant $AZ_TENANT_ID
          '''
          def token = sh(script: "az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken", returnStdout: true).trim()
          sh """
            echo $token | docker login ${ACR_NAME}.azurecr.io \
              --username 00000000-0000-0000-0000-000000000000 \
              --password-stdin
          """
        }
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

    stage('Set Up kubeconfig') {
      steps {
        script {
          def kubeConfigRaw = sh(
            script: 'terraform output -raw kube_config',
            returnStdout: true
          ).trim()

          // Remove potential EOT markers
          kubeConfigRaw = kubeConfigRaw
            .replaceAll('(?m)^<<EOT$', '')
            .replaceAll('(?m)^EOT$', '')

          writeFile file: 'azurek8s', text: kubeConfigRaw
          env.KUBECONFIG = "${pwd()}/azurek8s"

          // Optional check
          sh 'kubectl config current-context'
        }
      }
    }

    stage('Deploy to AKS') {
      steps {
        script {
          sh 'kubectl apply -f k8s/'
        }
      }
    }
  }

  post {
    success {
      echo "✅ CI/CD pipeline completed successfully!"
    }
    failure {
      echo "❌ CI/CD pipeline failed. Check the logs for details."
    }
  }
}
