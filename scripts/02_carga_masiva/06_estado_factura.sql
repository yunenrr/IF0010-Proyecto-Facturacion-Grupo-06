/* DATOS DE DBO.ESTADO_FACTURA — CICLO DE VIDA DEL COMPROBANTE. */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_ESTADO_FACTURA
    @FILAS_INSERTADAS INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @FILAS_INSERTADAS = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Estados de factura cargados.';

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO DBO.ESTADO_FACTURA (
            ID_ESTADO_FACTURA,
            ESTADO,
            DESCRIPCION_ESTADO
        )
        SELECT
            V.ID_ESTADO_FACTURA,
            V.ESTADO,
            V.DESCRIPCION_ESTADO
        FROM (
            VALUES
            (1, 'BORRADOR', N'Comprobante en elaboración, sin validez fiscal'),
            (2, 'EMITIDA', N'Comprobante emitido, pendiente de pago'),
            (3, 'PAGADA', N'Comprobante emitido y pagado en su totalidad'),
            (4, 'CANCELADA', N'Comprobante anulado, sin efecto fiscal')
        ) AS V(ID_ESTADO_FACTURA, ESTADO, DESCRIPCION_ESTADO)
        WHERE NOT EXISTS (
            SELECT 1
            FROM DBO.ESTADO_FACTURA AS E
            WHERE E.ID_ESTADO_FACTURA = V.ID_ESTADO_FACTURA
        );

        SET @FILAS_INSERTADAS = @@ROWCOUNT;

        IF (SELECT COUNT(*) FROM DBO.ESTADO_FACTURA) < 4
            THROW 50711,
            N'El catálogo de estados de factura quedó incompleto.',
            1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @FILAS_INSERTADAS = 0;
        SET @CODIGO_ERROR = ERROR_NUMBER();
        SET @MENSAJE = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- EJECUCIÓN DE LA CARGA
DECLARE @FILAS INT, @CODIGO INT, @MENSAJE NVARCHAR(4000);

EXEC DBO.USP_CARGAR_ESTADO_FACTURA
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('ESTADO_FACTURA: ', @FILAS, ' fila(s) nueva(s). ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
