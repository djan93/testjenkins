node {
  def acr = 'acrdemo4.azurecr.io'
  def appName = 'whoami'
  def imageName = "${acr}/${appName}"
  def imageTag = "${imageName}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
  def appRepo = "acrdemo4.azurecr.io/whoami:latest"

  checkout scm
  
 stage('Build the Image and Push to Azure Container Registry') 
 {
   app = docker.build("${imageName}")
   withDockerRegistry([credentialsId: 'acr_auth', url: "https://${acr}"]) {
      app.push("${env.BRANCH_NAME}.${env.BUILD_NUMBER}")
                }
  }

 stage ("Deploy Application on Azure Kubernetes Service")
 {
  switch (env.BRANCH_NAME) {
    // Roll out canary to production environment
    case "canary":
        // Change deployed image in canary to the one we just built
        sh("sed -i.bak 's#${appRepo}#${imageTag}#' ./k8s/production/*.yml")
        sh("sudo kubectl --kubeconfig ~daniel/.kube/config --namespace=prod apply -f k8s/production/")
        sh("echo http://`kubectl --namespace=prod get service/${appName} --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${appName}")
        break

    // Roll out master toproduction
    case "master":
        // Change deployed image in master to the one we just built
        sh("sed -i.bak 's#${appRepo}#${imageTag}#' ./k8s/production/*.yml")
        sh("sudo kubectl --kubeconfig ~daniel/.kube/config --namespace=prod apply -f k8s/production/")
        sh("echo http://`kubectl --namespace=prod get service/${appName} --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${appName}")
        break

        // Roll out release to stage
    case "release":
        // Change deployed image in master to the one we just built
        sh("sed -i.bak 's#${appRepo}#${imageTag}#' ./k8s/stage/*.yml")
        sh("sudo kubectl --kubeconfig ~daniel/.kube/config --namespace=stage apply -f k8s/stage/")
        sh("echo http://`kubectl --namespace=stage get service/${appName} --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${appName}")
        break

        // Roll out dev to dev
    case "dev":
        // Change deployed image in master to the one we just built
        sh("sed -i.bak 's#${appRepo}#${imageTag}#' ./k8s/dev/*.yml")
        sh("sudo kubectl --kubeconfig ~daniel/.kube/config --namespace=dev apply -f k8s/dev/")
        sh("echo http://`kubectl --namespace=dev get service/${appName} --output=json | jq -r '.status.loadBalancer.ingress[0].ip'` > ${appName}")
        break

    // Roll out a dev environment
    default:
        // Create namespace if it doesn't exist
        sh("kubectl get ns ${appName}-${env.BRANCH_NAME} || kubectl create ns ${appName}-${env.BRANCH_NAME}")
        withCredentials([usernamePassword(credentialsId: 'acr_auth', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
          sh "kubectl -n ${appName}-${env.BRANCH_NAME} get secret mysecret || kubectl --namespace=${appName}-${env.BRANCH_NAME} create secret docker-registry mysecret --docker-server ${acr} --docker-username $USERNAME --docker-password $PASSWORD"
        }  
        sh("sed -i.bak 's#${appRepo}#${imageTag}#' ./k8s/dev/*.yml")
        sh("kubectl --namespace=${appName}-${env.BRANCH_NAME} apply -f k8s/dev/")
        echo 'To access your environment run `kubectl proxy`'
        echo "Then access your service via http://localhost:8001/api/v1/namespaces/${appName}-${env.BRANCH_NAME}/services/${appName}:80/proxy/"       
    }
  }
}