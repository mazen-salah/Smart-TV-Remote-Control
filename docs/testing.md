# Testing on a real TV

Every protocol client in this app is written against vendor documentation and
public reverse-engineering notes. Only Samsung Tizen has been exercised on a
set by the maintainer; the others need someone with the hardware. This page is
what to check and what to send back, so a report is useful without a
back-and-forth.

Nothing here is a formality: the numbers that matter most — how far one pointer
unit moves the LG cursor, which of its own buttons a Bravia reports, whether a
particular Tizen app id still resolves — cannot be derived from documentation.

## Before you start

- **Build.** Either a release APK from
  [Releases](https://github.com/mazen-salah/Smart-TV-Remote-Control/releases),
  or from a checkout: `flutter build apk --debug`, then
  `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.
- **Logs.** From a checkout, `flutter run` shows them live. From an installed
  APK, `adb logcat | grep -E 'LG:|Sony:|Roku:'`. Every client logs its own
  decisions under those prefixes, including the ones where it deliberately does
  nothing.
- **Same network.** The phone and the TV must be on the same subnet: discovery
  is multicast, and Wake-on-LAN does not cross routers.
- **Not everything is in your build.** Some features are still open pull
  requests; if a button or screen described below is missing, that is why.

| Feature | Where it lands |
| --- | --- |
| LG pointer pad | PR #49 |
| App shortcuts (Netflix and friends) | PR #47 |
| Roku, Sony BRAVIA | PR #48 |
| Phone volume keys → TV | PR #46 |
| Brand label on the device card | PR #50 |

## What to send back

A report is worth having if it has these six lines:

1. TV model and, if you can find it, firmware version (`Settings → About`).
2. Which app build: release APK version, or the commit you built.
3. The way you added the TV: discovery, or **+ → brand → IP**.
4. Which keys worked, by group — navigation, media, volume, digits.
5. What did **not** work, with the log lines that start with the brand prefix.
6. Whether a second launch still connects without pairing again.

Post it on the issue for your brand: LG
[#9](https://github.com/mazen-salah/Smart-TV-Remote-Control/issues/9), Roku
[#16](https://github.com/mazen-salah/Smart-TV-Remote-Control/issues/16), Sony
[#17](https://github.com/mazen-salah/Smart-TV-Remote-Control/issues/17). Samsung
has no open issue — it is the one brand whose client has been run on a set — so
send it as a new issue or as a comment on the pull request that changed it.

## LG webOS (issue #9)

Setup: nothing to switch on. The set asks for permission on the first pairing —
pick **Yes** and, if it offers, remember the phone. The app pins the TV's
certificate when it pairs.

- Connects to `wss://<ip>:3001`, falls back to `ws://<ip>:3000` for pre-2018
  sets. A set that connects but ignores every key is a firmware difference
  worth reporting.
- Keys go through the pointer input socket: D-pad, **OK**, **BACK**, **EXIT**,
  **HOME**, **MENU**, **INFO**, colour keys, digits, mute, volume, channel.
  Play/pause/stop/rewind/fast-forward go through `ssap://media.controls/*`.
- **Power turns the TV off** (`ssap://system/turnOff`), it is not a toggle; an
  off webOS set does not answer on the network, so waking it needs Wake-on-LAN
  and a known MAC.
- With the pointer pad: does a swipe move the cursor the right distance, or is
  it too fast / too slow? The pad uses 4 dp of finger travel per pointer unit,
  which is a guess. This is the single most useful thing to report.

## Roku (issue #16)

Setup: **Settings → System → Advanced system settings → Control by mobile apps
→ Network access** must be **Enabled**. Without it every request is refused,
which is why the app reports the device as unreachable.

- ECP is plain HTTP on port 8060, no pairing; the device answers
  `GET /query/device-info` with its name, model, serial and the MAC that
  Wake-on-LAN needs.
- Keys: D-pad, **OK**, **BACK**, **HOME**, **INFO**, mute, volume, channel,
  play/pause, rewind, fast-forward, digits. Two deliberate aliases: **MENU**
  sends `Info` (Roku has nothing else) and **PAUSE** sends `Play`, which
  toggles.
- Not supported, by design: stop, the colour keys and a distinct pause. They
  are dropped, not guessed at.
- **Power turns the set off.** ECP has no toggle; a Roku TV that is off is woken
  with Wake-on-LAN instead.
- Worth reporting: does a **Roku Streaming Stick or set-top box**, as opposed to
  a Roku TV, behave the same? Volume keys are passed to the TV over CEC there
  and may do nothing.

## Samsung Tizen

Setup: nothing to switch on for the first connect — the set asks for permission
as soon as the app opens its control channel. The answer is remembered per
device; the list is under **Settings → General → External Device Manager →
Device Connection Manager** (wording differs by year), and an entry that was
denied once stays there until it is removed. The app announces itself as
**Smart TV Remote**. Builds before this change announced
`DartSamsungSmartTVDriver`; an entry under that name is this same app and can be
deleted.

- Transport: `http://<ip>:8001/api/v2/` for the device info, including the MAC
  that Wake-on-LAN needs, and
  `wss://<ip>:8002/api/v2/channels/samsung.remote.control` for keys, with the
  announced name base64-encoded.
- Pairing: the first connect carries no token. The set shows the prompt, returns
  a token and the app stores it. A second launch must connect without the
  prompt; if it asks again, the token is not being kept.
- Keys: Tizen takes its own key names, so the app sends `KEY_UP`, `KEY_ENTER`,
  `KEY_RETURN`, `KEY_VOLUP` and the rest verbatim — the pad, the media row, the
  digits, the colour keys, **HOME** and **MENU**. Whether a given set accepts
  all of them is exactly what a report answers.
- Tizen has no pointer socket, so the touchpad is hidden for this brand by
  design; there is nothing to verify there.
- **Power turns the set off** (`KEY_POWER`); an off set answers nothing on the
  network, so waking it needs Wake-on-LAN or the physical remote.
- Worth reporting: does the prompt name **Smart TV Remote** and does the entry
  under Device Connection Manager match it; does a second launch skip the
  prompt; and which keys that particular set ignores — a 2015–2016 Tizen build
  accepts a different key set from a 2019 one.

## Sony BRAVIA (issue #17)

Setup: **Settings → Network → Home network → IP control** must be **On**, and
**Authentication** should be **Normal and Pre-Shared Key** with a key you type
in, exactly as you typed it on the TV. Add the TV with **+ → Sony** and that
key. Turn **Remote start** on as well if you want the app to wake the set.

- Port 80, two interfaces: JSON-RPC at `/sony/system` and IRCC at `/sony/IRCC`.
- Keys: D-pad, **OK**, **BACK**, **HOME**, **TOOLS** (Sony calls it
  **OPTIONS**), input, exit, mute, volume, channel, digits, play/pause/stop,
  rewind/fast-forward. **Power turns the set off**; an off Bravia is woken with
  Wake-on-LAN.
- The app asks the set for its own button table
  (`getRemoteControllerInfo`) and uses it when it answers, falling back to
  Sony's documented codes otherwise. **Info**, **Exit**, **Rewind** and
  **Forward** are not in the documented table, so they work only if the set
  reports them.
- Worth reporting: does your set answer `getRemoteControllerInfo` at all, and
  does the key you typed survive an app restart? The log line
  `Sony: no IRCC code for …` answers the first; a second launch that asks for
  the key again answers the second.
- Mixed setups — a soundbar or an AV receiver between everything — are
  interesting: report the model of each box in the chain.

## Phone volume keys (issue #13)

Android only. Open the remote screen for a connected TV and press the phone's
rocker: the TV's volume should change and the phone's own volume UI should not
move. Leaving the screen — back, or switching apps — must hand the rocker back
to the phone.

Worth reporting: with music or a video playing on the phone at the same time,
does the TV still win the key, or does the media session take it back? That case
decides whether the feature needs a different approach.

## App shortcuts (issue #14)

The last row of the remote opens Netflix, YouTube, Disney+ and Prime Video.

- webOS ids are per product and stable (`netflix`, `youtube.leanback.v4`, …).
- Tizen ids are per app version: a set from a different year can carry a
  different id for the same app. A set that does not know an id simply stays
  where it is — report the model and the year and it can be looked up with
  `GET http://<ip>:8001/api/v2/applications`.
- Roku channel ids are per channel and identical on every device.
- Sony has no shortcut yet: Bravia launches apps through
  `appControl.setActiveApp` with a per-model URI, and guessing it would be worse
  than doing nothing.
