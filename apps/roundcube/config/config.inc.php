<?php
/*
 * Local configuration for Roundcube Webmail.
 * This file is specifically tailored for a Dockerized environment.
 */

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