-- SCRIPT 05: OPTIMIZACIÓN (ÍNDICES) Y RESPALDOS CIFRADOS (BACKUPS)

USE ColegioHorizonteDB;
GO

-- 1. ESTRATEGIA DE ÍNDICES PARA OPTIMIZAR LAS CONSULTAS PESADAS

-- A. Índice No Agrupado para acelerar la búsqueda y conteo de Asistencias
-- Filtra rápidamente por fecha y estado de asistencia sin escanear toda la tabla
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Asistencias_Fecha_Estado')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Asistencias_Fecha_Estado
    ON Asistencias_Diarias (Fecha, EstadoAsistencia)
    INCLUDE (EstudianteID);
END;
GO

-- B. Índice No Agrupado para Evaluaciones Bimestrales por Año y Bimestre
-- Optimiza las consultas de libretas de notas y reportes bimestrales
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Evaluaciones_Anio_Bimestre')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Evaluaciones_Anio_Bimestre
    ON Evaluaciones_Bimestrales (Anio, Bimestre)
    INCLUDE (EstudianteID);
END;
GO

-- C. Índice No Agrupado para Búsquedas Frecuentes de Estudiantes por Aula
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Estudiantes_AulaID')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Estudiantes_AulaID
    ON Estudiantes (AulaID)
    INCLUDE (Nombres, Apellidos, Estado);
END;
GO


-- 2. BACKUP CIFRADO (ENCRYPTED BACKUP) CON AES_256
-- Garantes la protección de la base de datos completa durante la exportación

-- Certificado para el cifrado del Backup (independiente de las llaves de columna)
USE master;
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertBackupColegioHorizonte')
BEGIN
    CREATE CERTIFICATE CertBackupColegioHorizonte
    WITH SUBJECT = 'Certificado para Cifrado de Copias de Seguridad ColegioHorizonteDB';
END;
GO

-- Ejecución de la Copia de Seguridad Completa (FULL) Cifrada
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

--DIFF
BACKUP DATABASE ColegioHorizonteDB
TO DISK = N'C:\SQL_Backups\ColegioHorizonteDB_Diff_Encrypted.bak'
WITH 
    DIFFERENTIAL, -- <-- Clave para indicar que es diferencial
    FORMAT,       -- Sobrescribe cualquier archivo existente en este medio
    INIT,         -- Inicializa el archivo de respaldo
    NAME = N'ColegioHorizonteDB - Copia de Seguridad Diferencial Cifrada',
    ENCRYPTION (
        ALGORITHM = AES_256,
        SERVER CERTIFICATE = CertBackupColegioHorizonte
    ),
    STATS = 10;
GO
--LOG
BACKUP LOG ColegioHorizonteDB
TO DISK = N'C:\SQL_Backups\ColegioHorizonteDB_Log_Encrypted.trn' -- <-- Extensión estándar .trn para logs
WITH 
    FORMAT,
    INIT,
    NAME = N'ColegioHorizonteDB - Copia de Seguridad del Log Cifrada',
    ENCRYPTION (
        ALGORITHM = AES_256,
        SERVER CERTIFICATE = CertBackupColegioHorizonte
    ),
    STATS = 10;
GO



--SIMULACIÓN
-- =========================================================================
-- SCRIPT 08: SIMULACIÓN DE PÉRDIDA ACCIDENTAL Y RECUPERACIÓN DE DATOS
-- =========================================================================
USE ColegioHorizonteDB;
GO

-- -------------------------------------------------------------------------
-- PASO 1: VERIFICAR LOS REGISTROS ANTES DE LA PÉRDIDA Y ASEGURAR BACKUP
-- -------------------------------------------------------------------------
-- 1.1. Consultamos las evaluaciones bimestrales de los 2 primeros alumnos
SELECT EvaluacionID, EstudianteID, Anio, Bimestre, DetalleNotasJSON 
FROM Evaluaciones_Bimestrales 
WHERE EstudianteID IN ('EST-2024-0001', 'EST-2024-0002');
GO

-- 1.2. Generamos un Backup Completo Cifrado (Estado "Sano" antes del incidente)
USE master;
GO

