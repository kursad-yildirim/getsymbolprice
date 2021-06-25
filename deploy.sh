#!/bin/bash
REGISTRY='registry.8-mega.io'
CONTAINER='/usr/bin/docker'
WORKDIR='/home/workspace'
APP="home-crypto"
MICROSERVICE="getsymbolprice"
TAG=$1
PORT='52380'
APPDIR=$WORKDIR/$APP/$MICROSERVICE
NAMESPACE="8-mega-apps"

# Create Dockerfile
cat > $APPDIR/code.dev/Dockerfile << EOLDOCKERFILE
FROM node:lts-alpine3.13
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE $PORT
CMD [ "npm", "start" ]
EOLDOCKERFILE
# Build and push docker image
sudo $CONTAINER build $WORKDIR/$APP/$MICROSERVICE/code.dev -t $REGISTRY/$MICROSERVICE-$APP:$TAG
sudo $CONTAINER push $REGISTRY/$MICROSERVICE-$APP:$TAG

# Create k8s resource  yaml files
cat > $APPDIR/kube.resource.files/$MICROSERVICE-pod.yaml << EOLPODYAML
apiVersion: v1
kind: Pod
metadata:
  name: $MICROSERVICE
  namespace: $NAMESPACE
  labels:
    app: $APP
    microservice: $MICROSERVICE
spec:
  containers:
    - name: $MICROSERVICE-container
      image: $REGISTRY/$MICROSERVICE-$APP:$TAG
      ports:
        - name: $MICROSERVICE-port
          protocol: TCP
          containerPort: $PORT
EOLPODYAML
cat > $APPDIR/kube.resource.files/$MICROSERVICE-svc.yaml << EOLSVCYAML
apiVersion: v1
kind: Service
metadata:
  name: $MICROSERVICE
  namespace: $NAMESPACE
  labels:
    app: $APP
    microservice: $MICROSERVICE
spec:
  selector:
    app: $APP
    microservice: $MICROSERVICE
  type: ClusterIP
  ports:
    - name: $MICROSERVICE-port
      protocol: TCP
      port: 52380
      targetPort: 52380
EOLSVCYAML

# delete existing  kube resources
kubectl -n $NAMESPACE delete pod $MICROSERVICE
kubectl -n $NAMESPACE delete svc $MICROSERVICE
# create new kube resources
kubectl create -f $APPDIR/kube.resource.files/$MICROSERVICE-pod.yaml
kubectl create -f $APPDIR/kube.resource.files/$MICROSERVICE-svc.yaml
