<?php
/* Local configuration for Roundcube Webmail (Dockerized) */

// ----------------------------------
// DOCKER RACE-CONDITION WORKAROUND
// Inject DB credentials before plugins initialize
// ----------------------------------
$db_user = rawurlencode(getenv('ROUNDCUBE_DB_USER'));
$db_pass = rawurlencode(getenv('ROUNDCUBE_DB_PASSWORD'));
$db_name = rawurlencode(getenv('ROUNDCUBE_DB_NAME'));
$db_host = getenv('ROUNDCUBE_DB_HOST') ?: 'mariadb';

if ($db_user && $db_pass && $db_name) {
    // Format: mysql://user:password@host/database
    $config['db_dsnw'] = "mysql://{$db_user}:{$db_pass}@{$db_host}/{$db_name}";
}

// ----------------------------------
// DYNAMIC MULTI-DOMAIN BRANDING
// ----------------------------------
// Grab the active domain from the Traefik proxy header
$host = $_SERVER['HTTP_HOST'] ?? '';

if (strpos($host, 'aaronsoft.de') !== false) {
    $config['product_name'] = 'Aaronsoft Webmail';
    $config['google_addressbook_client_redirect_url'] = 'https://mail2.aaronsoft.de/?_task=settings&_action=plugin.google_addressbook.auth';
} elseif (strpos($host, 'get-orga-niced.de') !== false) {
    $config['product_name'] = 'get Orga-niced Webmail';
    $config['google_addressbook_client_redirect_url'] = 'https://mail2.get-orga-niced.de/?_task=settings&_action=plugin.google_addressbook.auth';
}

// ----------------------------------
// IDENTITIES & BEHAVIOR
// ----------------------------------
$config['username_domain_forced'] = true;
$config['identities_level'] = 3;
$config['login_autocomplete'] = 1;
$config['message_sort_col'] = 'arrival';
$config['create_default_folders'] = true;

$config['enable_spellcheck'] = true;
$config['spellcheck_engine'] = 'pspell'; 
$config['spellcheck_languages'] = ['en' => 'English', 'de' => 'Deutsch'];
$config['spellcheck_dictionary'] = 'shared';

$config['managesieve_host'] = '%h:4190';
$config['managesieve_auth_type'] = 'plain';

// Google Address Book Secrets (Injected from Environment)
$config['google_addressbook_application_name'] = 'Roundcube Google Addressbook';
$config['google_addressbook_client_id'] = rawurlencode(getenv('ROUNDCUBE_GOOGLE_CLIENT_ID'));
$config['google_addressbook_client_secret'] = rawurlencode(getenv('ROUNDCUBE_GOOGLE_CLIENT_SECRET'));
$config['google_addressbook_client_redirect'] = true;