# Learning Microservices Architecture

In this (single, but quite long) document, I am trying to give a detailed step-by-step instruction set - no hidden steps - to cover a complete journey from very simple Node.js codes implementing _services_ exposing _API endpoints_ to _service mesh_ configuration.

This journey will go through the following technologies/platforms:

1\. Node.js - <https://nodejs.org/en/>

2\. curl - <https://curl.haxx.se/> - and jq - <https://stedolan.github.io/jq/>

3\. Docker - <https://www.docker.com/> and <https://hub.docker.com/>

4\. Kubernetes - <https://kubernetes.io/>

5\. Service Mesh

&nbsp;&nbsp;5\.1\. Linkerd - <https://linkerd.io/>

&nbsp;&nbsp;5\.2\. Istio - <https://istio.io/>

&nbsp;&nbsp;5\.3\. Consul Connect - <https://www.consul.io/>

&nbsp;&nbsp;5\.4\. Kuma - <https://kuma.io/>

## Prerequisites

In order to perform all these steps, I am using AWS Cloud9 as a development environment, and Google Cloud Platform to (easily) create Kubernetes clusters.

## Node.js

### How to install Node.js on a Linux machine

_Missing information about how to install Node.js..._

```
[ubuntu:~/environment]
$ node --version
v10.20.1
```

```
[ubuntu:~/environment]
$ npm --version
6.14.4
```

### How to create with Node.js a simple _service-b_ exposing an API endpoint

```
[ubuntu:~/environment]
$ mkdir service-b

[ubuntu:~/environment]
$ cd service-b/

[ubuntu:~/environment/service-b]
$ 
```

```
[ubuntu:~/environment/service-b]
$ touch package.json
```

```json
{
  "name": "service-b",
  "version": "1.0.0",
  "description": "service-b",
  "author": "Patrice Krakow <patrice.krakow@gmail.com>",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

```
[ubuntu:~/environment/service-b]
$ npm install
npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN service-b@1.0.0 No repository field.
npm WARN service-b@1.0.0 No license field.

added 50 packages from 37 contributors and audited 126 packages in 7.434s
found 0 vulnerabilities
```

```
[ubuntu:~/environment/service-b]
$ touch app.js
```

```javascript
'use strict';
const express = require('express');
const os = require('os');
const HOSTNAME = '0.0.0.0';
const PORT = 3001
const SERVICE_NAME = "service-b";
const SERVICE_VERSION = "1.0.0";
const app = express();
app.get('/path-01', (req, res) => {
  res.send({
    message: "Hello from get /path-01",
    internalInfo: {
      serviceName: SERVICE_NAME,
      version: SERVICE_VERSION,
      hostname: {
        configured: HOSTNAME,
        fromOS: os.hostname()
      },
      port: PORT
    }
  });
});
app.listen(PORT, HOSTNAME);
console.log(`Running on http://${HOSTNAME}:${PORT}`);
```

```
[ubuntu:~/environment/service-b]
$ npm start

> service-b@1.0.0 start /home/ubuntu/environment/service-b
> node app.js

