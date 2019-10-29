library('pipelines-configuration')

def container_image = "automation"
def helm_chart = "automation"
def namespace = "default"
def branch="master"
def revision =''
def env ='qa'
def sourcecodeurl= 'https://github.com/SaeedAlbarhami/automation'
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
              - name: helm
                image: linkyard/concourse-helm-resource
                command: ["cat"]
                tty: true
                volumeMounts:
                - name: concourse-helm-resource
                  mountPath: /var/concourse-helm-resource  
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
              - name: concourse-helm-resource
                hostPath:
                  path: /var/concourse-helm-resource                   
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
                    revision=clone.getsourcecode(sourcecodeurl, branch) 
                }
            }
        } 
        stage ('Clean, Test & Compile The Code') {
            steps {
                container('maven') {
                    sh 'mvn clean compile'
                    sh 'mvn test'
                    sh 'mvn clean verify'	
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
            steps {
                script
                    {
                       container_package.build_push(container_image, revision)
                    }
             }
         }        
       stage ('HELM Deployment') {
            steps {
                script
                   {
                       helm.install_upgrade(helm_chart, revision, namespace, env)
                   }
                }
            }
        }
}
