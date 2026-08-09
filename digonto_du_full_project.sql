DROP DATABASE IF EXISTS digonto_du;
CREATE DATABASE digonto_du;
USE digonto_du;

CREATE TABLE Drone (
    drone_id INT PRIMARY KEY AUTO_INCREMENT,
    drone_name VARCHAR(50) NOT NULL UNIQUE,
    model VARCHAR(60) NOT NULL,
    frame_type VARCHAR(30) NOT NULL,
    weight_kg DECIMAL(4,2) NOT NULL CHECK (weight_kg > 0),
    max_payload_kg DECIMAL(4,2) NOT NULL CHECK (max_payload_kg >= 0),
    firmware_version VARCHAR(30),
    status ENUM('Active','Maintenance','Retired') NOT NULL DEFAULT 'Active'
);

CREATE TABLE Pilot (
    pilot_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(80) NOT NULL,
    license_no VARCHAR(30) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(80) NOT NULL UNIQUE,
    experience_years DECIMAL(3,1) NOT NULL DEFAULT 0, 
    joining_date DATE NOT NULL
);

CREATE TABLE Component (
    component_id INT PRIMARY KEY AUTO_INCREMENT,
    drone_id INT NOT NULL,
    component_type VARCHAR(50) NOT NULL,
    model_no VARCHAR(30) NOT NULL,
    install_date DATE NOT NULL,
    usage_hours DECIMAL(6,1) NOT NULL DEFAULT 0 CHECK (usage_hours >= 0),
    status ENUM('Good','Needs Inspection','Replace Soon') NOT NULL DEFAULT 'Good',
    FOREIGN KEY (drone_id) REFERENCES Drone(drone_id) ON DELETE CASCADE
);

--kon araa restricted/safe/no-fly ei infro gulo thakbe

CREATE TABLE GeofenceZone (
    zone_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_name VARCHAR(80) NOT NULL,
    zone_type ENUM('No-Fly','Restricted','Safe') NOT NULL,
    center_lat DECIMAL(9,6) NOT NULL,
    center_lng DECIMAL(9,6) NOT NULL,
    radius_m INT NOT NULL CHECK (radius_m > 0),
    max_altitude_m INT NOT NULL DEFAULT 0
);

--  end > start (CHECK) mane shes shomoy shurur shomoyer poreri hote hobe

CREATE TABLE Mission (
    mission_id INT PRIMARY KEY AUTO_INCREMENT,
    drone_id INT NOT NULL,
    pilot_id INT NOT NULL,
    mission_name VARCHAR(30) NOT NULL,
    location VARCHAR(80) NOT NULL,
    purpose VARCHAR(120) NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    weather_condition VARCHAR(30),
    status ENUM('Completed','Aborted','In-Progress') NOT NULL DEFAULT 'Completed',
    FOREIGN KEY (drone_id) REFERENCES Drone(drone_id) ON DELETE CASCADE,
    FOREIGN KEY (pilot_id) REFERENCES Pilot(pilot_id) ON DELETE CASCADE,
    CHECK (end_time > start_time)
);


-- protita mission data recode hobe telemetrylog e

