/* DATOS DE DBO.SERVICIO: UNA FILA POR CADA PRODUCTO DE TIPO SRV. */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_SERVICIO
    @FILAS_INSERTADAS INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ESPERADOS INT;
    DECLARE @EXISTENTES INT;

    SET @FILAS_INSERTADAS = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Servicios cargados.';

    BEGIN TRY
        SELECT @ESPERADOS = COUNT(*)
        FROM DBO.PRODUCTO AS P
        INNER JOIN DBO.TIPO_PRODUCTO AS TP
            ON P.ID_TIPO_PRODUCTO = TP.ID_TIPO_PRODUCTO
        WHERE TP.CODIGO_TIPO = 'SRV';

        SELECT @EXISTENTES = COUNT(*) FROM DBO.SERVICIO;

        IF @EXISTENTES > 0 AND @EXISTENTES = @ESPERADOS
            BEGIN
                SET @MENSAJE = N'SERVICIO ya tenía todos sus servicios.';
                RETURN;
            END;

        IF @EXISTENTES > 0
            THROW 50786,
            N'SERVICIO tiene datos parciales; vaciar la tabla antes de cargar.',
            1;

        IF @ESPERADOS = 0
            THROW 50787,
            N'Cargue primero los productos de tipo SRV en dbo.PRODUCTO.',
            1;

        BEGIN TRANSACTION;

        -- DURACIÓN DETERMINÍSTICA POR RUBRO, CON VARIACIÓN POR ID_PRODUCTO
        INSERT INTO DBO.SERVICIO (
            ID_PRODUCTO,
            DURACION_ESTIMADA_MIN,
            SE_BRINDA_A_DOMICILIO
        )
        SELECT
            P.ID_PRODUCTO,
            CAST(
                CASE R.CODIGO_RUBRO
                    WHEN 'CON' THEN 60
                    WHEN 'INS' THEN 90
                    WHEN 'CLI' THEN 120
                    WHEN 'TRA' THEN 45
                    ELSE 60
                END + (P.ID_PRODUCTO % 4) * 15 AS SMALLINT
            ) AS DURACION_ESTIMADA_MIN,
            CAST(
                CASE
                    WHEN R.CODIGO_RUBRO IN ('CON', 'TRA') THEN 1
                    WHEN
                        R.CODIGO_RUBRO = 'CLI'
                        AND P.ID_PRODUCTO % 5 = 0
                        THEN 1
                    ELSE 0
                END AS BIT
            ) AS SE_BRINDA_A_DOMICILIO
        FROM DBO.PRODUCTO AS P
        INNER JOIN DBO.TIPO_PRODUCTO AS TP
            ON P.ID_TIPO_PRODUCTO = TP.ID_TIPO_PRODUCTO
        INNER JOIN DBO.RUBRO AS R
            ON P.ID_RUBRO = R.ID_RUBRO
        WHERE TP.CODIGO_TIPO = 'SRV';

        SET @FILAS_INSERTADAS = @@ROWCOUNT;

        IF @FILAS_INSERTADAS <> @ESPERADOS
            THROW 50788,
            N'No se insertó un servicio por cada producto SRV.',
            1;

        -- REGLA DE NEGOCIO QUE NO PUEDE SER CHECK
        IF
            EXISTS (
                SELECT 1
                FROM DBO.SERVICIO
                WHERE DURACION_ESTIMADA_MIN <= 0
            )
            THROW 50789,
            N'Algún servicio generado tiene una duración no válida.',
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

EXEC DBO.USP_CARGAR_SERVICIO
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('SERVICIO: ', @FILAS, ' FILA(S) NUEVA(S). ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
