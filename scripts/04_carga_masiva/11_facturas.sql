USE SISTEMA_FACTURACION;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_FACTURAS (
    @TOTAL_FACTURAS INT = 500000,
    @TAMANO_LOTE INT = 25000,
    @CANTIDAD_INSERTADA INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @CANTIDAD_INSERTADA = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'OK';

    DECLARE @PASO_SEGUNDOS INT;
    DECLARE @FECHA_BASE DATETIME2(0) = DATEADD(
        DAY, -365, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(0))
    );
    DECLARE @DESDE INT = 1;
    DECLARE @HASTA INT;
    DECLARE @MSG NVARCHAR(200);
    DECLARE @N_EMPRESA INT;
    DECLARE @N_CLIENTE INT;
    DECLARE @N_MONEDA INT;

    DECLARE @ID_BORRADOR TINYINT = (
        SELECT ID_ESTADO_FACTURA FROM DBO.ESTADO_FACTURA
        WHERE ESTADO = 'BORRADOR'
    );
    DECLARE @ID_EMITIDA TINYINT = (
        SELECT ID_ESTADO_FACTURA FROM DBO.ESTADO_FACTURA
        WHERE ESTADO = 'EMITIDA'
    );
    DECLARE @ID_PAGADA TINYINT = (
        SELECT ID_ESTADO_FACTURA FROM DBO.ESTADO_FACTURA
        WHERE ESTADO = 'PAGADA'
    );
    DECLARE @ID_CANCELADA TINYINT = (
        SELECT ID_ESTADO_FACTURA FROM DBO.ESTADO_FACTURA
        WHERE ESTADO = 'CANCELADA'
    );
    DECLARE @ID_FAC TINYINT = (
        SELECT ID_TIPO_DOCUMENTO FROM DBO.TIPO_DOCUMENTO
        WHERE CODIGO_IDENTIFICADOR = 'FAC'
    );
    DECLARE @ID_TIQ TINYINT = (
        SELECT ID_TIPO_DOCUMENTO FROM DBO.TIPO_DOCUMENTO
        WHERE CODIGO_IDENTIFICADOR = 'TIQ'
    );

    BEGIN TRY
        IF
            @TOTAL_FACTURAS IS NULL
            OR @TOTAL_FACTURAS < 1
            OR @TOTAL_FACTURAS > 31536000
            BEGIN
                THROW 50781,
                N'El total de facturas debe estar entre 1 y 31536000',
                1;
            END;

        IF @TAMANO_LOTE IS NULL OR @TAMANO_LOTE < 1
            BEGIN
                THROW 50782, N'El tamaño del lote debe ser mayor que 0', 1;
            END;

        IF EXISTS (SELECT 1 FROM DBO.FACTURA)
            BEGIN
                SET @MENSAJE = N'FACTURA ya tiene datos. No se cargó nada.';
                RETURN;
            END;

        IF
            @ID_BORRADOR IS NULL OR @ID_EMITIDA IS NULL
            OR @ID_PAGADA IS NULL OR @ID_CANCELADA IS NULL
            BEGIN
                THROW 50783, N'Faltan estados en ESTADO_FACTURA.', 1;
            END;

        IF @ID_FAC IS NULL OR @ID_TIQ IS NULL
            BEGIN
                THROW 50784,
                N'Faltan tipos FAC o TIQ en TIPO_DOCUMENTO.',
                1;
            END;

        SET @PASO_SEGUNDOS = 31536000 / @TOTAL_FACTURAS;

        CREATE TABLE #EMPRESA_CARGA (
            RN INT IDENTITY (1, 1) PRIMARY KEY,
            ID_EMPRESA INT NOT NULL
        );
        CREATE TABLE #CLIENTE_CARGA (
            RN INT IDENTITY (1, 1) PRIMARY KEY,
            ID_CLIENTE INT NOT NULL
        );
        CREATE TABLE #MONEDA_CARGA (
            RN INT IDENTITY (1, 1) PRIMARY KEY,
            ID_MONEDA TINYINT NOT NULL
        );

        INSERT INTO #EMPRESA_CARGA (ID_EMPRESA)
        SELECT ID_EMPRESA
        FROM DBO.EMPRESA
        WHERE ESTA_ACTIVA = 1;

        INSERT INTO #CLIENTE_CARGA (ID_CLIENTE)
        SELECT ID_CLIENTE FROM DBO.CLIENTE;

        INSERT INTO #MONEDA_CARGA (ID_MONEDA)
        SELECT ID_MONEDA
        FROM DBO.MONEDA
        WHERE CODIGO_MONEDA = 'CRC';

        SET @N_EMPRESA = (SELECT COUNT(*) FROM #EMPRESA_CARGA);
        SET @N_CLIENTE = (SELECT COUNT(*) FROM #CLIENTE_CARGA);
        SET @N_MONEDA = (SELECT COUNT(*) FROM #MONEDA_CARGA);

        IF @N_EMPRESA = 0 OR @N_CLIENTE = 0 OR @N_MONEDA = 0
            BEGIN
                THROW 50785,
                N'EMPRESA, CLIENTE o MONEDA estan vacios.',
                1;
            END;

        CREATE TABLE #LOTE (
            N INT NOT NULL PRIMARY KEY,
            R_TIPO INT NOT NULL,
            R_ESTADO INT NOT NULL,
            RN_EMPRESA INT NOT NULL,
            RN_CLIENTE INT NOT NULL,
            RN_MONEDA INT NOT NULL,
            FECHA DATETIME2(0) NOT NULL,
            MINUTOS_ANTES INT NOT NULL
        );

        WHILE @DESDE <= @TOTAL_FACTURAS
            BEGIN
                SET @HASTA = @DESDE + @TAMANO_LOTE - 1;
                IF @HASTA > @TOTAL_FACTURAS
                    BEGIN
                        SET @HASTA = @TOTAL_FACTURAS;
                    END;

                TRUNCATE TABLE #LOTE;

                BEGIN TRANSACTION;

                INSERT INTO #LOTE (
                    N, R_TIPO, R_ESTADO, RN_EMPRESA, RN_CLIENTE, RN_MONEDA,
                    FECHA, MINUTOS_ANTES
                )
                SELECT
                    T.N,
                    ABS(CHECKSUM(NEWID()) % 100) AS R_TIPO,
                    ABS(CHECKSUM(NEWID()) % 100) AS R_ESTADO,
                    1 + ABS(CHECKSUM(NEWID()) % @N_EMPRESA) AS RN_EMPRESA,
                    1 + ABS(CHECKSUM(NEWID()) % @N_CLIENTE) AS RN_CLIENTE,
                    1 + ABS(CHECKSUM(NEWID()) % @N_MONEDA) AS RN_MONEDA,
                    DATEADD(SECOND, T.N * @PASO_SEGUNDOS, @FECHA_BASE)
                        AS FECHA,
                    1 + ABS(CHECKSUM(NEWID()) % 120) AS MINUTOS_ANTES
                FROM (
                    SELECT TOP (@HASTA - @DESDE + 1)
                        @DESDE - 1
                        + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
                    FROM SYS.ALL_OBJECTS AS A
                    CROSS JOIN SYS.ALL_OBJECTS AS B
                ) AS T;

                INSERT INTO DBO.FACTURA (
                    ID_TIPO_DOCUMENTO,
                    ID_EMPRESA_EMISORA,
                    ID_CLIENTE_COMPRADOR,
                    ID_ESTADO_FACTURA,
                    ID_MONEDA,
                    CONSECUTIVO,
                    FECHA_CREACION,
                    FECHA_MODIFICACION,
                    FECHA_EMISION,
                    SUBTOTAL_FACTURA,
                    TOTAL_DESCUENTOS,
                    TOTAL_IMPUESTOS,
                    MONTO_FINAL
                )
                SELECT
                    X.ID_TIPO AS ID_TIPO_DOCUMENTO,
                    EM.ID_EMPRESA AS ID_EMPRESA_EMISORA,
                    CL.ID_CLIENTE AS ID_CLIENTE_COMPRADOR,
                    X.ID_ESTADO AS ID_ESTADO_FACTURA,
                    MO.ID_MONEDA,
                    DBO.UFN_CLAVE_COMPROBANTE(X.FECHA, X.COD_TIPO)
                        AS CONSECUTIVO,
                    CASE
                        WHEN X.ID_ESTADO = @ID_BORRADOR THEN X.FECHA
                        ELSE DATEADD(MINUTE, -X.MINUTOS_ANTES, X.FECHA)
                    END AS FECHA_CREACION,
                    X.FECHA AS FECHA_MODIFICACION,
                    X.FECHA AS FECHA_EMISION,
                    0.01 AS SUBTOTAL_FACTURA,
                    0 AS TOTAL_DESCUENTOS,
                    0 AS TOTAL_IMPUESTOS,
                    0 AS MONTO_FINAL
                FROM (
                    SELECT
                        L.N,
                        L.RN_EMPRESA,
                        L.RN_CLIENTE,
                        L.RN_MONEDA,
                        L.FECHA,
                        L.MINUTOS_ANTES,
                        CASE
                            WHEN L.R_TIPO < 70 THEN @ID_FAC
                            ELSE @ID_TIQ
                        END AS ID_TIPO,
                        CASE
                            WHEN L.R_TIPO < 70 THEN 'FAC'
                            ELSE 'TIQ'
                        END AS COD_TIPO,
                        CASE
                            WHEN L.R_ESTADO < 5 THEN @ID_BORRADOR
                            WHEN L.R_ESTADO < 20 THEN @ID_EMITIDA
                            WHEN L.R_ESTADO < 90 THEN @ID_PAGADA
                            ELSE @ID_CANCELADA
                        END AS ID_ESTADO
                    FROM #LOTE AS L
                ) AS X
                INNER JOIN #EMPRESA_CARGA AS EM ON X.RN_EMPRESA = EM.RN
                INNER JOIN #CLIENTE_CARGA AS CL ON X.RN_CLIENTE = CL.RN
                INNER JOIN #MONEDA_CARGA AS MO ON X.RN_MONEDA = MO.RN
                ORDER BY X.N;

                COMMIT TRANSACTION;

                SET @DESDE = @HASTA + 1;
                SET @CANTIDAD_INSERTADA = @HASTA;

                SET
                    @MSG = N'Facturas cargadas: '
                    + CAST(@HASTA AS NVARCHAR(10))
                    + N' de ' + CAST(@TOTAL_FACTURAS AS NVARCHAR(10));
                RAISERROR (@MSG, 0, 1) WITH NOWAIT;
            END;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        SET @CODIGO_ERROR = ERROR_NUMBER();
        SET @MENSAJE = ERROR_MESSAGE();
    END CATCH;
END;
GO

DECLARE @CANTIDAD INT;
DECLARE @ERROR INT;
DECLARE @MSG NVARCHAR(4000);

EXEC DBO.USP_CARGAR_FACTURAS
    @TOTAL_FACTURAS = 500000,
    @TAMANO_LOTE = 25000,
    @CANTIDAD_INSERTADA = @CANTIDAD OUTPUT,
    @CODIGO_ERROR = @ERROR OUTPUT,
    @MENSAJE = @MSG OUTPUT;

IF @ERROR <> 0
    THROW 50700, @MSG, 1;

SELECT
    @CANTIDAD AS CANTIDAD_INSERTADA,
    @ERROR AS CODIGO_ERROR,
    @MSG AS MENSAJE;
GO

SELECT
    COUNT(*) AS FACTURAS,
    MIN(FECHA_CREACION) AS FECHA_MIN,
    MAX(FECHA_CREACION) AS FECHA_MAX
FROM DBO.FACTURA;

SELECT
    CONSECUTIVO,
    COUNT(*) AS VECES
FROM DBO.FACTURA
GROUP BY CONSECUTIVO
HAVING COUNT(*) > 1;

SELECT
    E.ESTADO,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5, 2))
        AS PORCENTAJE,
    COUNT(*) AS CANTIDAD
FROM DBO.FACTURA AS F
INNER JOIN DBO.ESTADO_FACTURA AS E
    ON F.ID_ESTADO_FACTURA = E.ID_ESTADO_FACTURA
GROUP BY E.ESTADO
ORDER BY CANTIDAD DESC;
GO
