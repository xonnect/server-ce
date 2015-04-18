## XonnectIO Gateway Server Community Edition

<br/>

### API URLs

##### WebSocket Endpoints

`ws://unsafe.your.domain/api/v1/websocket`

`wss://your.domain/api/v1/websocket`

##### HTTP Endpoints

`http://unsafe.your.domain/api/v1/messages`

`https://your.domain/api/v1/messages`

##### TCP Endpoints

`tcp://unsafe.your.domain:50080`

`tcp+tls://your.domain:50443`

<br/>

### JSON API Demo

Usually, a client needs a universally unique identifier so that it can be found by other clients via name.

Register a unique nickname:

```
{
    "action": "register",
    "nick": "foo"
}
```

If everything goes fine:

```
{
    "code": "ok",
    "info": "register.ok",
    "data": "foo"
}
```

Or if the nickname is already taken:

```
{
    "code": "error",
    "info": "register.conflict",
    "data": "foo"
}
```

"nick" parameter in the request is optional. If it is omitted, a random one will be generated and returned instead.

<br/>

Messages are broadcast in channels or sent peer-to-peer.

Subscribe to a channel:

```
{
    "action": "subscribe",
    "channel": "demo"
}
```

If the channel does not exist yet, it will be automatically created.

```
{
    "code": "ok",
    "info": "subscribe.ok",
    "data": "demo"
}
```

When you don't want to receive messages from a channel any more, just unsubscribe it.

```
{
    "action": "unsubscribe",
    "channel": "demo"
}
```

<br/>

As mentioned above, messages can be sent to channels and some specific peer.

Broadcast a message in a channel:

```
{
    "action": "send",
    "target": "#demo",
    "data": "Hi, everyone."
}
```

You don't need to be a member of a channel first to send messages to it, although it is usually recommended so that you can get notified when there is news in the channel.

Send a message to a peer:

```
{
    "action": "send",
    "target": "@bar",
    "data": "Hi, buddy."
}
```

By default no response is generated since no news is good news, but if you really need a confirmation, add a "ref" parameter to the request.

```
{
    "action": "send",
    "target": "@bar",
    "data": "Hi, buddy. Again."
    "ref": "blah~blah~"
}
```

And it will be returned untouched.

```
{
    "code": "ok",
    "info": "send.ok",
    "data": {
        "ref": "blah~blah~"
    }
}
```

When a new message has arrived from a channel, it looks like this:

```
{
    "code": "new",
    "info": {
        "from": "#demo"
    },
    "data": "Hi, everyone."
}
```

Here is the one from another peer directly:

```
{
    "code": "new",
    "info": {
        "from": "@foo"
    },
    "data": "Hi, buddy."
}
```

Specially, since a direct message from a one-way HTTP endpoint has no way to identify itself, the "from" field will be filled with a reserved source "~unknown":

```
{
    "code": "new",
    "info": {
        "from": "~unknown"
    },
    "data": "Hi, I'am a ghost."
}
```

<br/>

### BSON API

BSON APIs are the same with JSON APIs, except that they are encoded in BSON. 

<br/>

### HTTP API

The HTTP API can only be used to send messages and it only supports JSON encoded request.

Broadcast a message in a channel:

```
POST /api/v1/messages

{
    "target": "#demo",
    "data": "Hi, everyone."
}
```

Send a message to a peer:

```
POST /api/v1/messages

{
    "target": "@bar",
    "data": "Hi, buddy."
}
```

In both situations, a "201 Created" will be returned.

<br/>

### License

BSD 2-Clause license, see LICENSE for more information.
