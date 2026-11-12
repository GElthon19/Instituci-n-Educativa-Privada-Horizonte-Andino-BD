-- 1. Ejecutar el Pipeline ETL
EXEC ColegioNH_DW.dbo.sp_Ejecutar_ETL_Libretas_Estudiantes;
GO

-- 2. Consultar las primeras 10 Libretas Trimestrales del Data Warehouse
SELECT TOP 100 
    DNI_Alumno, 
    Estudiante, 
    Grado, 
    Seccion, 
    Asignatura, 
    Nota_Final, 
    Condicion, 
    Asistencias, 
    Tardanzas, 
    Faltas_Injustificadas
FROM ColegioNH_DW.dbo.vw_impresion_libreta
WHERE Num_Trimestre = 1
ORDER BY Estudiante, Asignatura;