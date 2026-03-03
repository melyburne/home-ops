<?php
/*
 * Local configuration for Roundcube Webmail.
 * This file is specifically tailored for a Dockerized environment.
 */

// -----------------------------------------------------------------------------
// Database Configuration (Docker Race-Condition Workaround)
// Injects database credentials before plugins are initialized to prevent issues.
// -----------------------------------------------------------------------------
$db_user = rawurlencode(getenv('ROUNDCUBEMAIL_DB_USER'));
$db_pass = rawurlencode(getenv('ROUNDCUBEMAIL_DB_PASSWORD'));
$db_name = rawurlencode(getenv('ROUNDCUBEMAIL_DB_NAME'));
$db_host = getenv('ROUNDCUBEMAIL_DB_HOST') ?: 'mariadb';

if ($db_user && $db_pass && $db_name) {
    // Database connection string format: mysql://user:password@host/database
    $config['db_dsnw'] = "mysql://{$db_user}:{$db_pass}@{$db_host}/{$db_name}";
}

// -----------------------------------------------------------------------------
// Dynamic Multi-Domain Branding
// Adjusts product name and Google Address Book redirect URL based on the domain.
// -----------------------------------------------------------------------------
$host = $_SERVER['HTTP_HOST'] ?? '';

if (strpos($host, 'aaronsoft.de') !== false) {
    $config['product_name'] = 'Aaronsoft Webmail';
    $config['google_addressbook_client_redirect_url'] = 'https://mail2.aaronsoft.de/?_task=settings&_action=plugin.google_addressbook.auth';
} elseif (strpos($host, 'get-orga-niced.de') !== false) {
    $config['product_name'] = 'get Orga-niced Webmail';
    $config['google_addressbook_client_redirect_url'] = 'https://mail2.get-orga-niced.de/?_task=settings&_action=plugin.google_addressbook.auth';
}

// -----------------------------------------------------------------------------
// User Interface and Application Behavior Settings
// Configures various aspects of the Roundcube user experience.
// -----------------------------------------------------------------------------
$config['username_domain_forced'] = true;
$config['identities_level'] = 3;
$config['login_autocomplete'] = 1;
$config['message_sort_col'] = 'arrival';
$config['create_default_folders'] = true;
$config['enable_spellcheck'] = true;
$config['spellcheck_engine'] = 'pspell'; 
$config['spellcheck_languages'] = ['en' => 'English', 'de' => 'Deutsch'];
$config['spellcheck_dictionary'] = 'shared';

// Sieve Plugin
$config['managesieve_host'] = '%h:4190';
$config['managesieve_auth_type'] = 'plain';

// -----------------------------------------------------------------------------
// Password Management Driver Configuration
// Uses the 'gandi' driver for password changes and strength validation.
// -----------------------------------------------------------------------------
// Note: 'password_strength_driver' is often the same as 'password_driver'
// if the driver handles both changing and validating passwords.
// 'password_minimum_length' set to 'blank' means it's not enforced here,
// but likely by the password driver itself or an external system.
$config['password_driver'] = 'gandi';
$config['password_strength_driver'] = 'gandi';
$config['password_minimum_score'] = 2;
$config['password_confirm_current'] = true;
$config['password_minimum_length'] = 'blank';
$config['password_algorithm'] = 'sha512-crypt';
$config['password_crypt_rounds'] = 50000;
$config['password_username_format'] = '%u';
$config['password_gandi_keys'] = rawurlencode(getenv('GANDIV5_PERSONAL_ACCESS_TOKEN'));

// -----------------------------------------------------------------------------
// Google Address Book Plugin Configuration
// Client credentials for integrating with Google Address Book.
// -----------------------------------------------------------------------------
$config['google_addressbook_application_name'] = 'Roundcube Google Addressbook';
$config['google_addressbook_client_id'] = rawurlencode(getenv('ROUNDCUBEMAIL_GOOGLE_CLIENT_ID'));
$config['google_addressbook_client_secret'] = rawurlencode(getenv('ROUNDCUBEMAIL_GOOGLE_CLIENT_SECRET'));
$config['google_addressbook_client_redirect'] = true;