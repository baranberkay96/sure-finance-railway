# Deploy and Host Sure with Railway

Sure is an open-source personal finance app, the community-maintained fork of Maybe Finance. It tracks net worth, accounts, investments, budgets and transactions, with rules, imports and an optional AI assistant. This template runs the complete self-hosted stack on Railway with your owner account created at the first start.

## About Hosting Sure

Sure is a Ruby on Rails application. Running it properly takes a Puma web process, a Sidekiq worker for account syncs, market data, imports and scheduled jobs, Postgres, Redis, and file storage shared by web and worker. On a fresh install anyone who opens the sign-up page can create the first (super admin) account. This community template pins the official 0.7.6-hotfix.2 image, runs web and worker as separate services, stores uploads in a Railway Bucket (Railway volumes cannot be shared between services), generates the Rails and Active Record encryption keys, and creates the owner from your email and a generated password before the web server starts. New sign-ups then need an invitation or invite code.

## Common Use Cases

- One view of bank accounts, credit cards, loans, investments and property for net worth tracking
- Monthly budgets by category with transaction rules and tags
- Importing bank CSV, QIF and PDF statements, or data from Mint, YNAB, Actual and Sure exports
- Sharing finances inside a household (family members by invitation)
- Optional AI chat and auto-categorisation with your own OpenAI-compatible key

## Dependencies for Sure Hosting

- Sure web service (Rails, Puma) — the official image
- Worker service (Sidekiq) — same image
- Postgres, Redis
- Railway Bucket (S3-compatible) for uploads

### Deployment Dependencies

- [Sure on GitHub](https://github.com/we-promise/sure)
- [Self-hosting docs](https://github.com/we-promise/sure/tree/main/docs/hosting)
- [Railway Buckets](https://docs.railway.com/guides/storage-buckets)

### Implementation Details

| Service | What runs inside | Storage | Port |
|---|---|---|---|
| Sure | Rails 8 + Puma, migrations at start | Bucket (uploads) | 3000, public domain |
| Worker | Sidekiq (syncs, market data, imports, scheduled jobs) | Bucket | private `/healthz` |
| Postgres | PostgreSQL 18 | volume | private |
| Redis | Redis 8.2 | volume | private |
| Bucket | Railway Bucket | — | — |

**First login**

1. Enter your email in `SURE_OWNER_EMAIL` when you deploy.
2. Open `https://{your-domain}` and sign in with that email and the generated `SURE_OWNER_PASSWORD` (Variables tab of the Sure service).
3. Complete the onboarding (name, currency, locale) and add your first account.

**Owner password.** `SURE_OWNER_PASSWORD` is checked at every start: if it differs from the stored password of the `SURE_OWNER_EMAIL` user, it replaces it and ends that user's sessions. Change the variable and redeploy instead of changing the password in the app (an in-app change is reset at the next redeploy). A value shorter than 12 characters is ignored with a warning in the log: an existing password stays, and a brand-new install gets a random owner password until you set a valid one.

**Sign-ups.** `ONBOARDING_STATE=invite_only` means new people need an invitation from a family admin or an invite code generated under Settings, Self-Hosting. Set it to `closed` to disable sign-ups, or `open` only if you want a public instance.

**Keys.** `SECRET_KEY_BASE` and the three `ACTIVE_RECORD_ENCRYPTION_*` keys are generated once and must never change; Sure encrypts provider tokens, API keys and MFA secrets with them. The Worker reads them from the Sure service.

**Market data and AI.** Exchange rates and prices come from Yahoo Finance by default (no key). For the AI assistant set `OPENAI_ACCESS_TOKEN` on the Sure service (optionally `OPENAI_URI_BASE` and `OPENAI_MODEL` for compatible providers).

**Email.** Sure sends mail over SMTP (`SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `EMAIL_SENDER`). Railway allows outbound SMTP only on the Pro plan; on other plans keep `REQUIRE_EMAIL_CONFIRMATION=false` and invite people by link instead of by mail.

**Scaling and upgrades.** Web and worker are stateless (about 1 GB RAM in total for the stack at idle); raise `RAILS_MAX_THREADS` or add worker replicas for many accounts. Postgres and Redis keep state on volumes. To upgrade, eject the repo, change the tag and digest in `services/sure/Dockerfile`, and redeploy both Sure and Worker; migrations run when Sure starts and the Worker waits for them. Sure is pre-1.0 software: read the release notes and back up Postgres before upgrading.

### Why Deploy Sure on Railway?

Railway runs the whole Sure stack — web, worker, Postgres, Redis and object storage — in one project with HTTPS and private networking, so a household finance app is online in minutes without servers to manage. This template adds pinned versions, generated encryption keys and an owner account created before anyone can sign up.