BACKUP DATABASE ColegioHorizonteDB
TO DISK = N'C:\Backups\ColegioHorizonteDB_Full_Encrypted.bak'
WITH 
    FORMAT, INIT,
    NAME = N'ColegioHorizonteDB - Respaldado Previo a Incidente',
    ENCRYPTION (
        ALGORITHM = AES_256,
        SERVER CERTIFICATE = CertBackupColegioHorizonte
    ),
    STATS = 10;
GO

-- -------------------------------------------------------------------------
-- PASO 2: SIMULACIÓN DEL DESASTRE (BORRADO ACCIDENTAL DE DATOS)
-- -------------------------------------------------------------------------
USE ColegioHorizonteDB;
GO

-- Simulamos que un usuario o proceso elimina por error las libretas de estos estudiantes
DELETE FROM Evaluaciones_Bimestrales
WHERE EstudianteID IN ('EST-2024-0001', 'EST-2024-0002');
GO

-- Confirmamos que la tabla ya no contiene los registros (Devuelve 0 filas)
SELECT EvaluacionID, EstudianteID, Anio, Bimestre 
FROM Evaluaciones_Bimestrales 
WHERE EstudianteID IN ('EST-2024-0001', 'EST-2024-0002');
GO

-- -------------------------------------------------------------------------
-- PASO 3: RESTAURACIÓN AUXILIAR DEL BACKUP CIFRADO EN BD TEMPORAL
-- -------------------------------------------------------------------------
USE master;
GO

-- Restauramos el backup respaldado en el Paso 1 con un nombre temporal (ColegioHorizonteDB_Temp)
-- para no alterar la base de datos principal activa.
RESTORE DATABASE ColegioHorizonteDB_Temp
FROM DISK = N'C:\Backups\ColegioHorizonteDB_Full_Encrypted.bak'
WITH 
    MOVE 'ColegioHorizonteDB' TO 'C:\Backups\ColegioHorizonteDB_Temp.mdf',
    MOVE 'ColegioHorizonteDB_log' TO 'C:\Backups\ColegioHorizonteDB_Temp.ldf',
    REPLACE;
GO

-- -------------------------------------------------------------------------
-- PASO 4: RECUPERACIÓN QUIRÚRGICA DE REGISTROS FALTANTES
-- -------------------------------------------------------------------------
USE ColegioHorizonteDB;
GO

-- Reinsertamos en la base de datos en producción ÚNICAMENTE los registros 
-- que existían en el backup temporal y que fueron borrados por error
INSERT INTO Evaluaciones_Bimestrales (EstudianteID, Anio, Bimestre, DetalleNotasJSON)
SELECT EstudianteID, Anio, Bimestre, DetalleNotasJSON
FROM ColegioHorizonteDB_Temp.dbo.Evaluaciones_Bimestrales
WHERE EstudianteID IN ('EST-2024-0001', 'EST-2024-0002');
GO

-- -------------------------------------------------------------------------
-- PASO 5: VERIFICACIÓN FINAL Y LIMPIEZA
-- -------------------------------------------------------------------------
-- 5.1. Comprobamos que las libretas han reaparecido intactas en la BD principal
SELECT EvaluacionID, EstudianteID, Anio, Bimestre, DetalleNotasJSON 
FROM Evaluaciones_Bimestrales 
WHERE EstudianteID IN ('EST-2024-0001', 'EST-2024-0002');
GO

-- 5.2. Eliminamos la base de datos auxiliar para liberar almacenamiento
USE master;
GO

DROP DATABASE ColegioHorizonteDB_Temp;
GO


-- 3. PLAN DE MANTENIMIENTO: REORGANIZACIÓN Y RECONSTRUCCIÓN DE ÍNDICES
-- Recomendado ejecutar periódicamente cuando la base de datos supera los 300k registros

-- Reorganizar índices si la fragmentación es baja-media
ALTER INDEX IX_Asistencias_Fecha_Estado ON Asistencias_Diarias REORGANIZE;

-- Reconstruir índices si la fragmentación es alta
ALTER INDEX ALL ON Asistencias_Diarias REBUILD;
ALTER INDEX ALL ON Evaluaciones_Bimestrales REBUILD;
GO

