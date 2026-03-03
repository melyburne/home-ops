<?php
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