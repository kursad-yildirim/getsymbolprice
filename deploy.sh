#!/bin/bash
TAG=$1
REGISTRY='registry.8-mega.io'
CONTAINER='/usr/bin/docker'
WORKSPACE='/home/workspace'
NAMESPACE="8-mega-apps"
APP="home-crypto"
MICROSERVICE="getsymbolprice"
APPDIR=$WORKSPACE/$NAMESPACE/$APP/$MICROSERVICE
DBNAME="coin-prices";
DBSERVICENAME="svc-mongodb";
DBNAMESPACE="8-mega-data";
DBPORT=27017;
REDISSERVICENAME="svc-redis";
REDISNAMESPACE="8-mega-data";
REDISPORT=6379;
DBREQUIRED='coinPriceTime';

# Create Dockerfile
cat > $APPDIR/code.dev/Dockerfile << EOLDOCKERFILE
FROM node:lts-alpine3.13
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
CMD [ "npm", "start" ]
EOLDOCKERFILE
# Build and push docker image
sudo $CONTAINER build $APPDIR/code.dev -t $REGISTRY/$NAMESPACE/$APP/$MICROSERVICE:$TAG
sudo $CONTAINER push $REGISTRY/$NAMESPACE/$APP/$MICROSERVICE:$TAG

# delete existing  kube resources
rm -R $APPDIR/kube.resource.files/*
kubectl -n $NAMESPACE delete cronjob $MICROSERVICE
kubectl -n $NAMESPACE delete configmap $MICROSERVICE

# Create k8s resource  yaml files
cat > $APPDIR/kube.resource.files/$MICROSERVICE-cronjob.yaml << EOLCRONJOBYAML
apiVersion: batch/v1
kind: CronJob
metadata:
  name: $MICROSERVICE
  namespace: $NAMESPACE
  labels:
    app: $APP
    microservice: $MICROSERVICE
spec:
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  schedule: "13 */1 * * *"
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            app: $APP
            microservice: $MICROSERVICE
        spec:
          containers:
          - name: $MICROSERVICE-container
            image: $REGISTRY/$NAMESPACE/$APP/$MICROSERVICE:$TAG
            imagePullPolicy: IfNotPresent
            envFrom:
             - configMapRef:
                 name: $MICROSERVICE
          restartPolicy: OnFailure
EOLCRONJOBYAML
cat > $APPDIR/kube.resource.files/$MICROSERVICE-configmap.yaml << EOLCONFIGMAPYAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: $MICROSERVICE
  namespace: $NAMESPACE
  labels:
    app: $APP
    microservice: $MICROSERVICE
data:
  DB_NAME: $DBNAME
  DB_SVC_NAME: $DBSERVICENAME
  DB_NAMESPACE: $DBNAMESPACE
  DB_PORT: "$DBPORT"
  DB_REQUIRED: $DBREQUIRED
  REDIS_PORT: "$REDISPORT"
  REDIS_SVC_NAME: $REDISSERVICENAME
  REDIS_NAMESPACE: $REDISNAMESPACE
EOLCONFIGMAPYAML

# create new kube resources
kubectl create -f $APPDIR/kube.resource.files/$MICROSERVICE-configmap.yaml
kubectl create -f $APPDIR/kube.resource.files/$MICROSERVICE-cronjob.yaml
