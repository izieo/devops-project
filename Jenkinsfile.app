pipeline {
  agent {
    node {
      label 'docker-agent-azure'
    }
  }

  environment {
    ACR_NAME        = 'izieomodevopsacr'
    IMAGE_TAG       = 'latest'
    RESOURCE_GROUP  = 'devops-rg'
    CLUSTER_NAME    = 'devops-aks'

    AZ_CLIENT_ID     = credentials('AZURE_CLIENT_ID')
    AZ_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET')
    AZ_TENANT_ID     = credentials('AZURE_TENANT_ID')
    AZ_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID') // Needed for backend auth
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
      
      // Create buildx builder if it doesn't exist
      sh 'docker buildx create --use || true'

      for (svc in services) {
        def image = "${ACR_NAME}.azurecr.io/${svc}:${IMAGE_TAG}"
        sh """
          docker buildx build \
            --platform linux/amd64 \
            -t ${image} \
            --push \
            ./microservices/${svc}
        """
      }
    }
  }
}

    stage('Set Up kubeconfig') {
      steps {
        dir('terraform') {
          withEnv([
            "ARM_CLIENT_ID=${AZ_CLIENT_ID}",
            "ARM_CLIENT_SECRET=${AZ_CLIENT_SECRET}",
            "ARM_SUBSCRIPTION_ID=${AZ_SUBSCRIPTION_ID}",
            "ARM_TENANT_ID=${AZ_TENANT_ID}"
          ]) {
            sh '''
              terraform init -input=false
              terraform output -raw kube_config > azurek8s
              export KUBECONFIG=$PWD/azurek8s
              echo "[INFO] KUBECONFIG preview:"
              head -n 10 azurek8s
              kubectl config current-context
            '''
          }
        }
      }
    }

    stage('Deploy to AKS') {
      steps {
        dir('terraform') {
          sh '''
            export KUBECONFIG=$PWD/azurek8s
            kubectl apply -f ../k8s/
          '''
        }
      }
    }
  }

  post {
    success {
      echo "✅ CI/CD pipeline completed successfully!"
    }
    failure {
      echo "❌ Pipeline failed. Check the error logs above."
    }
  }
}
