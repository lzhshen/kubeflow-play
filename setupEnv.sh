#!/usr/bin/bash -x

##############################################
##########  Setting up a Cluster  ############
##############################################

# Set you active GCP project
gcloud config set project $PROJECT_ID

# create a cluster
gcloud container clusters create $K8S_CLUSTER --zone $ZONE --machine-type n1-standard-2 --enable-autoscaling --min-nodes 1 --max-nodes 6

# Connect our local environment to the cluster so we can interact with it locally using the Kubernetes CLI tool, kubectl:
gcloud container clusters get-credentials $K8S_CLUSTER --zone $ZONE

# Change the permissions on the cluster to allow kubeflow to run properly:
kubectl create clusterrolebinding default-admin --clusterrole=cluster-admin --user=$USER

##############################################
##########  Creating a ksonnet Project   #####
##############################################

# Switch to ML project directory
cd $ML_PROJECT_DIR

# Initialize ksonnet project
$KS_BIN init $KS_PROJECT
cd $KS_PROJECT

# The next step is to add our cluster as an available ksonnet environment:
$KS_BIN env add cloud

##############################################
##########  Adding Kubeflow Packages     #####
##############################################
$KS_BIN registry add kubeflow github.com/kubeflow/kubeflow/tree/${KF_VER}/kubeflow
$KS_BIN pkg install kubeflow/core@${KF_VER}
$KS_BIN pkg install kubeflow/tf-serving@${KF_VER}
$KS_BIN pkg install kubeflow/tf-job@${KF_VER}

# Generate the kubeflow-core component from its prototype
$KS_BIN generate core kubeflow-core --name=kubeflow-core --cloud=gke

# Apply component to our cluster
echo " Apply component to our cluster...\n"
$KS_BIN apply cloud -c kubeflow-core -v

# Print ks8 cluster information after deploying kubeflow
kubectl get all





