-- Crear Base de Datos
CREATE DATABASE ColegioNuevoHorizonte;
GO

USE ColegioNuevoHorizonte;
GO

-- 1. Periodo Académico (Trimestral)
CREATE TABLE periodos_academicos (
    id_periodo INT IDENTITY(1,1) PRIMARY KEY,
    anio_lectivo INT NOT NULL,
    trimestre INT CHECK (trimestre IN (1, 2, 3)),
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) DEFAULT 'Activo' CHECK (estado IN ('Activo', 'Cerrado', 'Planificado'))
);

-- 2. Personal Administrativo
CREATE TABLE administracion (
    id_personal INT IDENTITY(1,1) PRIMARY KEY,
    documento_identidad VARCHAR(20) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cargo VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    fecha_contratacion DATE DEFAULT GETDATE()
);

-- 3. Docentes
CREATE TABLE docentes (
    id_docente INT IDENTITY(1,1) PRIMARY KEY,
    documento_identidad VARCHAR(20) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    especialidad VARCHAR(100),
    email VARCHAR(100) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    estado VARCHAR(20) DEFAULT 'Activo'
);

-- 4. Padres de Familia / Tutores
CREATE TABLE padres_familia (
    id_padre INT IDENTITY(1,1) PRIMARY KEY,
    documento_identidad VARCHAR(20) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    parentesco VARCHAR(50) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    direccion VARCHAR(MAX) NOT NULL
);

-- 5. Estudiantes
CREATE TABLE estudiantes (
    id_estudiante INT IDENTITY(1,1) PRIMARY KEY,
    documento_identidad VARCHAR(20) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero CHAR(1) CHECK (genero IN ('M', 'F')),
    direccion VARCHAR(MAX),
    id_padre INT NOT NULL,
    CONSTRAINT FK_Estudiantes_Padres FOREIGN KEY (id_padre) 
        REFERENCES padres_familia(id_padre)
);

-- 6. Aulas, Grado y Sección
CREATE TABLE aulas (
    id_aula INT IDENTITY(1,1) PRIMARY KEY,
    nivel VARCHAR(50) NOT NULL,
    grado VARCHAR(50) NOT NULL,
    seccion CHAR(1) NOT NULL,
    vacantes_maximas INT DEFAULT 30,
    CONSTRAINT UQ_Grado_Seccion UNIQUE (nivel, grado, seccion)
);

-- 7. Cursos / Asignaturas
CREATE TABLE cursos (
    id_curso INT IDENTITY(1,1) PRIMARY KEY,
    nombre_curso VARCHAR(100) NOT NULL,
    id_aula INT NOT NULL,
    id_docente INT NOT NULL,
    CONSTRAINT FK_Cursos_Aulas FOREIGN KEY (id_aula) REFERENCES aulas(id_aula),
    CONSTRAINT FK_Cursos_Docentes FOREIGN KEY (id_docente) REFERENCES docentes(id_docente)
);

-- 8. Matrícula
CREATE TABLE matriculas (
    id_matricula INT IDENTITY(1,1) PRIMARY KEY,
    codigo_matricula VARCHAR(20) NOT NULL UNIQUE,
    id_estudiante INT NOT NULL,
    id_aula INT NOT NULL,
    id_periodo INT NOT NULL,
    fecha_matricula DATE DEFAULT GETDATE(),
    estado VARCHAR(20) DEFAULT 'Matriculado' CHECK (estado IN ('Matriculado', 'Retirado', 'Pendiente')),
    CONSTRAINT FK_Matriculas_Estudiantes FOREIGN KEY (id_estudiante) REFERENCES estudiantes(id_estudiante),
    CONSTRAINT FK_Matriculas_Aulas FOREIGN KEY (id_aula) REFERENCES aulas(id_aula),
    CONSTRAINT FK_Matriculas_Periodos FOREIGN KEY (id_periodo) REFERENCES periodos_academicos(id_periodo)
);

