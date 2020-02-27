#!/bin/bash

USER_NAME=test
SERVICE_ACCOUNT_NAME=sa-name
NAMESPACE_NAME=testing-namespace
KUBE_URL="https://0.0.0.0:6443" #URL of your kubernetes cluster. you can get it by running "kubectl cluster-info"
KUBE_CA_CERT_FILE="/etc/kubernetes/pki/ca.crt"
SERVICE_ACCOUNT_BASED_ACCESS="service-account-base-user-access.yaml"


#Checking namespace Exist or Not
kubectl get ns |grep $NAMESPACE_NAME

if [[ $(kubectl get ns |grep $NAMESPACE_NAME) ]]; then
    echo -e "\e[1;32m$NAMESPACE_NAME namespace is exist running the next commands\e[0m"
else
    echo -e "\e[1;31m$NAMESPACE_NAME namepsace is not created yet >>>>>>>>>>>>>>>>  create $NAMESPACE_NAME namespace first......GOOD BYE!!!!!!!\e[0m"; exit 1;
fi

kubectl get po -n $NAMESPACE_NAME

#Creating User ServiceAccount, role & rolebinding and get token to configure kubeconfig for accessing kubernetes cluster.........
echo "Creating ServiceAccount and kubeconfig file for $USER_NAME user"

useradd $USER_NAME

grep -rl 'namespace-name' $SERVICE_ACCOUNT_BASED_ACCESS | xargs sed -i "s|namespace-name|$NAMESPACE_NAME|g"
grep -rl 'sa-name' $SERVICE_ACCOUNT_BASED_ACCESS | xargs sed -i "s|sa-name|$SERVICE_ACCOUNT_NAME|g"

kubectl apply -f $SERVICE_ACCOUNT_BASED_ACCESS

cp $KUBE_CA_CERT_FILE /home/$USER_NAME

chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/*

# Change sa and namespace name from $SERVICE_ACCOUNT_BASED_ACCESS

grep -rl $NAMESPACE_NAME $SERVICE_ACCOUNT_BASED_ACCESS | xargs sed -i "s|$NAMESPACE_NAME|namespace-name|g"
grep -rl $SERVICE_ACCOUNT_NAME $SERVICE_ACCOUNT_BASED_ACCESS | xargs sed -i "s|$SERVICE_ACCOUNT_NAME|sa-name|g"

TOKENNAME=`kubectl -n $NAMESPACE_NAME get sa $SERVICE_ACCOUNT_NAME -o jsonpath='{.secrets[0].name}'`
TOKEN=`kubectl -n $NAMESPACE_NAME get secret $TOKENNAME -o jsonpath='{.data.token}' | base64 -d`

su - $USER_NAME -c "kubectl config set-cluster kubernetes --server=$KUBE_URL --certificate-authority=/home/$USER_NAME/ca.crt"
su - $USER_NAME -c "kubectl config set-credentials $SERVICE_ACCOUNT_NAME --token=$TOKEN"
su - $USER_NAME -c "kubectl config set-context $SERVICE_ACCOUNT_NAME --cluster=kubernetes --user=$SERVICE_ACCOUNT_NAME --namespace=$NAMESPACE_NAME"
su - $USER_NAME -c "kubectl config use-context $SERVICE_ACCOUNT_NAME"
su - $USER_NAME -c "kubectl get po"


su - $USER_NAME -c "kubectl get po"
su - $USER_NAME -c "kubectl get svc"

echo -e "\e[1;32mJob Succeeded:)\e[0m"
