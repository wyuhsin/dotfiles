---
name: haiwell-device-remote-access
description: Generate and validate production remote-access links for Haiwell enterprise or personal devices from a 19-digit PN by reading production MySQL routing and online-state data and creating a read-only or full-control PassID. Use when the user asks to create, regenerate, inspect, or verify a production enterprise-device or personal-device remote access URL.
---

# Haiwell Device Remote Access

## Trigger

Use this skill for production Haiwell enterprise-device or personal-device remote access links. Do not use it for LAN URLs, test/pre environments, VPN passthrough, or ordinary cloud-platform login links.

## Inputs

- `PN`: required 19-digit device code.
- Device type: `auto`, `enterprise`, or `personal`; default to `auto`.
- Access: `read-only` or `control`; default to `read-only`. Generate `control` only when the user explicitly requests remote control or full permission.
- Platform: default to `web` unless the caller requires another known client platform.

## Workflow

1. Read [references/implementation.md](references/implementation.md). If the listed source repositories are available, confirm that the platform code, payload fields, and verification behavior have not drifted before generating a production credential.
2. Run the helper with the requested PN and access mode:

   ```bash
   ~/.codex/skills/haiwell-device-remote-access/scripts/generate_remote_access.sh \
     --pn 7040749043090117188 \
     --device-type auto \
     --access read-only
   ```

3. Use `--access control` only after an explicit full-control request.
4. Stop when the production record is missing, routing data is incomplete, or the device is offline. Use `--allow-offline` only when the user explicitly wants an unverified link.
5. Return the generated URL, detected device type, access mode, online state, tunnel domain, and HTTP verification result.

Useful options:

- `--platform web`: set the client platform query value.
- `--allow-offline`: generate despite an offline database state and label the result unverified.
- `--skip-http-check`: skip tunnel checks when outbound access is unavailable; label verification as skipped.

## Verification

- Require the helper's encryption round-trip check to pass.
- Treat `/test` HTTP 200 plus an `/index` response of 200 or a normal redirect as a valid tunnel entry.
- Do not claim the HMI project rendered successfully unless the redirected project page was actually observed. Report device-page timeouts separately from link-generation failures.
- Re-query production data instead of reusing an old domain or online state.

## Output

Lead with one clickable URL. Then state device type, access level, online state, tunnel node, and verification. If verification is incomplete, say exactly which check failed or was skipped.

## Safety

- Keep production database access read-only. Never insert or update `visit_alid_time`, device membership, or routing records for this workflow.
- Treat the generated URL as a bearer credential. Do not save it to the skill, repository, memory, tickets, or chat systems unless the user explicitly requests that destination.
- Do not expose MySQL option files, passwords, PassID plaintext, encryption keys, or unrelated device/user data.
- Do not silently upgrade `read-only` to `control`.
- Do not invent a fallback domain when the database lookup fails.

## Failure Handling

- Missing `codex-mysql` or production profiles: report the missing local prerequisite.
- Device not found: verify the PN once, then stop.
- Offline device: report the database states; do not call the result usable.
- `/test` succeeds but the project page stalls: report that routing is healthy while the device-side project service is slow or unavailable.
- Source algorithm differs from the bundled reference: stop and update the skill before generating a credential.
