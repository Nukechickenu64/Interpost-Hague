#!/usr/bin/env bash
# Linux one-shot launcher: update the repo, start the MariaDB container, compile, run DreamDaemon.
set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PORT="${PORT:-6345}"
REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-}"
SKIP_UPDATE="${SKIP_UPDATE:-0}"
SKIP_COMPILE="${SKIP_COMPILE:-0}"
STOP_DB_ON_EXIT="${STOP_DB_ON_EXIT:-0}"
FORCE_RESET="${FORCE_RESET:-0}"

DB_USER="gamelord"
DB_PASS="gamelord"
DB_NAME="bs12"

usage() {
	cat <<'EOF'
Usage: ./start-server.sh [--yes] [--port N] [--branch NAME] [--skip-update] [--skip-compile] [--stop-db-on-exit]

Updates the repository (git fetch + hard reset), starts the MariaDB docker
container, compiles Marrow.dme, then runs DreamDaemon in the foreground.

Environment overrides: PORT, REMOTE, BRANCH, SKIP_UPDATE, SKIP_COMPILE,
STOP_DB_ON_EXIT, FORCE_RESET, BYOND_HOME.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--yes|-y) FORCE_RESET=1 ;;
		--port) PORT="$2"; shift ;;
		--branch) BRANCH="$2"; shift ;;
		--skip-update) SKIP_UPDATE=1 ;;
		--skip-compile) SKIP_COMPILE=1 ;;
		--stop-db-on-exit) STOP_DB_ON_EXIT=1 ;;
		-h|--help) usage; exit 0 ;;
		*) echo "Unknown argument: $1" >&2; usage >&2; exit 1 ;;
	esac
	shift
done

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# --- Preflight ---------------------------------------------------------------

log "Checking prerequisites..."

command -v git >/dev/null 2>&1 || die "git is not installed."
command -v docker >/dev/null 2>&1 || die "docker is not installed."
docker compose version >/dev/null 2>&1 || die "The 'docker compose' plugin is not available."
docker info >/dev/null 2>&1 || die "Docker is not running, or this user lacks access to the docker socket."

if [[ -n "${BYOND_HOME:-}" && -f "$BYOND_HOME/bin/byondsetup" ]]; then
	# shellcheck disable=SC1091
	. "$BYOND_HOME/bin/byondsetup"
fi

if [[ "$SKIP_COMPILE" != "1" ]]; then
	command -v DreamMaker >/dev/null 2>&1 || die "DreamMaker not on PATH. Install BYOND (see install-byond.sh) and set BYOND_HOME."
fi
command -v DreamDaemon >/dev/null 2>&1 || die "DreamDaemon not on PATH. Install BYOND (see install-byond.sh) and set BYOND_HOME."

# --- Update ------------------------------------------------------------------

if [[ "$SKIP_UPDATE" == "1" ]]; then
	log "Skipping repository update."
else
	if [[ -z "$BRANCH" ]]; then
		BRANCH="$(git rev-parse --abbrev-ref HEAD)"
		[[ "$BRANCH" == "HEAD" ]] && die "Detached HEAD; pass --branch NAME."
	fi

	log "Updating to $REMOTE/$BRANCH (this discards local changes)..."
	if [[ "$FORCE_RESET" != "1" ]]; then
		[[ -t 0 ]] || die "Refusing a hard reset without a TTY. Re-run with --yes to confirm."
		read -r -p "Hard reset '$BRANCH' to '$REMOTE/$BRANCH' and discard local changes? [y/N] " reply
		[[ "$reply" =~ ^[Yy]$ ]] || die "Aborted by user."
	fi

	git fetch "$REMOTE"
	git checkout "$BRANCH"
	git reset --hard "$REMOTE/$BRANCH"
fi

# --- Database ----------------------------------------------------------------

log "Building the database image..."
docker compose build db

log "Starting MariaDB..."
docker compose up -d db

log "Waiting for MariaDB to become ready..."
ready=0
for _ in $(seq 1 30); do
	if docker compose exec -T db mariadb-admin ping -h 127.0.0.1 -u "$DB_USER" -p"$DB_PASS" --silent >/dev/null 2>&1; then
		ready=1
		break
	fi
	sleep 2
done

if [[ "$ready" != "1" ]]; then
	docker compose logs --tail=40 db
	die "MariaDB did not become ready in time."
fi

log "MariaDB is ready. Verifying the schema..."
docker compose exec -T db mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SHOW TABLES;" \
	|| die "Database connection or schema verification failed."

# --- Compile -----------------------------------------------------------------

mkdir -p data/logs data/player_saves

if [[ "$SKIP_COMPILE" == "1" ]]; then
	log "Skipping compile."
else
	log "Compiling Marrow.dme..."
	if ! DreamMaker Marrow.dme 2>&1 | tee data/logs/compile.log; then
		die "Compilation failed. See data/logs/compile.log."
	fi
	grep -qE '\b0 errors\b' data/logs/compile.log || die "Compilation reported errors. See data/logs/compile.log."
fi

# --- Run ---------------------------------------------------------------------

if [[ "$STOP_DB_ON_EXIT" == "1" ]]; then
	trap 'log "Stopping the database container..."; docker compose stop db' EXIT
	log "Starting the server on port $PORT (Ctrl+C to stop)..."
	scripts/run-server.sh "$PORT"
else
	log "Starting the server on port $PORT (Ctrl+C to stop; the database keeps running)..."
	exec scripts/run-server.sh "$PORT"
fi
