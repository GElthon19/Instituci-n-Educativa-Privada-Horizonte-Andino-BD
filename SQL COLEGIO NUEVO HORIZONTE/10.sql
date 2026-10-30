
-- Consultar todos los eventos de modificaciones y lecturas capturados
USE master;
GO

SELECT 
    event_time AS [Fecha y Hora (UTC)],
    session_server_principal_name AS [Usuario SQL],
    database_name AS [Base de Datos],
    schema_name AS [Esquema],
    object_name AS [Tabla Afectada],
    action_id AS [Acción Código],
    CASE action_id
        WHEN 'SL' THEN 'SELECT'   
        WHEN 'UP' THEN 'UPDATE'
        WHEN 'DL' THEN 'DELETE'
        ELSE action_id
    END AS [Tipo Operación],
    statement AS [Sentencia Transact-SQL Ejecutada],
    succeeded AS [¿Fue Exitosa? (1=Sí, 0=No)]
FROM sys.fn_get_audit_file('C:\AuditLogs_Colegio_NuevoHorizonte\*', DEFAULT, DEFAULT)
WHERE database_name = 'ColegioHorizonteDB' 
ORDER BY event_time DESC;
GO

