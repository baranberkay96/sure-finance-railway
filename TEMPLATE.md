# TEMPLATE: Sure Personal Finance (Rails, Sidekiq, Postgres, Redis, S3)

Composer spec. `template.json` is the machine-readable copy. Sure is pre-1.0 (0.7.x), so the listing name carries no version.

## Services

| Service | Source | Public | Healthcheck | Storage | Restart |
|---|---|---|---|---|---|
| Sure | repo `baranberkay96/sure-finance-railway`, root `/services/sure` (`FROM ghcr.io/we-promise/sure:0.7.6-hotfix.2@sha256:08f4fb26…`, 2026-11-21) | 3000 | `/up`, 900 s | Bucket | ALWAYS |
| Worker | same repo/root, start `/railway/railway-start.sh worker` | no | `/healthz` (private, PORT 3000), 1200 s | Bucket | ALWAYS |
| Postgres | `postgres-ssl:18.6@sha256:4fc833b4…` | no | — | volume | ON_FAILURE |
| Redis | `redis:8.2.11@sha256:b0b01167…` | no | — | volume | ON_FAILURE |
| Bucket | Railway Bucket (`generic_s3`, virtual-hosted style) | — | — | — | — |

Required input: `SURE_OWNER_EMAIL`. Generated: `SURE_OWNER_PASSWORD` (24), `SECRET_KEY_BASE` (128 hex), three `ACTIVE_RECORD_ENCRYPTION_*` (32), DB/Redis passwords.

## Design

- web: `rails db:prepare` → `rails runner sure-owner.rb` → `exec rails server -b 0.0.0.0`. STANDARD 8.37: the owner exists before Puma listens. `sure-owner.rb` mirrors the sign-up controller (advisory lock, new `Family`, `role_for_new_family_creator` → super_admin). Existing users: password re-applied to the owner email only if `authenticate` fails, then sessions ended.
- `ONBOARDING_STATE=invite_only` closes open sign-up (invitations and invite codes still work).
- worker: background Ruby `/healthz` (8.34), waits (≤20 min, 15 s steps) until `needs_migration?` is false, then `exec bundle exec sidekiq`.
- Upstream shares `/rails/storage` between web and worker; Railway volumes cannot be shared (Rule 3b) → ActiveStorage on the Railway Bucket via Sure's `generic_s3` service.
- 8.29: bad PORT → 3000, bad email → admin@example.com, password outside 12–72 → lock mode; owner password passed in a 0600 temp file, removed from the env before Puma.
- `RAILS_ASSUME_SSL=true` (Railway edge is HTTPS), `RAILS_FORCE_SSL=false` (healthcheck is plain HTTP).

## Improvements over market templates

- `sure` (380 deploys): `latest` image, no healthcheck, `SECRET_KEY_BASE` taken from the Redis service, worker with a different random secret, no encryption keys, no file storage, open sign-up. `sure-finance`: third-party repo build, `ONBOARDING_STATE=open`. `er6blq`: archived Maybe image, Redis over the public TCP proxy. This one: pinned image, owner created before the port opens, invite-only sign-up, shared secrets referenced from one place, encryption keys, Bucket storage, worker healthcheck and migration wait.

## Resources

| Service | Idle RAM | Typical | CPU |
|---|---|---|---|
| Sure | 0.17–0.44 GB measured | 0.4–0.8 GB | low |
| Worker | 0.42 GB measured | 0.4–0.7 GB during syncs/imports | low/bursty |
| Postgres | 0.09–0.14 GB measured | 0.1–0.3 GB | low |
| Redis | 0.03 GB measured | — | low |

Measured total ≈ 1.0 GB idle → ≈ $10–14/month + volumes/bucket. Minimum plan: Hobby.

## Verification checklist

- `/up` 200; worker `/healthz` 200 and Sidekiq "Starting processing" in the log.
- Owner login works; `/registration/new` asks for an invite code (invite_only).
- Create an account and a transaction; upload an attachment (Bucket); data survives a redeploy.
- `SURE_OWNER_PASSWORD=abc` → SUCCESS, warning, old password works.

## Open questions

- Plaid/SimpleFIN/other bank sync providers need the user's own credentials; not tested.
