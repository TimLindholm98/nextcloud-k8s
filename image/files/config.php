<?php
$CONFIG = array (
  'upgrade.disable-web' => true,
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'redis' => array (
      'host' => getenv('REDIS_HOST'),
      'port' => getenv('REDIS_PORT'),
      'password' => getenv('REDIS_PASSWORD'),
  ),
  'objectstore' => array(
      'class' => '\OC\Files\ObjectStore\S3',
      'arguments' => array (
            'hostname' => getenv('OBJECTSTORE_HOST'),
            'port' => getenv('OBJECTSTORE_PORT'),
            'bucket' => getenv('OBJECTSTORE_BUCKET'),
            'key' => getenv('OBJECTSTORE_KEY'),
            'secret' => getenv('OBJECTSTORE_SECRET'),
            'use_path_style' => (bool) true,
            'use_ssl' => (bool) false,
            'concurrency' => '10',
        ),
    ),
    'apps_paths' => array (
      0 => array (
          'path'     => OC::$SERVERROOT.'/apps',
          'url'      => '/apps',
          'writable' => false,
      ),
      1 => array (
          'path'     => OC::$SERVERROOT.'/custom_apps',
          'url'      => '/custom_apps',
          'writable' => true,
      ),
  ),
  'trusted_domains' => array_filter(array_map('trim', explode(',', getenv('TRUSTED_DOMAINS')))),
  'htaccess.RewriteBase' => '/',
  'overwriteprotocol' => 'https',
  'overwrite.cli.url' => 'https://localhost',
  'enable_previews' => true,
  'datadirectory' => '/var/www/nextcloud/data',
  'dbname' => getenv('POSTGRES_DB'),
  'dbhost' => getenv('POSTGRES_HOST'),
  'dbport' => getenv('POSTGRES_PORT'),
  'dbtableprefix' => 'oc_',
  'dbuser' => getenv('POSTGRES_USER'),
  'dbpassword' => getenv('POSTGRES_PASSWORD'),
);