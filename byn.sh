#!/bin/bash

LOG_FILE="./log.txt"

verifyResult() {
  if [ $1 -ne 0 ]; then
    errorLog=$(tr -d '\n' < $LOG_FILE)
    echo "======== !!! HLF SCRIPT ERROR !!! "$2" !!! RETURN CODE: "$1" !!! ERROR LOG: $errorLog !!!! ==============="
    echo
    exit 1
  fi
}

hlfStatus=$(kubectl get configmap hlf-status -o jsonpath={.data.hlfStatus} --namespace hlf)
if [ ! "$hlfStatus" == "Done" ]; then
  res=1
  verifyResult $res "HLF Organization is not setup yet. Can't run the script."
fi
kubectl apply -f ./fabric-admin.yaml
theargs=""
for i in "$@" ; do
   theargs="${theargs} \"$i\""
done
kubectl wait --for=condition=Ready pod -l name=fabric-admin --namespace hlf --timeout=300s &> $LOG_FILE
res=$?
verifyResult $res "Failed to start fabric-admin pod"
echo
echo "======== Started fabric-admin pod!!! =========="
echo

FABRIC_ADMIN_POD=$(kubectl get pods -l name=fabric-admin -ojsonpath={.items[0].metadata.name} --namespace hlf)
kubectl exec ${FABRIC_ADMIN_POD} --namespace hlf -- bash -c "/var/hyperledger/consortiumScripts/byn2.sh ${theargs}"
kubectl delete pod ${FABRIC_ADMIN_POD} --namespace hlf &> $LOG_FILE
res=$?
verifyResult $res "Deletion of fabric-admin pod Failed"
echo
echo "======== Deleted fabric-admin pod!!! =========="
echo
