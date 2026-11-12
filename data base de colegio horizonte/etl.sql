USE ColegioNH_DW;
GO

CREATE OR ALTER PROCEDURE sp_Ejecutar_ETL_Libretas_Estudiantes
AS
BEGIN
    SET NOCOUNT ON;

    -- ==========================================
    -- 1. LIMPIEZA DE STAGING
    -- ==========================================
    TRUNCATE TABLE stg_estudiantes;
    TRUNCATE TABLE stg_aulas;
    TRUNCATE TABLE stg_cursos;

    -- ==========================================
    -- 2. EXTRACCIÓN A STAGING AREA
    -- ==========================================
    INSERT INTO stg_estudiantes
    SELECT 
        e.id_estudiante,
        e.documento_identidad,
        CONCAT(e.apellidos, ', ', e.nombres),
        e.genero,
        p.id_padre,
        CONCAT(p.apellidos, ', ', p.nombres),
        p.telefono
    FROM ColegioNuevoHorizonte.dbo.estudiantes e
    INNER JOIN ColegioNuevoHorizonte.dbo.padres_familia p ON e.id_padre = p.id_padre;

    INSERT INTO stg_aulas
    SELECT id_aula, nivel, grado, seccion 
    FROM ColegioNuevoHorizonte.dbo.aulas;

    INSERT INTO stg_cursos
    SELECT 
        c.id_curso,
        c.nombre_curso,
        d.id_docente,
        CONCAT(d.apellidos, ', ', d.nombres)
    FROM ColegioNuevoHorizonte.dbo.cursos c
    INNER JOIN ColegioNuevoHorizonte.dbo.docentes d ON c.id_docente = d.id_docente;

    -- ==========================================
    -- 3. CARGA DE DIMENSIONES (UPSERT / MERGE)
    -- ==========================================
    MERGE dim_periodo AS T
    USING (
        SELECT id_periodo, anio_lectivo, trimestre, 
               CONCAT(trimestre, '° Trimestre ', anio_lectivo) AS nombre_trimestre,
               fecha_inicio, fecha_fin, estado
        FROM ColegioNuevoHorizonte.dbo.periodos_academicos
    ) AS S ON T.id_periodo_bk = S.id_periodo
    WHEN NOT MATCHED THEN
        INSERT (id_periodo_bk, anio_lectivo, trimestre, nombre_trimestre, fecha_inicio, fecha_fin, estado)
        VALUES (S.id_periodo, S.anio_lectivo, S.trimestre, S.nombre_trimestre, S.fecha_inicio, S.fecha_fin, S.estado);

    MERGE dim_estudiante AS T
    USING stg_estudiantes AS S
    ON T.id_estudiante_bk = S.id_estudiante
    WHEN NOT MATCHED THEN
        INSERT (id_estudiante_bk, documento_identidad, nombre_estudiante, genero, nombre_apoderado, telefono_apoderado)
        VALUES (S.id_estudiante, S.documento_identidad, S.nombre_completo, S.genero, S.nombre_padre, S.telefono_padre);

    MERGE dim_aula AS T
    USING stg_aulas AS S
    ON T.id_aula_bk = S.id_aula
    WHEN NOT MATCHED THEN
        INSERT (id_aula_bk, nivel, grado, seccion)
        VALUES (S.id_aula, S.nivel, S.grado, S.seccion);

    MERGE dim_curso AS T
    USING stg_cursos AS S
    ON T.id_curso_bk = S.id_curso
    WHEN NOT MATCHED THEN
        INSERT (id_curso_bk, nombre_curso, nombre_docente)
        VALUES (S.id_curso, S.nombre_curso, S.nombre_docente);

    -- ==========================================
    -- 4. CARGA DE LA FACT TABLE (LIBRETAS INDIVIDUALES)
    -- ==========================================
    TRUNCATE TABLE fact_libreta_estudiante;

    INSERT INTO fact_libreta_estudiante (
        sk_estudiante, sk_aula, sk_curso, sk_periodo, id_matricula_bk,
        promedio_trimestre, condicion_materia,
        dias_asistidos, tardanzas, faltas_injustificadas, faltas_justificadas
    )
    SELECT 
        de.sk_estudiante,
        da.sk_aula,
        dc.sk_curso,
        dp.sk_periodo,
        m.id_matricula,
        ISNULL(pt.promedio_trimestre, 0.00),
        ISNULL(pt.condicion, 'Sin Calificar'),
        
        -- Conteo de asistencias por alumno dentro de las fechas del trimestre
        COUNT(CASE WHEN asi.estado_asistencia = 'Asistio' THEN 1 END),
        COUNT(CASE WHEN asi.estado_asistencia = 'Tardanza' THEN 1 END),
        COUNT(CASE WHEN asi.estado_asistencia = 'Falta' THEN 1 END),
        COUNT(CASE WHEN asi.estado_asistencia = 'Justificado' THEN 1 END)

    FROM ColegioNuevoHorizonte.dbo.matriculas m
    INNER JOIN ColegioNuevoHorizonte.dbo.periodos_academicos p ON m.id_periodo = p.id_periodo
    INNER JOIN ColegioNuevoHorizonte.dbo.cursos c ON c.id_aula = m.id_aula
    INNER JOIN dim_estudiante de ON de.id_estudiante_bk = m.id_estudiante
    INNER JOIN dim_aula da ON da.id_aula_bk = m.id_aula
    INNER JOIN dim_curso dc ON dc.id_curso_bk = c.id_curso
    INNER JOIN dim_periodo dp ON dp.id_periodo_bk = p.id_periodo
    LEFT JOIN ColegioNuevoHorizonte.dbo.promedios_trimestrales pt 
        ON pt.id_matricula = m.id_matricula AND pt.id_curso = c.id_curso AND pt.id_periodo = p.id_periodo
    LEFT JOIN ColegioNuevoHorizonte.dbo.asistencias asi 
        ON asi.id_matricula = m.id_matricula AND asi.id_curso = c.id_curso AND asi.fecha BETWEEN p.fecha_inicio AND p.fecha_fin

    GROUP BY 
        de.sk_estudiante, da.sk_aula, dc.sk_curso, dp.sk_periodo, m.id_matricula, pt.promedio_trimestre, pt.condicion;

    PRINT 'ETL de Libretas por Estudiante ejecutado con éxito.';
END;
GO

-- Invocación del Pipeline ETL
EXEC sp_Ejecutar_ETL_Libretas_Estudiantes;
GO