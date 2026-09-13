# TV protocols used by this app

Notes on the wire protocols the app speaks, collected here because the vendor
documentation is thin and scattered. Everything below is implemented in
`lib/services/`; line references are to the files there.

## Discovery

**SSDP (UPnP)** — `lib/services/upnp/ssdp_discovery_service.dart`

One `M-SEARCH` for `ssdp:all` on `239.255.255.250:1900`. Responders are
classified from their headers before any HTTP fetch:

| Brand | Recognised by |
| --- | --- |
| Samsung | `SERVER` header matching `Samsung … UPnP … SDK` |
| LG | `ST` / `USN` containing `urn:lge-com:service:webos-second-screen:1` |

The `LOCATION` URL then yields the device description XML, from which
`friendlyName` and `modelName` are read. Android only delivers multicast
replies while a `WifiManager.MulticastLock` is held, so the sweep acquires one
through a method channel. iOS refuses raw multicast without Apple's
`com.apple.developer.networking.multicast` entitlement; the failure is logged
and Bonjour covers discovery there.

**Bonjour / mDNS** — `lib/services/mdns/bonjour_discovery_service.dart`

Browsed through the platform service browser (`bonsoir`), which needs no
entitlement or lock. Types and how the brand is decided:

| Type | Brand |
| --- | --- |
| `_samsungmsf._tcp` | Samsung |
| `_lg-mrt._tcp` | LG |
| `_airplay._tcp` | from TXT `manufacturer` / `model` |
| `_googlecast._tcp` | from TXT `md` / `fn` |

Devices whose brand cannot be determined (Apple TVs, Chromecasts, Macs) are
dropped. Every browsed type must be listed under `NSBonjourServices` in
`ios/Runner/Info.plist`.

## Samsung Tizen (2016+)

`lib/services/samsung/samsung_tv_service.dart`

**Device info** — `GET http://<ip>:8001/api/v2/` returns JSON with
`device.name`, `device.modelName`, `device.wifiMac` (used for Wake-on-LAN) and
`device.PowerState`.

**Control channel** — a WebSocket to

```
wss://<ip>:8002/api/v2/channels/samsung.remote.control?name=<base64 app name>[&token=<token>]
```

The TV presents a self-signed certificate, so certificate validation is
disabled for this host. Port 8001 (`ws://`) still exists on older firmware but
does not issue tokens; use 8002.

**Pairing** — on the first connection without a token the TV shows an
"Allow" prompt. Accepting it yields an event:

```json
{"event":"ms.channel.connect","data":{"token":"12345678", ...}}
```

The token is persisted (`TvTokenStorage`) and appended to the URL from then
on, so the prompt does not reappear. `ms.channel.unauthorized` means the user
denied the prompt or the TV's *Device Connection Manager* blocks this phone.

**Sending a key**

```json
{
  "method": "ms.remote.control",
  "params": {
    "Cmd": "Click",
    "DataOfCmd": "KEY_VOLUP",
    "Option": "false",
    "TypeOfRemote": "SendRemoteKey"
  }
}
```

`Cmd` may also be `Press` / `Release` for held keys. Key names are the
`KEY_*` identifiers in `lib/constants/key_codes.dart`.

**Keep-alive** — the socket's native ping interval; no application-level
heartbeat is needed.

## LG webOS (3.0+)

`lib/services/lg/lg_tv_service.dart`

**Transport** — `wss://<ip>:3001` (self-signed certificate; required by
firmware released since January 2023, including webOS 23+) with a fallback to
`ws://<ip>:3000` for sets from before 2018. The scheme that worked is
remembered for the session. Only a failed TCP/TLS handshake triggers the
fallback; a registration that is refused or times out does not.

**Certificate pinning** — the TV's certificate cannot be validated against a
CA, so it is pinned on first use: the SHA-256 of the certificate presented
during the connection in which the user approved pairing is stored next to
the client key (`TvTokenStorage`, key `cert:lg:<identifier>`). Later TLS
connections reject any other certificate and do **not** fall back to
plaintext; the app reports that the certificate changed and asks the user to
forget the TV and pair again. The saved client key is only ever sent over a
pinned TLS connection. On the plaintext fallback the `register` message omits
it, so pre-2018 sets show the pairing prompt on every session, and the key
they hand back is not stored.

**Pairing** — the first message is a `register` request (given up to 60 s for
the on-screen prompt) whose payload is LG's signed sample manifest (`lg_pairing.dart`, copied verbatim; the `signed` block
is covered by the signature and must not be edited). With a stored
`client-key` the TV replies `registered` immediately; without one it shows an
on-screen prompt and returns a new `client-key` in the `registered` payload,
which is persisted. If a TV rejects the signed manifest the client retries
once with the unsigned variant.

**Requests** — JSON messages with an `id`, `type: "request"`, an `ssap://`
URI and an optional payload. Responses carry the same `id`. Used here:

| URI | Purpose |
| --- | --- |
| `ssap://audio/volumeUp`, `volumeDown`, `setMute` | volume |
| `ssap://tv/channelUp`, `channelDown` | channels |
| `ssap://media.controls/play`, `pause`, `stop`, `rewind`, `fastForward` | transport |
| `ssap://system/turnOff` | power off |
| `ssap://system.launcher/launch` `{ "id": appId }` | app launch |
| `ssap://com.webos.service.networkinput/getPointerInputSocket` | see below |

**Buttons** — navigation, colour, digit and most remote keys are not `ssap://`
calls. `getPointerInputSocket` returns a `socketPath` (another `wss://` URL on
the TV); on that socket each press is a plain-text message:

```
type:button
name:UP

```

(key:value lines terminated by a blank line). Names used: `UP DOWN LEFT
RIGHT ENTER BACK EXIT HOME MENU INFO RED GREEN YELLOW BLUE MUTE VOLUMEUP
VOLUMEDOWN CHANNELUP CHANNELDOWN 0-9`. The same socket accepts
`type:move` / `type:click` for pointer control, which the app does not use
yet.

**Power on** — a TV that is off does not listen on either port; Wake-on-LAN
is the only way to turn it on (enable *Mobile TV On* on the set).

## Wake-on-LAN

`lib/core/services/wake_on_lan_service.dart`

A standard magic packet (6 × `0xFF` followed by the MAC 16 times) sent as UDP
to the broadcast address on port 9. Magic packets do not cross routers, so
the phone must be on the same subnet as the TV.

## References

- lgtv2 (Node.js LG client): https://github.com/hobbyquaker/lgtv2
- aiopylgtv (Python LG client, Home Assistant): https://github.com/bendavid/aiopylgtv
- samsungtvws (Python Samsung client): https://github.com/xchwarze/samsung-tv-ws-api
- Apple, "How to use multicast networking in your app":
  https://developer.apple.com/news/?id=0oi77447
