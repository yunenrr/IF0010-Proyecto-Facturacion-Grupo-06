
/* Cubre el requisito de consultar facturas por comprador.*/

USE Sistema_Facturacion;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'NC_Factura_cliente_fecha'
AND object_id = OBJECT_ID(dbo.Factura))
BEGIN
    DROP INDEX NC_Factura_cliente_fecha ON dbo.Factura;
END
GO

CREATE NONCLUSTERED INDEX NC_Factura_cliente_fecha
    ON dbo.Factura (id_cliente_comprador, fecha_emision DESC)
    INCLUDE (consecutivo, monto_final)
GO
