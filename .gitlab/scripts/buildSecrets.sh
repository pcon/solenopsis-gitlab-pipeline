#!/bin/bash

# Workaround for https://issues.redhat.com/browse/ITALM-3418
# See https://redhat-internal.slack.com/archives/C04KYC1E138/p1682446097213609
mkdir ~/.kube
cp /alm/kubeconfig ~/.kube/config
unset KUBECONFIG

oc config use-context sfdc-pipeline-preprod
oc project sfdc--pipeline

oc process -f $GITLAB_TEMPLATES_DIR/secret.yml --param-file .gitlab/vars/"$CI_ENVIRONMENT_NAME".yml -p env="$CI_ENVIRONMENT_NAME" --ignore-unknown-parameters=true | oc apply -f -

export USERNAME=$(oc get secret sfdc-$CI_ENVIRONMENT_NAME-secret -n sfdc--pipeline -o go-template --template='{{ index .data "USERNAME" | base64decode }}')
export PASSWORD=$(oc get secret sfdc-$CI_ENVIRONMENT_NAME-secret -n sfdc--pipeline -o go-template --template='{{ index .data "PASSWORD" | base64decode }}')
export TOKEN=$(oc get secret sfdc-$CI_ENVIRONMENT_NAME-secret -n sfdc--pipeline -o go-template --template='{{ index .data "TOKEN" | base64decode }}')