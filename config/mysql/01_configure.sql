-- -------------------------------------------------------------------------
-- Trivadis AG, Infrastructure Managed Services
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-- -------------------------------------------------------------------------
-- Name.......: 01_configure.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
-- Editor.....: Stefan Oehrli
-- Date.......: 2020.04.28
-- Revision...: 
-- Purpose....: Configure guacamole DB.
-- Notes......: --
-- Reference..: --
-- --------------------------------------------------------------------------

use guacadb;

-- reset guacadmin password
SET @salt = UNHEX(SHA2(UUID(), 256));
UPDATE guacamole_user SET 
    password_salt = @salt,
    password_hash = UNHEX(SHA2(CONCAT('GUACADMIN_PASSWORD', HEX(@salt)), 256)),
    password_date = CURRENT_TIMESTAMP WHERE entity_id = 1;

-- Create connection
INSERT INTO guacamole_connection (connection_name, protocol) VALUES ('Windows Server (ad - 10.0.1.4)', 'rdp');
INSERT INTO guacamole_connection (connection_name, protocol) VALUES ('Database Server (db - 10.0.1.6)', 'ssh');
INSERT INTO guacamole_connection (connection_name, protocol) VALUES ('OUD Server (oud - 10.0.1.5)', 'ssh');

-- Add parameters to the Windows connection
INSERT INTO guacamole_connection_parameter VALUES (1, 'hostname', '10.0.1.4');
INSERT INTO guacamole_connection_parameter VALUES (1, 'port', '3389');
-- Add parameters to the Database connection
INSERT INTO guacamole_connection_parameter VALUES (2, 'hostname', '10.0.1.6');
INSERT INTO guacamole_connection_parameter VALUES (2, 'port', '22');
INSERT INTO guacamole_connection_parameter VALUES (2, 'username', 'oracle');
-- Add parameters to the OUD connection
INSERT INTO guacamole_connection_parameter VALUES (3, 'hostname', '10.0.1.5');
INSERT INTO guacamole_connection_parameter VALUES (3, 'port', '22');
INSERT INTO guacamole_connection_parameter VALUES (3, 'username', 'oracle');