pipeline {
    agent any

    environment {
        // Jenkins credentials ID for AWS Access Key and Secret Key
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {
        stage('Checkout') {
            steps {
                // Checkout your source code from your SCM
                git 'https://your-repo-url.git'
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    terraform init
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    terraform plan -out=tfplan
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    terraform apply -auto-approve tfplan
                    '''
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


### Explanation:

1. **Environment Variables in Jenkins:**
   - `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set using Jenkins credentials. These credentials should match the IDs you used when storing the AWS keys in Jenkins.

2. **withCredentials Block:**
   - The `withCredentials` step sets the AWS credentials as environment variables for the duration of the script block.

3. **Terraform Commands:**
   - `terraform init`: Initializes the Terraform working directory.
   - `terraform plan -out=tfplan`: Creates an execution plan and saves it to a file named `tfplan`.
   - `terraform apply -auto-approve tfplan`: Applies the plan saved in the `tfplan` file automatically without requiring manual approval.

### Storing AWS Credentials in Jenkins:

1. **Add AWS Access Key ID:**
   - Go to `Manage Jenkins` > `Manage Credentials`.
   - Select `(global)` > `Add Credentials`.
   - Select `Secret text` as the kind.
   - Enter your AWS Access Key ID.
   - Give it an ID like `aws-access-key-id`.

2. **Add AWS Secret Access Key:**
   - Repeat the steps above, but this time enter your AWS Secret Access Key and give it an ID like `aws-secret-access-key`.