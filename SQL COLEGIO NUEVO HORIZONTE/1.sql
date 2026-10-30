-- creación de base de datos
CREATE DATABASE ColegioHorizonteDB;
GO
USE ColegioHorizonteDB;
GO


-- 1. Tabla Aulas (Primaria y Secundaria)
CREATE TABLE Aulas (
    AulaID INT IDENTITY(1,1) PRIMARY KEY,
    Anio INT NOT NULL,
    Nivel VARCHAR(20) NOT NULL CHECK (Nivel IN ('PRIMARIA', 'SECUNDARIA')),
    Grado INT NOT NULL,
    Seccion CHAR(1) NOT NULL,
    CodigoAula VARCHAR(20) UNIQUE NOT NULL
);
GO

-- 2. Tabla Usuarios del Sistema (Credenciales Cifradas)
CREATE TABLE Usuarios_Sistema (
    UsuarioID INT IDENTITY(1,1) PRIMARY KEY,
    SQLLoginName VARCHAR(50) NOT NULL,
    Rol VARCHAR(30) NOT NULL CHECK (Rol IN ('ADMINISTRADOR', 'SECRETARIA', 'DOCENTE', 'PADRE_FAMILIA')),
    DNI CHAR(8) UNIQUE NOT NULL,
    NombreCompleto VARCHAR(100) NOT NULL,
    PasswordCifrado VARBINARY(MAX) NOT NULL
);
GO

-- 3. Tabla Estudiantes (PK Estándar 'EstudianteID')
CREATE TABLE Estudiantes (
    EstudianteID VARCHAR(20) PRIMARY KEY, -- Ej: 'EST-2024-0001'
    DNI CHAR(8) UNIQUE NOT NULL,
    Nombres VARCHAR(50) NOT NULL,
    Apellidos VARCHAR(50) NOT NULL,
    FechaNacimiento DATE NOT NULL,
    AulaID INT FOREIGN KEY REFERENCES Aulas(AulaID),
    Estado VARCHAR(15) DEFAULT 'ACTIVO' CHECK (Estado IN ('ACTIVO', 'INACTIVO', 'TRASLADADO')),
    DatosMedicosJSON NVARCHAR(MAX)CHECK (DatosMedicosJSON IS NULL OR ISJSON(DatosMedicosJSON) = 1)
);
GO

-- 4. Tabla Vínculos Familiares
CREATE TABLE Vinculos_Familiares (
    VinculoID INT IDENTITY(1,1) PRIMARY KEY,
    ApoderadoUsuarioID INT FOREIGN KEY REFERENCES Usuarios_Sistema(UsuarioID),
    EstudianteID VARCHAR(20) FOREIGN KEY REFERENCES Estudiantes(EstudianteID),
    Parentesco VARCHAR(20) CHECK (Parentesco IN ('PADRE', 'MADRE', 'APODERADO_LEGAL'))
);
GO

-- 5. Tabla Asistencias Diarias (Filtro por Fecha Exacta y Restricción Unívoca)
CREATE TABLE Asistencias_Diarias (
    AsistenciaID BIGINT IDENTITY(1,1) PRIMARY KEY,
    EstudianteID VARCHAR(20) FOREIGN KEY REFERENCES Estudiantes(EstudianteID),
    Fecha DATE NOT NULL,
    EstadoAsistencia CHAR(1) NOT NULL CHECK (EstadoAsistencia IN ('P', 'T', 'F')),
    Observacion VARCHAR(150),
    CONSTRAINT UQ_Estudiante_Fecha UNIQUE (EstudianteID, Fecha)
);
GO

-- 6. Tabla Evaluaciones Bimestrales (JSON)
CREATE TABLE Evaluaciones_Bimestrales (
    EvaluacionID INT IDENTITY(1,1) PRIMARY KEY,
    EstudianteID VARCHAR(20) FOREIGN KEY REFERENCES Estudiantes(EstudianteID),
    Anio INT NOT NULL,
    Bimestre INT CHECK (Bimestre BETWEEN 1 AND 4),
    DetalleNotasJSON NVARCHAR(MAX) NOT NULL CHECK (ISJSON(DetalleNotasJSON) = 1),
    CONSTRAINT UQ_Estudiante_Bimestre UNIQUE (EstudianteID, Anio, Bimestre)
);
GO
