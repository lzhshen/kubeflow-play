##############################################
##########  Setting up a Cluster  ############
##############################################

cd ${KUBEFLOW_REPO_BASE}
curl https://raw.githubusercontent.com/kubeflow/kubeflow/${KUBEFLOW_TAG}/scripts/download.sh | bash
mkdir ${KUBEFLOW_REPO}
ls -l
mv ${KUBEFLOW_REPO_BASE}/kubeflow  ${KUBEFLOW_REPO}/
mv ${KUBEFLOW_REPO_BASE}/scripts ${KUBEFLOW_REPO}/
cd ${KUBEFLOW_REPO}


${KUBEFLOW_REPO}/scripts/kfctl.sh init ${KFAPP} --platform gcp --project ${PROJECT}
cd ${KFAPP}
${KUBEFLOW_REPO}/scripts/kfctl.sh generate platform
${KUBEFLOW_REPO}/scripts/kfctl.sh apply platform
#${KUBEFLOW_REPO}/scripts/kfctl.sh generate k8s
#${KUBEFLOW_REPO}/scripts/kfctl.sh apply k8s


