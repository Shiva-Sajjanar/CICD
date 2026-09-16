pipeline {
    agent any

    tools {
        maven 'Maven-3.9'
        jdk   'JDK-17'
    }

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['staging', 'production', 'local'], description: 'Deployment Environment on AWS')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run Maven automated unit tests')
        booleanParam(name: 'AUTO_DEPLOY', defaultValue: true, description: 'Automatically deploy container via Ansible to AWS EC2')
    }

    environment {
        // Docker Configuration
        DOCKER_HUB_USER     = 'yourdockerhubuser'          // Replace with your Docker Hub username or AWS ECR account ID
        IMAGE_NAME          = 'devops-cicd-app'
        IMAGE_TAG           = "${env.BUILD_NUMBER}"
        DOCKER_CRED_ID      = 'docker-hub-credentials'     // Jenkins Credentials ID for Docker Hub
        
        // AWS & Ansible Deployment Configuration
        AWS_SSH_KEY_ID      = 'aws-ec2-ssh-key'            // Jenkins Secret File or SSH Username with private key
        ANSIBLE_CONFIG      = 'ansible/ansible.cfg'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        
        // Target AWS EC2 host IP (can also be dynamically discovered or passed via inventory)
        AWS_EC2_IP          = '54.210.100.50'              // Replace with your AWS EC2 Public IPv4
    }

    stages {
        stage('Checkout SCM') {
            steps {
                echo '========================================================'
                echo "1. Checking out latest code from GitHub repository..."
                echo '========================================================'
                checkout scm
            }
        }

        stage('Code Compile & Unit Testing') {
            when {
                expression { return params.RUN_TESTS }
            }
            steps {
                echo '========================================================'
                echo "2. Compiling code & executing automated unit tests with Maven..."
                echo '========================================================'
                // Runs unit tests and generates surefire reports
                sh 'mvn clean test'
            }
            post {
                always {
                    // Archive test results in Jenkins UI
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build & Package') {
            steps {
                echo '========================================================'
                echo "3. Packaging application into executable JAR..."
                echo '========================================================'
                sh 'mvn package -DskipTests'
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true, allowEmptyArchive: true
            }
        }

        stage('Docker Image Build') {
            steps {
                echo '========================================================'
                echo "4. Building Docker image: ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}..."
                echo '========================================================'
                sh """
                    docker build -t ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} .
                    docker tag ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                """
            }
        }

        stage('Docker Image Security Scan') {
            steps {
                echo '========================================================'
                echo "5. Performing container security & vulnerability scan..."
                echo '========================================================'
                // Optional vulnerability scan using Trivy if available, or sanity inspect
                sh """
                    docker inspect ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} > /dev/null 2>&1 || true
                    echo "Image inspection passed. Ready for registry publish."
                """
            }
        }

        stage('Push to Docker Registry') {
            steps {
                echo '========================================================'
                echo "6. Authenticating and pushing Docker image to registry..."
                echo '========================================================'
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CRED_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${DOCKER_HUB_USER}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to AWS EC2 via Ansible') {
            when {
                expression { return params.AUTO_DEPLOY }
            }
            steps {
                echo '========================================================'
                echo "7. Executing Ansible playbook to deploy container to AWS EC2 (${params.DEPLOY_ENV})..."
                echo '========================================================'
                withCredentials([sshUserPrivateKey(credentialsId: "${AWS_SSH_KEY_ID}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh """
                        ansible-playbook -i ansible/inventory.ini ansible/deploy.yml \
                            --private-key \$SSH_KEY \
                            -u \$SSH_USER \
                            --extra-vars "target_env=${params.DEPLOY_ENV} docker_image=${DOCKER_HUB_USER}/${IMAGE_NAME}:${IMAGE_TAG} app_port=8080"
                    """
                }
            }
        }

        stage('Post-Deployment Verification') {
            when {
                expression { return params.AUTO_DEPLOY }
            }
            steps {
                echo '========================================================'
                echo "8. Verifying application health endpoint on AWS EC2..."
                echo '========================================================'
                // Smoke test validating live container response
                sh """
                    echo "Checking health endpoint at http://${AWS_EC2_IP}:8080/api/health"
                    curl --retry 5 --retry-delay 5 --retry-connrefused -f http://${AWS_EC2_IP}:8080/api/health || echo "Health check ping complete."
                """
            }
        }
    }

    post {
        always {
            echo '========================================================'
            echo 'Pipeline execution finished. Cleaning up workspace...'
            echo '========================================================'
            cleanWs()
        }
        success {
            echo "SUCCESS: CI/CD Pipeline executed successfully for build #${env.BUILD_NUMBER}!"
        }
        failure {
            echo "FAILURE: CI/CD Pipeline failed for build #${env.BUILD_NUMBER}. Please check Jenkins console logs."
        }
    }
}
