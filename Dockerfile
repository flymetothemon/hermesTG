# Railway wrapper around the official Hermes Agent image.
#
# The official image is the source of truth for the Hermes runtime, including
# Python 3.13, Node 26, s6-overlay supervision, immutable /opt/hermes,
# /opt/data persistence semantics, and the fixed SQLite build that avoids the
# SQLite WAL-reset corruption bug.
FROM nousresearch/hermes-agent:latest

ENV HERMES_HOME=/opt/data \
    HERMES_WRITE_SAFE_ROOT=/opt/data \
    HERMES_DASHBOARD=1 \
    HERMES_DASHBOARD_HOST=0.0.0.0 \
    PORT=9119 \
    HERMES_DISABLE_LAZY_INSTALLS=1

# Railway injects PORT at runtime. This shim copies it into Hermes' dashboard
# port before handing control to the official s6-overlay /init entrypoint so
# the dashboard and Railway health checks always agree on the listening port.
COPY --chmod=0755 railway-entrypoint.sh /railway-entrypoint.sh

# Fail the build if the base image unexpectedly regresses to a vulnerable
# SQLite. Current Hermes images build and verify SQLite >= 3.51.3.
USER root
RUN python3 -c 'import sqlite3, sys; v=sqlite3.sqlite_version_info; print("SQLite", sqlite3.sqlite_version); sys.exit("ERROR: SQLite WAL-reset fix missing; need >= 3.51.3") if v < (3,51,3) else None'

ENTRYPOINT ["/railway-entrypoint.sh"]
CMD ["gateway", "run"]
