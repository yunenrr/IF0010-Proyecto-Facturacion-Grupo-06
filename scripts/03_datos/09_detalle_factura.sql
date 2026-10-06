USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_DETALLES (
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

    DECLARE @ID_MIN INT = (SELECT MIN(ID_FACTURA) FROM DBO.FACTURA);
    DECLARE @ID_MAX INT = (SELECT MAX(ID_FACTURA) FROM DBO.FACTURA);
    DECLARE @DESDE INT;
    DECLARE @HASTA INT;
    DECLARE @LINEAS_LOTE INT;
    DECLARE @MSG NVARCHAR(200);
    DECLARE @N_PRODUCTO INT;

    BEGIN TRY
        IF @TAMANO_LOTE IS NULL OR @TAMANO_LOTE < 1
            BEGIN
                THROW 50614, N'El tamaño del lote debe ser mayor que 0', 1;
            END;

        IF @ID_MIN IS NULL
            BEGIN
                THROW 50611,
                N'FACTURA esta vacia; ejecuta primero USP_CARGAR_FACTURAS.',
                1;
            END;

        SET @DESDE = (
            SELECT ISNULL(MAX(ID_FACTURA), 0) + 1
            FROM DBO.DETALLE_FACTURA
        );

        IF @DESDE < @ID_MIN
            BEGIN
                SET @DESDE = @ID_MIN;
            END;

        CREATE TABLE #PRODUCTO_CARGA (
            RN INT IDENTITY (1, 1) PRIMARY KEY,
            ID_PRODUCTO INT NOT NULL,
            DESCRIPCION_PRODUCTO NVARCHAR(150) NOT NULL,
            PRECIO_UNITARIO DECIMAL(18, 5) NOT NULL,
            TASA_IMPUESTO DECIMAL(5, 4) NOT NULL
        );

        INSERT INTO #PRODUCTO_CARGA (
            ID_PRODUCTO, DESCRIPCION_PRODUCTO, PRECIO_UNITARIO, TASA_IMPUESTO
        )
        SELECT
            ID_PRODUCTO,
            DESCRIPCION_PRODUCTO,
            PRECIO_UNITARIO,
            TASA_IMPUESTO
        FROM DBO.PRODUCTO
        WHERE ESTADO_PRODUCTO = 1 AND PRECIO_UNITARIO >= 0.01;

        SET @N_PRODUCTO = (SELECT COUNT(*) FROM #PRODUCTO_CARGA);

        IF @N_PRODUCTO = 0
            BEGIN
                THROW 50613,
                N'No hay productos activos con precio >= 0.01.',
                1;
            END;

        CREATE TABLE #DET_LOTE (
            ID_FACTURA INT NOT NULL,
            NUMERO_LINEA TINYINT NOT NULL,
            RN_PRODUCTO INT NOT NULL,
            CANTIDAD DECIMAL(9, 3) NOT NULL,
            PCT_DESCUENTO DECIMAL(5, 2) NOT NULL,
            ID_PRODUCTO INT NULL,
            DESCRIPCION_LINEA NVARCHAR(150) NULL,
            PRECIO_UNITARIO DECIMAL(18, 5) NULL,
            TASA_IMPUESTO DECIMAL(5, 4) NULL,
            SUBTOTAL DECIMAL(18, 2) NULL,
            DESCUENTO DECIMAL(18, 2) NULL,
            IMPUESTO DECIMAL(18, 2) NULL,
            PRIMARY KEY (ID_FACTURA, NUMERO_LINEA)
        );

        WHILE @DESDE <= @ID_MAX
            BEGIN
                SET @HASTA = @DESDE + @TAMANO_LOTE - 1;
                IF @HASTA > @ID_MAX
                    BEGIN
                        SET @HASTA = @ID_MAX;
                    END;

                TRUNCATE TABLE #DET_LOTE;

                BEGIN TRANSACTION;

                INSERT INTO #DET_LOTE (
                    ID_FACTURA,
                    NUMERO_LINEA,
                    RN_PRODUCTO,
                    CANTIDAD,
                    PCT_DESCUENTO
                )
                SELECT
                    F.ID_FACTURA,
                    LN.N AS NUMERO_LINEA,
                    1 + ABS(CHECKSUM(NEWID())) % @N_PRODUCTO AS RN_PRODUCTO,
                    1 + ABS(CHECKSUM(NEWID())) % 10 AS CANTIDAD,
                    CASE
                        WHEN ABS(CHECKSUM(NEWID())) % 100 < 25
                            THEN 5 + ABS(CHECKSUM(NEWID())) % 11
                        ELSE 0
                    END AS PCT_DESCUENTO
                FROM DBO.FACTURA AS F
                CROSS JOIN (VALUES (1), (2), (3), (4), (5)) AS LN(N)
                WHERE
                    F.ID_FACTURA BETWEEN @DESDE AND @HASTA
                    AND LN.N <= 3 + ABS(CHECKSUM(F.ID_FACTURA)) % 3;

                UPDATE D
                SET
                    D.ID_PRODUCTO = P.ID_PRODUCTO,
                    D.DESCRIPCION_LINEA = P.DESCRIPCION_PRODUCTO,
                    D.PRECIO_UNITARIO = P.PRECIO_UNITARIO,
                    D.TASA_IMPUESTO = P.TASA_IMPUESTO,
                    D.SUBTOTAL = ROUND(D.CANTIDAD * P.PRECIO_UNITARIO, 2)
                FROM #DET_LOTE AS D
                INNER JOIN #PRODUCTO_CARGA AS P ON D.RN_PRODUCTO = P.RN;

                UPDATE #DET_LOTE
                SET DESCUENTO = ROUND(SUBTOTAL * PCT_DESCUENTO / 100, 2);

                UPDATE #DET_LOTE
                SET IMPUESTO = ROUND(
                    (SUBTOTAL - DESCUENTO) * TASA_IMPUESTO, 2
                );

                INSERT INTO DBO.DETALLE_FACTURA (
                    ID_FACTURA,
                    ID_PRODUCTO,
                    NUMERO_LINEA,
                    DESCRIPCION_LINEA,
                    CANTIDAD_FACTURADA,
                    PRECIO_UNITARIO,
                    TASA_IMPUESTO,
                    MONTO_DESCUENTO,
                    MONTO_IMPUESTO_LINEA,
                    SUBTOTAL_LINEA,
                    MONTO_TOTAL_LINEA
                )
                SELECT
                    D.ID_FACTURA,
                    D.ID_PRODUCTO,
                    D.NUMERO_LINEA,
                    D.DESCRIPCION_LINEA,
                    D.CANTIDAD AS CANTIDAD_FACTURADA,
                    D.PRECIO_UNITARIO,
                    D.TASA_IMPUESTO,
                    D.DESCUENTO AS MONTO_DESCUENTO,
                    D.IMPUESTO AS MONTO_IMPUESTO_LINEA,
                    D.SUBTOTAL AS SUBTOTAL_LINEA,
                    D.SUBTOTAL - D.DESCUENTO + D.IMPUESTO
                        AS MONTO_TOTAL_LINEA
                FROM #DET_LOTE AS D
                ORDER BY D.ID_FACTURA, D.NUMERO_LINEA;

                SET @LINEAS_LOTE = @@ROWCOUNT;

                WITH TOTALES AS (
                    SELECT
                        D.ID_FACTURA,
                        SUM(D.SUBTOTAL) AS SUBTOTAL,
                        SUM(D.DESCUENTO) AS DESCUENTOS,
                        SUM(D.IMPUESTO) AS IMPUESTOS,
                        SUM(D.SUBTOTAL - D.DESCUENTO + D.IMPUESTO) AS TOTAL
                    FROM #DET_LOTE AS D
                    GROUP BY D.ID_FACTURA
                )

                UPDATE F
                SET
                    F.SUBTOTAL_FACTURA = T.SUBTOTAL,
                    F.TOTAL_DESCUENTOS = T.DESCUENTOS,
                    F.TOTAL_IMPUESTOS = T.IMPUESTOS,
                    F.MONTO_FINAL = T.TOTAL
                FROM DBO.FACTURA AS F
                INNER JOIN TOTALES AS T ON F.ID_FACTURA = T.ID_FACTURA;

                COMMIT TRANSACTION;

                SET @CANTIDAD_INSERTADA = @CANTIDAD_INSERTADA + @LINEAS_LOTE;
                SET @DESDE = @HASTA + 1;

                SET
                    @MSG = N'Detalles cargados hasta la factura '
                    + CAST(@HASTA AS NVARCHAR(10))
                    + N' de ' + CAST(@ID_MAX AS NVARCHAR(10));
                RAISERROR (@MSG, 0, 1) WITH NOWAIT;
            END;

        IF @CANTIDAD_INSERTADA = 0
            BEGIN
                SET @MENSAJE = N'OK: no había facturas pendientes de detalle';
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

