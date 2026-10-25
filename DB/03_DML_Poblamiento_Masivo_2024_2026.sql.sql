USE ColegioHorizonteDB;
GO

SET NOCOUNT ON;
GO

-- 1. Insertar Aulas (2024 - 2026)
DECLARE @AnioEval INT = 2024;
WHILE @AnioEval <= 2026
BEGIN
    INSERT INTO Aulas (Anio, Nivel, Grado, Seccion, CodigoAula)
    SELECT @AnioEval, 'PRIMARIA', G.Grado, S.Seccion, 
           CAST(G.Grado AS VARCHAR(1)) + S.Seccion + '-PRI-' + CAST(@AnioEval AS VARCHAR(4))
    FROM (VALUES (1),(2),(3),(4),(5),(6)) AS G(Grado)
    CROSS JOIN (VALUES ('A'),('B'),('C')) AS S(Seccion);

    INSERT INTO Aulas (Anio, Nivel, Grado, Seccion, CodigoAula)
    SELECT @AnioEval, 'SECUNDARIA', G.Grado, S.Seccion, 
           CAST(G.Grado AS VARCHAR(1)) + S.Seccion + '-SEC-' + CAST(@AnioEval AS VARCHAR(4))
    FROM (VALUES (1),(2),(3),(4),(5)) AS G(Grado)
    CROSS JOIN (VALUES ('A'),('B'),('C')) AS S(Seccion);

    SET @AnioEval = @AnioEval + 1;
END;
GO

-- 2. Insertar Usuarios Cifrados
OPEN SYMMETRIC KEY SymKeyColegioHorizonte
DECRYPTED BY CERTIFICATE CertColegioHorizonte;

INSERT INTO Usuarios_Sistema (SQLLoginName, Rol, DNI, NombreCompleto, PasswordCifrado) VALUES
('usr_admin', 'ADMINISTRADOR', '10203040', 'Jhon Ticona (DBA)', ENCRYPTBYKEY(KEY_GUID('SymKeyColegioHorizonte'), N'AdminPass2026!')),
('usr_secre', 'SECRETARIA', '20304050', 'Maria Flores (Secretaria)', ENCRYPTBYKEY(KEY_GUID('SymKeyColegioHorizonte'), N'SecrePass2026!')),
('usr_docente1', 'DOCENTE', '30405060', 'Prof. Carlos Vega', ENCRYPTBYKEY(KEY_GUID('SymKeyColegioHorizonte'), N'DocentePass2026!')),
('usr_docente2', 'DOCENTE', '30405061', 'Profa. Ana Morales', ENCRYPTBYKEY(KEY_GUID('SymKeyColegioHorizonte'), N'DocentePass2026!'));

DECLARE @iPadre INT = 1;
WHILE @iPadre <= 500
BEGIN
    INSERT INTO Usuarios_Sistema (SQLLoginName, Rol, DNI, NombreCompleto, PasswordCifrado)
    VALUES (
        'usr_padre' + CAST(@iPadre AS VARCHAR(5)),
        'PADRE_FAMILIA',
        CAST(40000000 + @iPadre AS VARCHAR(8)),
        'Padre Familia ' + CAST(@iPadre AS VARCHAR(5)),
        ENCRYPTBYKEY(KEY_GUID('SymKeyColegioHorizonte'), N'PadrePass2026!')
    );
    SET @iPadre = @iPadre + 1;
END;

CLOSE SYMMETRIC KEY SymKeyColegioHorizonte;
GO

-- 3. Poblar Estudiantes
DECLARE @Nombres TABLE (ID INT IDENTITY(1,1), Nombre VARCHAR(50));
INSERT INTO @Nombres VALUES ('Mateo'),('Lucia'),('Gabriel'),('Sofia'),('Thiago'),('Camila'),('Santi'),('Valeria'),('Benjamin'),('Ainhoa');

DECLARE @Apellidos TABLE (ID INT IDENTITY(1,1), Apellido VARCHAR(50));
INSERT INTO @Apellidos VALUES ('Quispe'),('Suma'),('Huaman'),('Condori'),('Yabar'),('Mendoza'),('Loaiza'),('Vargas'),('Ccolque'),('Gutierrez');

WITH NumSequence AS (
    SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Seq
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
),
Aulas2024 AS (
    SELECT AulaID, ROW_NUMBER() OVER (ORDER BY AulaID) AS RowNum, COUNT(*) OVER() AS TotalAulas
    FROM Aulas WHERE Anio = 2024
)
INSERT INTO Estudiantes (EstudianteID, DNI, Nombres, Apellidos, FechaNacimiento, AulaID, Estado, DatosMedicosJSON)
SELECT 
    'EST-2024-' + RIGHT('0000' + CAST(S.Seq AS VARCHAR(4)), 4),
    CAST(70000000 + S.Seq AS VARCHAR(8)),
    N.Nombre,
    A1.Apellido + ' ' + A2.Apellido,
    DATEADD(DAY, - (365 * 10 + (S.Seq % 1000)), '2024-01-01'),
    Au.AulaID,
    'ACTIVO',
    CASE (S.Seq % 3)
        WHEN 0 THEN '{"grupo_sanguineo": "O+", "alergias": ["Penicilina"]}'
        WHEN 1 THEN '{"grupo_sanguineo": "A+", "alergias": []}'
        ELSE '{"grupo_sanguineo": "O-", "alergias": ["Polen", "Polvo"]}'
    END
