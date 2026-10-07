# Hosting Marrow

This guide helps you spin up a public Marrow (SS13) server quickly.

## 1. Prerequisites
- BYOND account (for admin login)
- Port forwarding for TCP 8000 (or whichever port you expose)
- Git + Docker (recommended) OR native BYOND install (Windows)

## 2. Quick Start (Docker)
```bash
# Build images
docker compose build
# Launch (detached)
docker compose up -d
# View logs
docker compose logs -f game
```
Connect using BYOND: `byond://<your-ip>:8000`

## 3. Native (Windows) Quick Run
1. Install BYOND 516.
2. Open Dream Maker, compile `Marrow.dme`.
3. Open Dream Daemon, load `Marrow.dmb`, set port (e.g., 8000), enable Trusted / Invisible, start.

## 3b. Linux One-Shot Start
`start-server.sh` updates the repo, brings up the MariaDB container, compiles, and runs DreamDaemon in the foreground on port 26370.

```bash
./start-server.sh          # prompts before the hard reset
./start-server.sh --yes    # non-interactive
```

Requires Docker and a BYOND install on `PATH` (see `install-byond.sh`; set `BYOND_HOME` if it isn't).

**The update step runs `git reset --hard`, discarding local changes.**

Flags / env overrides: `--port N`, `--branch NAME`, `--skip-update`, `--skip-compile`, `--stop-db-on-exit`, plus `PORT`, `REMOTE`, `BRANCH`, `PUBLIC_HOST`, `BYOND_HOME`.

The `db` and `tts` Compose services are started. The game runs natively on the host, reaching the database at `127.0.0.1:3307` and TTS at `127.0.0.1:5000`. Ctrl+C stops the game; the database keeps running unless `--stop-db-on-exit` is passed, and TTS keeps running. Set `TTS_HTTP_URL` to an external service to skip starting bundled TTS.

## 4. Configuration
Edit `config/config.txt`:
- `SERVERNAME` – displayed server label.
- `DISCORDURL`, `GITHUBURL` – player-facing metadata.
- Uncomment features (remove leading #) only when required; start conservative.

Recommended to leave disabled for first public test:
- Extra antagonist vote toggles (#ALLOW_EXTRA_ANTAGS)
- Continuous rounds (#CONTINUOUS_ROUNDS)
- Aggressive changelog (#AGGRESSIVE_CHANGELOG)

## 5. Admin Setup
Add your ckey to `config/admins.txt` (or configure SQL + remove `ADMIN_LEGACY_SYSTEM` comment to migrate later).

Grant yourself host / primary rank, restart the server, then use the Admin > Secrets menu path to verify verbs.

## 6. Jobs & Opposition
The Revolutionary job appears under the Opposition section in late join and (after pending UI cleanup) in Occupation preferences. Verify slots (default 3) via the Job panel.

## 7. Persistence & Logs
- Player saves: `data/player_saves/`
- Logs: `data/logs/`
The Docker `game` service mounts `./data` to persist these across container restarts/rebuilds.

## 8. Updating
```bash
git pull
docker compose build --no-cache
docker compose up -d
```
Warn players before updates; compile locally first when changing code.

## 9. Troubleshooting
| Symptom | Fix |
|---------|-----|
| Clients on another network cannot connect | While DreamDaemon is running, verify `sudo ss -ltnp | grep ':26370'`. Allow it with `sudo ufw allow 26370/tcp`, add an inbound TCP 26370 rule in any cloud firewall, or forward TCP 26370 on the router to this host. From the other network, test with PowerShell: `Test-NetConnection <public-ip> -Port 26370`. If the router's WAN address differs from `curl -4 https://api4.ipify.org` or is private/CGNAT space, ordinary port forwarding cannot work; request a public IPv4 address or host on a public VPS. |
| Undefined type path on compile | Ensure new .dm file added to `.dme`. |
| SQL auth errors | Confirm DB migration and credentials in `config/dbconfig.txt`. |
| High tick lag | Reduce event frequency, disable unused random events. |
| No CSS/HTML renders for players (blank chat/UI), but works when you test locally | DreamDaemon's embedded browser is IE/Trident-based and needs the `FEATURE_BROWSER_EMULATION` registry key set for `DreamDaemon.exe` (value `11001`, DWORD) in the **HKCU hive of the Windows account that actually runs DreamDaemon**. If you host via a service/scheduled task/different user than the one you use for local testing, that account's registry won't have the key even though yours does. `scripts/run-server.ps1` now sets this automatically before launch — use it instead of starting `DreamDaemon.exe` directly, or set the key manually for that user account and restart the process. |

## Text To Speech

Local speech TTS is adapted from Watermelon914's [CMSS13 PR #7095](https://github.com/cmss13-devs/cmss13/pull/7095), revision `137d53f2f7d16c15157e9841d9a2cef28e9fb2bc`. That PR was closed without merging; CMSS13 master does not contain this feature. The upstream code is AGPL-3.0; preserve its applicable source-availability obligations when distributing or hosting this adaptation.

The bundled Linux service uses **eSpeak NG** for local synthesis and **FFmpeg** for OGG encoding. It has lightweight, robotic English voices rather than neural voices, requires no external API or token, and implements CM's speech, blips, pitch, and silicon-filter endpoints. A rust-g library with asynchronous HTTP support is required by the game.

For native BYOND on a Linux host, start the service from the repository root:

```bash
docker compose up -d --build --wait --wait-timeout 60 tts
curl --fail http://127.0.0.1:5000/tts-voices
```

Both `start-server.sh` and `start-server.bat` build/start TTS automatically and wait up to 120 seconds for it to become healthy before launching the game. On Windows, the batch launcher starts Docker Desktop if its engine is stopped; Docker Desktop must be configured for Linux containers. Both launchers skip the bundled service when `TTS_HTTP_URL` points to an external backend. A recent Docker Compose v2 with `--wait` support is required. The service restarts with Docker and publishes its port only on host loopback. The shipped configuration already points at it:

```text
TTS_HTTP_URL http://127.0.0.1:5000
TTS_MAX_CONCURRENT_REQUESTS 4
```

For a containerized game, `docker compose up -d --build` starts the same service and waits for its health check. Compose sets the game's endpoint to `http://tts:5000` over the private container network. The game image builds and runs `Interpost-Hague`, not `Marrow`.

Restart the game after changing configuration, then enable **Server > Toggle Text To Speech**. If already enabled, discovery retries within one minute once the service is ready. Inspect service failures with `docker compose logs --tail=50 tts`; stop it with `docker compose stop tts`.

To run without Docker, install Node.js 22+, `espeak-ng`, and `ffmpeg` on Linux, then run `HOST=127.0.0.1 node tools/tts/server.js` under your service manager. Default Node binding is `0.0.0.0` for container networking, so set `HOST` for a native launch. The service executes argument arrays, not shell commands, and rejects arbitrary audio filters.

An external CM-compatible service can still be selected with `TTS_HTTP_URL` in configuration or the game process environment. Environment values take precedence. `TTS_HTTP_TOKEN` is optional and sent verbatim in the `Authorization` header; keep real tokens out of version control. For the bundled service, set the same environment token on both processes if authentication is needed. Do not expose an unauthenticated TTS port to the internet. Optional `TTS_VOICE_BLACKLIST` accepts comma-separated identifiers without surrounding spaces.

The service must implement:
- `GET /tts-voices`: a JSON array of voice identifiers.
- `GET /pitch-available`: HTTP 200 if pitch adjustment is supported; otherwise a non-200 response.
- `GET /speech-profile-available`: optional capability endpoint, returning HTTP 200 when character gender and age metadata are supported. Unsupported services keep receiving text-only requests.
- `GET /tts` and `GET /tts-blips`: accept a JSON body with `text` and query parameters `voice`, `identifier`, `filter`, `pitch`, and `special_filters`; return OGG audio. The speech endpoint should return `audio-length` in seconds. The `silicon` filter is used for silicon speakers.

Admins with `R_ADMIN` can use **Server > Toggle Text To Speech**. It starts disabled and saves its state in `data/tts_enabled.txt`, surviving rounds and server restarts. Disabling drops queued audio; audio already sent to clients finishes normally. Missing or unavailable services do not delay ordinary text chat. Voice discovery retries every minute while enabled.

Players can select Enabled, Blips Only, or Disabled and adjust volume, voice, and pitch in the **Preferences** stat tab or through **OOC > Toggle Preference**. **OOC > Choose Text To Speech Voice** provides a voice-selection menu after discovery. These settings use the existing saved player preferences. Automatic voices are stable for a given displayed voice name; voice and pitch selections are player-wide, not separate character-slot settings. Pitch is used only when supported by the backend.

The bundled service varies speech using the speaking character's in-game gender and age. Male and female characters use eSpeak's masculine/feminine variants of the selected accent; neuter and plural characters retain the base voice. Below age 25, pitch and pace increase slightly; above age 60, they decrease gradually. Character age is bounded to 0-120 for synthesis, and nonhuman speakers without an age use 30. The player's selected pitch remains an additive adjustment. Blip pitch varies as well. Metadata is captured when the line is spoken, not when playback eventually starts. Restart the game after updating it and rebuild the TTS service to activate this feature.

This covers audible local speech, including whispers and speech overheard locally from radio users, not remote radio, deadchat, OOC, or CM-specific hivemind speech. Deaf, sleeping, unconscious, and language-incompatible listeners receive no TTS. Nonverbal and innate languages are excluded. Like the upstream implementation, synthesis text is limited to ASCII letters, numbers, basic punctuation, and 299 characters. Speech text is sent to the configured service; use a trusted endpoint.

Manual in-game verification with a configured backend:
1. Enable TTS, speak near another player, and check voice discovery, spatial playback, whispers, and consecutive lines without overlap from the same speaker.
2. Switch playback to Blips Only, Disabled, and volume 0; verify the settings survive reconnecting and restarting.
3. Check deafness, unconsciousness, vacuum, unknown languages, and nonverbal speech produce no intelligible TTS outside ordinary hearing rules.
4. Disable TTS during pending requests; confirm no queued lines play, then restart and confirm the saved global state.
5. Stop the backend and verify text chat remains responsive and expired audio is discarded.

## 10. Next Hardening Ideas
- Add Prometheus exporter for basic metrics.
- Set up automatic log rotation (cron or Docker log driver limits).
- Implement CI compile test (GitHub Actions) per PR.

Happy hosting! Report issues via the repo tracker.
