#!/bin/sh

REQUIRED_ENVIRONMENT_VARIABLES="\
NEXTCLOUD_VERSION \
POSTGRES_DB \
POSTGRES_USER \
POSTGRES_PASSWORD \
POSTGRES_HOST \
POSTGRES_PORT \
REDIS_HOST \
REDIS_PORT \
REDIS_PASSWORD \
NEXTCLOUD_ADMIN_USER \
NEXTCLOUD_ADMIN_PASSWORD \
TRUSTED_DOMAINS \
TRUSTED_PROXIES \
DATA_DIRECTORY \
NEXTCLOUD_DIRECTORY"

OBJECTSTORE_VARS="\
OBJECTSTORE_HOST \
OBJECTSTORE_PORT \
OBJECTSTORE_BUCKET \
OBJECTSTORE_KEY \
OBJECTSTORE_SECRET"

check_required_environment_variables() {  
    for var in "$@" ; do
        # Use eval to get the value of the variable whose name is in $var
        eval "value=\$$var"
        if [ -z "$value" ]; then
            echo "ERROR: ${var} is not set and is required"
            exit 1
        fi
    done
}

check_directory_permissions() {
  for dir in "$@" ; do
    if [ ! -d "$dir" ]; then
      echo "ERROR: $dir does not exist"
      exit 1
    fi
    if [ ! -w "$dir" ]; then
      echo "ERROR: $dir is not writable by current user. Please check permissions."
      exit 1
    fi
    if [ ! -r "$dir" ]; then
      echo "ERROR: $dir is not readable by current user. Please check permissions."
      exit 1
    fi
  done
}

check_if_nextcloud_is_installed() {
  echo "Checking if Nextcloud is installed" >&2

  if [ ! -f "${NEXTCLOUD_DIRECTORY}/occ" ]; then
    echo "false"
  else
    install_bool=$(php occ status --output=json --no-warnings 2>/dev/null | jq .installed)
    if [ "$install_bool" = "true" ]; then  
      echo "true"
    else
      echo "false"
    fi
  fi
}

download_and_unpack_nextcloud() {
    UNPACK_DIR=$1

    if [ -z "$2" ]; then
        DOWNLOAD_URL="https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"
    else
        DOWNLOAD_URL=$2
    fi

    # Check if the required variables are set
    if [ -z "${NEXTCLOUD_VERSION}" ]; then
        echo "ERROR: NEXTCLOUD_VERSION is not set"
        exit 1
    fi
    if [ -z "${UNPACK_DIR}" ]; then
        echo "ERROR: UNPACK_DIR is not set"
        exit 1
    fi
    if ! [ -d "${UNPACK_DIR}" ]; then
        echo "ERROR: ${UNPACK_DIR} does not exist"
        exit 1
    fi
    set -e
    echo "Downloading Nextcloud ${NEXTCLOUD_VERSION} to /tmp"
    curl -fsSL \
        -o /tmp/nextcloud.tar.bz2 \
        "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"

    echo "Unpacking the Nextcloud tarball to ${UNPACK_DIR}"
    # pv <some .tar.gz file> | tar -xvzf - -C <some directory>
    pv /tmp/nextcloud.tar.bz2 | tar -xjf - -C ${UNPACK_DIR} --strip-components=1
    echo "Done unpacking, removing tarball"
    rm /tmp/nextcloud.tar.bz2
    #tar -xjf /tmp/nextcloud.tar.bz2 -C ${UNPACK_DIR} --strip-components=1 && rm /tmp/nextcloud.tar.bz2

    chmod +x ${NEXTCLOUD_DIRECTORY}/occ
}

install_nextcloud() {
  php occ maintenance:install -n \
    --database pgsql \
    --database-name "$POSTGRES_DB" \
    --database-user "$POSTGRES_USER" \
    --database-pass "$POSTGRES_PASSWORD" \
    --database-host "${POSTGRES_HOST}:${POSTGRES_PORT}" \
    --admin-user "$NEXTCLOUD_ADMIN_USER" \
    --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD" \
    --data-dir "$DATA_DIRECTORY"

  # As kubernetes pvc is used, we can disable the check_data_directory_permissions.
  sed -i "/^);$/i\\  'check_data_directory_permissions' => false," ${NEXTCLOUD_DIRECTORY}/config/config.php
  echo "Installed Nextcloud"
}

