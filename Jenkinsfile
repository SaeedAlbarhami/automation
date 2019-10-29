properties([
    parameters(
        [ 
        booleanParam(name: 'DEPLOY_BRANCH_TO_TST', defaultValue: false),

        text(name: 'Remarks', defaultValue: 'Release Manager', description: 'Why this pipeline is running?'),

        string(name: 'DOCKER_USER', defaultValue: 'saeedalbarhami', description: 'Enter user info docker hub'),

        password(name: 'DOCKER_PASS', defaultValue: '******', description: 'Enter a password'),

        choice(name: 'CHOICE', choices: ['Continuous Integration', 'Build & Deploy to QA', 'Build & Deploy Production'], description: 'Attention Please'),
       
    ])

])

/*
    Helm install
 */
def helmInstall (namespace, release) {
    echo "Installing ${release} in ${namespace}"

    script {
        release = "${release}-${namespace}"
        sh "helm repo add helm ${HELM_REPO}; helm repo update"
        sh """
            helm upgrade --install --namespace ${namespace} ${release} \
                --set image.repository=${registryIp}/automation,image.tag=${revision} helm/acme
        """
        sh "sleep 5"
    }
}

def branch
def revision
def registryIp

pipeline {
        agent {
        kubernetes {
            label 'build-service-pod'
            defaultContainer 'jnlp'
            yaml """
            apiVersion: v1
            kind: Pod
            metadata:
              labels:
                job: build-service
            spec:
              containers:
              - name: maven
                image: maven:3.6-jdk-8-alpine
                command: ["cat"]
                tty: true
                volumeMounts:
                - name: repository
                  mountPath: /root/.m2/repository
              - name: docker
                image: docker:18.09.2
                command: ["cat"]
                tty: true
                volumeMounts:
                - name: docker-sock
                  mountPath: /var/run/docker.sock
              - name: kubectl
                image: lachlanevenson/k8s-kubectl:v1.4.8
                command: ["cat"]
                tty: true
                volumeMounts:
                - name: k8s-kubectl
                  mountPath: /var/k8s-kubectl
              volumes:
              - name: repository
                hostPath:
                  path: /var/jenkins-repo
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
              - name: k8s-kubectl
                hostPath:
                  path: /var/k8s-kubectl              
            """
        }
    }
    options {
        skipDefaultCheckout true
    }

    stages {
        stage ('Checking Out The Latest Changes') {
            steps {
                script {
                    def repo = checkout scm
                    revision = sh(script: 'git log -1 --format=\'%h.%ad\' --date=format:%Y%m%d-%H%M | cat', returnStdout: true).trim()
                    branch = repo.GIT_BRANCH.take(20).replaceAll('/', '_')
                    if (branch != 'master') {
                        revision += "-${branch}"
                    }
                    sh "echo ${branch}"
                    sh "echo 'Building revision: ${revision}'"
                }
            }

        }
        stage ('Clean & Compile The Code') {
            steps {
                container('maven') {
                    sh 'mvn clean compile'
                }
            }
        }
        stage ('Running Unit Tests - SonarQube') {
            steps {
                container('maven') {
                    sh 'mvn sonar:sonar  -Dsonar.projectKey=automation1  -Dsonar.host.url=http://10.100.96.224:9000 -Dsonar.login=cd38448ccd16b8afb53b054f7e3217fa5ceb5ea6'
                }
            }
        }
        stage ('Running Integration Tests') {
            steps {
                container ('maven') {
                    sh 'mvn verify'
                }
            }
        }
        stage ('Building Artifact') {
            steps {
                container('maven') {
                    sh "mvn package -Dmaven.test.skip -Drevision=${revision}"
                }
            }
        }
        stage ('Building & Pushing Container Image') {
            when {
                expression {
                    branch == 'master' || params.DEPLOY_BRANCH_TO_TST
                }
            }
            steps {
                container('docker') {
                    script {
                        registryIp = 'saeedalbarhami'
                        sh "docker build . -t ${registryIp}/automation:${revision} --build-arg REVISION=${revision}"
                        sh "docker login -u ${params.DOCKER_USER} -p ${params.DOCKER_PASS}"
                        sh "docker push ${registryIp}/automation:${revision}"
                    }
                }
            }
         }
      
        stage ('Deploy The New Version Of The Application To K8S') {
          
            when {
                expression {
                    branch == 'master' || params.DEPLOY_BRANCH_TO_TST
                }
            }
            steps {
                container('kubectl')
                {
                    sh "kubectl version"
                    // Deploy with helm
                    echo "Deploying"
                    
                                       
                }
                 echo 'Thank you '
            }
        }
    }
}
