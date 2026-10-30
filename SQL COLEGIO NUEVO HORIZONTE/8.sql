USE master;
GO

-- 1. Crear el objeto Server Audit apuntando a disco para el colegio
CREATE SERVER AUDIT Audit_ColegioHorizonte
TO FILE (
    FILEPATH = 'C:\AuditLogs_Colegio_NuevoHorizonte\',
    MAXSIZE = 10 MB,
    MAX_ROLLOVER_FILES = 5,
    RESERVE_DISK_SPACE = OFF
)
WITH (
    QUEUE_DELAY = 1000, -- Retardo en ms para escribir a disco
    ON_FAILURE = CONTINUE
);
GO

-- 2. Activar la auditoría global
ALTER SERVER AUDIT Audit_ColegioHorizonte
WITH (STATE = ON);
GO


USE ColegioHorizonteDB;
GO

-- 3. Crear la especificación de eventos vinculada al nuevo Server Audit
CREATE DATABASE AUDIT SPECIFICATION DB_Audit_ColegioHorizonte
FOR SERVER AUDIT Audit_ColegioHorizonte
-- Vinculación de operaciones para cada una de tus tablas
ADD (SELECT, UPDATE, DELETE ON dbo.Aulas BY public),
ADD (SELECT, UPDATE, DELETE ON dbo.Usuarios_Sistema BY public),
ADD (SELECT, UPDATE, DELETE ON dbo.Estudiantes BY public),
ADD (SELECT, UPDATE, DELETE ON dbo.Vinculos_Familiares BY public),
ADD (SELECT, UPDATE, DELETE ON dbo.Asistencias_Diarias BY public),
ADD (SELECT, UPDATE, DELETE ON dbo.Evaluaciones_Bimestrales BY public);
GO

-- 4. Activar la especificación en la BD
ALTER DATABASE AUDIT SPECIFICATION DB_Audit_ColegioHorizonte
WITH (STATE = ON);
GO
