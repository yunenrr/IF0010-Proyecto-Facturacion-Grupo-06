USE SISTEMA_FACTURACION;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

/*La función devuelve el monto final a pagar de una factura
  Toma en cuenta el subtotal - descuentos + impuestos, si la
  factura no existe entonces devuelve un null
*/

CREATE OR ALTER FUNCTION DBO.UFN_MONTO_FINAL_FACTURA(
    @ID_FACTURA INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    RETURN (
        SELECT F.SUBTOTAL_FACTURA - F.TOTAL_DESCUENTOS + F.TOTAL_IMPUESTOS
        FROM DBO.FACTURA AS F
        WHERE F.ID_FACTURA = @ID_FACTURA
    );
END;
GO
