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

# Copy custom Roundcube configuration files into the image alongside custom password driver
COPY ./config/config.inc.php /usr/src/roundcubemail/config/config.inc.php
COPY ./drivers/gandi.php /usr/src/roundcubemail/plugins/password/drivers/gandi.php

# Change ownership of the copied files to the unprivileged user (UID 1000).
RUN chown 1000:1000 /usr/src/roundcubemail/config/config.inc.php
RUN chown 1000:1000 /usr/src/roundcubemail/plugins/password/drivers/gandi.php

# Switch back to the default unprivileged user for security and portability.
USER 1000