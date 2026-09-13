
/* Cubre el requisito de consultar totales de una factura por identificador de comprobante.
   Es unique filtrando los NULL porque el consecutivo puede ser NULL mientras la factura esta en BORRADOR */

USE Sistema_Facturacion;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'NC_Factura_consecutivo'
AND object_id = OBJECT_ID(dbo.Factura))
BEGIN
    DROP INDEX NC_Factura_consecutivo ON dbo.Factura;
END
GO

CREATE UNIQUE NONCLUSTERED INDEX NC_Factura_consecutivo
    ON dbo.Factura (consecutivo)
    INCLUDE (subtotal_factura, total_descuentos, total_impuestos, monto_final)
    WHERE consecutivo IS NOT NULL;
GO