Running on http://0.0.0.0:3001
```

## Curl and jq

### How to install curl on a Linux machine

```
[ubuntu:~/environment]
$ sudo apt-get -y update
...
$ sudo apt-get install -y curl
...
```

```
[ubuntu:~/environment]
$ curl --version
curl 7.58.0 (x86_64-pc-linux-gnu) libcurl/7.58.0 OpenSSL/1.1.1 zlib/1.2.11 libidn2/2.0.4 libpsl/0.19.1 (+libidn2/2.0.4) nghttp2/1.30.0 librtmp/2.3
Release-Date: 2018-01-24
Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtmp rtsp smb smbs smtp smtps telnet tftp 
Features: AsynchDNS IDN IPv6 Largefile GSS-API Kerberos SPNEGO NTLM NTLM_WB SSL libz TLS-SRP HTTP2 UnixSockets HTTPS-proxy PSL 
```

### How to install jq on a Linux machine

```
[ubuntu:~/environment]
$ sudo apt-get -y update
...
$ sudo apt-get install -y jq
...
```

```
[ubuntu:~/environment]
$ jq --version
jq-1.5-1-a5b5cbe
```

### How to call an _API endpoint_ with curl and jq

```
[ubuntu:~/environment]
$ curl -s http://localhost:3001/path-01 | jq
{
  "message": "Hello from get /path-01",
  "internalInfo": {
    "serviceName": "service-b",
    "version": "1.0.0",
    "hostname": {
      "configured": "0.0.0.0",
      "fromOS": "ip-172-31-37-121"
    },
    "port": 3001
  }
}
```

## Docker

### Documentation

* <https://docs.docker.com/get-started/overview/>
* <https://docs.docker.com/get-started/>
* <https://docs.docker.com/get-started/part2/>
* <https://docs.docker.com/get-started/part3/>

### How to install Docker on a Linux machine

_Missing information about how to install Docker..._

```
[ubuntu:~/environment]
$ docker --version
Docker version 19.03.8, build afacb8b7f0
```

### How to create a Docker image with the _service-b_

If necessary, go back to the `service-b` folder, where the source code files `package.json` and `app.js` are.

```
[ubuntu:~/environment]
$ cd service-b/

[ubuntu:~/environment/service-b]
$ ls
app.js  node_modules  package-lock.json  package.json
```

```
[ubuntu:~/environment/service-b]
$ touch Dockerfile
```

```dockerfile
# Use the official image as a parent image.
FROM node:current-slim

# Set the working directory.
WORKDIR /usr/src/app

# Copy the file from your host to your current location.
COPY package.json .

# Run the command inside your image filesystem.
RUN npm install

# Inform Docker that the container is listening on the specified port at runtime.
EXPOSE 3001

# Run the specified command within the container.
CMD [ "npm", "start" ]

# Copy the rest of your app's source code from your host to your image filesystem.
COPY . .
```

```
[ubuntu:~/environment/service-b]
$ docker build --tag patrice1972/service-b:1.0.0 .
Sending build context to Docker daemon  2.009MB
Step 1/7 : FROM node:current-slim
current-slim: Pulling from library/node
b248fa9f6d2a: Pull complete 
dffc92453adc: Pull complete 
536433711f92: Pull complete 
9a9f964feabf: Pull complete 
5d1b4472543b: Pull complete 
Digest: sha256:b71737516643fa2c1df6d5a76ab5d4e7e959b3c40e494ff2b9587be2af9efd55
Status: Downloaded newer image for node:current-slim
 ---> 8d32307afb40
Step 2/7 : WORKDIR /usr/src/app
 ---> Running in 53f25c0c7f29
Removing intermediate container 53f25c0c7f29
 ---> d2e5d4e9ee7f
Step 3/7 : COPY package.json .
 ---> 6b1378c71a90
Step 4/7 : RUN npm install
 ---> Running in 76cb17d53fe4
npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN service-b@1.0.0 No repository field.
npm WARN service-b@1.0.0 No license field.

added 50 packages from 37 contributors and audited 126 packages in 1.701s
found 0 vulnerabilities

Removing intermediate container 76cb17d53fe4
 ---> 5e8c59ef2ded
Step 5/7 : EXPOSE 3001
 ---> Running in ff8f54bafde8
Removing intermediate container ff8f54bafde8
 ---> 870d69cf8a53
Step 6/7 : CMD [ "npm", "start" ]
 ---> Running in a0fd23f44a45
Removing intermediate container a0fd23f44a45
 ---> bbf81f290b9b
Step 7/7 : COPY . .
 ---> 49a01c188cd6