-- 9. Pagos
CREATE TABLE pagos (
    id_pago INT IDENTITY(1,1) PRIMARY KEY,
    id_matricula INT NOT NULL,
    id_personal_admin INT NOT NULL,
    concepto VARCHAR(100) NOT NULL,
    monto DECIMAL(10, 2) NOT NULL,
    fecha_pago DATETIME2 DEFAULT GETDATE(),
    metodo_pago VARCHAR(50) NOT NULL,
    estado_pago VARCHAR(20) DEFAULT 'Completado' CHECK (estado_pago IN ('Completado', 'Pendiente', 'Anulado')),
    CONSTRAINT FK_Pagos_Matriculas FOREIGN KEY (id_matricula) REFERENCES matriculas(id_matricula),
    CONSTRAINT FK_Pagos_Admin FOREIGN KEY (id_personal_admin) REFERENCES administracion(id_personal)
);

-- Criterios de Evaluación / Competencias
-- Permite desglosar las notas de un curso (ej. Exámenes 40%, Tareas 30%, etc.)
CREATE TABLE criterios_evaluacion (
    id_criterio INT IDENTITY(1,1) PRIMARY KEY,
    id_curso INT NOT NULL,
    nombre_criterio VARCHAR(100) NOT NULL, -- Ej. Examen Trimestral, Trabajos Prácticos
    porcentaje DECIMAL(5,2) DEFAULT 0.00,  -- Ej. 30.00 para 30%
    CONSTRAINT FK_Criterios_Cursos FOREIGN KEY (id_curso) REFERENCES cursos(id_curso)
);

-- Calificaciones (Notas detalladas por criterio y trimestre)
CREATE TABLE calificaciones (
    id_calificacion INT IDENTITY(1,1) PRIMARY KEY,
    id_matricula INT NOT NULL,
    id_curso INT NOT NULL,
    id_periodo INT NOT NULL,
    id_criterio INT NOT NULL,
    nota DECIMAL(4,2) NOT NULL CHECK (nota BETWEEN 0.00 AND 20.00), -- Escala vigesimal 0-20
    observacion VARCHAR(255),
    fecha_registro DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT FK_Calificaciones_Matriculas FOREIGN KEY (id_matricula) REFERENCES matriculas(id_matricula),
    CONSTRAINT FK_Calificaciones_Cursos FOREIGN KEY (id_curso) REFERENCES cursos(id_curso),
    CONSTRAINT FK_Calificaciones_Periodos FOREIGN KEY (id_periodo) REFERENCES periodos_academicos(id_periodo),
    CONSTRAINT FK_Calificaciones_Criterios FOREIGN KEY (id_criterio) REFERENCES criterios_evaluacion(id_criterio)
);

-- Promedios Trimestrales (Consolidado para Libretas de Notas)
CREATE TABLE promedios_trimestrales (
    id_promedio INT IDENTITY(1,1) PRIMARY KEY,
    id_matricula INT NOT NULL,
    id_curso INT NOT NULL,
    id_periodo INT NOT NULL,
    promedio_trimestre DECIMAL(4,2) NOT NULL CHECK (promedio_trimestre BETWEEN 0.00 AND 20.00),
    condicion VARCHAR(20) CHECK (condicion IN ('Aprobado', 'Desaprobado', 'En Proceso')),
    CONSTRAINT UQ_Promedio_Estudiante_Curso_Periodo UNIQUE (id_matricula, id_curso, id_periodo),
    CONSTRAINT FK_Promedios_Matriculas FOREIGN KEY (id_matricula) REFERENCES matriculas(id_matricula),
    CONSTRAINT FK_Promedios_Cursos FOREIGN KEY (id_curso) REFERENCES cursos(id_curso),
    CONSTRAINT FK_Promedios_Periodos FOREIGN KEY (id_periodo) REFERENCES periodos_academicos(id_periodo)
);

-- Registro de Asistencias
CREATE TABLE asistencias (
    id_asistencia INT IDENTITY(1,1) PRIMARY KEY,
    id_matricula INT NOT NULL,
    id_curso INT NOT NULL,
    fecha DATE NOT NULL DEFAULT GETDATE(),
    estado_asistencia VARCHAR(20) NOT NULL CHECK (estado_asistencia IN ('Asistio', 'Falta', 'Tardanza', 'Justificado')),
    justificacion VARCHAR(MAX) NULL,
    CONSTRAINT UQ_Asistencia_Diaria UNIQUE (id_matricula, id_curso, fecha),
    CONSTRAINT FK_Asistencias_Matriculas FOREIGN KEY (id_matricula) REFERENCES matriculas(id_matricula),
    CONSTRAINT FK_Asistencias_Cursos FOREIGN KEY (id_curso) REFERENCES cursos(id_curso)
);