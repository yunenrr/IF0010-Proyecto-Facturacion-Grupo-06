/* Cubre el requisito de consultar totales de una factura por identificador de comprobante.
   Es unique filtrando los NULL porque el consecutivo puede ser NULL mientras la factura esta en BORRADOR */

USE SISTEMA_FACTURACION;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'NC_FACTURA_CONSECUTIVO'
AND object_id = OBJECT_ID ('dbo.FACTURA'))
BEGIN
    DROP INDEX NC_FACTURA_CONSECUTIVO ON dbo.FACTURA;
END
GO

CREATE UNIQUE NONCLUSTERED INDEX NC_FACTURA_CONSECUTIVO
    ON dbo.FACTURA (CONSECUTIVO)
    INCLUDE (SUBTOTAL_FACTURA,TOTAL_DESCUENTOS,TOTAL_IMPUESTOS,MONTO_FINAL)
    WHERE CONSECUTIVO IS NOT NULL;
GO