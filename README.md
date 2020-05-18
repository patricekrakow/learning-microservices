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

In order to perform all these steps, I am using [AWS Cloud9](https://eu-west-1.console.aws.amazon.com/cloud9/home?region=eu-west-1) as a development environment, and [Google Cloud Platform](https://console.cloud.google.com/) to (easily) create Kubernetes clusters.

### Change the prompt of my terminals

At the time of writing Cloud9 comes with the following prompt:

```
ubuntu:~/environment $ echo \'$PS1\'
```
```
'\[\033[01;32m\]$(_cloud9_prompt_user)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)" 2>/dev/null) $ '
```

I like to make the following change to keep the path indication, but moving it one line up, so it does not eat space:

```
ubuntu:~/environment $ PS1='[\[\033[01;32m\]$(_cloud9_prompt_user)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$(__git_ps1 " (%s)" 2>/dev/null)]\n$ '
```
```
[ubuntu:~/environment]
$ 
```

Of course, if you want that change to be permanent, you will need to update the `~/.bashrc` file.

## Node.js

### How to install Node.js on a Linux machine

```
[ubuntu:~/environment]
$ nvm install --lts
```
```
Installing latest LTS version.
Downloading https://nodejs.org/dist/v12.16.3/node-v12.16.3-linux-x64.tar.xz...
...
Now using node v12.16.3 (npm v6.14.4)
nvm_ensure_default_set: a version is required
```

```
[ubuntu:~/environment]
$ node --version
```
```
v12.16.3
```

```
[ubuntu:~/environment]
$ npm install -g npm
```
```
/home/ubuntu/.nvm/versions/node/v12.16.3/bin/npm -> /home/ubuntu/.nvm/versions/node/v12.16.3/lib/node_modules/npm/bin/npm-cli.js
/home/ubuntu/.nvm/versions/node/v12.16.3/bin/npx -> /home/ubuntu/.nvm/versions/node/v12.16.3/lib/node_modules/npm/bin/npx-cli.js
+ npm@6.14.5
updated 5 packages in 7.22s
```

```
[ubuntu:~/environment]
$ npm --version
```
```
6.14.5
```

### How to create with Node.js a simple _service-b_ exposing an API endpoint

```
[ubuntu:~/environment]
$ mkdir service-b
```
```
[ubuntu:~/environment]
$ cd service-b/
```
```
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
```
```
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
```
```
> service-b@1.0.0 start /home/ubuntu/environment/service-b
> node app.js

Running on http://0.0.0.0:3001
```

Just keep it running for now and open a new terminal.

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
```
```
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
```
```
jq-1.5-1-a5b5cbe
```

### How to call an _API endpoint_ with curl and jq

```
[ubuntu:~/environment]
$ curl -s http://localhost:3001/path-01 | jq
```
```json
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

Docker is already installed on a AWS Cloud9 machine.

```
[ubuntu:~/environment]
$ docker --version
```
```
Docker version 19.03.8, build afacb8b7f0
```

### How to create a Docker image with the _service-b_

If necessary, go back to the `service-b` folder, where the source code files `package.json` and `app.js` are.

```
[ubuntu:~/environment]
$ cd service-b/
```
```
[ubuntu:~/environment/service-b]
$ 
```

```
[ubuntu:~/environment/service-b]
$ ls
```
```
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
```
```
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

**_Warning_**. First you need to stop the `node app.js` process - that we started with `npm start` - in order to free the TCP port `3001`.

```
[ubuntu:~/environment/service-b]
$ docker run --publish 3001:3001 --detach patrice1972/service-b:1.0.0
```
```
130f20b9a674647bccfe211a6774b48e9d67d65c2a0fb7bdc8abde69d49e2d91
```

```
[ubuntu:~/environment/service-b]
$ docker ps
```
```
CONTAINER ID        IMAGE                         COMMAND                  CREATED             STATUS              PORTS                    NAMES
130f20b9a674        patrice1972/service-b:1.0.0   "docker-entrypoint.s…"   27 seconds ago      Up 26 seconds       0.0.0.0:3001->3001/tcp   sad_borg
```

```
[ubuntu:~/environment/service-b]
$ curl -s http://localhost:3001/path-01 | jq
```
```json
{
  "message": "Hello from get /path-01",
  "internalInfo": {
    "serviceName": "service-b",
    "version": "1.0.0",
    "hostname": {
      "configured": "0.0.0.0",
      "fromOS": "130f20b9a674"
    },
    "port": 3001
  }
}
```

If you want to stop this Docker container, just type the following command

```
[ubuntu:~/environment/service-b]
$ docker rm --force 130f20b9a674
```
```
130f20b9a674
```

```
[ubuntu:~/environment/service-b]
$ docker ps -all
```
```
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
```

```
[ubuntu:~/environment/service-b]
$ docker images
```
```
REPOSITORY              TAG                 IMAGE ID            CREATED             SIZE
patrice1972/service-b   1.0.0               50260307ea8e        7 minutes ago       170MB
node                    current-slim        f1f04567e715        9 hours ago         165MB
...
```

### How to push the _service-b_ Docker image to the Docker Hub registry

_Missing information about how to register on the Docker Hub registry..._

```
[ubuntu:~/environment/service-b]
$ docker login
```
```
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
```
```
The push refers to repository [docker.io/patrice1972/service-b]
69af279303d4: Pushed 
dc62183efc3e: Pushed 
a9eaead0bbce: Pushed 
ac5c289a2647: Pushed 
ff761e4387bc: Mounted from library/node 
2c3c9eb53f44: Mounted from library/node 
a9ba2906d8f3: Mounted from library/node 
29936941072e: Mounted from library/node 
370ffef31d12: Mounted from library/node 
1.0.0: digest: sha256:51b340cc3ae32ac2586ad76b2352c5945197a981a31cb59454cb641a39691c15 size: 2202
```

### How to create with bash a simple _service-a_ calling the API endpoint

```
[ubuntu:~/environment]
$ mkdir service-a
```
```
[ubuntu:~/environment]
$ cd service-a/
```
```
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

if [ -z "$SERVICE_B_NAME" ]; then
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
```
```
[DEBUG] hostname (OS): 130f20b9a674
[DEBUG] hostname (OS): 130f20b9a674
[DEBUG] hostname (OS): 130f20b9a674
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
```
```
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
[ubuntu:~/environment/service-b]
$ hostname -I
```
```
172.31.25.203 172.17.0.1 
```

```
[ubuntu:~/environment/service-a]
$ docker run --env SERVICE_B_NAME="172.31.25.203" patrice1972/service-a:1.0.0
```
```
[DEBUG] hostname (OS): 130f20b9a674
[DEBUG] hostname (OS): 130f20b9a674
[DEBUG] hostname (OS): 130f20b9a674
...
```

### How to push the _service-a_ Docker image to the Docker Hub registry

If necessary, you should re-login to the Docker Hub registry.

```
[ubuntu:~/environment/service-a]
$ docker login
```
```
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
```
```
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

[Create a Kubernetes Cluster on GCP](https://github.com/patricekrakow/learning-kubernetes/blob/master/create-a-cluster.md)

```
$ kubectl version
```
```
Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.2", GitCommit:"52c56ce7a8272c798dbc29846288d7cd9fbae032", GitTreeState:"clean", BuildDate:"2020-04-16T11:56:40Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"16+", GitVersion:"v1.16.8-gke.15", GitCommit:"9cabee15e0922c3b36724de4866a98f6c2da5e6a", GitTreeState:"clean", BuildDate:"2020-05-01T21:47:04Z", GoVersion:"go1.13.8b4", Compiler:"gc", Platform:"linux/amd64"}
```

```
$ kubectl get nodes
```
```
NAME                                        STATUS   ROLES    AGE     VERSION
gke-cluster-01-default-pool-00f718cd-bp95   Ready    <none>   9m27s   v1.16.8-gke.15
gke-cluster-01-default-pool-00f718cd-hdzj   Ready    <none>   9m27s   v1.16.8-gke.15
gke-cluster-01-default-pool-00f718cd-kvxd   Ready    <none>   9m27s   v1.16.8-gke.15
gke-cluster-01-default-pool-00f718cd-m5x3   Ready    <none>   9m27s   v1.16.8-gke.15
```

### How to deploy our _services_ on Kubernetes

```
$ touch service-b.deployment.yaml
```

```yaml
# service-b.deployment.yaml
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
```
```
deployment.apps/service-b created
```

```
$ kubectl get pods
```
```
NAME                         READY   STATUS    RESTARTS   AGE
service-b-597c4ffc5b-6fzbb   1/1     Running   0          27s
```

```
$ kubectl describe pod service-b-597c4ffc5b-6fzbb
```
```
Name:           service-b-597c4ffc5b-6fzbb
Namespace:      default
Priority:       0
Node:           gke-cluster-01-default-pool-e6a715d1-41jx/10.132.0.6
Start Time:     Thu, 14 May 2020 15:57:14 +0200
Labels:         app=service-b
                pod-template-hash=597c4ffc5b
Annotations:    kubernetes.io/limit-ranger: LimitRanger plugin set: cpu request for container service-b
Status:         Running
IP:             10.40.1.4
...
```

```
$ touch service-a.deployment.yaml
```

```yaml
# service-a.deployment.yaml
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
          value: "10.40.1.4"
```

```
$ kubectl apply -f service-a.deployment.yaml
```
```
deployment.apps/service-a created
```

```
$ kubectl get pods
```
```
NAME                         READY   STATUS    RESTARTS   AGE
service-a-8658d565bc-xmffh   1/1     Running   0          27s
service-b-597c4ffc5b-6fzbb   1/1     Running   0          4m54s
```

```
$ kubectl logs service-a-8658d565bc-xmffh
```
```
[DEBUG] hostname (OS): service-b-597c4ffc5b-6fzbb
[DEBUG] hostname (OS): service-b-597c4ffc5b-6fzbb
[DEBUG] hostname (OS): service-b-597c4ffc5b-6fzbb
...
```

If it does not work, you can debug the situation by connecting to the container running service-a with a shell interface using the following command:

```
$ kubectl exec -it service-a-8658d565bc-xmffh -- /bin/bash
```
```
root@service-a-8658d565bc-xmffh:/app#
```

## Service Mesh

<https://servicemesh.io/>

### Linkerd

_Work in progress..._

### Istio

_Work in progress..._

### Consul Connect

_The text below is still a work in progress..._
`

<https://www.consul.io/docs/platform/k8s/index.html>

```
$ kubectl cluster-info
```
```
Kubernetes master is running at https://35.195.63.166
GLBCDefaultBackend is running at https://35.195.63.166/api/v1/namespaces/kube-system/services/default-http-backend:http/proxy
KubeDNS is running at https://35.195.63.166/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://35.195.63.166/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

```
$ helm version
```
```
Client: &version.Version{SemVer:"v2.14.1", GitCommit:"5270352a09c7e8b6e8c9593002a73535276507c0", GitTreeState:"clean"}
Error: could not find tiller
```

```
$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
```

```
$ chmod 700 get_helm.sh
```
```
$ ./get_helm.sh
```
```
Error: could not find tiller
Helm v3.2.1 is available. Changing from version .
Downloading https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm
```

```
$ helm version
```
```
version.BuildInfo{Version:"v3.2.1", GitCommit:"fe51cd1e31e6a202cba7dead9552a6d418ded79a", GitTreeState:"clean", GoVersion:"go1.13.10"}
```

```
$ helm repo add hashicorp https://helm.releases.hashicorp.com
```
```
"hashicorp" has been added to your repositories
```

```
$ helm search repo hashicorp/consul
```
```
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
hashicorp/consul        0.21.0          1.7.3           Official HashiCorp Consul Chart
```

```
$ touch helm-consul-values.yaml
```

```yaml
global:
  acls:
    manageSystemACLs: true

server:
  replicas: 1
  bootstrapExpect: 1
  connect: true

client:
  enabled: true

ui:
  service:
    type: 'LoadBalancer'

connectInject:
  enabled: true
```

```
$ helm install hashicorp hashicorp/consul -f helm-consul-values.yaml
```
```
NAME: hashicorp
LAST DEPLOYED: Fri May 15 16:39:06 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
Thank you for installing HashiCorp Consul!

Now that you have deployed Consul, you should look over the docs on using
Consul with Kubernetes available here:

https://www.consul.io/docs/platform/k8s/index.html


Your release is named hashicorp.

To learn more about the release if you are using Helm 2, run:

  $ helm status hashicorp
  $ helm get hashicorp

To learn more about the release if you are using Helm 3, run:

  $ helm status hashicorp
  $ helm get all hashicorp
```

```
$ kubectl get pods
```
```
NAME                                                              READY   STATUS    RESTARTS   AGE
hashicorp-consul-76x52                                            1/1     Running   0          90s
hashicorp-consul-9td4g                                            1/1     Running   0          90s
hashicorp-consul-connect-injector-webhook-deployment-6f96cjrxqm   1/1     Running   0          90s
hashicorp-consul-m4szz                                            1/1     Running   0          90s
hashicorp-consul-pvqll                                            1/1     Running   0          90s
hashicorp-consul-server-0                                         1/1     Running   0          90s
```

```
$ kubectl exec -it hashicorp-consul-server-0 /bin/sh
```
```
kubectl exec [POD] [COMMAND] is DEPRECATED and will be removed in a future version. Use kubectl kubectl exec [POD] -- [COMMAND] i
nstead.
/ #
```

```
/ # consul members
```
```
Node                                       Address         Status  Type    Build  Protocol  DC   Segment
hashicorp-consul-server-0                  10.40.2.5:8301  alive   server  1.7.3  2         dc1  <all>
gke-cluster-01-default-pool-00f718cd-bp95  10.40.3.3:8301  alive   client  1.7.3  2         dc1  <default>
gke-cluster-01-default-pool-00f718cd-hdzj  10.40.0.9:8301  alive   client  1.7.3  2         dc1  <default>
gke-cluster-01-default-pool-00f718cd-kvxd  10.40.2.4:8301  alive   client  1.7.3  2         dc1  <default>
gke-cluster-01-default-pool-00f718cd-m5x3  10.40.1.3:8301  alive   client  1.7.3  2         dc1  <default>
```

```
/ # exit
```

```
$ kubectl get services
```
```
NAME                                    TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                                                   AGE
hashicorp-consul-connect-injector-svc   ClusterIP      10.43.246.84    <none>           443/TCP                                                                   3m55s
hashicorp-consul-dns                    ClusterIP      10.43.243.94    <none>           53/TCP,53/UDP                                                             3m54s
hashicorp-consul-server                 ClusterIP      None            <none>           8500/TCP,8301/TCP,8301/UDP,8302/TCP,8302/UDP,8300/TCP,8600/TCP,8600/UDP   3m54s
hashicorp-consul-ui                     LoadBalancer   10.43.244.143   35.205.152.234   80:31348/TCP                                                              3m55s
kubernetes                              ClusterIP      10.43.240.1     <none>           443/TCP                                                                   21m
```

Let's edit the `service-b.deployment.yaml` and `service-a.deployment.yaml` to add the annotation to automatically inject the sidecar:

```yaml
# service-b.deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: service-b
---
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
      annotations:
        "consul.hashicorp.com/connect-inject": "true"
    spec:
      containers:
      # This name will be the service name in Consul.
      - name: service-b
        image: patrice1972/service-b:1.0.0
        ports:
        - containerPort: 3001
      ## If ACLs are enabled, the serviceAccountName must match the Consul service name.
      serviceAccountName: service-b
```

```
$ kubectl apply -f service-b.deployment.yaml
```
```
deployment.apps/service-b created
```

```
$ touch service-a.deployment.yaml
```

```yaml
# service-a.deployment.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: service-a
---
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
      annotations:
        "consul.hashicorp.com/connect-inject": "true"
        "consul.hashicorp.com/connect-service-upstreams": "service-b:3001"
    spec:
      containers:
      - name: service-a
        image: patrice1972/service-a:1.0.0
        env:
        - name: SERVICE_B_NAME
          value: "localhost"
      ## If ACLs are enabled, the serviceAccountName must match the Consul service name.
      serviceAccountName: service-a
```

```
$ kubectl apply -f service-a.deployment.yaml
```
```
deployment.apps/service-a configured
```

```
$ kubectl get pods
```
```
NAME                                                              READY   STATUS    RESTARTS   AGE
helm-consul-consul-5zl6b                                          1/1     Running   0          18h
helm-consul-consul-6tzxf                                          1/1     Running   0          18h
helm-consul-consul-972jc                                          1/1     Running   0          18h
helm-consul-consul-9ps8n                                          1/1     Running   0          18h
helm-consul-consul-connect-injector-webhook-deployment-85ctnjqt   1/1     Running   0          18h
helm-consul-consul-server-0                                       1/1     Running   0          18h
service-a-79fcb7bb59-86s4n                                        3/3     Running   0          51s
service-b-54bb466db8-sz7h9                                        3/3     Running   0          18h
```

```
$ kubectl logs service-a-79fcb7bb59-86s4n service-a
```
```

```

If it does not work, you can debug the situation by connecting to the container running service-a with a shell interface using the following command:

```
$ kubectl exec -it service-a-7598597bc8-6pm4w service-a -- /bin/bash
```
```
[DEBUG] hostname (OS): service-b-75f6f6b4f7-lfbll
[DEBUG] hostname (OS): service-b-75f6f6b4f7-lfbll
[DEBUG] hostname (OS): service-b-75f6f6b4f7-lfbll
```

#### Consul Connect SMI Adapter

```
$ curl -s https://releases.hashicorp.com/consul/1.7.3/consul_1.7.3_linux_amd64.zip -o consul.zip
```

```
$ unzip consul.zip
```
```
Archive:  consul.zip
  inflating: consul
```
```
$ sudo chmod +x consul
```
```
$ sudo mv consul /usr/bin/consul
```


```
$ git clone https://github.com/hashicorp/consul-smi-controller.git
```

```
$ kubectl apply -f consul-smi-controller.yml
```
```

```

```
$ kubectl exec -it helm-consul-consul-5zl6b -- /bin/bash
```

```
$ consul agent \
  -config-dir=/etc/consul.d \
  -data-dir=/tmp/consul \
  -node=cloudshell \
  -bind=172.18.0.1
```

```
/ # consul acl token create -description "read/write access for the consul-smi-controller" -policy-name global-management
```