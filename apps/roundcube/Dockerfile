FROM roundcube/roundcubemail:latest-nonroot

# Switch to root to install the required system packages
USER root

# Install the enchant library and the English/German hunspell dictionaries
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libenchant-2-dev \
    hunspell-en-us \
    hunspell-de-de \
    && docker-php-ext-install enchant \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch back to the default unprivileged user for image portability
USER 1000