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
| Clients hang on connection | Check port forward / firewall; ensure DreamDaemon running. |
| Undefined type path on compile | Ensure new .dm file added to `.dme`. |
| SQL auth errors | Confirm DB migration and credentials in `config/dbconfig.txt`. |
| High tick lag | Reduce event frequency, disable unused random events. |

## 10. Next Hardening Ideas
- Add Prometheus exporter for basic metrics.
- Set up automatic log rotation (cron or Docker log driver limits).
- Implement CI compile test (GitHub Actions) per PR.

Happy hosting! Report issues via the repo tracker.
