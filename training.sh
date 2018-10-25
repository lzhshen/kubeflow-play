#!/usr/bin/bash

##############################################
##########  Setting up a Storage Bucket ######
##############################################

# create the GCS bucket
gsutil mb gs:# $BUCKET_NAME/

# move back to the ML project directory 
cd $ML_PROJECT_DIR

# create service account
gcloud iam service-accounts create $SERVICE_ACCOUNT --display-name $SERVICE_ACCOUNT

# get the email associated with the new service account
IAM_EMAIL=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com

# allow the service account to upload data to the bucket
gsutil acl ch -u $IAM_EMAIL:O gs:# $BUCKET_NAME

# Finally, we can download the key file that lets us authenticate as the service account
gcloud iam service-accounts keys create ./tensorflow-model/key.json --iam-account=$IAM_EMAIL


##############################################
##########  Building the Container   #########
##############################################

# the version number associated with this model
# here, we are tagging each run with the current unix timestamp
VERSION_TAG=$(date +%s)

# set the path on GCR you want to push the image to
TRAIN_PATH=us.gcr.io/$PROJECT_ID/kubeflow-train:$VERSION_TAG

# build the tensorflow-model directory
# container is tagged with its eventual path on GCR, but it stays local for now
docker build -t $TRAIN_PATH ./tensorflow-model --build-arg version=$VERSION_TAG --build-arg bucket=$BUCKET_NAME

# If everything went well, your program should be encapsulated in a new container. First, let's test it locally to make sure everything is working:
docker run -it $TRAIN_PATH

# allow docker to access our GCR registry
gcloud auth configure-docker

# push container to GCR
docker push $TRAIN_PATH

##############################################
##########  Training on the Cluster   ########
##############################################

# move back into ksonnet directory
cd $KS_PROJECT_DIR

# generate component from prototype
$KS_BIN generate tf-job train

# set the parameters for this job
$KS_BIN param set train image $TRAIN_PATH
$KS_BIN param set train name "train-"$VERSION_TAG

# Kick of training job in k8s cluster
echo " Kick of training job in k8s cluster ... \n"
$KS_BIN apply cloud -c train -v

#  You can use kubectl to query some information about the job, including its current state.
kubectl describe tfjob

#  You can retrieve the python logs from the pod that's running the container itself (after the container has finished initializing):
#POD_NAME=$(kubectl get pods --selector=tf_job_name=train-$VERSION_TAG --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
#kubectl logs -f $POD_NAME