CREATE TABLE TelemetryLog (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    mission_id INT NOT NULL,
    log_time DATETIME NOT NULL,
    latitude DECIMAL(9,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    altitude_m DECIMAL(5,1) NOT NULL,
    speed_mps DECIMAL(4,1) NOT NULL,
    battery_voltage DECIMAL(4,2) NOT NULL,
    battery_percent DECIMAL(4,1) NOT NULL CHECK (battery_percent BETWEEN 0 AND 100),
    satellite_count INT NOT NULL,
    heading_deg INT NOT NULL,
    vertical_speed_mps DECIMAL(4,2) NOT NULL,
    FOREIGN KEY (mission_id) REFERENCES Mission(mission_id) ON DELETE CASCADE
);


-- jokhn drone restricted/no fly zone e enter krbe 

CREATE TABLE GeofenceViolation (
    violation_id INT PRIMARY KEY AUTO_INCREMENT,
    mission_id INT NOT NULL,
    zone_id INT NOT NULL,
    log_id INT NOT NULL,
    violation_time DATETIME NOT NULL,
    violation_type VARCHAR(30) NOT NULL,
    severity ENUM('Low','Medium','High') NOT NULL,
    FOREIGN KEY (mission_id) REFERENCES Mission(mission_id) ON DELETE CASCADE,
    FOREIGN KEY (zone_id) REFERENCES GeofenceZone(zone_id) ON DELETE CASCADE,
    FOREIGN KEY (log_id) REFERENCES TelemetryLog(log_id) ON DELETE CASCADE
);

--component er all details including cost

CREATE TABLE MaintenanceLog (
    maintenance_id INT PRIMARY KEY AUTO_INCREMENT,
    component_id INT NOT NULL,
    maintenance_date DATE NOT NULL,
    description VARCHAR(120) NOT NULL,
    performed_by VARCHAR(80) NOT NULL,
    cost DECIMAL(8,2) NOT NULL CHECK (cost >= 0),
    next_due_date DATE,
    FOREIGN KEY (component_id) REFERENCES Component(component_id) ON DELETE CASCADE
);

-- battery low hole othoba geofense zone e gele alert krbe

CREATE TABLE AlertLog (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    mission_id INT NOT NULL,
    alert_type VARCHAR(40) NOT NULL,
    alert_time DATETIME NOT NULL,
    severity ENUM('Info','Warning','Critical') NOT NULL,
    message VARCHAR(150),
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (mission_id) REFERENCES Mission(mission_id) ON DELETE CASCADE
);

-- Digonto er info 

INSERT INTO Drone (drone_id, drone_name, model, frame_type, weight_kg, max_payload_kg, firmware_version, status) VALUES
(1, 'Digonto', 'Custom Quadcopter (SpeedyBee F405 V4 FC)', 'X-Quad Custom Build', 2.0, 0.8, 'ArduPilot', 'Active');

-- 5 jon pilot er info 

INSERT INTO Pilot (pilot_id, full_name, license_no, phone, email, experience_years, joining_date) VALUES
(1, 'Ontu', 'DIU-UAV-2025-1001', '01647712782', 'ontu1@diu.edu.bd', 3.3, '2025-04-12'),
(2, 'Omor', 'DIU-UAV-2025-1002', '01998935572', 'omor2@diu.edu.bd', 0.6, '2025-07-30'),
(3, 'Biva', 'DIU-UAV-2025-1003', '01875398922', 'biva3@diu.edu.bd', 0.8, '2025-05-30'),
(4, 'Siam', 'DIU-UAV-2025-1004', '01362275869', 'siam4@diu.edu.bd', 3.2, '2025-02-24'),
(5, 'Foysal', 'DIU-UAV-2025-1005', '01340260662', 'foysal5@diu.edu.bd', 0.8, '2025-04-18');

-- Component er details

INSERT INTO Component (component_id, drone_id, component_type, model_no, install_date, usage_hours, status) VALUES
(1, 1, 'Brushless Motor Set (x4)', 'BLM-2212-KV920', '2025-09-12', 126.7, 'Good'),
(2, 1, 'Electronic Speed Controller (x4)', 'ESC-30A-BLHeli', '2025-09-11', 411.0, 'Good'),
(3, 1, 'LiPo Battery Pack', 'LP-6S-5200mAh', '2025-09-17', 107.7, 'Good'),
(4, 1, 'Flight Controller', 'SpeedyBee F405 V4', '2025-09-11', 639.0, 'Good'),
(5, 1, 'GPS + Compass Module', 'GPS-M8N-Ublox', '2025-09-17', 60.8, 'Needs Inspection'),
(6, 1, 'Propeller Set', 'PROP-1045-Carbon', '2025-09-19', 40.4, 'Good'),
(7, 1, 'Telemetry Radio', 'TX-915MHz-3DR', '2025-09-28', 346.2, 'Needs Inspection'),
(8, 1, 'Landing Gear + Frame', 'FRM-X650-Carbon', '2025-09-15', 150.7, 'Good');

-- 16 GeofenceZone 

INSERT INTO GeofenceZone (zone_id, zone_name, zone_type, center_lat, center_lng, radius_m, max_altitude_m) VALUES
(1, 'Central Playground No-Fly Buffer', 'No-Fly', 23.944557, 90.340649, 50, 50),
(2, 'Administrative Building Restricted Zone', 'Restricted', 23.941992, 90.342819, 120, 30),
(3, 'Dormitory Airspace', 'Restricted', 23.950112, 90.357169, 100, 30),
(4, 'DIU Lake Safe Testing Zone', 'Safe', 23.945769, 90.342295, 80, 100),
(5, 'Football Ground Safe Zone', 'Safe', 23.952288, 90.349204, 100, 150),
(6, 'Main Gate Approach Buffer', 'No-Fly', 23.949777, 90.350879, 50, 0),
(7, 'Auditorium Complex Zone', 'Restricted', 23.951039, 90.341999, 100, 0),
(8, 'Botanical Garden Zone', 'Safe', 23.959465, 90.347134, 50, 150),
(9, 'Cricket Ground Safe Zone', 'Safe', 23.952261, 90.35621, 100, 120),
(10, 'Library Building Restricted Zone', 'Restricted', 23.954706, 90.350587, 120, 0),
(11, 'Faculty Parking No-Fly Buffer', 'No-Fly', 23.957599, 90.357594, 120, 50),
(12, 'Innovation Hub Rooftop Buffer', 'No-Fly', 23.954083, 90.339913, 100, 50),
(13, 'Smart City Boulevard Safe Zone', 'Safe', 23.952359, 90.352325, 120, 120),
(14, 'Medical Center Restricted Zone', 'Restricted', 23.955133, 90.356441, 100, 0),
(15, 'Cafeteria Complex Buffer', 'No-Fly', 23.959613, 90.345809, 50, 30),
(16, 'Green Valley Open Test Zone', 'Safe', 23.941979, 90.354065, 80, 150);

-- amdr total 22 ta mission

INSERT INTO Mission (mission_id, drone_id, pilot_id, mission_name, location, purpose, start_time, end_time, weather_condition, status) VALUES
(1, 1, 2, 'Mission-004', 'Innovation Hub Open Field', 'Search & Rescue Drill', '2026-04-02 16:16:00', '2026-04-02 16:35:00', 'Cloudy', 'Completed'),
(2, 1, 4, 'Mission-007', 'Botanical Garden', 'Aerial Campus Survey', '2026-04-14 16:13:00', '2026-04-14 16:29:00', 'Partly Cloudy', 'Completed'),
(3, 1, 1, 'Mission-011', 'Botanical Garden', 'Signal Range Test', '2026-04-15 16:19:00', '2026-04-15 16:32:00', 'Cloudy', 'Completed'),
(4, 1, 1, 'Mission-013', 'DIU Lake Area', 'Flight Stability Calibration Test', '2026-04-27 17:00:00', '2026-04-27 17:11:00', 'Clear', 'Completed'),
(5, 1, 4, 'Mission-018', 'Innovation Hub Open Field', 'Security Patrol Test', '2026-05-04 11:18:00', '2026-05-04 11:35:00', 'Light Wind', 'Completed'),
(6, 1, 5, 'Mission-002', 'Botanical Garden', 'Flight Stability Calibration Test', '2026-05-06 10:20:00', '2026-05-06 10:39:00', 'Cloudy', 'Completed'),
(7, 1, 3, 'Mission-019', 'Central Playground', 'Payload Delivery Trial', '2026-05-17 09:22:00', '2026-05-17 09:31:00', 'Light Wind', 'Completed'),
(8, 1, 5, 'Mission-010', 'Football Ground', 'Security Patrol Test', '2026-05-19 10:32:00', '2026-05-19 10:48:00', 'Windy', 'Completed'),
(9, 1, 1, 'Mission-021', 'DIU Lake Area', 'Mapping & 3D Terrain Modelling', '2026-05-20 11:24:00', '2026-05-20 11:37:00', 'Humid', 'Completed'),
(10, 1, 2, 'Mission-001', 'Botanical Garden', 'Vegetation Health Scan (Botanical Garden)', '2026-05-21 14:40:00', '2026-05-21 15:00:00', 'Partly Cloudy', 'Completed'),
(11, 1, 2, 'Mission-005', 'Innovation Hub Open Field', 'Security Patrol Test', '2026-05-24 17:07:00', '2026-05-24 17:18:00', 'Partly Cloudy', 'Completed'),
(12, 1, 2, 'Mission-008', 'Football Ground', 'Aerial Campus Survey', '2026-05-27 10:46:00', '2026-05-27 10:53:00', 'Clear', 'Completed'),
(13, 1, 4, 'Mission-022', 'Central Playground', 'Search & Rescue Drill', '2026-05-30 14:51:00', '2026-05-30 15:08:00', 'Partly Cloudy', 'Aborted'),
(14, 1, 2, 'Mission-020', 'Auditorium Front Yard', 'Security Patrol Test', '2026-06-01 08:01:00', '2026-06-01 08:14:00', 'Humid', 'Completed'),
(15, 1, 2, 'Mission-017', 'Auditorium Front Yard', 'Aerial Campus Survey', '2026-06-06 16:24:00', '2026-06-06 16:35:00', 'Clear', 'Completed'),
(16, 1, 2, 'Mission-009', 'Innovation Hub Open Field', 'Aerial Campus Survey', '2026-06-08 09:43:00', '2026-06-08 09:54:00', 'Clear', 'Completed'),
(17, 1, 5, 'Mission-006', 'Auditorium Front Yard', 'Flight Stability Calibration Test', '2026-06-19 08:55:00', '2026-06-19 09:08:00', 'Light Wind', 'Completed'),
(18, 1, 3, 'Mission-014', 'Football Ground', 'Flight Stability Calibration Test', '2026-06-22 09:33:00', '2026-06-22 09:50:00', 'Cloudy', 'Completed'),
(19, 1, 3, 'Mission-003', 'DIU Lake Area', 'Vegetation Health Scan (Botanical Garden)', '2026-06-27 14:29:00', '2026-06-27 14:38:00', 'Partly Cloudy', 'Completed'),
(20, 1, 1, 'Mission-012', 'Football Ground', 'Signal Range Test', '2026-07-05 13:50:00', '2026-07-05 14:07:00', 'Humid', 'Completed'),
(21, 1, 3, 'Mission-015', 'Innovation Hub Open Field', 'Flight Stability Calibration Test', '2026-07-08 11:48:00', '2026-07-08 12:02:00', 'Cloudy', 'Completed'),
(22, 1, 5, 'Mission-016', 'DIU Lake Area', 'Mapping & 3D Terrain Modelling', '2026-07-13 11:19:00', '2026-07-13 11:37:00', 'Humid', 'Completed');

-- GeofenceViolation (18 violations)

INSERT INTO GeofenceViolation (violation_id, mission_id, zone_id, log_id, violation_time, violation_type, severity) VALUES
(1, 9, 1, 114, '2026-05-20 11:31:35', 'Altitude Breach', 'Medium'),
(2, 5, 2, 67, '2026-05-04 11:28:12', 'Zone Entry', 'High'),
(3, 13, 1, 156, '2026-05-30 15:02:45', 'Altitude Breach', 'Low'),
(4, 2, 4, 28, '2026-04-14 16:22:10', 'Zone Entry', 'Medium'),
(5, 8, 6, 89, '2026-05-19 10:41:55', 'Altitude Breach', 'High'),
(6, 15, 7, 172, '2026-06-06 16:30:18', 'Zone Entry', 'Low'),
(7, 3, 3, 35, '2026-04-15 16:25:40', 'Altitude Breach', 'Medium'),
(8, 19, 8, 198, '2026-06-27 14:34:22', 'Zone Entry', 'High'),
(9, 7, 5, 76, '2026-05-17 09:28:50', 'Speed Violation', 'Medium'),
(10, 11, 9, 123, '2026-05-24 17:12:33', 'Altitude Breach', 'Low'),
(11, 1, 10, 15, '2026-04-02 16:28:05', 'Zone Entry', 'High'),
(12, 18, 11, 185, '2026-06-22 09:42:17', 'Altitude Breach', 'Medium'),
(13, 4, 12, 52, '2026-04-27 17:06:40', 'Zone Entry', 'Low'),
(14, 20, 13, 205, '2026-07-05 13:58:59', 'Altitude Breach', 'High'),
(15, 6, 14, 58, '2026-05-06 10:31:25', 'Speed Violation', 'Medium'),
(16, 16, 15, 178, '2026-06-08 09:48:11', 'Zone Entry', 'Low'),
(17, 21, 2, 215, '2026-07-08 11:55:44', 'Altitude Breach', 'Medium'),
(18, 22, 6, 220, '2026-07-13 11:35:12', 'Zone Entry', 'High');

-- MaintenanceLog (21 events)

INSERT INTO MaintenanceLog (maintenance_id, component_id, maintenance_date, description, performed_by, cost, next_due_date) VALUES
(1, 3, '2025-10-08', 'Wiring/connector check', 'Omor', 1470.27, '2026-02-01'),
(2, 1, '2025-09-20', 'Motor bearing lubrication', 'Ontu', 850.50, '2025-12-15'),
(3, 4, '2025-10-01', 'Firmware update & calibration', 'Siam', 2000.00, '2026-01-01'),
(4, 7, '2025-10-15', 'Antenna replacement', 'Foysal', 1200.75, '2026-04-15'),
(5, 2, '2025-09-25', 'ESC firmware sync', 'Biva', 950.25, '2025-12-20'),
(6, 5, '2025-11-01', 'GPS module re-calibration', 'Omor', 300.00, '2026-05-01'),
(7, 6, '2025-10-20', 'Propeller balancing', 'Ontu', 450.00, '2026-01-20'),
(8, 8, '2025-11-05', 'Landing gear screw tightening', 'Siam', 150.00, '2026-02-05'),
(9, 3, '2025-11-15', 'Battery health test', 'Biva', 1100.00, '2026-05-15'),
(10, 1, '2025-12-01', 'Motor replacement (front-right)', 'Foysal', 3200.00, '2026-06-01'),
(11, 4, '2025-12-10', 'FC gyro recalibration', 'Omor', 500.00, '2026-03-10'),
(12, 7, '2025-12-20', 'Radio telemetry module check', 'Ontu', 700.00, '2026-06-20'),
(13, 2, '2026-01-05', 'ESC capacitor replacement', 'Siam', 1800.50, '2026-07-05'),
(14, 5, '2026-01-15', 'Compass calibration', 'Biva', 250.00, '2026-07-15'),
(15, 6, '2026-01-25', 'Propeller set replacement', 'Foysal', 2200.00, '2026-07-25'),
(16, 8, '2026-02-01', 'Frame structural inspection', 'Omor', 600.00, '2026-08-01'),
(17, 3, '2026-02-10', 'Battery balancing', 'Ontu', 950.30, '2026-08-10'),
(18, 1, '2026-02-20', 'Motor shaft cleaning', 'Siam', 400.00, '2026-08-20'),
(19, 4, '2026-03-01', 'FC port cleaning & check', 'Biva', 350.00, '2026-09-01'),
(20, 7, '2026-03-15', 'Antenna positioning fix', 'Foysal', 650.00, '2026-09-15'),
(21, 2, '2026-04-01', 'Full ESC diagnostic test', 'Omor', 2100.00, '2026-10-01');

-- AlertLog (22 alerts)

INSERT INTO AlertLog (alert_id, mission_id, alert_type, alert_time, severity, message, resolved) VALUES
(1, 1, 'High Wind Warning', '2026-04-02 16:23:00', 'Critical', 'High Wind Warning detected during Mission-004', 1),
(2, 2, 'Low Battery Warning', '2026-04-14 16:18:45', 'Warning', 'Battery dropped to 22% during Mission-007', 1),
(3, 3, 'Geofence Alert', '2026-04-15 16:25:40', 'Critical', 'Unauthorized zone entry detected', 0),
(4, 4, 'GPS Signal Lost', '2026-04-27 17:05:15', 'Warning', 'GPS signal lost for 5 seconds', 1),
(5, 5, 'High Wind Warning', '2026-05-04 11:28:12', 'Critical', 'Sudden gust detected over 8m/s', 1),
(6, 6, 'Low Battery Warning', '2026-05-06 10:31:25', 'Warning', 'Battery at 19%', 0),
(7, 7, 'Geofence Alert', '2026-05-17 09:28:50', 'High', 'Speed violation inside Safe Zone', 1),
(8, 8, 'Motor Overheat Warning', '2026-05-19 10:41:55', 'Critical', 'Rear-left motor temperature high', 1),
(9, 9, 'Altitude Breach Alert', '2026-05-20 11:31:35', 'Medium', 'Exceeded max altitude limit', 0),
(10, 10, 'Low Battery Warning', '2026-05-21 14:52:30', 'Warning', 'Battery at 15%', 1),
(11, 11, 'Geofence Alert', '2026-05-24 17:12:33', 'High', 'Restricted zone proximity warning', 0),
(12, 12, 'GPS Signal Lost', '2026-05-27 10:48:10', 'Info', 'GPS momentary drop', 1),
(13, 13, 'High Wind Warning', '2026-05-30 15:02:45', 'Critical', 'Wind speed exceeded safe limit', 1),
(14, 14, 'Low Battery Warning', '2026-06-01 08:08:20', 'Warning', 'Battery at 20%', 0),
(15, 15, 'Geofence Alert', '2026-06-06 16:30:18', 'Medium', 'Zone boundary crossing', 1),
(16, 16, 'Motor Overheat Warning', '2026-06-08 09:48:11', 'High', 'Front-right motor heating up', 0),
(17, 17, 'Altitude Breach Alert', '2026-06-19 09:02:05', 'Low', 'Slight altitude overshoot', 1),
(18, 18, 'High Wind Warning', '2026-06-22 09:42:17', 'Critical', 'Wind shear detected', 1),
(19, 19, 'Low Battery Warning', '2026-06-27 14:34:22', 'Warning', 'Battery at 18%', 0),
(20, 20, 'Geofence Alert', '2026-07-05 13:58:59', 'High', 'Restricted zone violation', 1),
(21, 21, 'GPS Signal Lost', '2026-07-08 11:55:44', 'Info', 'GPS temporary loss', 1),
(22, 22, 'Low Battery Warning', '2026-07-13 11:35:12', 'Critical', 'Battery critically low (8%)', 0);


--Trigger1: battery jokhn low thakbe

DELIMITER //
CREATE TRIGGER trg_LowBatteryAlert
AFTER INSERT ON TelemetryLog
FOR EACH ROW
BEGIN
    IF NEW.battery_percent < 25 THEN
        INSERT INTO AlertLog (mission_id, alert_type, alert_time, severity, message, resolved)
        VALUES (
            NEW.mission_id,
            'Low Battery Warning',
            NEW.log_time,
            IF(NEW.battery_percent < 15, 'Critical', 'Warning'),
            CONCAT('Battery dropped to ', NEW.battery_percent, '% during mission ', NEW.mission_id),
            FALSE
        );
    END IF;
END //
DELIMITER ;

-- Trigger 2: component jokhn beshi use hoye jabe

-- Before updating a component, if usage_hours reaches 800, mark it for inspection.
DELIMITER //
CREATE TRIGGER trg_ComponentWearFlag
BEFORE UPDATE ON Component
FOR EACH ROW
BEGIN
    IF NEW.usage_hours >= 800 AND OLD.status = 'Good' THEN
        SET NEW.status = 'Needs Inspection';
    END IF;
END //
DELIMITER ;


--Procedure1: pilot er stats ache

DELIMITER //
CREATE PROCEDURE sp_PilotStats(IN p_pilot_id INT)
BEGIN
    SELECT
        full_name,
        license_no,
        experience_years,
        DATEDIFF(CURDATE(), joining_date) AS days_since_joining
    FROM Pilot
    WHERE pilot_id = p_pilot_id;
END //
DELIMITER ;

--Procedure2: pilot er missioncount ache

DELIMITER //
CREATE PROCEDURE sp_PilotMissionCount(IN p_pilot_id INT)
BEGIN
    SELECT
        p.full_name,
        COUNT(m.mission_id) AS total_missions
    FROM Pilot p
    LEFT JOIN Mission m ON m.pilot_id = p.pilot_id
    WHERE p.pilot_id = p_pilot_id
    GROUP BY p.pilot_id;
END //
DELIMITER ;

-- View : kon geofence zone ta kotobar violation hoyeche dekha jabe

CREATE VIEW vw_ZoneRisk AS
SELECT
    z.zone_id, z.zone_name, z.zone_type,
    COUNT(gv.violation_id) AS violation_count
FROM GeofenceZone z
LEFT JOIN GeofenceViolation gv ON gv.zone_id = z.zone_id
GROUP BY z.zone_id;



-- 1. notun mission add kora

INSERT INTO Mission (drone_id, pilot_id, mission_name, location, purpose, start_time, end_time, weather_condition, status)
VALUES (1, 3, 'Mission-023', 'Central Playground', 'Aerial Campus Survey', '2026-08-05 09:00:00', '2026-08-05 09:14:00', 'Clear', 'Completed');

-- 2. drone status update

UPDATE Drone SET status = 'Maintenance' WHERE drone_id = 1;

-- 3. delete false alert

DELETE FROM AlertLog WHERE severity = 'Info' AND resolved = FALSE LIMIT 1;

-- 4. 5ta recent bad weather mission select kora

SELECT mission_id, mission_name, location, weather_condition, start_time
FROM Mission
WHERE weather_condition IN ('Windy','Cloudy','Overcast')
ORDER BY start_time DESC
LIMIT 5;

-- 5. protita drone er toal flight minutes ber kora

SELECT d.drone_name, COUNT(m.mission_id) AS missions, 
       SUM(TIMESTAMPDIFF(MINUTE, m.start_time, m.end_time)) AS total_minutes_flown
FROM Drone d
JOIN Mission m ON m.drone_id = d.drone_id
GROUP BY d.drone_name
ORDER BY total_minutes_flown DESC;


SELECT m.mission_id, m.mission_name, d.drone_name, p.full_name AS pilot, m.location, m.status
FROM Mission m
JOIN Drone d ON d.drone_id = m.drone_id
JOIN Pilot p ON p.pilot_id = m.pilot_id
ORDER BY m.mission_id;


SELECT p.full_name, COUNT(*) AS missions_flown
FROM Pilot p
JOIN Mission m ON m.pilot_id = p.pilot_id
GROUP BY p.full_name
HAVING COUNT(*) > 3
ORDER BY missions_flown DESC;


SELECT drone_name FROM Drone
WHERE drone_id = (
    SELECT m.drone_id
    FROM Mission m
    GROUP BY m.drone_id
    ORDER BY SUM(TIMESTAMPDIFF(MINUTE, m.start_time, m.end_time)) DESC
    LIMIT 1
);


SELECT c.component_id, c.component_type, c.drone_id, c.usage_hours
FROM Component c
WHERE NOT EXISTS (
    SELECT 1 FROM MaintenanceLog ml
    WHERE ml.component_id = c.component_id
      AND ml.maintenance_date >= DATE_SUB('2026-08-05', INTERVAL 60 DAY)
);


SELECT gz.zone_name, gz.zone_type, COUNT(*) AS violation_count
FROM GeofenceViolation gv
JOIN GeofenceZone gz ON gz.zone_id = gv.zone_id
GROUP BY gz.zone_name, gz.zone_type
ORDER BY violation_count DESC
LIMIT 5;


SELECT d.model,
       ROUND(AVG(sub.drain_pct), 2) AS avg_battery_drain_pct
FROM drone d
JOIN (
    SELECT m.drone_id,
           MAX(t.battery_percent) - MIN(t.battery_percent) AS drain_pct
    FROM telemetrylog t
    JOIN mission m ON t.mission_id = m.mission_id
    GROUP BY t.mission_id, m.drone_id
) sub ON d.drone_id = sub.drone_id
GROUP BY d.model;


SELECT * FROM vw_ComponentHealth WHERE status != 'Good';
SELECT * FROM vw_ZoneRisk ORDER BY violation_count DESC;


CALL sp_PilotStats(1);
CALL sp_PilotMissionCount(2);

--new mission and component use update eksathe rakha hoyeche jeno ekta fail krle bakitao fail kore

START TRANSACTION;

INSERT INTO Mission (drone_id, pilot_id, mission_name, location, purpose, start_time, end_time, weather_condition, status)
VALUES (1, 4, 'Mission-024', 'Football Ground', 'Aerial Campus Survey', '2026-08-08 09:00:00', '2026-08-08 09:15:00', 'Clear', 'Completed');

UPDATE Component
SET usage_hours = usage_hours + 0.25   
WHERE drone_id = 1;


COMMIT;
