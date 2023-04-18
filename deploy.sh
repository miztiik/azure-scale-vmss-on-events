# set -x
set -e

# Set Global Variables
MAIN_BICEP_TEMPL_NAME="main.bicep"
LOCATION=$(jq -r '.parameters.deploymentParams.value.location' params.json)
SUB_DEPLOYMENT_PREFIX=$(jq -r '.parameters.deploymentParams.value.sub_deploymnet_prefix' params.json)
ENTERPRISE_NAME=$(jq -r '.parameters.deploymentParams.value.enterprise_name' params.json)
ENTERPRISE_NAME_SUFFIX=$(jq -r '.parameters.deploymentParams.value.enterprise_name_suffix' params.json)
GLOBAL_UNIQUENESS=$(jq -r '.parameters.deploymentParams.value.global_uniqueness' params.json)

RG_NAME="${ENTERPRISE_NAME}_${ENTERPRISE_NAME_SUFFIX}_${GLOBAL_UNIQUENESS}"


# # Generate and SSH key pair to pass the public key as parameter
# ssh-keygen -m PEM -t rsa -b 4096 -C '' -f ./miztiik.pem

# pubkeydata=$(cat miztiik.pem.pub)



# Function Deploy all resources
function deploy_everything()
{
az bicep build --file $1

# Initiate Deployments
echo -e "\033[33m Initiating Subscription Deployment \033[0m" # Yellow
echo -e "\033[32m  - ${SUB_DEPLOYMENT_PREFIX}"-"${GLOBAL_UNIQUENESS} at ${LOCATION} \033[0m" # Green

az deployment sub create \
    --name ${SUB_DEPLOYMENT_PREFIX}"-"${GLOBAL_UNIQUENESS}"-Deployment" \
    --location ${LOCATION} \
    --parameters @params.json \
    --template-file $1 \
    # --confirm-with-what-if
}

function shiva_de_destroyer {
  if [[ $1 == "shiva" ]]; then
    echo "|------------------------------------------------------------------|"
    echo "|                                                                  |"
    echo "|                   Shiva the destroyer in action                  |"
    echo "|             Beginning the end of the Miztiikon Universe          |"
    echo "|                                                                  |"
    echo "|------------------------------------------------------------------|"
    

    # Delete Subscription deployments
    echo -e "\033[33m Initiating Subscription Deployment Deletion \033[0m" # Yellow
    echo -e "\033[31m  - ${SUB_DEPLOYMENT_PREFIX}"-"${GLOBAL_UNIQUENESS} \033[0m" # Red

    az deployment sub delete \
        --name ${SUB_DEPLOYMENT_PREFIX}"-"${GLOBAL_UNIQUENESS}"-Deployment"
    
    echo -e "\033[33m Initiating Resource Group Deletion \033[0m" # Yellow
    echo -e "\033[31m  - ${RG_NAME} \033[0m" # Red

    az deployment sub delete \
        --name ${RG_NAME}

    # Delete a resource group without confirmation
    az group delete \
        --name ${RG_NAME} --yes \
        --no-wait
  fi
}

deploy_everything $MAIN_BICEP_TEMPL_NAME


# Universal DESTROYER BE CAREFUL
# shiva_de_destroyer $1
