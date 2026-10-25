USE ColegioHorizonteDB;
GO

-- 1. Reporte Consolidado de Asistencias por Estudiante
SELECT 
    E.EstudianteID,
    E.Apellidos + ', ' + E.Nombres AS Estudiante,
    A.CodigoAula,
    SUM(CASE WHEN AD.EstadoAsistencia = 'P' THEN 1 ELSE 0 END) AS Total_Presente,
    SUM(CASE WHEN AD.EstadoAsistencia = 'T' THEN 1 ELSE 0 END) AS Total_Tardanzas,
    SUM(CASE WHEN AD.EstadoAsistencia = 'F' THEN 1 ELSE 0 END) AS Total_Faltas
FROM Estudiantes E
INNER JOIN Aulas A ON E.AulaID = A.AulaID
INNER JOIN Asistencias_Diarias AD ON E.EstudianteID = AD.EstudianteID
GROUP BY E.EstudianteID, E.Apellidos, E.Nombres, A.CodigoAula;

-- 2. Descrifrado de Contraseñas (Prueba de Seguridad)
OPEN SYMMETRIC KEY SymKeyColegioHorizonte
DECRYPTED BY CERTIFICATE CertColegioHorizonte;

SELECT 
    SQLLoginName,
    Rol,
    NombreCompleto,
    CONVERT(NVARCHAR(100), DECRYPTBYKEY(PasswordCifrado)) AS PasswordDescifrado
FROM Usuarios_Sistema;

CLOSE SYMMETRIC KEY SymKeyColegioHorizonte;

-- 3. Extracción de Notas desde el campo JSON
SELECT 
    E.EstudianteID,
    E.Apellidos + ', ' + E.Nombres AS Estudiante,
    EB.Anio,
    EB.Bimestre,
    JSON_VALUE(EB.DetalleNotasJSON, '$.cursos[0].materia') AS Materia,
    JSON_VALUE(EB.DetalleNotasJSON, '$.cursos[0].competencias[0].calificacion') AS Calificacion_C1
FROM Evaluaciones_Bimestrales EB
INNER JOIN Estudiantes E ON EB.EstudianteID = E.EstudianteID;
GO