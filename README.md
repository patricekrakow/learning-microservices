# learning-microservices
My (long) journey into the microservices architecture world.

This journey will go through the following steps:

1\. Node.js - <https://nodejs.org/en/>

2\. curl - <https://curl.haxx.se/>

3\. Docker - <https://www.docker.com/> and <https://hub.docker.com/>

4\. Kubernetes - <https://kubernetes.io/>

5\. Service Mesh

&nbsp;&nbsp;5\.1\. Linkerd - <https://linkerd.io/>

&nbsp;&nbsp;5\.2\. Istio - <https://istio.io/>

&nbsp;&nbsp;5\.3\. Consul Connect - <https://www.consul.io/>

&nbsp;&nbsp;5\.4\. Kuma - <https://kuma.io/>

## Node.js

### How to install Node.js on a Windows laptop

```
[C:\Users\Patrice]
$ node --version
v12.16.3
```

```
[C:\Users\Patrice]
$ npm --version
6.14.4
```

### How to create a simple _service_ exposing an _API endpoint_ in Node.js

```
[C:\Users\Patrice]
$ md experiment-01

[C:\Users\Patrice]
$ cd experiment-01

[C:\Users\Patrice\experiment-01]
$
```

```
[C:\Users\Patrice\experiment-01]
$ fsutil file createNew package.json 0
File C:\Users\Patrice\experiment-01\package.json is created
```

```json
{
  "name": "service-b",
  "version": "1.0.0",
  "description": "Service-b",
  "author": "Patrice Krakow <patrice.krakow@gmail.com>",
  "main": "app.js",
  "dependencies": {
    "express": "^4.17.1"
  }
}
```

```
[C:\Users\Patrice\experiment-01]
$ npm install
npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN service-b@1.0.0 No repository field.
npm WARN service-b@1.0.0 No license field.

added 50 packages from 37 contributors and audited 126 packages in 7.434s
found 0 vulnerabilities
```

```
[C:\Users\Patrice\experiment-01]
$ fsutil file createNew service-b.js 0
File C:\Users\Patrice\experiment-01\service-b.js is created
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
[C:\Users\Patrice\experiment-01]
$ node service-b.js
Running on http://0.0.0.0:3001
```

And now, you can call the _API endpoint_ by going to the following address <http://localhost:3001/path-01> in your browser!
