<?php
/* Local configuration for Roundcube Webmail (Dockerized) */

// ----------------------------------
// SQL DATABASE
// ----------------------------------
$db_user = getenv('DB_USER');
$db_pass = getenv('DB_PASS');
$db_name = getenv('DB_NAME');
// Assumes your database container in the 'db-internal' network will be reachable as 'mariadb' or 'mysql'
$config['db_dsnw'] = "mysql://{$db_user}:{$db_pass}@mariadb/${db_name}"; 

// ----------------------------------
// MULTI-DOMAIN SETUP
// ----------------------------------
$config['include_host_config'] = array(
    'mail.aaronsoft.de' => 'aaronsoft_config.inc.php',
    'mail.get-orga-niced.de' => 'get-orga-niced_config.inc.php',
);

// ----------------------------------
// IMAP & SMTP
// ----------------------------------
$config['imap_host'] = 'ssl://mail.gandi.net:993';
$config['smtp_host'] = 'ssl://mail.gandi.net:465';

// ----------------------------------
// SYSTEM DIRECTORIES
// ----------------------------------
$config['log_dir'] = '/var/www/html/logs/';
$config['temp_dir'] = '/var/www/html/temp/';
$config['mime_types'] = '/etc/mime.types'; // Standard path in Debian-based Docker images

// ----------------------------------
// SECURITY & SESSIONS
// ----------------------------------
$config['des_key'] = getenv('DES_KEY');
$config['session_storage'] = 'redis';
$config['redis_hosts'] = ['tcp://roundcube-redis:6379']; // Pointing to the Docker Redis container

// ----------------------------------
// IDENTITIES & BEHAVIOR
// ----------------------------------
$config['username_domain'] = '%d';
$config['username_domain_forced'] = true;
$config['identities_level'] = 3;
$config['login_autocomplete'] = 1;
$config['message_sort_col'] = 'arrival';
$config['create_default_folders'] = true;

// ----------------------------------
// PLUGINS & ADDONS
// ----------------------------------
$config['plugins'] = [
    'archive', 'attachment_reminder', 'emoticons', 'filesystem_attachments', 
    'managesieve', 'password', 'subscriptions_option', 'vcard_attachments', 
    'zipdownload', 'google_addressbook'
];

$config['enable_spellcheck'] = true;
$config['spellcheck_engine'] = 'pspell'; 
$config['spellcheck_languages'] = ['en' => 'English', 'de' => 'Deutsch'];
$config['spellcheck_dictionary'] = 'shared';

$config['managesieve_host'] = '%h:4190';
$config['managesieve_auth_type'] = 'plain';

// Google Address Book Secrets (Injected from Environment)
$config['google_addressbook_application_name'] = 'Roundcube Google Addressbook';
$config['google_addressbook_client_id'] = getenv('GOOGLE_ID');
$config['google_addressbook_client_secret'] = getenv('GOOGLE_SECRET');
$config['google_addressbook_client_redirect'] = true;