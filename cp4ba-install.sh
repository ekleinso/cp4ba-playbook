#!/bin/bash

export ENTITLED_REGISTRY=cp.icr.io
export ENTITLED_REGISTRY_USER=cp
export ENTITLED_REGISTRY_KEY=<your key>

echo "Adding catalog"
oc apply -f 01-catalog.yaml

echo "Creating project"
oc apply -f 02-namespace.yaml
oc project cp4ba

echo "Configure PVC for operator"
oc apply -f 03-operator-pvc.yaml

echo "Create/assign roles"
oc apply -f 04-cluster_role.yaml
oc apply -f 05-cluster_role_binding.yaml
oc apply -f 06-role_binding.yaml

if [ $ENTITLED_REGISTRY_KEY == "<your key>" ] then
  echo "You must configured ENTITLED_REGISTRY_KEY in script"
else
  echo "Creating admin.registrykey"
  oc create secret docker-registry admin.registrykey --docker-username=${ENTITLED_REGISTRY_USER} --docker-password=${ENTITLED_REGISTRY_KEY} --docker-server=${ENTITLED_REGISTRY} --namespace=cp4ba
  echo "Creating ibm-entitlement-key"
  oc create secret docker-registry ibm-entitlement-key --docker-username=${ENTITLED_REGISTRY_USER} --docker-password=${ENTITLED_REGISTRY_KEY} --docker-server=${ENTITLED_REGISTRY} --namespace=cp4ba
fi
 
echo "Creating subscription"
oc apply -f 07-subscription.yaml

mkdir -p operator/jdbc/db2
# Get driver https://www.ibm.com/support/pages/db2-jdbc-driver-versions-and-downloads

mkdir -p operator/jdbc/oracle
curl -L -s -o operator/jdbc/oracle/ojdbc8.jar https://download.oracle.com/otn-pub/otn_software/jdbc/211/ojdbc8.jar

mkdir -p operator/jdbc/sqlserver
curl -s -o operator/jdbc/sqlserver/mssql-jdbc-8.2.2.jre8.jar https://github.com/microsoft/mssql-jdbc/releases/download/v8.2.2/mssql-jdbc-8.2.2.jre8.jar

mkdir -p operator/jdbc/postgresql
curl -s -o operator/jdbc/postgresql/postgresql-42.2.9.jar https://jdbc.postgresql.org/download/postgresql-42.2.9.jar

podname=$(oc get pod | grep ibm-cp4a-operator | awk '{print $1}')
oc cp operator/jdbc cp4ba/$podname:/opt/ansible/share
