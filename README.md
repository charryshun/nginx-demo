## Nginx Service Demo for DevOps

This project is for CI/CD pipeline using nginx service on kubernetes cluster. In this demo, implement below steps:
  - Build nginx-ingress image and push to dockerhub
  - Deploy nginx-ingress service on kubernetes cluster using the customized image

## Deployment Prerequisite
For building docker images in kubernetes pods, and running some scripts, I prepared two docker images as Jenkins agent slaves.
  - docker image: `simonzhaohui/jenkins-slave:latest`
  - docker image: `simonzhaohui/dind:latest`

## Detail Configurations

### Deploy Jenkins Server Kubernetes Cluster
  - Provision one free Kubernetes Cluster on IBM Cloud. In this demo, the kube cluster is `kube-us-south-01`
  - Deploy Jenkins server using helm chart. Due to free account, skip persistence storage for Jenkins server, and expose Jenkins server with `NodePort`.
```
$ helm install jenkins jenkins/jenkins --namespace jenkins \
        --set persistence.enabled=False \
        --set controller.serviceType=NodePort \
        --set controller.resources.limits.cpu=1000m \
        --set controller.resources.limits.memory=1024Mi
NAME: jenkins
LAST DEPLOYED: Mon Jan 25 17:42:01 2021
NAMESPACE: jenkins
STATUS: deployed
REVISION: 1
NOTES:
1. Get your 'admin' user password by running:
  kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/chart-admin-password && echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  export NODE_PORT=$(kubectl get --namespace jenkins -o jsonpath="{.spec.ports[0].nodePort}" services jenkins)
  export NODE_IP=$(kubectl get nodes --namespace jenkins -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT/login

...
```
   - Configure Jenkins webhook in current Github project. The Jenkins job will be triggered by Pull or Push requests.
   - Add Github Token and kubernetes IAM API key to Jenkins Credentials

#### CI/CD Implementation in Jenkinsfile
- The `nginx-ingress` demo image is based on image `nginx/nginx-ingress:1.9.1`, and pushed to docker hub under account `simonzhaohui`, the format of image tag is `<VERSION>-<BRNACH>-<EPOCH>`.
- The nginx ingress is deployed using helm chart `nginx-stable/nginx-ingress` with the above customized docker image.
- The default webpage `index.html` of nginx ingress service is customized, output messages like:
```
$ curl http://169.51.207.177:31819/
hello world generated from branch master
```
- If branch is non master branch, the steps of build image and deployment are skipped
- For all PRs, the image tag should be like `0.0.1-PR-2-1611633819`, and deploy to kube cluster. After validation, the helm release and namespace will be removed.
- Under branch master, the image tag should be like `0.0.1-master-1611633819`, and upgrade helm chart with kube namespace `nginx-hello`.


### The project directory is:

```
├── Jenkinsfile     --> Jenkinsfile for CI/CD pipeline
├── Makefile        --> build docker image        
├── README.md
└── nginx-hello     --> The Dockerfile for nginx hello demo
    ├── Dockerfile
    ├── index.html
    └── nginx.tmpl
```