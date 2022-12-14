


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
  pusher.trigger(channel, event, data);
  res.json({"message" : "success"});

});



app.listen(port, () => {
    console.log('App listening on port ${port}')
})
