FROM roundcube/roundcubemail:latest-nonroot

# Switch to root to install the required system packages
USER root

# Install the pspell library and the English/German aspell dictionaries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    aspell \
    aspell-en \
    aspell-de \
    libpspell-dev \
    && docker-php-ext-install pspell \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch back to the default unprivileged user for image portability
USER 1000