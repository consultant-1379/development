# Get running a dashboard on Kubernetes

The readme pretends to show how to deploy and work with Dashin on Kubernetes

## Previous requisites
The deploy needs the following repositories:
1. development
2. credentials
And have setup the KUBECONFIG variable pointing to the desired Kubernetes cluster.

## How to prepare the setup:

### Create a namespace
```
kubectl create namespace tv-5gcicd
```

### Create the secrets
Use the README from credentials for more info/details. 

### Create the volumes
This yaml and the following yamls are located under the path: 5gcicd_tv/cfg/
```
   kubectl create -n tv-5gcicd -f create_das​hboard_tv_​5gcicd_vol​s.yaml
```

### Create the secret for user/pass
```
   kubectl create -n tv-5gcicd -f dashboard-​tv-5gcicd-​secret-use​r-pass.yam​l
```

### Create the support Pod

```
   kubectl create -n tv-5gcicd -f create_das​hboard_tv_​5gcicd.yam​l
```

## Get inside the support pod
Move to the path /clone/

### Update and install packages
 
```
apt-get update
apt-get install -y git vim
```

### Create the SSH key
 
```
eval `ssh-agent -s`
mkdir -p /home/jenkins/.ssh/
cp /root/.ssh/adp/id_rsa /root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
ssh-add /root/.ssh/id_rsa
```

### Clone the repository
```
git clone ssh://esdccci@gerrit.ericsson.se:29418/5gcicd/development
/clone/development
```

### Copy the script folder to clone
```
cp /clone/development/5gcicd_tv/cfg/scripts/* /clone
```
### Execute the script
This script will move all the needed files from the cloned repository to their correspondent paths
```
./copy_all_elements.sh
```
## Out of the support container
### Create the statefulset

```
   kubectl create -n tv-5gcicd -f deploy_dashboard_tv_5gcicd_statefulset.yaml
```

## Where is the dashboard

The dashboard should be found under the following URL
```
http://dashboard-tv-5gcicd.<cluster>/01_main_testing_jenkins_5gcicd_tv
```