# Use the official Ruby image as base
FROM ruby:3.3-slim

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  git \
  curl \
  sqlite3 \
  libsqlite3-dev \
  libyaml-dev \
  && rm -rf /var/lib/apt/lists/*

# Install Node.js (for documentation site)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
  && apt-get install -y nodejs

# Create a non-root user
RUN groupadd --gid 1000 user \
  && useradd --uid 1000 --gid user --shell /bin/bash --create-home user

# Set up the working directory
WORKDIR /workspace

# Install bundler
RUN gem install bundler

# Create cache directory for gems
RUN mkdir -p /usr/local/bundle && chown -R user:user /usr/local/bundle

# Switch to non-root user
USER user

# Set the default shell
SHELL ["/bin/bash", "-c"]
