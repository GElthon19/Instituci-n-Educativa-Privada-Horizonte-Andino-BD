USE ColegioHorizonteDB;
GO

-- =========================================================================
-- A. OPERACIONES SELECT (Consultas de lectura para auditar)
-- =========================================================================

-- 1. Ver datos estructurados de Estudiantes junto a sus datos médicos en JSON
SELECT EstudianteID, DNI, Nombres, Apellidos,
       JSON_VALUE(DatosMedicosJSON, '$.grupo_sanguineo') AS GrupoSanguineo
FROM Estudiantes
WHERE JSON_VALUE(DatosMedicosJSON, '$.grupo_sanguineo') = 'O+';

-- 2. Alumnos con más de 2 faltas injustificadas
SELECT EstudianteID, COUNT(*) AS TotalFaltas
FROM Asistencias_Diarias
WHERE EstadoAsistencia = 'F'
GROUP BY EstudianteID
HAVING COUNT(*) > 2;

-- 3. Revisar datos de las evaluaciones bimestrales cifradas/estructuradas
SELECT EstudianteID, Anio, Bimestre,
       JSON_QUERY(DetalleNotasJSON, '$.cursos') AS CursosEvaluados
FROM Evaluaciones_Bimestrales
WHERE Anio = 2024 AND Bimestre = 1;
GO


-- =========================================================================
-- B. OPERACIONES UPDATE (Modificaciones para auditar)
-- =========================================================================

-- 1. Modificar el estado de estudiantes asignados a un aula específica
UPDATE Estudiantes
SET Estado = 'TRASLADADO'
WHERE AulaID = 1 AND EstudianteID LIKE '%001%';

-- 2. Corregir una observación de asistencia masiva por un error de carga
UPDATE Asistencias_Diarias
SET Observacion = 'Asistencia regularizada por dirección'
WHERE Fecha = '2024-03-05' AND EstadoAsistencia = 'T';
GO


-- =========================================================================
-- C. OPERACIONES DELETE (Eliminaciones para auditar)
-- =========================================================================

-- 1. Limpieza de asistencias de pruebas o duplicadas ficticias
DELETE FROM Asistencias_Diarias
WHERE Fecha = '2024-03-01' AND EstadoAsistencia = 'F' AND EstudianteID LIKE '%009%';

-- 2. Quitar un vínculo familiar de prueba
DELETE FROM Vinculos_Familiares
WHERE VinculoID = 5;
GO
