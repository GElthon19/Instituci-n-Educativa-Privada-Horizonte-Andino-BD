-- ============================================================================
-- SCRIPT 05: OPTIMIZACIÓN (ÍNDICES) Y RESPALDOS CIFRADOS (BACKUPS)
-- ============================================================================

USE ColegioHorizonteDB;
GO

-- ----------------------------------------------------------------------------
-- 1. ESTRATEGIA DE ÍNDICES PARA OPTIMIZAR LAS CONSULTAS PESADAS
-- ----------------------------------------------------------------------------

-- A. Índice No Agrupado para acelerar la búsqueda y conteo de Asistencias
-- Filtra rápidamente por fecha y estado de asistencia sin escanear toda la tabla
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Asistencias_Fecha_Estado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Asistencias_Fecha_Estado
    ON Asistencias_Diarias (Fecha, EstadoAsistencia)
    INCLUDE (EstudianteID);
    PRINT 'Índice IX_Asistencias_Fecha_Estado creado con éxito.';
END;
GO

-- B. Índice No Agrupado para Evaluaciones Bimestrales por Año y Bimestre
-- Optimiza las consultas de libretas de notas y reportes bimestrales
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Evaluaciones_Anio_Bimestre')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Evaluaciones_Anio_Bimestre
    ON Evaluaciones_Bimestrales (Anio, Bimestre)
    INCLUDE (EstudianteID);
    PRINT 'Índice IX_Evaluaciones_Anio_Bimestre creado con éxito.';
END;
GO

-- C. Índice No Agrupado para Búsquedas Frecuentes de Estudiantes por Aula
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Estudiantes_AulaID')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Estudiantes_AulaID
    ON Estudiantes (AulaID)
    INCLUDE (Nombres, Apellidos, Estado);
    PRINT 'Índice IX_Estudiantes_AulaID creado con éxito.';
END;
GO

-- ----------------------------------------------------------------------------
-- 2. BACKUP CIFRADO (ENCRYPTED BACKUP) CON AES_256
-- Garantes la protección de la base de datos completa durante la exportación
-- ----------------------------------------------------------------------------

-- Certificado para el cifrado del Backup (independiente de las llaves de columna)
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertBackupColegioHorizonte')
BEGIN
    CREATE CERTIFICATE CertBackupColegioHorizonte
    WITH SUBJECT = 'Certificado para Cifrado de Copias de Seguridad ColegioHorizonteDB';
    PRINT 'Certificado para respaldos creado.';
END;
GO

-- Ejecución de la Copia de Seguridad Completa (FULL) Cifrada
-- NOTA: La ruta 'C:\SQL_Backups\' debe existir en el servidor SQL Server.
BACKUP DATABASE ColegioHorizonteDB
TO DISK = N'C:\SQL_Backups\ColegioHorizonteDB_Full_Encrypted.bak'
WITH 
    FORMAT,
    INIT,
    NAME = N'ColegioHorizonteDB - Copia de Seguridad Completa Cifrada',
    ENCRYPTION (
        ALGORITHM = AES_256,
        SERVER CERTIFICATE = CertBackupColegioHorizonte
    ),
    STATS = 10;
GO

-- ----------------------------------------------------------------------------
-- 3. PLAN DE MANTENIMIENTO: REORGANIZACIÓN Y RECONSTRUCCIÓN DE ÍNDICES
-- Recomendado ejecutar periódicamente cuando la base de datos supera los 300k registros
-- ----------------------------------------------------------------------------

-- Reorganizar índices si la fragmentación es baja-media
ALTER INDEX IX_Asistencias_Fecha_Estado ON Asistencias_Diarias REORGANIZE;

-- Reconstruir índices si la fragmentación es alta
ALTER INDEX ALL ON Asistencias_Diarias REBUILD;
ALTER INDEX ALL ON Evaluaciones_Bimestrales REBUILD;
GO

PRINT 'Módulo 05: Índices y Backups configurado correctamente.';