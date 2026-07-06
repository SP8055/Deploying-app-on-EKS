pipeline {
    agent any
    
    tools { 
        maven 'Maven3' // Jenkins lo Maven global tool name
        jdk 'jdk17'              // Jenkins lo JDK17 global tool name
    }
    
    environment {
        DOCKER_IMAGE = 'petshop'   // Change this
        ECR_REPO = '216569733367.dkr.ecr.ap-south-1.amazonaws.com/my-repo'
        AWS_REGION = 'ap-south-1'
        CLUSTER_NAME = 'sreeganesh-EKS'
        APP_NAME = 'petshop'
        AWS_CRED_ID = 'AWS-CRED'
        SONAR_ENV = 'sonar-server'
    }

    stages {
        stage('Clean Workspace') {
            steps { cleanWs() }
        }
        
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/SP8055/Deploying-app-on-EKS.git'
            }
        }
        
        stage('Maven Build & Test') {
            steps {
        withEnv(["JAVA_HOME=${tool 'jdk17'}", "PATH+MAVEN=${tool 'Maven3'}/bin:${env.PATH}"]) {
            sh 'mvn clean package -DskipTests'
               }
            }
        }
        
       // stage('SonarQube Analysis') {
       //     steps {
       //         withSonarQubeEnv("${SONAR_ENV}") {
       //             sh '''
       //             mvn sonar:sonar \
       //                -Dsonar.projectKey=${APP_NAME} \
       //               -Dsonar.host.url=$SONAR_HOST_URL \
       //               -Dsonar.login=$SONAR_AUTH_TOKEN
       //             '''
       //         }
       //     }
       // }
        
         stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --exit-code 0 --severity HIGH,CRITICL . || true'
                }
            }
         
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
                    sh "docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest"
                }
            }
        }
       // stage('trivy image scan'){
    //        steps{
      //          sh "trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:latest || true"
        //    }
    //    }
        
        stage('Push to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-CRED', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh '''
                    aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${ECR_REPO}
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${ECR_REPO}:${BUILD_NUMBER}
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${ECR_REPO}:latest
                    docker push ${ECR_REPO}:${BUILD_NUMBER}
                    docker push ${ECR_REPO}:latest
                    '''
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CRED_ID}"]]){
                    sh """
                aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${AWS_REGION}
                kubectl set image deployment/petshop-deployment petshop=${ECR_REPO}:${BUILD_NUMBER} -n default
                """
                }
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
        }
        success {
            echo '✅ Build & Deployment Successful!'
        }
        failure {
            echo '❌ Pipeline Failed!'
        }
    }
}
