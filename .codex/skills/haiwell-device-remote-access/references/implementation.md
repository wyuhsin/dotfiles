# Production implementation reference

Last verified: 2026-07-01.

## Source of truth

- `/Users/haiwell/go/src/device-core/internal/logic/device/device_visit_url.go`: enterprise-maintenance URL and PassID generation.
- `/Users/haiwell/go/src/open-api/internal/app/logic/device/device.go`: stateless read-only/full-control link generation.
- `/Users/haiwell/go/src/device-service/app/service/internal/logic/device/device_visit_time.go`: PassID verification and permission mapping.
- `/Users/haiwell/go/src/personal/app/service/internal/logic/machine/machine_base.go`: device tunnel URL formatting.

Re-read the relevant functions when these repositories are present. Stop if the platform code, payload layout, encryption, route, or read-only mapping differs from this reference.

## Production data

Use `~/.codex/bin/codex-mysql` with these read-only profiles:

- `mysql` (`hwcloud2`): `all_machines`, `machine_server`, and `server` provide device existence, tunnel state, server ID, domain, and area.
- `mysql-enterprise` (`enterprise`): `device` provides enterprise-device presence, enterprise ID, and online state.

`auto` classifies a device with an enterprise row and nonzero `eid` as enterprise; otherwise it uses the personal-device path. An explicit type requires its corresponding record.

## Link format

- Routed base URL: `https://<PN>.<server.domain>` when a tunnel domain exists.
- Legacy fallback: `http://<PN>.machine.haiwell.com:8000` only when the device exists and its current production routing record has no domain.
- Entry route: `/index`.
- Query: `?passid=<hex>&platform=<platform>`.

The current stateless payload is encrypted with 3DES-CBC and PKCS#5 padding. It contains:

```text
md5,subject,PN,platform-code,timestamp-ms
```

Permission subjects:

- `-1`: read-only.
- `0`: full control.

The enterprise platform verifier currently maps this platform code to maintainer access and applies read-only only when the subject is `-1`. It does not currently enforce server-side expiry for that branch. Therefore every generated link must be handled as a sensitive bearer credential even if it was created for temporary operational use.

## Verification boundary

`/test` HTTP 200 verifies the tunnel endpoint. `/index` returning 200 or redirecting to `/project/apps/index` verifies the entry route. Neither proves the HMI project UI completed rendering; verify the redirected page separately when the user requires end-to-end usability.
