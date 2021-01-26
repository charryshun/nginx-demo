pipeline {
    agent {
    kubernetes {
        yaml """
apiVersion: v1
kind: Pod
spec:
  volumes:
  - name: docker-socket
    emptyDir: {}
  containers:
  - name: docker
    image: simonzhaohui/jenkins-slave:latest
    command:
    - sleep
    args:
    - 99d
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run
  - name: docker-daemon
    image: simonzhaohui/dind:latest
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run
"""
        }
    }
    environment {
       EPOCH = sh(returnStdout: true, script: 'date +%s').trim()
       EXTERNAL_IP = "169.51.207.177"
    }
    stages {
        stage('Setup Environment') {
            steps {
                container('docker') {
                  sh "echo setup environment"  
                }
            }
        }
        stage('Build image') {
            when { anyOf { branch 'master'; branch 'PR-*' } }
            steps {
                container('docker') {
                    withCredentials([
                        string(
                            credentialsId: 'REGISTRY_TOKEN',
                            variable: 'REGISTRY_TOKEN')
                    ]) {
                        sh "make build"
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            when { anyOf { branch 'master'; branch 'PR-*' } }
            steps {
                script {
                    container('docker') {
                        String IMAGE_NAME = sh(returnStdout: true, script: 'make fetch-image-name').trim()
                        String IMAGE_TAG = sh(returnStdout: true, script: 'make fetch-image-tag').trim()
                        withCredentials([
                        string(
                            credentialsId: 'IBMCLOUD_TOKEN',
                            variable: 'IBMCLOUD_TOKEN')
                    ]) {
                        sh 'ibmcloud login -a cloud.ibm.com -r us-south --apikey ${IBMCLOUD_TOKEN} -q'
                        sh 'ibmcloud plugin install container-service -f -q;ibmcloud plugin list'
                        sh 'ibmcloud cs cluster config --cluster kube-us-south-01 -q'
                        sh 'kubectl get namespaces; kubectl get pods -n jenkins'
                        sh 'helm repo add nginx-stable https://helm.nginx.com/stable; helm repo update'
                        if (env.BRANCH_NAME == 'master') {
                            env.NAMESPACE = 'nginx-hello'
                            sh """
                            helm upgrade ${env.NAMESPACE} nginx-stable/nginx-ingress -n ${env.NAMESPACE} \
                                --set controller.image.repository=$IMAGE_NAME \
                                --set controller.image.tag=$IMAGE_TAG \
                                --set controller.enableCustomResources=false \
                                --set controller.ingressClass=${env.NAMESPACE} \
                                --set controller.image.pullPolicy=Always \
                                --create-namespace 
                            """
                        } else {
                            env.NAMESPACE = "nginx-hello-test-${env.EPOCH}"
                            sh """
                            helm install ${env.NAMESPACE} nginx-stable/nginx-ingress -n ${env.NAMESPACE} \
                                --set controller.image.repository=$IMAGE_NAME \
                                --set controller.image.tag=$IMAGE_TAG \
                                --set controller.enableCustomResources=false \
                                --set controller.ingressClass=${env.NAMESPACE} \
                                --set controller.image.pullPolicy=Always \
                                --create-namespace 
                            """
                        }
                        // deployment validation
                        String EXTERNAL_PORT = sh(
                            returnStdout: true,
                            script: "kubectl get svc ${env.NAMESPACE}-nginx-ingress -n ${env.NAMESPACE} -o json | jq '.spec.ports[]|select(.name==\"http\")|.nodePort'"
                        ).trim()
                        // wait for helm deployment
                        sleep 15
                        sh "curl http://${env.EXTERNAL_IP}:${EXTERNAL_PORT}/ 2>/dev/null --connect-timeout 3"

                        //uninstall deployment for non master branch
                        if (env.BRANCH_NAME != 'master') {
                            sh """
                            helm uninstall ${env.NAMESPACE} -n ${env.NAMESPACE}
                            kubectl delete namespace ${env.NAMESPACE}
                            """
                            }
                        }
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                sh "echo finished"
            }
        }
    }
}
