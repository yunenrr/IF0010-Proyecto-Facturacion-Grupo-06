USE SISTEMA_FACTURACION;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CAMBIAR_ESTADO_FACTURA (
    @ID_FACTURA INT,
    @NUEVO_ESTADO VARCHAR(10),
    @CONSECUTIVO CHAR(20) OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'OK';

    BEGIN TRY
        DECLARE @ESTADO_ACTUAL VARCHAR(10);
        DECLARE @CANTIDAD_LINEAS INT;
        DECLARE @CODIGO_TIPO CHAR(3);
        DECLARE @FECHA_ACTUAL DATETIME2 = SYSDATETIME();

        SELECT
            @ESTADO_ACTUAL = E.ESTADO,
            @CANTIDAD_LINEAS = (
                SELECT COUNT(*)
                FROM DBO.DETALLE_FACTURA AS DF_SUB
                WHERE DF_SUB.ID_FACTURA = F.ID_FACTURA
            ),
            @CODIGO_TIPO = TD.CODIGO_IDENTIFICADOR
        FROM DBO.FACTURA AS F
        INNER JOIN DBO.ESTADO_FACTURA AS E
            ON F.ID_ESTADO_FACTURA = E.ID_ESTADO_FACTURA
        INNER JOIN DBO.TIPO_DOCUMENTO AS TD
            ON F.ID_TIPO_DOCUMENTO = TD.ID_TIPO_DOCUMENTO
        WHERE F.ID_FACTURA = @ID_FACTURA;

        IF @ESTADO_ACTUAL IS NULL
            BEGIN
                THROW 50201, N'La factura no existe', 1;
            END;

        IF @NUEVO_ESTADO NOT IN ('BORRADOR', 'EMITIDA', 'PAGADA', 'CANCELADA')
            BEGIN
                THROW 50202, N'El estado destino no existe', 1;
            END;

        IF
            @ESTADO_ACTUAL IN ('PAGADA', 'CANCELADA')
            OR (
                @ESTADO_ACTUAL = 'BORRADOR'
                AND @NUEVO_ESTADO NOT IN ('EMITIDA', 'CANCELADA')
            )
            OR (
                @ESTADO_ACTUAL = 'EMITIDA'
                AND @NUEVO_ESTADO NOT IN ('PAGADA', 'CANCELADA')
            )
            BEGIN
                THROW 50203, N'Transición no permitida', 1;
            END;

        IF @NUEVO_ESTADO = 'EMITIDA' AND @CANTIDAD_LINEAS = 0
            BEGIN
                THROW 50204, N'Se intenta emitir una factura sin líneas', 1;
            END;

        BEGIN TRANSACTION;

        IF @NUEVO_ESTADO = 'EMITIDA'
            BEGIN
                SET
                    @CONSECUTIVO = CONVERT(CHAR(8), @FECHA_ACTUAL, 112)
                    + REPLACE(CONVERT(CHAR(8), @FECHA_ACTUAL, 108), ':', '')
                    + '-'
                    + @CODIGO_TIPO;

                DECLARE @BIENES_DISTINTOS INT;
                SELECT @BIENES_DISTINTOS = COUNT(DISTINCT DF.ID_PRODUCTO)
                FROM DBO.DETALLE_FACTURA AS DF
                INNER JOIN DBO.PRODUCTO AS P
                    ON DF.ID_PRODUCTO = P.ID_PRODUCTO
                INNER JOIN DBO.TIPO_PRODUCTO AS TP
                    ON P.ID_TIPO_PRODUCTO = TP.ID_TIPO_PRODUCTO
                WHERE
                    DF.ID_FACTURA = @ID_FACTURA
                    AND TP.CODIGO_TIPO = 'PRD';

                UPDATE P
                SET P.EXISTENCIA = P.EXISTENCIA - SUM_DF.CANTIDAD_TOTAL
                FROM DBO.PRODUCTO AS P
                INNER JOIN DBO.TIPO_PRODUCTO AS TP
                    ON P.ID_TIPO_PRODUCTO = TP.ID_TIPO_PRODUCTO
                INNER JOIN (
                    SELECT
                        DF.ID_PRODUCTO,
                        SUM(DF.CANTIDAD_FACTURADA) AS CANTIDAD_TOTAL
                    FROM DBO.DETALLE_FACTURA AS DF
                    WHERE DF.ID_FACTURA = @ID_FACTURA
                    GROUP BY DF.ID_PRODUCTO
                ) AS SUM_DF
                    ON P.ID_PRODUCTO = SUM_DF.ID_PRODUCTO
                WHERE
                    TP.CODIGO_TIPO = 'PRD'
                    AND P.EXISTENCIA >= SUM_DF.CANTIDAD_TOTAL;

                IF @@ROWCOUNT < @BIENES_DISTINTOS
                    BEGIN
                        THROW 50207,
                        N'Existencia insuficiente para emitir la factura',
                        1;
                    END;
            END;

        IF @NUEVO_ESTADO = 'CANCELADA' AND @ESTADO_ACTUAL = 'EMITIDA'
            BEGIN
                UPDATE P
                SET P.EXISTENCIA = P.EXISTENCIA + SUM_DF.CANTIDAD_TOTAL
                FROM DBO.PRODUCTO AS P
                INNER JOIN DBO.TIPO_PRODUCTO AS TP
                    ON P.ID_TIPO_PRODUCTO = TP.ID_TIPO_PRODUCTO
                INNER JOIN (
                    SELECT
                        DF.ID_PRODUCTO,
                        SUM(DF.CANTIDAD_FACTURADA) AS CANTIDAD_TOTAL
                    FROM DBO.DETALLE_FACTURA AS DF
                    WHERE DF.ID_FACTURA = @ID_FACTURA
                    GROUP BY DF.ID_PRODUCTO
                ) AS SUM_DF
                    ON P.ID_PRODUCTO = SUM_DF.ID_PRODUCTO
                WHERE TP.CODIGO_TIPO = 'PRD';
            END;

        UPDATE F
        SET
            F.ID_ESTADO_FACTURA = (
                SELECT EST.ID_ESTADO_FACTURA
                FROM DBO.ESTADO_FACTURA AS EST
                WHERE EST.ESTADO = @NUEVO_ESTADO
            ),
            F.FECHA_MODIFICACION = @FECHA_ACTUAL,
            F.FECHA_EMISION = CASE
                WHEN @NUEVO_ESTADO = 'EMITIDA' THEN @FECHA_ACTUAL
                ELSE F.FECHA_EMISION
            END,
            F.CONSECUTIVO = CASE
                WHEN @NUEVO_ESTADO = 'EMITIDA' THEN @CONSECUTIVO
                ELSE F.CONSECUTIVO
            END
        FROM DBO.FACTURA AS F
        WHERE
            F.ID_FACTURA = @ID_FACTURA
            AND F.ID_ESTADO_FACTURA = (
                SELECT EST.ID_ESTADO_FACTURA
                FROM DBO.ESTADO_FACTURA AS EST
                WHERE EST.ESTADO = @ESTADO_ACTUAL
            );

        IF @@ROWCOUNT = 0
            BEGIN
                THROW 50206,
                N'Otro usuario cambió el estado al mismo tiempo',
                1;
            END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        SET @CODIGO_ERROR = CASE
            WHEN ERROR_NUMBER() IN (2601, 2627) THEN 50205
            ELSE ERROR_NUMBER()
        END;

        SET @MENSAJE = CASE
            WHEN
                ERROR_NUMBER() IN (2601, 2627)
                THEN N'Otra factura del mismo tipo ya tiene ese consecutivo'
            ELSE ERROR_MESSAGE()
        END;
    END CATCH;
END;
GO