EXEC DBO.USP_CARGAR_DETALLES
    @TAMANO_LOTE = 25000,
    @CANTIDAD_INSERTADA = @CANTIDAD OUTPUT,
    @CODIGO_ERROR = @ERROR OUTPUT,
    @MENSAJE = @MSG OUTPUT;

SELECT
    @CANTIDAD AS LINEAS_INSERTADAS,
    @ERROR AS CODIGO_ERROR,
    @MSG AS MENSAJE;
GO

SELECT
    (SELECT COUNT(*) FROM DBO.FACTURA) AS FACTURAS,
    (SELECT COUNT(*) FROM DBO.DETALLE_FACTURA) AS DETALLES;

SELECT
    MIN(X.LINEAS) AS MIN_LINEAS,
    MAX(X.LINEAS) AS MAX_LINEAS
FROM (
    SELECT COUNT(*) AS LINEAS
    FROM DBO.DETALLE_FACTURA
    GROUP BY ID_FACTURA
) AS X;

SELECT COUNT(*) AS FACTURAS_SIN_LINEAS
FROM DBO.FACTURA AS F
WHERE NOT EXISTS (
    SELECT 1 FROM DBO.DETALLE_FACTURA AS DF
    WHERE DF.ID_FACTURA = F.ID_FACTURA
);

WITH D AS (
    SELECT
        ID_FACTURA,
        SUM(SUBTOTAL_LINEA) AS SUBTOTAL,
        SUM(MONTO_TOTAL_LINEA) AS TOTAL
    FROM DBO.DETALLE_FACTURA
    GROUP BY ID_FACTURA
)

SELECT COUNT(*) AS FACTURAS_DESCUADRADAS
FROM DBO.FACTURA AS F
INNER JOIN D
    ON F.ID_FACTURA = D.ID_FACTURA
WHERE
    F.SUBTOTAL_FACTURA <> D.SUBTOTAL
    OR F.MONTO_FINAL <> D.TOTAL;
GO
