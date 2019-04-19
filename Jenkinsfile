properties([
    parameters(
        [
        booleanParam(name: 'DEPLOY_BRANCH_TO_TST', defaultValue: false),

        text(name: 'Remarks', defaultValue: 'Release Manager', description: 'Why this pipeline is running?'),

        string(name: 'DOCKER_USER', defaultValue: 'saeedalbarhami', description: 'Enter user info docker hub'),

        password(name: 'DOCKER_PASS', defaultValue: '******', description: 'Enter a password'),

        choice(name: 'CHOICE', choices: ['Build Only', 'Build & Deploy to QA', 'Build & Deploy to QA & Prod'], description: 'Attention Please'),
       
    ])

])

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
              volumes:
              - name: repository
                persistentVolumeClaim:
                  claimName: jenkins
              - name: docker-sock
                hostPath:
                  path: /var/run/docker.sock
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
        stage ('Running Unit Tests') {
            steps {
                container('maven') {
                    sh 'mvn test'
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
        stage ('Building Container Image') {
            steps {
                container('docker') {
                    script {
                        registryIp = 'saeedalbarhami'
                        sh "docker build . -t ${registryIp}/demo1:${revision} --build-arg REVISION=${revision}"
                    }
                }
            }
                }
        stage ('publish Container Image') {
            when {
                expression {
                    branch == 'master' || params.DEPLOY_BRANCH_TO_TST
                }
            }
            steps {
                container('docker') {
                    sh "docker login -u ${params.DOCKER_USER} -p ${params.DOCKER_PASS}"
                    sh "docker push ${registryIp}/demo1:${revision}"
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
                
                 echo 'Thank you '
            }
        }
    }
}
