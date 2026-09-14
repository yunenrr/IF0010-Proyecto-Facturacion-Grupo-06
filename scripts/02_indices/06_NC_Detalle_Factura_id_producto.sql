USE Sistema_Facturacion;
GO

CREATE NONCLUSTERED INDEX nc_Detalle_Factura_id_producto
ON dbo.Detalle_Factura(id_producto) 
INCLUDE(id_factura,cantidad_facturada,monto_total_linea);
GO
