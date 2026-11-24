# NOTICE: Sure template

This is a community template. It is not made, endorsed or supported by the Sure project (we-promise), Maybe Finance or Railway.

## Components

| Component | Source | License | How it is used |
|---|---|---|---|
| Sure 0.7.6-hotfix.2 (`ghcr.io/we-promise/sure:0.7.6-hotfix.2@sha256:08f4fb26cedd0e5743792178ee744c1ea8b3ccd8cd9da1941ffc3ba7ef16ae6c`) | https://github.com/we-promise/sure | AGPL-3.0 (fork of Maybe Finance, AGPL-3.0) | Official image, unmodified, used as the base image for the Sure and Worker services. Source: https://github.com/we-promise/sure/tree/v0.7.6-hotfix.2 |
| PostgreSQL 18 (`ghcr.io/railwayapp-templates/postgres-ssl`) | https://github.com/railwayapp-templates/postgres-ssl | PostgreSQL License | Database |
| Redis 8.2 | https://hub.docker.com/_/redis | RSALv2/SSPLv1/AGPLv3 | Sidekiq queues and cache |
| Sure logo (`public/android-chrome-512x512.png`, via jsDelivr) | Sure repository | Project asset | Listing and service icon, to identify the app |

"Maybe" is a trademark of Maybe Finance, Inc.; Sure is a separate community project. This template uses the name Sure only to identify the software it deploys.

## Files written for this template

`services/sure/Dockerfile`, `railway-start.sh`, `sure-owner.rb`, `sure-migrated.rb`, `sure-healthz.rb` and the documentation were written for this template and are offered under the MIT License. `sure-owner.rb` uses Sure's own models (`User`, `Family`, `User.role_for_new_family_creator`, `User.lock_first_user_role!`) inside the running image; no Sure source files are copied.

## Upstream files checked (tag v0.7.6-hotfix.2)

- `compose.example.yml` (web + Sidekiq worker sharing `/rails/storage`, Postgres, Redis), `.env.example`, `Dockerfile`, `bin/docker-entrypoint` (jemalloc, `db:prepare` before `rails server`)
- `config/storage.yml` (`generic_s3` service and its variables), `config/environments/production.rb` (SSL flags, `APP_DOMAIN`, SMTP), `config/puma.rb`, `config/sidekiq.yml`
- `app/controllers/registrations_controller.rb` (new family creation, sign-up gating), `app/models/setting.rb` (`ONBOARDING_STATE`), `app/models/user.rb` (roles, first user = super_admin), `lib/active_record_encryption_config.rb`

## Market templates

The Railway marketplace templates `sure` (Sure Finance), `sure-finance` and `er6blq` (Maybe Finance) were reviewed for features only. No files or text were copied.
