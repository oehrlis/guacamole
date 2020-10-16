-----------------------------------------------------------------------------
--Trivadis AG, Infrastructure Managed Services
--Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-----------------------------------------------------------------------------
--Name.......: 01_configure.sql
--Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--Editor.....: Stefan Oehrli
--Date.......: 2020.04.28
--Revision...: 
--Purpose....: Configure guacamole DB.
--Notes......: --
--Reference..: --
-----------------------------------------------------------------------------

use guacadb;

-- reset guacadmin password
SET @salt = UNHEX(SHA2(UUID(), 256));
UPDATE guacamole_user SET 
    password_salt = @salt,
    password_hash = UNHEX(SHA2(CONCAT('GUACADMIN_PASSWORD', HEX(@salt)), 256)),
    password_date = CURRENT_TIMESTAMP WHERE entity_id = 1;

-- Create connection
INSERT INTO guacamole_connection (connection_name, protocol) VALUES ('Windows', 'rdp');

-- Add parameters to the new connection
INSERT INTO guacamole_connection_parameter VALUES (1, 'hostname', 'ad');
INSERT INTO guacamole_connection_parameter VALUES (1, 'port', '3389');