USE Sistema_Facturacion;
GO

CREATE NONCLUSTERED INDEX nc_Factura_fecha_emision
ON dbo.Factura(fecha_emision) INCLUDE (monto_final);
GO
