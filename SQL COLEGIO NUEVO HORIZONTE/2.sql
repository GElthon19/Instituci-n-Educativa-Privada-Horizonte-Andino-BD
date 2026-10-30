USE master;
GO

-- 1. Master Key de la Base de Datos
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MasterKeyPassword2026!';
GO

-- 2. Certificado Digital
CREATE CERTIFICATE CertColegioHorizonte
WITH SUBJECT = 'Certificado de Cifrado para Datos Sensibles de Colegio Horizonte';
GO

-- 3. Llave Simétrica AES_256
CREATE SYMMETRIC KEY SymKeyColegioHorizonte
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE CertColegioHorizonte;
GO