Successfully built 49a01c188cd6
Successfully tagged patrice1972/service-b:1.0.0
```

### How to create a Docker container running the _service-b_

```
[ubuntu:~/environment/service-b]
$ docker run --publish 3001:3001 --detach patrice1972/service-b:1.0.0
8acde250e9947b07dd8d86d2d0aae3ae89c8cc632957878bfe705c7595af3f53
```

```
[ubuntu:~/environment/service-b]
$ docker ps
CONTAINER ID        IMAGE                         COMMAND                  CREATED             STATUS              PORTS                    NAMES
8acde250e994        patrice1972/service-b:1.0.0   "docker-entrypoint.s…"   11 seconds ago      Up 10 seconds       0.0.0.0:8080->3001/tcp   gifted_albattani
```

And now, you can call the _API endpoint_ by going to the following address <http://localhost:3001/path-01> using curl an jq:

```
[ubuntu:~/environment/service-b]
$ curl -s http://localhost:3001/path-01 | jq
{
  "message": "Hello from get /path-01",
  "internalInfo": {
    "serviceName": "service-b",
    "version": "1.0.0",
    "hostname": {
      "configured": "0.0.0.0",
      "fromOS": "8acde250e994"
    },
    "port": 3001
  }
}
```

```
[ubuntu:~/environment/service-b]
$ docker rm --force 8acde250e994
8acde250e994
```

```
[ubuntu:~/environment/service-b]
$ docker ps -all
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

```
[ubuntu:~/environment/service-b]
$ docker images
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
patrice1972/service-b   1.0.0               49a01c188cd6        12 minutes ago      170MB
node                    current-slim        8d32307afb40        4 days ago          165MB
```

### How to push the _service-b_ Docker image to the Docker Hub registry

_Missing information about how to register on the Docker Hub registry..._

```
[ubuntu:~/environment/service-b]
$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: patrice1972
Password: 
WARNING! Your password will be stored unencrypted in /home/ubuntu/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

```
[ubuntu:~/environment/service-b]
$ docker push patrice1972/service-b:1.0.0
The push refers to repository [docker.io/patrice1972/service-b]
71a61d9eeb4d: Pushed 
b41246acddf6: Pushed 
4db83ac9b90f: Pushed 
6b9a0cd1c999: Pushed 
91ee6be5fc57: Mounted from library/node 
d22eb286b341: Mounted from library/node 
66d5400ac932: Mounted from library/node 
a8bfdcd294e1: Mounted from library/node 
cde96efde55e: Mounted from library/node 
1.0.0: digest: sha256:9d24a0bc87925aa3a2f09e6ce392b0e873f0527c2a09b5dbbd7b0c1c3cda5960 size: 2202
```

### How to create with bash a simple _service-a_ calling the API endpoint

```
[ubuntu:~/environment]
$ mkdir service-a

[ubuntu:~/environment]
$ cd service-a/

[ubuntu:~/environment/service-a]
$ 
```

```
[ubuntu:~/environment/service-a]
$ touch service-a.sh
```

```bash
#!/bin/bash
# chmod 755 service-a.sh

if [ -z "$SERVICE_B_NAME" ] then
  SERVICE_B_NAME=localhost
fi
while true
  do sleep 1
  echo "[DEBUG] hostname (OS): $(\
    curl -s {$SERVICE_B_NAME}:3001/path-01 |\
      jq .internalInfo.hostname.fromOS | tr -d "\"")"
done
```

```
[ubuntu:~/environment/service-a]
$ chmod 755 service-a.sh
```

```
[ubuntu:~/environment/service-a]
$ ./service-a.sh
[DEBUG] hostname (OS): 8acde250e994
[DEBUG] hostname (OS): 8acde250e994
[DEBUG] hostname (OS): 8acde250e994
...
```

### How to create a Docker image with the _service-a_

```
[ubuntu:~/environment/service-a]
$ touch Dockerfile
```

```dockerfile
FROM ubuntu:18.04
RUN apt-get -y update
RUN apt-get install -y curl
RUN apt-get install -y jq
WORKDIR /app
COPY service-a.sh /app
RUN chmod 755 /app/service-a.sh
CMD /app/service-a.sh
```

```
[ubuntu:~/environment/service-a]
$ docker build --tag patrice1972/service-a:1.0.0 .
Sending build context to Docker daemon  3.072kB
Step 1/8 : FROM ubuntu:18.04
18.04: Pulling from library/ubuntu
23884877105a: Pull complete 
bc38caa0f5b9: Pull complete 
2910811b6c42: Pull complete 
36505266dcc6: Pull complete 
Digest: sha256:3235326357dfb65f1781dbc4df3b834546d8bf914e82cce58e6e6b676e23ce8f
Status: Downloaded newer image for ubuntu:18.04
 ---> c3c304cb4f22
