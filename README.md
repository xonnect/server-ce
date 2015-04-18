## XonnectIO Gateway Server Community Edition

This is the source code of our community edition gateway server, it contains almost all the common features we provide at [XonnectIO](https://xonnect.io).

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


### JSON APIs Demo

Usually, a client needs a universally unique identifier so that it can be found by other clients via name.

Register a unique nickname:

```json
{
    "action": "register",
    "nick": "foo"
}
```

If everything goes fine:

```json
{
    "code": "ok",
    "info": "register.ok",
    "data": "foo"
}
```

Or if the nickname is already taken:

```json
{
    "code": "error",
    "info": "register.conflict",
    "data": "foo"
}
```

"nick" field in the request is optional. If it is omitted, a random one will be generated and returned instead.

<br/>

Messages are broadcast in channels or sent peer-to-peer.

Subscribe to a channel:

```json
{
    "action": "subscribe",
    "channel": "demo"
}
```

If the channel does not exist yet, it will be automatically created.

```json
{
    "code": "ok",
    "info": "subscribe.ok",
    "data": "demo"
}
```

When you don't want to receive messages from a channel any more, just unsubscribe it.

```json
{
    "action": "unsubscribe",
    "channel": "demo"
}
```

<br/>

As mentioned above, messages can be sent to channels and some specific peer by its nickname.

Broadcast a message in a channel:

```json
{
    "action": "send",
    "target": "#demo",
    "data": "Hi, everyone."
}
```

You don't need to be a member of a channel first to send messages to it, although it is usually recommended so that you can get notified when there is news in the channel.

Send a message to a peer:

```json
{
    "action": "send",
    "target": "@bar",
    "data": "Hi, buddy."
}
```

By default no response is generated since no news is good news, but if you really need a confirmation, add a "ref" field to the request.

```json
{
    "action": "send",
    "target": "@bar",
    "data": "Hi, buddy. Again.",
    "ref": "blah~blah~"
}
```

And it will be returned untouched.

```json
{
    "code": "ok",
    "info": "send.ok",
    "data": {
        "ref": "blah~blah~"
    }
}
```

When a new message has arrived from a channel, it looks like this:

```json
{
    "code": "new",
    "info": {
        "from": "#demo"
    },
    "data": "Hi, everyone."
}
```

Here is the one from another peer directly:

```json
{
    "code": "new",
    "info": {
        "from": "@foo"
    },
    "data": "Hi, buddy."
}
```

Specially, since a direct message from a one-way HTTP endpoint has no way to identify itself, the "from" field will be filled in with a reserved source "~unknown":

```json
{
    "code": "new",
    "info": {
        "from": "~unknown"
    },
    "data": "Hi, I'am a ghost."
}
```

### BSON APIs

BSON APIs are the same with JSON APIs, except that they are encoded in BSON. 

### HTTP APIs

The HTTP APIs can only be used to send messages and they only support JSON encoded requests.

Broadcast a message in a channel:

```http
POST /api/v1/messages

{
    "target": "#demo",
    "data": "Hi, everyone."
}
```

Send a message to a peer:

```http
POST /api/v1/messages

{
    "target": "@bar",
    "data": "Hi, buddy."
}
```

In both situations, a `201 Created` will be returned.

### License

BSD 2-Clause license, see LICENSE for more information.
