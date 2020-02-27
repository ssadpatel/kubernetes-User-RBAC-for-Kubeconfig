# kubernetes-User-RBAC-for-Kubeconfig

We can authenticate users using kubectl in kubernetes with below two way!!!!

1. User base authentication with kubernetes CA certificate.
2. User base authentication with kubernetes service account token. 

####################################################################################

# 1. User base authentication with kubernetes CA certificate.

Creating a test-namespace.

$ kubectl create ns test-namespace

Creating role and rolebinding for accessing kubernetes cluster.........
Replace namespace and username with your in role-and-binding-base-user-access.yaml file !!!!

`$ kubectl apply -f user-base-authentication-with-ca-certificate/role-and-binding-base-user-access.yaml`

Now creating user certificate to authenticate kubernetes cluster. Creating certificate for user: test  

`$ openssl genrsa -out test.key 2048`
`$ openssl req -new -key test.key -out test.csr -subj /CN=test`
`$ openssl x509 -req -in test.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out test.crt -days 500 -sha256`

Set the context for user test. Add a new user and copy the certs file to their home direcotry and run the below command. 

$ su - test

$ kubectl config set-cluster kubernetes --server=KUBE-URL --certificate-authority=/home/test/ca.crt
$ kubectl config set-credentials test --client-certificate=test.crt --client-key=test.key --certificate-authority=ca.crt
$ kubectl config set-context test --cluster=kubernetes --namespace=test-namespace --user=test
$ kubectl config use-context test
$ kubectl get po




# 2. User base authentication with kubernetes service account token.

Creating service account, role and rolebinding for accessing kubernetes cluster.........
 Change the sa-name and namespace with your in service-account-base-user-access.yaml file !!!!

$ kubectl apply -f user-base-authentication-with-service-account-token/service-account-base-user-access.yaml

Storing token name in TOKEN-NAME variable which we will use in next step.. 

$ TOKEN-NAME=`kubectl -n test-namespace get sa service-account-name -o jsonpath='{.secrets[0].name}'`

stroing token in TOKEN variable after decode the token value.. 

$ TOKEN=`kubectl -n test-namespace get secret $TOKEN-NAME -o jsonpath='{.data.token}' | base64 -d`


Set the context for user test. Add a new user and copy the kubernetes ca cert file to their home direcotry and run the below command.
 In '--user' we have to use the same name which we are using in service-account. 


$ kubectl config set-cluster kubernetes --server=KUBE-URL --certificate-authority=/home/test/ca.crt
$ kubectl config set-credentials service-account-name --token='use the token which is generated and decoded'
$ kubectl config set-context service-account-name --cluster=kubernetes --user=service-account-name --namespace=test-namespace
$ kubectl config use-context service-account-name
$ kubectl get po