FROM NumSequence S
CROSS JOIN @Nombres N
CROSS JOIN @Apellidos A1
CROSS JOIN @Apellidos A2
INNER JOIN Aulas2024 Au ON Au.RowNum = ((S.Seq % Au.TotalAulas) + 1)
WHERE N.ID = (S.Seq % 10) + 1 
  AND A1.ID = (S.Seq % 10) + 1 
  AND A2.ID = ((S.Seq + 3) % 10) + 1;
GO

-- 4. Vincular Apoderados
INSERT INTO Vinculos_Familiares (ApoderadoUsuarioID, EstudianteID, Parentesco)
SELECT 
    U.UsuarioID,
    E.EstudianteID,
    CASE WHEN U.UsuarioID % 2 = 0 THEN 'PADRE' ELSE 'MADRE' END
FROM Estudiantes E
INNER JOIN Usuarios_Sistema U ON U.UsuarioID = ((CAST(RIGHT(E.EstudianteID,4) AS INT) % 500) + 5);
GO

-- 5. Asistencias Diarias (Marzo 2024 a Abril 2026, filtrando feriado de Cusco)
CREATE TABLE #DiasLectivos (Fecha DATE);
DECLARE @FechaInicio DATE = '2024-03-01';
DECLARE @FechaFin DATE = GETDATE();

WHILE @FechaInicio <= @FechaFin
BEGIN
    IF DATEPART(WEEKDAY, @FechaInicio) NOT IN (1, 7) 
       AND NOT (MONTH(@FechaInicio) = 6 AND DAY(@FechaInicio) = 24)
       AND NOT (MONTH(@FechaInicio) IN (1, 2))
    BEGIN
        INSERT INTO #DiasLectivos VALUES (@FechaInicio);
    END
    SET @FechaInicio = DATEADD(DAY, 1, @FechaInicio);
END;

INSERT INTO Asistencias_Diarias (EstudianteID, Fecha, EstadoAsistencia, Observacion)
SELECT 
    E.EstudianteID,
    D.Fecha,
    CASE 
        WHEN (CHECKSUM(NEWID()) % 100) < 85 THEN 'P'
        WHEN (CHECKSUM(NEWID()) % 100) BETWEEN 85 AND 94 THEN 'T'
        ELSE 'F'
    END,
    CASE 
        WHEN (CHECKSUM(NEWID()) % 100) >= 95 THEN 'Falta injustificada'
        WHEN (CHECKSUM(NEWID()) % 100) BETWEEN 85 AND 94 THEN 'Ingresó con retraso'
        ELSE 'Asistencia normal'
    END
FROM Estudiantes E
CROSS JOIN #DiasLectivos D;

DROP TABLE #DiasLectivos;
GO

-- 6. Evaluaciones Bimestrales (JSON)
DECLARE @AnioNota INT = 2024;
DECLARE @Bimestre INT;

WHILE @AnioNota <= 2026
BEGIN
    SET @Bimestre = 1;
    WHILE @Bimestre <= 4
    BEGIN
        IF @AnioNota = 2026 AND @Bimestre > 1 BREAK;

        INSERT INTO Evaluaciones_Bimestrales (EstudianteID, Anio, Bimestre, DetalleNotasJSON)
        SELECT 
            E.EstudianteID,
            @AnioNota,
            @Bimestre,
            N'{
              "cursos": [
                {
                  "materia": "Matemática",
                  "docente": "Prof. Carlos Vega",
                  "competencias": [
                    { "codigo": "C1", "nombre": "Resuelve problemas de cantidad", "calificacion": "' + 
                    CASE WHEN CHECKSUM(NEWID())%4=0 THEN 'AD' WHEN CHECKSUM(NEWID())%4=1 THEN 'A' WHEN CHECKSUM(NEWID())%4=2 THEN 'B' ELSE 'C' END + '" },
                    { "codigo": "C2", "nombre": "Resuelve problemas de forma y movimiento", "calificacion": "' + 
                    CASE WHEN CHECKSUM(NEWID())%4=0 THEN 'AD' WHEN CHECKSUM(NEWID())%4=1 THEN 'A' WHEN CHECKSUM(NEWID())%4=2 THEN 'B' ELSE 'C' END + '" }
                  ]
                },
                {
                  "materia": "Comunicación",
                  "docente": "Profa. Ana Morales",
                  "competencias": [
                    { "codigo": "C1", "nombre": "Lee diversos tipos de textos escritos", "calificacion": "' + 
                    CASE WHEN CHECKSUM(NEWID())%4=0 THEN 'AD' WHEN CHECKSUM(NEWID())%4=1 THEN 'A' WHEN CHECKSUM(NEWID())%4=2 THEN 'B' ELSE 'C' END + '" }
                  ]
                }
              ]
            }'
        FROM Estudiantes E;

        SET @Bimestre = @Bimestre + 1;
    END;
    SET @AnioNota = @AnioNota + 1;
END;
GO