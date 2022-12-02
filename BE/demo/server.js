


const express = require('express')
const app = express();
const port = 8000;
const cors = require("cors");
const Pusher = require("pusher");

app.use(express.json())


const pusher = new Pusher({
    appId: "1515379",
    key: "1579121763e81d460d93",
    secret: "b4aa310b4198f6eeb240",
    cluster: "ap1",
    useTLS: true
  });

app.use(express.urlencoded({ extended: false }));
app.use(cors());



// authorize users for a presence channel.
// app.post("/api/pusher/auth-user", (req, res) => {
//   const socketId = req.body.socket_id;
//   const channel = req.body.channel_name;
//   const userName = req.body.user_name;
//   const pusherId = userName + "_1234"

//   console.log("socketId :  " + socketId.toString());
//   console.log("channel :  " + channel.toString());
//   console.log("userName : " + userName.toString());
//   console.log("pusherId : " + pusherId.toString());

//   const user = {
//     id: pusherId,
//     user_info: {
//       name: userName
//     },
//     watchlist: [channel]
//   };

//   const authResponseUser =  pusher.authenticateUser(socketId, user);
//   console.log("authResponseUser :");
//   console.log(authResponseUser);  
//   res.send(authResponseUser);
// });



app.post("/api/pusher/auth-channel", (req, res) => {
  const socketId = req.body.socket_id;
  const channel = req.body.channel_name;
  const authResponse =  pusher.authorizeChannel(socketId, channel);
  console.log("authResponse : ");
  console.log(authResponse);
  res.send(authResponse);
});

app.post('/api/pusher/trigger',async (req, res)  => {

  const channel = req.body.channel;
  const event = req.body.event;
  const data = req.body.data;

  console.log("req: " + req);
  console.log("channel: " + channel);
  console.log("event: " + event);
  console.log("data: " + data);

  pusher.trigger(channel, event, data);
  res.json({"message" : "success"});

});



app.listen(port, () => {
    console.log('App listening on port ${port}')
})
