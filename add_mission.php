<?php
// ─────────────────────────────────────────────────────────────
// Digonto — add_mission.php
// Demonstrates a TRANSACTION: adding a new Mission and updating
// the drone's Component usage_hours must succeed TOGETHER.
// If either step fails, everything is rolled back so the
// database never ends up half-updated.
//
// Called from dashboard.html via fetch('add_mission.php', {POST}).
// ─────────────────────────────────────────────────────────────

header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/config.php';

$conn = get_db_connection();

// ---- read + validate incoming JSON from the form ----
$input = json_decode(file_get_contents('php://input'), true);

$drone_id   = 1; // single-drone fleet
$pilot_id   = isset($input['pilot_id']) ? (int)$input['pilot_id'] : 0;
$mission_name = trim($input['mission_name'] ?? '');
$location     = trim($input['location'] ?? '');
$purpose      = trim($input['purpose'] ?? '');
$start_time   = trim($input['start_time'] ?? ''); // 'YYYY-MM-DD HH:MM:SS'
$end_time     = trim($input['end_time'] ?? '');
$weather      = trim($input['weather_condition'] ?? '');

if (!$pilot_id || !$mission_name || !$location || !$purpose || !$start_time || !$end_time) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'Missing required fields.']);
    exit;
}

// ---- helper to run a query and stop on failure ----
function run(mysqli $conn, string $sql, array $params, string $types) {
    $stmt = mysqli_prepare($conn, $sql);
    if (!$stmt) throw new Exception('Prepare failed: ' . mysqli_error($conn));
    if ($params) mysqli_stmt_bind_param($stmt, $types, ...$params);
    if (!mysqli_stmt_execute($stmt)) {
        $err = mysqli_stmt_error($stmt);
        mysqli_stmt_close($stmt);
        throw new Exception('Execute failed: ' . $err);
    }
    $insertId = mysqli_stmt_insert_id($stmt);
    mysqli_stmt_close($stmt);
    return $insertId;
}

// ================================================================
// TRANSACTION: Step 1 (insert Mission) + Step 2 (update Component
// usage_hours) must both succeed, or neither is kept.
// ================================================================
mysqli_begin_transaction($conn);

try {
    // Step 1: insert the new mission
    $missionId = run(
        $conn,
        "INSERT INTO Mission (drone_id, pilot_id, mission_name, location, purpose, start_time, end_time, weather_condition, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Completed')",
        [$drone_id, $pilot_id, $mission_name, $location, $purpose, $start_time, $end_time, $weather],
        'iissssss'
    );

    // Step 2: work out flight duration in hours and add it to every
    // component belonging to this drone (mirrors sp_UpdateComponentUsageAfterMission)
    $hours = (strtotime($end_time) - strtotime($start_time)) / 3600.0;
    if ($hours <= 0) {
        throw new Exception('End time must be after start time.');
    }

    run(
        $conn,
        "UPDATE Component SET usage_hours = usage_hours + ? WHERE drone_id = ?",
        [$hours, $drone_id],
        'di'
    );

    // Both steps succeeded -> make the changes permanent
    mysqli_commit($conn);

    echo json_encode([
        'success'    => true,
        'mission_id' => $missionId,
        'hours_added_to_components' => round($hours, 2),
    ]);

} catch (Exception $e) {
    // Something failed -> undo Step 1 and Step 2 completely
    mysqli_rollback($conn);
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

mysqli_close($conn);
