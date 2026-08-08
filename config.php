<?php
// ─────────────────────────────────────────────────────────────
// Digonto — Database connection config (XAMPP / MySQL)
// Edit these 4 values if your XAMPP MySQL setup is different.
// Default XAMPP install: host=localhost, user=root, password="" (empty)
// ─────────────────────────────────────────────────────────────
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'digonto_du');

function get_db_connection(): mysqli {
    mysqli_report(MYSQLI_REPORT_OFF); // we handle errors ourselves
    $conn = mysqli_connect(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    if (!$conn) {
        http_response_code(500);
        header('Content-Type: application/json');
        echo json_encode([
            'error' => 'Database connection failed: ' . mysqli_connect_error(),
            'hint'  => 'Make sure XAMPP\'s MySQL service is running and the "digonto_du" database has been imported from digonto_du_full_project.sql'
        ]);
        exit;
    }
    mysqli_set_charset($conn, 'utf8mb4');
    return $conn;
}
