USE Sistema_Facturacion; 
GO

--Índice Nonclustered de la tabla dbo.Factura_Historial
--Optimiza la auditoría cronológica de cambios sobre un comprobante

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'NC_FacturaHistorial_id_factura_fecha_cambio' 
AND object_id = OBJECT_ID('dbo.Factura_Historial'))
BEGIN
	DROP INDEX NC_FacturaHistorial_id_factura_fecha_cambio ON dbo.Factura_Historial; 
END
GO

CREATE NONCLUSTERED INDEX NC_FacturaHistorial_id_factura_fecha_cambio
ON dbo.Factura_Historial (id_factura ASC, fecha_cambio ASC); 
GO
