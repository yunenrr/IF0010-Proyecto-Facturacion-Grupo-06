USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_ACTUALIZAR_PRECIO_PRODUCTO
    @ID_PRODUCTO INT,
    @NUEVO_PRECIO DECIMAL(18, 5) = NULL,
    @NUEVA_TASA DECIMAL(5, 4) = NULL,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'OK';

    BEGIN TRY
        --Validar que el producto exista
        IF
            NOT EXISTS (
                SELECT 1
                FROM DBO.PRODUCTO
                WHERE ID_PRODUCTO = @ID_PRODUCTO
            )
            BEGIN
                THROW 50601, N'El producto no existe.', 1;
            END

        --Validar que la actualización sea de al menos un parámetro
        IF @NUEVO_PRECIO IS NULL AND @NUEVA_TASA IS NULL
            BEGIN
                THROW 50602,
                N'No se envió ni precio ni tasa para actualizar.',
                1;
            END

        --Validar que el precio sea positivo si fue enviado, prohibido negativos
        IF @NUEVO_PRECIO IS NOT NULL AND @NUEVO_PRECIO <= 0
            BEGIN
                THROW 50603, N'El precio unitario debe ser mayor que 0.', 1;
            END

        --Validar que la tasa corresponda a una tarifa oficial de IVA
        IF
            @NUEVA_TASA IS NOT NULL
            AND @NUEVA_TASA NOT IN (0.0000, 0.0100, 0.0200, 0.0400, 0.1300)
            BEGIN
                THROW 50604, N'La tasa no es una tarifa oficial de IVA.', 1;
            END

        BEGIN TRANSACTION;

        UPDATE DBO.PRODUCTO
        SET
            PRECIO_UNITARIO = COALESCE(@NUEVO_PRECIO, PRECIO_UNITARIO),
            TASA_IMPUESTO = COALESCE(@NUEVA_TASA, TASA_IMPUESTO)
        WHERE ID_PRODUCTO = @ID_PRODUCTO;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            BEGIN
                ROLLBACK TRANSACTION;
            END

        SET @CODIGO_ERROR = ERROR_NUMBER();
        SET @MENSAJE = ERROR_MESSAGE();
    END CATCH;
END;
GO
