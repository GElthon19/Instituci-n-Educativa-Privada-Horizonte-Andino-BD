USE ColegioNuevoHorizonte;
GO

-- 1. Periodo Académico (Trimestral - Año Lectivo 2026)
INSERT INTO periodos_academicos (anio_lectivo, trimestre, fecha_inicio, fecha_fin, estado)
VALUES 
(2026, 1, '2026-03-02', '2026-05-29', 'Activo'),
(2026, 2, '2026-06-01', '2026-08-31', 'Planificado'),
(2026, 3, '2026-09-01', '2026-11-30', 'Planificado');

-- 2. Personal Administrativo
INSERT INTO administracion (documento_identidad, nombres, apellidos, cargo, email, telefono)
VALUES 
('10203040', 'Rosa Elvira', 'Campos Vargas', 'Secretaria Académica', 'rcampos@nuevohorizonte.edu.pe', '987654321'),
('10203041', 'Carlos Alberto', 'Mendoza Ríos', 'Tesorero / Contador', 'cmendoza@nuevohorizonte.edu.pe', '987654322');

-- 3. Docentes
INSERT INTO docentes (documento_identidad, nombres, apellidos, especialidad, email, telefono, estado)
VALUES 
('20304050', 'Roberto', 'Gómez Bolaños', 'Matemáticas y Física', 'rgomez@nuevohorizonte.edu.pe', '912345678', 'Activo'),
('20304051', 'María Luisa', 'Valdez Soto', 'Lengua y Literatura', 'mvaldez@nuevohorizonte.edu.pe', '912345679', 'Activo');

-- 4. Padres de Familia / Tutores
INSERT INTO padres_familia (documento_identidad, nombres, apellidos, parentesco, telefono, email, direccion)
VALUES 
('30405060', 'Fernando', 'Torres Benítez', 'Padre', '955443322', 'ftorres@gmail.com', 'Av. El Sol 456, Cusco'),
('30405061', 'Patricia', 'Quispe Huamán', 'Madre', '955443323', 'pquispe@gmail.com', 'Calle Nueva 123, Cusco');

-- 5. Estudiantes
INSERT INTO estudiantes (documento_identidad, nombres, apellidos, fecha_nacimiento, genero, direccion, id_padre)
VALUES 
('70809001', 'Mateo', 'Torres Quispe', '2012-05-14', 'M', 'Av. El Sol 456, Cusco', 1),
('70809002', 'Sofia', 'Torres Quispe', '2014-08-22', 'F', 'Av. El Sol 456, Cusco', 1);

-- 6. Aulas, Grado y Sección
INSERT INTO aulas (nivel, grado, seccion, vacantes_maximas)
VALUES 
('Secundaria', '1° Secundaria', 'A', 30),
('Secundaria', '2° Secundaria', 'A', 30);

-- 7. Cursos / Asignaturas
INSERT INTO cursos (nombre_curso, id_aula, id_docente)
VALUES 
('Matemáticas I', 1, 1),    -- 1° Sec - Prof. Roberto Gómez
('Comunicación I', 1, 2);   -- 1° Sec - Prof. María Valdez

-- 8. Matrícula (Se matricula a Mateo Torres en 1° Secundaria - Trimestre 1 2026)
INSERT INTO matriculas (codigo_matricula, id_estudiante, id_aula, id_periodo, fecha_matricula, estado)
VALUES 
('MAT-2026-001', 1, 1, 1, '2026-02-15', 'Matriculado');

-- 9. Pagos (Procesados por la administración)
INSERT INTO pagos (id_matricula, id_personal_admin, concepto, monto, metodo_pago, estado_pago)
VALUES 
(1, 2, 'Cuota de Matrícula 2026', 350.00, 'Transferencia', 'Completado'),
(1, 2, 'Pensión Marzo 2026', 450.00, 'Efectivo', 'Completado');

-- 10. Criterios de Evaluación / Competencias (Para Matemáticas I)
INSERT INTO criterios_evaluacion (id_curso, nombre_criterio, porcentaje)
VALUES 
(1, 'Examen Parcial', 40.00),
(1, 'Prácticas Calificadas', 30.00),
(1, 'Tareas y Trabajos', 30.00);

-- 11. Calificaciones (Notas registradas para Mateo Torres en Matemáticas I)
INSERT INTO calificaciones (id_matricula, id_curso, id_periodo, id_criterio, nota, observacion)
VALUES 
(1, 1, 1, 1, 16.50, 'Buen desempeño en el examen'),
(1, 1, 1, 2, 14.00, 'Faltó resolver un ejercicio'),
(1, 1, 1, 3, 18.00, 'Entregó a tiempo todas las tareas');

-- 12. Promedios Trimestrales (Calculado del deslose de notas)
INSERT INTO promedios_trimestrales (id_matricula, id_curso, id_periodo, promedio_trimestre, condicion)
VALUES 
(1, 1, 1, 16.20, 'Aprobado');

-- 13. Registro de Asistencias (Asistencias diarias del alumno en Matemáticas I)
INSERT INTO asistencias (id_matricula, id_curso, fecha, estado_asistencia, justificacion)
VALUES 
(1, 1, '2026-03-02', 'Asistio', NULL),
(1, 1, '2026-03-03', 'Tardanza', 'Tráfico en la avenida principal'),
(1, 1, '2026-03-04', 'Falta', 'Cita médica reprogramada'),
(1, 1, '2026-03-05', 'Asistio', NULL);