Step 2/8 : RUN apt-get -y update
 ---> Running in d47ea880894e
Get:1 http://archive.ubuntu.com/ubuntu bionic InRelease [242 kB]
...
Fetched 17.9 MB in 2s (10.1 MB/s)
Reading package lists...
Removing intermediate container d47ea880894e
 ---> e13d81a86f3f
Step 3/8 : RUN apt-get install -y curl
 ---> Running in 05535834b8a6
Reading package lists...
Building dependency tree...
Reading state information...
The following additional packages will be installed:
...
done.
Removing intermediate container 05535834b8a6
 ---> 714e1fc36693
Step 4/8 : RUN apt-get install -y jq
 ---> Running in 7efb14e2e40c
Reading package lists...
Building dependency tree...
Reading state information...
The following additional packages will be installed:
...
Removing intermediate container 7efb14e2e40c
 ---> 0ec6c58550cd
Step 5/8 : WORKDIR /app
 ---> Running in 3379affc3154
Removing intermediate container 3379affc3154
 ---> 072f21427ada
Step 6/8 : COPY service-a.sh /app
 ---> b9ef79ca09f9
Step 7/8 : RUN chmod 755 /app/service-a.sh
 ---> Running in 20ddab814a17
Removing intermediate container 20ddab814a17
 ---> 8cb89bd46677
Step 8/8 : CMD /app/service-a.sh
 ---> Running in 24ee1862bd6a
Removing intermediate container 24ee1862bd6a
 ---> 9ec0ae2b469f
Successfully built 9ec0ae2b469f
Successfully tagged patrice1972/service-a:1.0.0
```

### How to create a Docker container running the _service-a_

```
[ubuntu:~/environment/service-a]
$ docker run --env SERVICE_B_NAME="172.31.34.146" patrice1972/service-a:1.0.0
[DEBUG] hostname (OS): 78b4071b4d44
[DEBUG] hostname (OS): 78b4071b4d44
[DEBUG] hostname (OS): 78b4071b4d44
...
```

### How to push the _service-a_ Docker image to the Docker Hub registry

If necessary, you should re-login to the Docker Hub registry.

```
[ubuntu:~/environment/service-a]
$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: patrice1972
Password: 
WARNING! Your password will be stored unencrypted in /home/ubuntu/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

```
[ubuntu:~/environment/service-a]
$ docker push patrice1972/service-a:1.0.0
The push refers to repository [docker.io/patrice1972/service-a]
a68017e9c91c: Pushed 
9fee0f5ba9a0: Pushed 
856c5d580e7e: Pushed 
2a1e41ee9735: Pushed 
908bac4e65e6: Pushed 
28ba7458d04b: Mounted from library/ubuntu 
838a37a24627: Mounted from library/ubuntu 
a6ebef4a95c3: Mounted from library/ubuntu 
b7f7d2967507: Mounted from library/ubuntu 
1.0.0: digest: sha256:5ac9708284f2aeda018eab50ca9f15cdded1d34a50a8c9b863f8ea13296cf564 size: 2406
```

## Kubernetes

### How to create a Kubernetes cluster on GCP

_Missing information about how to create a Kubernetes cluster on CGP..._

```
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.9", GitCommit:"2e808b7cb054ee242b68e62455323aa783991f03", G
itTreeState:"clean", BuildDate:"2020-01-18T23:33:14Z", GoVersion:"go1.12.12", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"15+", GitVersion:"v1.15.11-gke.9", GitCommit:"e1af17fd873e15a48769e2c7b9851405f89e
3d0d", GitTreeState:"clean", BuildDate:"2020-04-06T20:56:54Z", GoVersion:"go1.12.17b4", Compiler:"gc", Platform:"linux/amd64"}
```

