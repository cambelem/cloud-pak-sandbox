# Installation steps for GA version of IAF

- [Installation steps for GA version of IAF](#installation-steps-for-ga-version-of-iaf)
  - [Log into cloud account](#log-into-cloud-account)
  - [Install Prereqs](#install-prereqs)
    - [1. Enable IBM Operator Catalog](#1-enable-ibm-operator-catalog)
    - [2. Install Common Services](#2-install-common-services)
    - [3. Add Entitled Registry Pull Secret](#3-add-entitled-registry-pull-secret)
      - [Using CLI](#using-cli)
      - [Using OpenShift UI](#using-openshift-ui)
    - [4. Prerequisites for installing AI components (optional)](#4-prerequisites-for-installing-ai-components-optional)
  - [Install IAF](#install-iaf)
  - [Create Instance of Automation Foundation (Optional)](#create-instance-of-automation-foundation-optional)
  - [Install Demo Cartridge (Optional)](#install-demo-cartridge-optional)
    - [1. Add Entitled Registry Pull Secret for staging](#1-add-entitled-registry-pull-secret-for-staging)
    - [2. Reload workers](#2-reload-workers)
    - [3. Create Demo Cartridge Catalog Source](#3-create-demo-cartridge-catalog-source)
    - [4. Subscribe to Demo Cartridge Operator](#4-subscribe-to-demo-cartridge-operator)
  - [Additional references](#additional-references)
  
## Log into cloud account

In a terminal window, execute:

```bash
ibmcloud login --sso
```
or open an IBM Cloud Shell window on the Cloud account and

Target resource group:

```bash
ibmcloud target -g <resource-group>
```

Gain access to the OCP cluster:

```bash
ibmcloud oc cluster config -c <openshift-cluster> --admin
```

## Install Prereqs

### 1. [Enable IBM Operator Catalog](https://github.com/IBM/cloud-pak/blob/master/reference/operator-catalog-enablement.md)

```bash
cat << EOF | kubectl apply -n openshift-marketplace -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
    name: ibm-operator-catalog
    namespace: openshift-marketplace
spec:
    displayName: IBM Operator Catalog
    publisher: IBM
    sourceType: grpc
    image: docker.io/ibmcom/ibm-operator-catalog
    updateStrategy:
      registryPoll:
        interval: 45m
EOF
```

Verify Install

```console
oc get catalogsource -n openshift-marketplace | grep IBM
```

### 2. [Install Common Services](https://www.ibm.com/support/knowledgecenter/SSHKN6/installer/3.x.x/install_cs_cli.html)

Run this command to install Common Services (Bedrock):

```bash
cat << EOF | kubectl apply -n openshift-marketplace -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: opencloud-operators
  namespace: openshift-marketplace
spec:
  displayName: IBMCS Operators
  publisher: IBM
  sourceType: grpc
  image: docker.io/ibmcom/ibm-common-service-catalog:latest
  updateStrategy:
    registryPoll:
      interval: 45m
EOF
```

After a few minutes, verify operator installation:

```bash
oc -n openshift-marketplace get catalogsource opencloud-operators -o jsonpath="{.status.connectionState.lastObservedState}"
```

Should say `READY`.

### 3. Add Entitled Registry Pull Secret

Update your OpenShift cluster with global pull secrets for the `cp.icr.io` entitled registry.

Use the following:

- username: `cp`
- password: [entitlement key](https://myibm.ibm.com/products-services/containerlibrary)

Update secret and reload workers:

```bash
oc extract secret/pull-secret -n openshift-config --confirm --to=.
jq --arg apikey `echo -n "cp:<password>" | base64` --arg registry "cp.icr.io" '.auths += {($registry): {"auth":$apikey}}' .dockerconfigjson > .dockerconfigjson-new
mv .dockerconfigjson-new .dockerconfigjson
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson
rm .dockerconfigjson

for worker in $(ibmcloud ks workers --cluster $CLUSTER | grep kube | awk '{ print $1 }'); \
  do echo "reloading worker"; \
  ibmcloud oc worker reload --cluster $CLUSTER -w $worker -f; \
  done

echo "Completed setting pull secret and sending command to reload workers..."
```
### 4. Prerequisites for installing AI components (optional)

work in progress

## [Install IAF](https://www.ibm.com/support/knowledgecenter/SSUJN4_ent/install/installing.html)

Verify prerequisites:

```bash
oc get catalogsource -n openshift-marketplace | grep IBM
oc get pods -n openshift-marketplace | grep opencloud-operators
oc get pods -n openshift-marketplace | grep ibm-operator
```

Run the following commands to set up for installation:

```bash
export IAF_PROJECT=<project to install IAF>
oc new-project ${IAF_PROJECT}
```

Create an `OperatorGroup`:

```bash
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: iaf-group
  namespace: ${IAF_PROJECT}
spec:
  targetNamespaces:
  - ${IAF_PROJECT}
EOF
```

Create a `Subscription`:

```bash
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-automation
  namespace: ${IAF_PROJECT}
spec:
  channel: v1.0
  installPlanApproval: Automatic
  name: ibm-automation
  source: ibm-operator-catalog
  sourceNamespace: openshift-marketplace
EOF
```

[Verify installation](https://www.ibm.com/support/knowledgecenter/SSUJN4_ent/install/validate-install.html)

```bash
oc get subscription -n ${IAF_PROJECT} | grep ibm-automation
```

After a few minutes, should see:

```console
ibm-automation                                                          ibm-automation                 iaf-operators      v1.0
ibm-automation-ai-v1.0-iaf-operators-openshift-marketplace              ibm-automation-ai              iaf-operators      v1.0
ibm-automation-core-v1.0-iaf-core-operators-openshift-marketplace       ibm-automation-core            iaf-core-operators v1.0
ibm-automation-elastic-v1.0-iaf-operators-openshift-marketplace         ibm-automation-elastic         iaf-operators      v1.0
ibm-automation-eventprocessing-v1.0-iaf-operators-openshift-marketplace ibm-automation-eventprocessing iaf-operators      v1.0
ibm-automation-flink-v1.0-iaf-operators-openshift-marketplace           ibm-automation-flink           iaf-operators      v1.0
ibm-automation-v1.0-iaf-operators-openshift-marketplace                 ibm-automation                 iaf-operators      v1.0
```

Verify the install status and the ClusterServiceVersions:

```bash
oc get csv -n ${IAF_PROJECT}  | grep ibm-automation
```

Should see:

```console
ibm-automation-ai.v1.0.0              IBM Automation Foundation AI               1.0.0      Succeeded
ibm-automation-core.v1.0.0            IBM Automation Foundation Core             1.0.0      Succeeded
ibm-automation-elastic.v1.0.0         IBM Elastic                                1.0.0      Succeeded
ibm-automation-eventprocessing.v1.0.0 IBM Automation Foundation Event Processing 1.0.0      Succeeded
ibm-automation-flink.v1.0.0           IBM Automation Foundation Flink            1.0.0      Succeeded
ibm-automation.v1.0.0                 IBM Automation Foundation                  1.0.0      Succeeded
```

Verify pods are running

```bash
oc get pods -n ${IAF_PROJECT}
```

## Create Instance of Automation Foundation (Optional)

See [these](https://pages.github.ibm.com/automation-base-pak/abp-playbook/planning-install/install-ui-driven#creating-an-instance-of-ibm-automation-foundation) instructions to provision the `AutomationBase`.

Go [here](https://pages.github.ibm.com/automation-base-pak/abp-playbook/cartridges/custom-resources/#automationbase) to see the custom resource for `AutomationBase`.

## [Install Demo Cartridge](https://github.ibm.com/automation-base-pak/iaf-internal/blob/main/install-iaf-demo.sh) (Optional)

**NOTE** the Demo cartridge will create the `AutomationBase` instance if it hasn't been provisioned yet.

### 1. Add Entitled Registry Pull Secret for staging

For the entitled registry, enter the `username` and `password`:

- username: `cp`
- password: [entitlement key](https://wwwpoc.ibm.com/myibm/products-services/containerlibrary)

Update secret and reload workers:

```
oc extract secret/pull-secret -n openshift-config --confirm --to=.
jq --arg apikey `echo -n "cp:<password>" | base64` --arg registry "cp.stg.icr.io" '.auths += {($registry): {"auth":$apikey}}' .dockerconfigjson > .dockerconfigjson-new
mv .dockerconfigjson-new .dockerconfigjson
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson
rm .dockerconfigjson

for worker in $(ibmcloud ks workers --cluster $CLUSTER | grep kube | awk '{ print $1 }'); \
  do echo "reloading worker"; \
  ibmcloud oc worker reload --cluster $CLUSTER -w $worker -f; \
  done
```

### 2. Set up Image Mirroring

Image mirroring is required to allow the correct container registry image to be accessed to install the demo cartridge.

Execute:

```
oc create -f setimagemirror.yaml -n kube-system
# TODO - add a check to make sure initContainer has finished
echo "Waiting for daemonset to update image mirror config for workers"
sleep 120
oc get pods -n kube-system | grep iaf-enable-mirrors
oc delete -f setimagemirror.yaml -n kube-system

for worker in $(ibmcloud ks workers --cluster $CLUSTER | grep kube | awk '{ print $1 }'); \
  do echo "reloading worker"; \
  ibmcloud oc worker reboot --cluster $CLUSTER -w $worker -f; \
  done

# wait 10 minutes for reboots to complete
echo "Completed setting up registry mirrors, going to sleep for 10 minutes..."
sleep 600
```

### 3. Create Demo Cartridge Catalog Source

```bash
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: iaf-demo-cartridge
  namespace: openshift-marketplace  
spec:
  displayName: IAF Demo Cartridge
  publisher: IBM  
  sourceType: grpc  
  image: cp.stg.icr.io/cp/iaf-demo-cartridge-catalog:latest
  updateStrategy:
    registryPoll:
     interval: 45m
EOF
```

Verify:

```bash
oc get CatalogSources iaf-demo-cartridge  -n openshift-marketplace
```

### 4. Subscribe to Demo Cartridge Operator

```bash
cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: iaf-demo-cartridge-operator
  namespace: ${IAF_PROJECT}
spec:
  channel: alpha
  installPlanApproval: Automatic
  name: iaf-demo-cartridge
  source: iaf-demo-cartridge-catalog
  sourceNamespace: openshift-marketplace
EOF
```

## Additional references

[Getting started with IBM Automation Foundation](https://www.ibm.com/support/knowledgecenter/en/cloudpaks_start/cloud-paks/about/overview-cp.html)

[IBM Automation Foundation Installation links](https://www.ibm.com/support/knowledgecenter/SSUJN4_ent/install/installation-links.html)

[Enabling IBM Operator Catalog](https://github.com/IBM/cloud-pak/blob/master/reference/operator-catalog-enablement.md)

[Installing Common Services](https://www.ibm.com/support/knowledgecenter/SSHKN6/installer/3.x.x/install_cs_cli.html)

[Installing IAF](https://www.ibm.com/support/knowledgecenter/SSUJN4_ent/install/installing.html)

[Development IAF repo, including Demo Cartridge Installation](https://github.ibm.com/automation-base-pak/iaf-internal/blob/main/README.md)

