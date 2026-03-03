<?php
/* Local configuration for Roundcube Webmail (Dockerized) */

// ----------------------------------
// MULTI-DOMAIN SETUP
// ----------------------------------
$config['include_host_config'] = array(
    'mail.aaronsoft.de' => 'aaronsoft_config.inc.php',
    'mail.get-orga-niced.de' => 'get-orga-niced_config.inc.php',
);

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
$config['google_addressbook_client_id'] = getenv('ROUNDCUBEMAIL_GOOGLE_CLIENT_ID');
$config['google_addressbook_client_secret'] = getenv('ROUNDCUBEMAIL_GOOGLE_CLIENT_SECRET');
$config['google_addressbook_client_redirect'] = true;