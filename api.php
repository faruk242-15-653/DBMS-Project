<?php
// ─────────────────────────────────────────────────────────────
// Digonto — api.php
// This is the piece that was missing: it actually queries the
// live MySQL "digonto_du" database (via mysqli) and returns the
// current data as JSON. dashboard.html calls this file with
// fetch('api.php') instead of using a hardcoded JS object, so any
// INSERT/UPDATE/DELETE you run in MySQL / phpMyAdmin shows up here.
// ─────────────────────────────────────────────────────────────

header('Content-Type: application/json; charset=utf-8');
require_once __DIR__ . '/config.php';

$conn = get_db_connection();

function query_all(mysqli $conn, string $sql): array {
    $result = mysqli_query($conn, $sql);
    if ($result === false) {
        http_response_code(500);
        echo json_encode(['error' => 'Query failed: ' . mysqli_error($conn), 'sql' => $sql]);
        exit;
    }
    $rows = [];
    while ($row = mysqli_fetch_assoc($result)) {
        $rows[] = $row;
    }
    return $rows;
}

// Cast a row's fields from mysqli's default strings into proper
// int/float/bool types, using a map of {field => 'int'|'float'|'bool'}.
function cast_row(array $row, array $types): array {
    foreach ($types as $field => $type) {
        if (!array_key_exists($field, $row) || $row[$field] === null) continue;
        switch ($type) {
            case 'int':   $row[$field] = (int)$row[$field]; break;
            case 'float': $row[$field] = (float)$row[$field]; break;
            case 'bool':  $row[$field] = (bool)$row[$field]; break;
        }
    }
    return $row;
}
function cast_rows(array $rows, array $types): array {
    return array_map(fn($r) => cast_row($r, $types), $rows);
}

// ---------- Drone (single row) ----------
$droneRows = query_all($conn, "SELECT * FROM Drone LIMIT 1");
$drone = $droneRows
    ? cast_row($droneRows[0], ['drone_id' => 'int', 'weight_kg' => 'float', 'max_payload_kg' => 'float'])
    : null;

// ---------- Pilot ----------
$pilots = cast_rows(
    query_all($conn, "SELECT * FROM Pilot ORDER BY pilot_id"),
    ['pilot_id' => 'int', 'experience_years' => 'float']
);

// ---------- Component ----------
$components = cast_rows(
    query_all($conn, "SELECT * FROM Component ORDER BY component_id"),
    ['component_id' => 'int', 'drone_id' => 'int', 'usage_hours' => 'float']
);

// ---------- GeofenceZone ----------
$zones = cast_rows(
    query_all($conn, "SELECT * FROM GeofenceZone ORDER BY zone_id"),
    ['zone_id' => 'int', 'center_lat' => 'float', 'center_lng' => 'float',
     'radius_m' => 'float', 'max_altitude_m' => 'float']
);

// ---------- Mission ----------
$missions = cast_rows(
    query_all($conn, "SELECT *, REPLACE(start_time,' ','T') AS start_time_iso,
                              REPLACE(end_time,' ','T') AS end_time_iso
                       FROM Mission ORDER BY mission_id"),
    ['mission_id' => 'int', 'drone_id' => 'int', 'pilot_id' => 'int']
);
// use ISO-formatted datetimes (with T separator) like the original dataset, then drop helper cols
foreach ($missions as &$m) {
    $m['start_time'] = $m['start_time_iso'];
    $m['end_time']   = $m['end_time_iso'];
    unset($m['start_time_iso'], $m['end_time_iso']);
}
unset($m);

// ---------- TelemetryLog ----------
$telemetry = cast_rows(
    query_all($conn, "SELECT *, REPLACE(log_time,' ','T') AS log_time_iso
                       FROM TelemetryLog ORDER BY log_id"),
    ['log_id' => 'int', 'mission_id' => 'int', 'latitude' => 'float', 'longitude' => 'float',
     'altitude_m' => 'float', 'speed_mps' => 'float', 'battery_voltage' => 'float',
     'battery_percent' => 'float', 'satellite_count' => 'int', 'heading_deg' => 'int',
     'vertical_speed_mps' => 'float']
);
foreach ($telemetry as &$t) {
    $t['log_time'] = $t['log_time_iso'];
    unset($t['log_time_iso']);
}
unset($t);

// ---------- GeofenceViolation ----------
$violations = cast_rows(
    query_all($conn, "SELECT *, REPLACE(violation_time,' ','T') AS violation_time_iso
                       FROM GeofenceViolation ORDER BY violation_id"),
    ['violation_id' => 'int', 'mission_id' => 'int', 'zone_id' => 'int', 'log_id' => 'int']
);
foreach ($violations as &$v) {
    $v['violation_time'] = $v['violation_time_iso'];
    unset($v['violation_time_iso']);
}
unset($v);

// ---------- MaintenanceLog ----------
$maintenance = cast_rows(
    query_all($conn, "SELECT * FROM MaintenanceLog ORDER BY maintenance_id"),
    ['maintenance_id' => 'int', 'component_id' => 'int', 'cost' => 'float']
);

// ---------- AlertLog ----------
$alerts = cast_rows(
    query_all($conn, "SELECT *, REPLACE(alert_time,' ','T') AS alert_time_iso
                       FROM AlertLog ORDER BY alert_id"),
    ['alert_id' => 'int', 'mission_id' => 'int', 'resolved' => 'int']
);
foreach ($alerts as &$a) {
    $a['alert_time'] = $a['alert_time_iso'];
    unset($a['alert_time_iso']);
}
unset($a);

mysqli_close($conn);

echo json_encode([
    'drone'       => $drone,
    'pilots'      => $pilots,
    'components'  => $components,
    'zones'       => $zones,
    'missions'    => $missions,
    'telemetry'   => $telemetry,
    'violations'  => $violations,
    'maintenance' => $maintenance,
    'alerts'      => $alerts,
], JSON_UNESCAPED_UNICODE);
