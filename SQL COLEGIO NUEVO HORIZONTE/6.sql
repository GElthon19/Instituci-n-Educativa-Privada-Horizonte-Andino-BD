-- =========================================================================
-- SCRIPT 07: SEGURIDAD Y CONTROL DE ACCESO BASE EN ROLES (RBAC REAL)
-- =========================================================================
USE master;
GO

-- 1. CREACIÓN / ACTUALIZACIÓN DE LOGINS A NIVEL DE INSTANCIA
-- (Utilizamos ALTER LOGIN para asegurar que si ya existía, active la clave y se habilite)

-- A. Administrador
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usr_admin')
    CREATE LOGIN usr_admin WITH PASSWORD = 'AdminSecurePass2026!', CHECK_POLICY = OFF;
ELSE
    ALTER LOGIN usr_admin WITH PASSWORD = 'AdminSecurePass2026!', CHECK_POLICY = OFF;
ALTER LOGIN usr_admin ENABLE;

-- B. Secretaría
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usr_secre')
    CREATE LOGIN usr_secre WITH PASSWORD = 'SecreSecurePass2026!', CHECK_POLICY = OFF;
ELSE
    ALTER LOGIN usr_secre WITH PASSWORD = 'SecreSecurePass2026!', CHECK_POLICY = OFF;
ALTER LOGIN usr_secre ENABLE;

-- C. Docentes
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usr_docente1')
    CREATE LOGIN usr_docente1 WITH PASSWORD = 'Docente1SecurePass2026!', CHECK_POLICY = OFF;
ELSE
    ALTER LOGIN usr_docente1 WITH PASSWORD = 'Docente1SecurePass2026!', CHECK_POLICY = OFF;
ALTER LOGIN usr_docente1 ENABLE;

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usr_docente2')
    CREATE LOGIN usr_docente2 WITH PASSWORD = 'Docente2SecurePass2026!', CHECK_POLICY = OFF;
ELSE
    ALTER LOGIN usr_docente2 WITH PASSWORD = 'Docente2SecurePass2026!', CHECK_POLICY = OFF;
ALTER LOGIN usr_docente2 ENABLE;

-- D. Padre de Familia (Completando la Matriz RBAC del Informe)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usr_padre1')
    CREATE LOGIN usr_padre1 WITH PASSWORD = 'Padre1SecurePass2026!', CHECK_POLICY = OFF;
ELSE
    ALTER LOGIN usr_padre1 WITH PASSWORD = 'Padre1SecurePass2026!', CHECK_POLICY = OFF;
ALTER LOGIN usr_padre1 ENABLE;
GO

-- =========================================================================
-- 2. MAPEO DE USUARIOS EN LA BASE DE DATOS DEL COLEGIO
-- =========================================================================
USE ColegioHorizonteDB;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usr_admin')
    CREATE USER usr_admin FOR LOGIN usr_admin;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usr_secre')
    CREATE USER usr_secre FOR LOGIN usr_secre;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usr_docente1')
    CREATE USER usr_docente1 FOR LOGIN usr_docente1;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usr_docente2')
    CREATE USER usr_docente2 FOR LOGIN usr_docente2;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usr_padre1')
    CREATE USER usr_padre1 FOR LOGIN usr_padre1;
GO

-- =========================================================================
-- 3. CREACIÓN Y ASIGNACIÓN DE ROLES RBAC SEGÚN ESPECIFICACIÓN DEL INFORME
-- =========================================================================

---------------------------------------------------------------------------
-- A. ROL ADMINISTRADOR (Control Total de la BD)
---------------------------------------------------------------------------
ALTER ROLE db_owner ADD MEMBER usr_admin;

---------------------------------------------------------------------------
-- B. ROL SECRETARÍA (Gestión de Matrículas y Aulas - SIN Acceso a Modificar Notas)
---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_Secretaria' AND type = 'R')
BEGIN
    CREATE ROLE Rol_Secretaria;
END;
GO

-- Permisos granulares de Secretaría
GRANT SELECT, INSERT, UPDATE ON Estudiantes TO Rol_Secretaria;
GRANT SELECT, INSERT, UPDATE ON Aulas TO Rol_Secretaria;
GRANT SELECT, INSERT, UPDATE ON Vinculos_Familiares TO Rol_Secretaria;
GRANT SELECT ON Asistencias_Diarias TO Rol_Secretaria;
-- Denegamos explícitamente la modificación de calificaciones
DENY INSERT, UPDATE, DELETE ON Evaluaciones_Bimestrales TO Rol_Secretaria;

ALTER ROLE Rol_Secretaria ADD MEMBER usr_secre;

---------------------------------------------------------------------------
-- C. ROL DOCENTE (Asistencia y Notas - Lectura Limitada)
---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_Docente' AND type = 'R')
BEGIN
    CREATE ROLE Rol_Docente;
END;
GO

-- Permisos granulares de Docentes
GRANT SELECT ON Aulas TO Rol_Docente;
GRANT SELECT ON Estudiantes TO Rol_Docente;
GRANT SELECT, INSERT, UPDATE ON Asistencias_Diarias TO Rol_Docente;
GRANT SELECT, INSERT, UPDATE ON Evaluaciones_Bimestrales TO Rol_Docente;

ALTER ROLE Rol_Docente ADD MEMBER usr_docente1;
ALTER ROLE Rol_Docente ADD MEMBER usr_docente2;

---------------------------------------------------------------------------
-- D. ROL PADRE DE FAMILIA (Consulta Exclusiva - Prohibida la Escritura)
---------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Rol_Padre_Familia' AND type = 'R')
BEGIN
    CREATE ROLE Rol_Padre_Familia;
END;
GO

-- Permisos de solo lectura para apoderados
GRANT SELECT ON Estudiantes TO Rol_Padre_Familia;
GRANT SELECT ON Asistencias_Diarias TO Rol_Padre_Familia;
GRANT SELECT ON Evaluaciones_Bimestrales TO Rol_Padre_Familia;
GRANT SELECT ON Vinculos_Familiares TO Rol_Padre_Familia;

-- Denegación explícita de escrituras
DENY INSERT, UPDATE, DELETE ON Estudiantes TO Rol_Padre_Familia;
DENY INSERT, UPDATE, DELETE ON Asistencias_Diarias TO Rol_Padre_Familia;
DENY INSERT, UPDATE, DELETE ON Evaluaciones_Bimestrales TO Rol_Padre_Familia;

ALTER ROLE Rol_Padre_Familia ADD MEMBER usr_padre1;
GO

-- =========================================================================
-- 4. CONSULTA DE VERIFICACIÓN
-- =========================================================================
SELECT 
    dp.name AS Usuario_BD,
    dp.type_desc AS Tipo,
    p.name AS Rol_Asignado
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals p ON rm.role_principal_id = p.principal_id
WHERE dp.name IN ('usr_admin', 'usr_secre', 'usr_docente1', 'usr_docente2', 'usr_padre1');
GO