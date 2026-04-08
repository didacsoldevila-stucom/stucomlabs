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