FROM roundcube/roundcubemail:latest-nonroot

# Switch to the root user to install necessary system packages.
USER root

# Update package lists, install aspell and its language packs, then clean up.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    aspell \
    aspell-en \
    aspell-de \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy custom password driver alongside translation files into the image
COPY ./plugins/password-gandi/gandi.php /usr/src/roundcubemail/plugins/password/plugins/gandi.php
RUN chown 1000:1000 /usr/src/roundcubemail/plugins/password/plugins/gandi.php
RUN --mount=type=bind,source=./plugins/password-gandi,target=/host_locales \
    cat /host_locales/de_DE.inc >> /usr/src/roundcubemail/plugins/password/localization/de_DE.inc && \
    cat /host_locales/en_US.inc >> /usr/src/roundcubemail/plugins/password/localization/en_US.inc

# Copy custom Roundcube configuration files into the image
# -----------------------------------------------------------------------------
# Database Configuration (Docker Race-Condition Workaround)
# Injects database credentials before plugins are initialized to prevent issues.
# -----------------------------------------------------------------------------
COPY ./config/config.inc.php /usr/src/roundcubemail/config/config.inc.php
RUN chown 1000:1000 /usr/src/roundcubemail/config/config.inc.php

# Switch back to the default unprivileged user for security and portability.
USER 1000