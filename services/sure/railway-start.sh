#!/bin/bash
# Start Sure on Railway: "web" (default) or "worker".
#
# web:    rails db:prepare, then create the owner account from the
#         SURE_OWNER_* variables (sure-owner.rb) before Puma opens the port,
#         so the sign-up page is never the way to claim the instance.
# worker: wait until the web service has migrated the database, then run
#         Sidekiq with a tiny /healthz listener on PORT (STANDARD 8.34).
#
# Bad variable values never fail the deploy (STANDARD 8.29): a bad owner
# email falls back to admin@example.com, a too short password keeps the
# stored one (or locks a new owner with a random password).
set -euo pipefail

DEFAULT_PORT=3000
DEFAULT_EMAIL=admin@example.com
MIN_PASSWORD=12
MAX_PASSWORD=72
cd /rails

log() { printf '%s railway-start: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

JEMALLOC="/usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2"
if [[ -f $JEMALLOC && -z ${DISABLE_JEMALLOC:-} ]]; then
  export LD_PRELOAD="${LD_PRELOAD:+$LD_PRELOAD:}$JEMALLOC"
fi

port=${PORT:-$DEFAULT_PORT}
if ! [[ $port =~ ^[0-9]{1,5}$ ]] || ((port < 1 || port > 65535)); then
  log "PORT='$port' is not a valid port; using $DEFAULT_PORT"
  port=$DEFAULT_PORT
fi
export PORT=$port

for key in ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT; do
  if [[ -z ${!key:-} ]]; then
    log "WARNING: $key is empty; Sure stores provider tokens and MFA secrets unencrypted until all three keys are set"
  fi
done

mode=${1:-web}
case $mode in
  web)
    log "Preparing the database (rails db:prepare)"
    ./bin/rails db:prepare

    email=${SURE_OWNER_EMAIL:-}
    if ! [[ $email =~ ^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$ ]]; then
      log "SURE_OWNER_EMAIL='$email' is not an email address; using $DEFAULT_EMAIL"
      email=$DEFAULT_EMAIL
    fi
    password=${SURE_OWNER_PASSWORD:-}
    if ((${#password} < MIN_PASSWORD || ${#password} > MAX_PASSWORD)); then
      log "WARNING: SURE_OWNER_PASSWORD must be $MIN_PASSWORD-$MAX_PASSWORD characters (has ${#password})." \
          "An existing password is kept; a new owner gets a random password nobody knows." \
          "Set a valid SURE_OWNER_PASSWORD on the Sure service and redeploy to log in."
      owner_mode=lock
    else
      owner_mode=set
    fi
    # Hand the password over in a private file, not in Puma's environment.
    password_file=$(mktemp /tmp/railway-owner.XXXXXX)
    chmod 0600 "$password_file"
    printf '%s' "$password" > "$password_file"
    unset SURE_OWNER_PASSWORD password
    RAILWAY_OWNER_EMAIL=$email RAILWAY_OWNER_MODE=$owner_mode RAILWAY_OWNER_PASSWORD_FILE=$password_file \
      ./bin/rails runner /railway/sure-owner.rb
    rm -f "$password_file"

    log "Starting Puma on 0.0.0.0:$PORT"
    exec ./bin/rails server -b 0.0.0.0 -p "$PORT"
    ;;
  worker)
    unset SURE_OWNER_PASSWORD
    ruby /railway/sure-healthz.rb &
    # The web service runs the migrations; Sidekiq jobs need the final schema.
    for attempt in $(seq 1 80); do
      if ./bin/rails runner /railway/sure-migrated.rb >/dev/null 2>&1; then
        break
      fi
      if ((attempt == 80)); then
        log "WARNING: the database still needs migrations after 20 minutes; starting Sidekiq anyway"
        break
      fi
      ((attempt == 1)) && log "Waiting for the web service to migrate the database"
      sleep 15
    done
    log "Starting Sidekiq"
    exec bundle exec sidekiq
    ;;
  *)
    log "Unknown mode '$mode'; running it as a command"
    exec "$@"
    ;;
esac
