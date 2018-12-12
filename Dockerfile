# Dockerfile
#
# The mix of packages to add are based on the needs of various gems:
# @see https://github.com/exAspArk/docker-alpine-ruby/blob/master/Dockerfile

FROM ruby:2.5.1-alpine
RUN apk add --no-cache \
    bash \
    build-base \
    curl-dev \
    g++ \
    gcc \
    git \
    libc-dev \
    libcurl \
    libffi-dev \
    libxml2 \
    libxslt-dev \
    nodejs \
    sqlite-dev \
    tzdata \
    yarn

# =============================================================================
# :section: System setup
# =============================================================================

ENV USER=webservice \
    GROUP=webservice \
    LANG='en_US.UTF-8' \
    LC_ALL='en_US.UTF-8' \
    LANGUAGE='en_US:en' \
    TZ='America/New_York'

# Set the timezone; create the user and group for the process.
RUN ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime; \
    echo "$TZ" > /etc/timezone; \
    addgroup $GROUP && \
    adduser -D -G $USER $GROUP

# =============================================================================
# :section: Platform setup
# =============================================================================

ENV APP_HOME=/virgo4 \
    RAILS_ENV=production

# Copy the Gemfile and Gemfile.lock into the image.
# Temporarily set the working directory to where they are.
WORKDIR /tmp
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install --retry=2 --jobs=4

# Create work directory and copy the application to it.
WORKDIR $APP_HOME
ADD . $APP_HOME

# Generate the assets.
RUN SECRET_KEY_BASE=x rake assets:precompile

# Update permissions on the application and user home directory.
RUN chown -R $USER:$GROUP $APP_HOME /home/$USER

# =============================================================================
# :section: Launch the application
# =============================================================================

# Set the user for the process.
USER $USER:$GROUP

# Define port and startup script.
EXPOSE 3000
CMD bin/Docker_run.sh
