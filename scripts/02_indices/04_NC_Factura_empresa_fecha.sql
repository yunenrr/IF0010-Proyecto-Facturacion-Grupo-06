USE Sistema_Facturacion; 
GO

--Índice Nonclustered de la tabla dbo.Factura
--Consutas sobre las facturas emitidas por empresa emisora y fecha

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'NC_Factura_id_empresa_emisora_fecha_emision' 
AND object_id = OBJECT_ID('dbo.Factura'))
BEGIN
	DROP INDEX NC_Factura_id_empresa_emisora_fecha_emision ON dbo.Factura; 
END
GO

CREATE NONCLUSTERED INDEX NC_Factura_id_empresa_emisora_fecha_emision
ON dbo.Factura (id_empresa_emisora ASC, fecha_emision DESC); 
GO
