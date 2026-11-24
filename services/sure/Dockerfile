# syntax=docker/dockerfile:1
#
# Sure 0.7.6-hotfix.2 (community fork of Maybe Finance) for Railway.
#
# Base: the official image, pinned by digest (ghcr.io/we-promise/sure,
# tag 0.7.6-hotfix.2, released 2026-11-21). To upgrade, change the tag and
# digest together and redeploy; migrations run when the web service starts.
#
# One image for both services:
#   web    (default)  db:prepare -> owner account -> rails server
#   worker            waits for the migrations -> Sidekiq (+ /healthz)
FROM ghcr.io/we-promise/sure:0.7.6-hotfix.2@sha256:08f4fb26cedd0e5743792178ee744c1ea8b3ccd8cd9da1941ffc3ba7ef16ae6c

COPY --chmod=0755 railway-start.sh /railway/railway-start.sh
COPY --chmod=0644 sure-owner.rb sure-healthz.rb sure-migrated.rb /railway/

ENV PORT=3000
EXPOSE 3000
ENTRYPOINT ["/railway/railway-start.sh"]
CMD ["web"]