configure_nextcloud() {
  echo "Configuring Nextcloud settings"

  # Trusted domains
  index=0
  for domain in $TRUSTED_DOMAINS; do
    index=$(expr $index + 1)
    echo "Setting trusted domain $index to $domain"
    php /var/www/html/occ config:system:set trusted_domains $index --value=${domain}
  done

  # Trusted proxies
  index=0
  for proxy in $TRUSTED_PROXIES; do
    index=$(expr $index + 1)
    echo "Setting trusted proxy $index to $proxy"
    php /var/www/html/occ config:system:set trusted_proxies $index --value=${proxy}
  done

  # S3 configuration
  object_storage_configured=false
  for var in $OBJECTSTORE_VARS; do
    if [ -n "${!var}" ]; then
      object_storage_configured=true
      break
    fi
  done
  if [ "$object_storage_configured" = true ]; then
    for var in $OBJECTSTORE_VARS; do
      if [ -z "${!var}" ]; then
        echo -e "ERROR: $var is not set and is required to configure object storage\nYou must set all of the following environment variables: $OBJECTSTORE_VARS"
        exit 1
      fi
    done

    echo "Setting S3 configuration"
    php /var/www/html/occ config:system:set objectstore class --value='\OC\Files\ObjectStore\S3'
    php /var/www/html/occ config:system:set objectstore arguments hostname --value=${OBJECTSTORE_HOST}
    php /var/www/html/occ config:system:set objectstore arguments port --value=${OBJECTSTORE_PORT}
    php /var/www/html/occ config:system:set objectstore arguments bucket --value=${OBJECTSTORE_BUCKET}
    php /var/www/html/occ config:system:set objectstore arguments key --value=${OBJECTSTORE_KEY}
    php /var/www/html/occ config:system:set objectstore arguments secret --value=${OBJECTSTORE_SECRET}
    php /var/www/html/occ config:system:set objectstore arguments use_path_style --type=bool --value=true
    php /var/www/html/occ config:system:set objectstore arguments use_ssl --type=bool --value=false
    php /var/www/html/occ config:system:set objectstore arguments concurrency --value='10'
  fi

  # Redis configuration
  echo "Setting Redis configuration"
  php ${NEXTCLOUD_DIRECTORY}/occ config:system:set redis host --value=${REDIS_HOST}
  php ${NEXTCLOUD_DIRECTORY}/occ config:system:set redis port --value=${REDIS_PORT}
  php ${NEXTCLOUD_DIRECTORY}/occ config:system:set redis password --value=${REDIS_PASSWORD}
  php ${NEXTCLOUD_DIRECTORY}/occ config:system:set memcache.distributed --value='\OC\Memcache\Redis'
  php ${NEXTCLOUD_DIRECTORY}/occ config:system:set memcache.locking --value='\OC\Memcache\Redis'
  php ${NEXTCLOUD_DIRECTORY}/occ config:system:set memcache.local --value='\OC\Memcache\APCu'
  # APCu is the default memcache implementation, Are there a point in just using redis?
  echo "Setting memcache configuration"
  php ${NEXTCLOUD_DIRECTORY}/occ config:system:set memcache.local --value='\OC\Memcache\APCu'


  # Trying to decrase the security warnings in browser
  echo "Setting overwriteprotocol to https"
  php ${NEXTCLOUD_DIRECTORY}/occ config:system:set overwriteprotocol --value='https'

}


# There is a list at the top of the file that is used to check if all required environment variables are set
check_required_environment_variables $REQUIRED_ENVIRONMENT_VARIABLES
# Check that the data directory and nextcloud directory are usable by the current user
check_directory_permissions $DATA_DIRECTORY $NEXTCLOUD_DIRECTORY


if [ "$(check_if_nextcloud_is_installed)" = "false" ]; then
  echo "Nextcloud is not installed, starting installation."
  # Download and unpack nextcloud to the directory specified in the environment variable $NEXTCLOUD_DIRECTORY
  download_and_unpack_nextcloud ${NEXTCLOUD_DIRECTORY}
  # Install nextcloud to the database
  install_nextcloud
else
  echo "Nextcloud is already installed."
fi

# Configure nextcloud settings as we want them
# 1. Trusted domains
# 2. Trusted proxies
# 3. S3 configuration
# 4. Redis configuration
# 5. Memcache configuration
# 6. Overwrite protocol
# 7. Instanceid
configure_nextcloud

# Unset the environment variables
for var in $REQUIRED_ENVIRONMENT_VARIABLES; do
  unset $var
done