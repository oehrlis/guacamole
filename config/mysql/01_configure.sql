-- -------------------------------------------------------------------------
-- Trivadis AG, Infrastructure Managed Services
-- Saegereistrasse 29, 8152 Glattbrugg, Switzerland
-- -------------------------------------------------------------------------
-- Name.......: 01_configure.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@accenture.com
-- Editor.....: Stefan Oehrli
-- Date.......: 2020.10.26
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
