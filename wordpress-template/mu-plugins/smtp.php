<?php
add_action('phpmailer_init', function ($phpmailer) {
    $phpmailer->isSMTP();
    $phpmailer->Host = 'smtp.office365.com';
    $phpmailer->Port = 587;
    $phpmailer->SMTPAuth = true;
    $phpmailer->SMTPSecure = 'tls';

    $phpmailer->Username = getenv('SMTP_USER');
    $phpmailer->Password = getenv('SMTP_PASS');

    $phpmailer->From = getenv('SMTP_USER');
    $phpmailer->FromName = 'STUCOM Labs';
});

add_filter('retrieve_password_title', function ($title, $user_login, $user_data) {
    return 'STUCOM Labs - Configura la teva contrasenya de WordPress';
}, 10, 3);

add_filter('retrieve_password_message', function ($message, $key, $user_login, $user_data) {
    $site_name = wp_specialchars_decode(get_option('blogname'), ENT_QUOTES);
    $reset_url = network_site_url("wp-login.php?action=rp&key=$key&login=" . rawurlencode($user_login), 'login');

    $message  = "Hola {$user_data->first_name},\n\n";
    $message .= "Ja tens disponible el teu entorn de pràctiques de WordPress a STUCOM Labs.\n\n";
    $message .= "Usuari: {$user_login}\n";
    $message .= "Web: " . home_url('/') . "\n\n";
    $message .= "Per definir la teva contrasenya, fes clic aquí:\n";
    $message .= "{$reset_url}\n\n";
    $message .= "Si no has sol·licitat aquest correu, pots ignorar-lo.\n\n";
    $message .= "Departament TIC Grup STUCOM\n";

    return $message;
}, 10, 4);