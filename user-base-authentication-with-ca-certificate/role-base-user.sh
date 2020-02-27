#!/bin/bash

USER_NAME=test
NAMESPACE_NAME=testing-namespace
KUBE_URL="https://0.0.0.0:6443" #URL of your kubernetes cluster. you can get it by running "kubectl cluster-info"
KUBE_CA_CERT_FILE="/etc/kubernetes/pki/ca.crt"
KUBE_CA_KEY_FILE="/etc/kubernetes/pki/ca.key"
ROLE_BASED_ACCESS="role-and-binding-base-user-access.yaml"

#Checking namespace Exist or Not
kubectl get ns |grep $NAMESPACE_NAME

if [[ $(kubectl get ns |grep $NAMESPACE_NAME) ]]; then
    echo -e "\e[1;32m$NAMESPACE_NAME namespace is exist\e[0m"
else
    echo -e "\e[1;31m$NAMESPACE_NAME namepsace is not exist...create first\e[0m"; exit 1;
fi

kubectl get po -n $NAMESPACE_NAME

#Creating User certificate and kubeconfig for accessing kubernetes cluster.........
echo "Creating certificate and kubeconfig file for $USER_NAME user"

useradd $USER_NAME

grep -rl 'namespace-name' $ROLE_BASED_ACCESS | xargs sed -i "s|namespace-name|$NAMESPACE_NAME|g"
grep -rl 'username' $ROLE_BASED_ACCESS | xargs sed -i "s|username|$USER_NAME|g"
grep -rl 'namespace-name' $Coffee_Deployment | xargs sed -i "s|namespace-name|$NAMESPACE_NAME|g"

kubectl apply -f $ROLE_BASED_ACCESS

openssl genrsa -out $USER_NAME.key 2048
openssl req -new -key $USER_NAME.key -out $USER_NAME.csr -subj /CN=$USER_NAME
openssl x509 -req -in $USER_NAME.csr -CA $KUBE_CA_CERT_FILE -CAkey $KUBE_CA_KEY_FILE -CAcreateserial -out $USER_NAME.crt -days 500 -sha256

cp $USER_NAME.* /home/$USER_NAME
cp $KUBE_CA_CERT_FILE /home/$USER_NAME

chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/*

# Change user name from $ROLE_BASED_ACCESS

grep -rl $NAMESPACE_NAME $ROLE_BASED_ACCESS | xargs sed -i "s|$NAMESPACE_NAME|namespace-name|g"
grep -rl $USER_NAME $ROLE_BASED_ACCESS | xargs sed -i "s|$USER_NAME|username|g"


su - $USER_NAME -c "kubectl config set-cluster kubernetes --server=$KUBE_URL --certificate-authority=/home/$USER_NAME/ca.crt"
su - $USER_NAME -c "kubectl config set-credentials $USER_NAME --client-certificate=$USER_NAME.crt --client-key=$USER_NAME.key --certificate-authority=/home/$USER_NAME/ca.crt"
su - $USER_NAME -c "kubectl config set-context $USER_NAME --cluster=kubernetes --namespace=$NAMESPACE_NAME --user=$USER_NAME"
su - $USER_NAME -c "kubectl config use-context $USER_NAME"
su - $USER_NAME -c "kubectl get po"


su - $USER_NAME -c "kubectl get po"
su - $USER_NAME -c "kubectl get svc"  # You will get (Forbidden): services is forbidden: User "test" cannot list resource "services" in API group "" in the namespace "" because we haven't create role for this resource.

echo -e "\e[1;32mJob Succeeded:)\e[0m"

