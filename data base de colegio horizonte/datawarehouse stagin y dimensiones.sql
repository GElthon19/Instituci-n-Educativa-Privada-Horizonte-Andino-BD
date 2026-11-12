CREATE DATABASE ColegioNH_DW;
GO

USE ColegioNH_DW;
GO

-- ==========================================
-- 1. STAGING AREA (Tablas Temporales de Carga)
-- ==========================================
CREATE TABLE stg_estudiantes (
    id_estudiante INT,
    documento_identidad VARCHAR(20),
    nombre_completo VARCHAR(200),
    genero CHAR(1),
    id_padre INT,
    nombre_padre VARCHAR(200),
    telefono_padre VARCHAR(20)
);

CREATE TABLE stg_aulas (
    id_aula INT,
    nivel VARCHAR(50),
    grado VARCHAR(50),
    seccion CHAR(1)
);

CREATE TABLE stg_cursos (
    id_curso INT,
    nombre_curso VARCHAR(100),
    id_docente INT,
    nombre_docente VARCHAR(200)
);

-- ==========================================
-- 2. TABLAS DIMENSIONALES (Modelo OLAP)
-- ==========================================

-- Dimensión Periodo Trimestral
CREATE TABLE dim_periodo (
    sk_periodo INT IDENTITY(1,1) PRIMARY KEY,
    id_periodo_bk INT NOT NULL,
    anio_lectivo INT NOT NULL,
    trimestre INT NOT NULL,
    nombre_trimestre VARCHAR(50) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado VARCHAR(20) NOT NULL
);

-- Dimensión Estudiante (Con datos del Apoderado)
CREATE TABLE dim_estudiante (
    sk_estudiante INT IDENTITY(1,1) PRIMARY KEY,
    id_estudiante_bk INT NOT NULL,
    documento_identidad VARCHAR(20) NOT NULL,
    nombre_estudiante VARCHAR(200) NOT NULL,
    genero CHAR(1) NOT NULL,
    nombre_apoderado VARCHAR(200) NOT NULL,
    telefono_apoderado VARCHAR(20)
);

-- Dimensión Aula
CREATE TABLE dim_aula (
    sk_aula INT IDENTITY(1,1) PRIMARY KEY,
    id_aula_bk INT NOT NULL,
    nivel VARCHAR(50) NOT NULL,
    grado VARCHAR(50) NOT NULL,
    seccion CHAR(1) NOT NULL
);

-- Dimensión Curso y Docente
CREATE TABLE dim_curso (
    sk_curso INT IDENTITY(1,1) PRIMARY KEY,
    id_curso_bk INT NOT NULL,
    nombre_curso VARCHAR(100) NOT NULL,
    nombre_docente VARCHAR(200) NOT NULL
);