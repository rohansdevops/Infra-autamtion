pipeline {
    agent any

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Select the action to perform')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_Access_Key')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_Secret_Access_Key')
        AWS_DEFAULT_REGION    = 'eu-north-1'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/rohansdevops/Infra-autamtion.git'
            }
        }
        stage('Terraform init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Plan') {
            steps {
                sh 'terraform plan -out tfplan'
                sh 'terraform show -no-color tfplan > tfplan.txt'
            }
        }
        stage('Apply / Destroy') {
            steps {
                script {
                    if (params.action == 'apply') {
                        if (!params.autoApprove) {
                            def plan = readFile 'tfplan.txt'
                            input message: "Do you want to apply the plan?",
                            parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                        }

                        sh "terraform ${action} -input=false tfplan"
                    } else if (params.action == 'destroy') {
                        sh "terraform ${action} --auto-approve"
                    } else {
                        error "Invalid action selected. Please choose either 'apply' or 'destroy'."
                    }
                }
            }
        }
        stage('Configure EC2 waiting for running status') {
            steps {
                sh 'sleep 90'
            }
        }
        stage('Deployment Validation') {
            when {
                expression { return params.action == 'apply'}
            }
            steps {
                script {
                    def public_ip = sh(script: "terraform output -raw instance_public_ip", returnStdout: true).trim()
                    
                    def response = sh(script: "curl -s http://$public_ip", returnStdout: true).trim()

                    
                    echo "Response: ${response}"

                    def normalizedResponse = response.replaceAll("–", "-").trim()

                    echo "Normalized Response: ${normalizedResponse}"

                    if(!normalizedResponse.contains("CSA DevOps Exam - Instance IP:")) {
                        error "Deployment validation failed"
                    }
                }
            }
        }
        stage('Output Result') {
            when {
                expression { return params.action == 'apply'}
            }
            steps {
                script {
                    def public_ip = sh(script: "terraform output -raw instance_public_ip", returnStdout: true).trim()
                    echo "Application is deployed at http://$public_ip"
                }
            }
        }
    }
}