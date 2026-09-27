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

Only the `db` compose service is started — the game runs natively on the host and reaches the database via `127.0.0.1:3307` as configured in `config/dbconfig.txt`. Ctrl+C stops the server; the database keeps running unless `--stop-db-on-exit` is passed.

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
Ensure these are volume-mounted or backed up if using Docker for continuity.

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

## 10. Next Hardening Ideas
- Add Prometheus exporter for basic metrics.
- Set up automatic log rotation (cron or Docker log driver limits).
- Implement CI compile test (GitHub Actions) per PR.

Happy hosting! Report issues via the repo tracker.