```
$ kubectl get nodes
NAME                                        STATUS   ROLES    AGE   VERSION
gke-cluster-01-default-pool-ac4a8b10-95hp   Ready    <none>   8d    v1.15.11-gke.9
gke-cluster-01-default-pool-ac4a8b10-qz9j   Ready    <none>   8d    v1.15.11-gke.9
gke-cluster-01-default-pool-ac4a8b10-v7pn   Ready    <none>   8d    v1.15.11-gke.9
gke-cluster-01-default-pool-ac4a8b10-z510   Ready    <none>   8d    v1.15.11-gke.9
```

### How to deploy our _services_ on Kubernetes

```
$ touch service-b.deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-b
  labels:
    app: service-b
spec:
  replicas: 1
  selector:
    matchLabels:
      app: service-b
  template:
    metadata:
      labels:
        app: service-b
    spec:
      containers:
      - name: service-b
        image: patrice1972/service-b:1.0.0
```

```
$ kubectl apply -f service-b.deployment.yaml
deployment.apps/service-b created
```

```
$ kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
service-b-597c4ffc5b-26jzr   1/1     Running   0          78s
```

```
$ kubectl describe pod service-b-597c4ffc5b-26jzr
Name:           service-b-597c4ffc5b-26jzr
Namespace:      default
Priority:       0
Node:           gke-cluster-01-default-pool-fb2d9fc6-m9pb/10.132.0.3
Start Time:     Wed, 06 May 2020 11:58:33 +0200
Labels:         app=service-b
                pod-template-hash=597c4ffc5b
Annotations:    kubernetes.io/limit-ranger: LimitRanger plugin set: cpu request for container service-b
Status:         Running
IP:             10.40.2.4
...
```

```
$ touch service-a.deployment.yaml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-a
  labels:
    app: service-a
spec:
  replicas: 1
  selector:
    matchLabels:
      app: service-a
  template:
    metadata:
      labels:
        app: service-a
    spec:
      containers:
      - name: service-a
        image: patrice1972/service-a:1.0.0
        env:
        - name: SERVICE_B_NAME
          value: "10.40.3.4"
```

```
$ kubectl apply -f service-a.deployment.yaml
deployment.apps/service-a created
```

```
$ kubectl get pods
kubectl get pods
NAME                         READY   STATUS    RESTARTS   AGE
service-a-8db6f8bfd-hnvt6    1/1     Running   0          37s
service-b-597c4ffc5b-26jzr   1/1     Running   0          6m20s
```

```
$ kubectl logs service-a-8db6f8bfd-hnvt6
[DEBUG] hostname (OS): service-b-7d88584dbf-jqg7v
[DEBUG] hostname (OS): service-b-7d88584dbf-jqg7v
[DEBUG] hostname (OS): service-b-7d88584dbf-jqg7v
...
```

If it does not work, you can debug the situation by connecting to the container running service-a with a shell interface using the following command:

```
$ kubectl exec -it service-a-8db6f8bfd-hnvt6 -- /bin/bash
```

## Service Mesh

<https://servicemesh.io/>

### Linkerd

_Work in progress..._

### Istio

_Work in progress..._

### Consul Connect

_The text below is still a work in progress..._

```
$ git clone https://github.com/hashicorp/consul-helm.git
...
```

```
$ touch consul-values.yaml
```

```yaml
global:
  datacenter: dc1
  image: "consul:1.7.0"
  imageK8S: "hashicorp/consul-k8s:0.11.0"

server:
  replicas: 1
  bootstrapExpect: 1

client:
  enabled: true
  grpc: true

ui:
  enabled: true

syncCatalog:
  enabled: true
  toConsul: true
  toK8S: false
  default: true

connectInject:
  enabled: true
  #envoy image with curl and utils
  imageEnvoy: nicholasjackson/consul-envoy:v1.7.0-v0.12.2

  #true will inject by default, otherwise requires annotation
  default: false

  centralConfig:
    enabled: true
    defaultProtocol: "http"
    proxyDefaults: |
      {
      "envoy_dogstatsd_url": "udp://127.0.0.1:9125"
      }
```

```
$ helm install -f consul-values.yaml lab ./consul-helm --wait
...
```

```
$ kubectl get pods
...
```

Let's edit the `service-a.deployment.yaml` to add 
