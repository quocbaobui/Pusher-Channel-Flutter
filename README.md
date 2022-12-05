# Pusher-Channel-Flutter




## I. Server API Overview

####  1. Folder Folder: ```BE -> demo```

####  2. Prerequisites

- Have ```npm``` installed.
- Have ```express``` framework isntalled.
- Have ```npm install pusher```  isntalled.
- Have ```npm install cors```  isntalled.

### Usage

```
npm start
```

#### Funtions
- Init pusher
```
const Pusher = require("pusher");v
const pusher = new Pusher({
  appId: "APP_ID",
  key: "APP_KEY",
  secret: "APP_SECRET",
  cluster: "APP_CLUSTER",
  useTLS: true,
});
```


- Authorized connections
```
app.post("/api/pusher/auth-channel", (req, res) => {
  const socketId = req.body.socket_id;
  const channel = req.body.channel_name;
  const authResponse =  pusher.authorizeChannel(socketId, channel);
  console.log("authResponse : ");
  console.log(authResponse);
  res.send(authResponse);
});
```

- API Trigger (Support Public channel, Private Channel)

```
app.post("/api/pusher/auth-channel", (req, res) => {
  const socketId = req.body.socket_id;
  const channel = req.body.channel_name;
  const authResponse =  pusher.authorizeChannel(socketId, channel);
  console.log("authResponse : ");
  console.log(authResponse);
  res.send(authResponse);
});
```

## 2. Server API Overview


####  1. Folder Folder: ```FE -> demopusher```






- 