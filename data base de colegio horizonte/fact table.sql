USE ColegioNH_DW;
GO

CREATE TABLE fact_libreta_estudiante (
    sk_fact BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Claves Foráneas a Dimensiones (Esquema Estrella)
    sk_estudiante INT NOT NULL,
    sk_aula INT NOT NULL,
    sk_curso INT NOT NULL,
    sk_periodo INT NOT NULL,
    
    -- Clave Degenerada OLTP
    id_matricula_bk INT NOT NULL,
    
    -- Métricas Académicas Individuales
    promedio_trimestre DECIMAL(4,2) NOT NULL,
    condicion_materia VARCHAR(20) NOT NULL, -- 'Aprobado', 'Desaprobado', 'En Proceso'
    
    -- Acumulado Individual de Asistencia en el Trimestre
    dias_asistidos INT DEFAULT 0,
    tardanzas INT DEFAULT 0,
    faltas_injustificadas INT DEFAULT 0,
    faltas_justificadas INT DEFAULT 0,
    
    CONSTRAINT FK_Fact_Estudiante FOREIGN KEY (sk_estudiante) REFERENCES dim_estudiante(sk_estudiante),
    CONSTRAINT FK_Fact_Aula FOREIGN KEY (sk_aula) REFERENCES dim_aula(sk_aula),
    CONSTRAINT FK_Fact_Curso FOREIGN KEY (sk_curso) REFERENCES dim_curso(sk_curso),
    CONSTRAINT FK_Fact_Periodo FOREIGN KEY (sk_periodo) REFERENCES dim_periodo(sk_periodo)
);