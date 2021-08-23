## setup AKS
## Install Azure CLI on Mac with brew update && brew install azure-cli
## Docker CLI and Docker daemon must be installed and running


# Login options https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli
az login

# create resource group
az group create --name shiny_aks --location westeurope

# create pricing plan for the resource group
az appservice plan create -g shiny_aks -n shinybaseplan --sku B1 --is-linux # didn't work with Switzerland location for some reason

# Docker
# create a container registry - place to hold container images (like DockerHub) - name has to be unique across the full server
# https://docs.microsoft.com/cs-cz/azure/container-registry/container-registry-get-started-azure-cli

az acr create --resource-group shiny_aks --name vnahodildockerimgs --sku Basic
az acr repository list --name vnahodildockerimgs # should be empty

# have a shiny server image on your machine
docker run -h shinyserver -p 3838:3838 rocker/shiny
# sample app should be running now on http://localhost:3838/sample-apps/hello/

# tag the existing image on your machine with the full name of the acr + slash + name we want to use for it on Azure
docker tag rocker/shiny:latest vnahodildockerimgs.azurecr.io/shinyserver

# login to ACR using the token created when running az login
az acr login -n vnahodildockerimgs

# push the image to the container registry
docker push vnahodildockerimgs.azurecr.io/shinyserver

# check if it is there
az acr repository list -n vnahodildockerimgs

# deploy the image after enabling admin rights
az acr update -n vnahodildockerimgs --admin-enabled true
az webapp create -g shiny_aks -p shinybaseplan -n myshinyserver -i vnahodildockerimgs.azurecr.io/shinyserver

# output JSON shows the path to the new app:   "defaultHostName": "myshinyserver.azurewebsites.net",

# clean up everything at the end
az group delete -n shiny_aks


# TODO
# multicontainer app - Make sure you have all images in your acr and the YAML file in the folder you execute the line from.
az webapp create -g shinyapps -p shinyappplan -n myshinyapp
   --multicontainer-config-type compose
   --multicontainer-config-file docker-compose.yml



# AKS
# register monitoring containers
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights

# check if registered
az provider show -n Microsoft.OperationsManagement -o table
az provider show -n Microsoft.OperationalInsights -o table


# create AKS cluster with one node and enabled monitoring
az aks create --resource-group shiny_aks --name shiny_aks_cluster --node-count 1 --enable-addons monitoring --generate-ssh-keys