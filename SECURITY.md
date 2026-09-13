# Security Policy

## Supported versions

Only the latest release on the `main` branch receives security fixes.

## Reporting a vulnerability

Please do not open a public issue for security problems.

Use GitHub's private vulnerability reporting instead:
**Security → Report a vulnerability** on this repository. You will get an
acknowledgement within a few days, and a fix or mitigation plan as soon as the
report is confirmed.

## Scope

This app talks to TVs over the local network only. Areas worth extra care:

- Samsung pairing tokens and LG client keys are stored on the device with
  `shared_preferences`. They grant remote-control access to the paired TV.
- Wake-on-LAN sends UDP broadcast packets on the local network.
- Discovery uses UPnP and mDNS multicast; responses are treated as untrusted.
