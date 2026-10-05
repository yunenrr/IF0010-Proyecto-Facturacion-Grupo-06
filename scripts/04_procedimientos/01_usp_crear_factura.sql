USE SISTEMA_FACTURACION;
GO


IF TYPE_ID(N'DBO.TT_LINEA_FACTURA') IS NULL
BEGIN
    CREATE TYPE DBO.TT_LINEA_FACTURA AS TABLE (
        ID_PRODUCTO INT NOT NULL,
        CANTIDAD DECIMAL(9, 3) NOT NULL,
        MONTO_DESCUENTO DECIMAL(18, 2) NOT NULL DEFAULT (0)
    );
END
GO

CREATE OR ALTER PROCEDURE DBO.USP_CREAR_FACTURA
    @ID_EMPRESA INT,
    @ID_CLIENTE INT,
    @ID_TIPO_DOCUMENTO TINYINT,
    @ID_MONEDA TINYINT,
    @OBSERVACIONES NVARCHAR(500) = NULL,
    @LINEAS DBO.TT_LINEA_FACTURA READONLY,
    @ID_FACTURA INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ID_FACTURA = NULL;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'OK';

    DECLARE @CANT_LINEAS INT;
    DECLARE @RUBRO_EMPRESA VARCHAR(3);
    DECLARE @ID_BORRADOR TINYINT;
    DECLARE @SUBTOTAL DECIMAL(18, 2);
    DECLARE @DESCUENTOS DECIMAL(18, 2);
    DECLARE @IMPUESTOS DECIMAL(18, 2);
    DECLARE @MONTO_FINAL DECIMAL(18, 2);
    DECLARE @NUEVO_ID INT;

    -- Aquí se calculan las líneas una sola vez, el detalle y los totales del encabezado. 
    
    DECLARE @CALC TABLE (
        NUMERO_LINEA INT NOT NULL,
        ID_PRODUCTO INT NOT NULL,
        DESCRIPCION_LINEA NVARCHAR(150) NOT NULL,
        CANTIDAD DECIMAL(9, 3) NOT NULL,
        PRECIO_UNITARIO DECIMAL(18, 5) NOT NULL,
        TASA_IMPUESTO DECIMAL(5, 4) NOT NULL,
        MONTO_DESCUENTO DECIMAL(18, 2) NOT NULL,
        SUBTOTAL_LINEA DECIMAL(18, 2) NOT NULL,
        MONTO_IMPUESTO_LINEA DECIMAL(18, 2) NOT NULL,
        MONTO_TOTAL_LINEA DECIMAL(18, 2) NOT NULL
    );

    BEGIN TRY
        --Validaciones: 
        IF NOT EXISTS (SELECT 1 FROM DBO.EMPRESA
                       WHERE ID_EMPRESA = @ID_EMPRESA AND ESTA_ACTIVA = 1)
            THROW 50101, N'La empresa no existe o está inactiva.', 1;

        IF NOT EXISTS (SELECT 1 FROM DBO.CLIENTE
                       WHERE ID_CLIENTE = @ID_CLIENTE)
            THROW 50102, N'El cliente no existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM DBO.TIPO_DOCUMENTO
                       WHERE ID_TIPO_DOCUMENTO = @ID_TIPO_DOCUMENTO)
            OR NOT EXISTS (SELECT 1 FROM DBO.MONEDA
                           WHERE ID_MONEDA = @ID_MONEDA)
            THROW 50103, N'El tipo de documento o la moneda no existen.', 1;

        SELECT @ID_BORRADOR = ID_ESTADO_FACTURA
        FROM DBO.ESTADO_FACTURA
        WHERE ESTADO = 'BORRADOR';

        IF @ID_BORRADOR IS NULL
            THROW 50109, N'El estado BORRADOR no existe en el catálogo.', 1;

        --Validaciones en las líneas: 
        SELECT @CANT_LINEAS = COUNT(*) FROM @LINEAS;

        IF @CANT_LINEAS < 1 OR @CANT_LINEAS > 255
            THROW 50104, N'La factura debe tener entre 1 y 255 líneas.', 1;

        IF EXISTS (SELECT 1 FROM @LINEAS
                   WHERE CANTIDAD <= 0 OR MONTO_DESCUENTO < 0)
            THROW 50105, N'Una línea tiene cantidad <= 0 o descuento < 0.', 1;

        IF EXISTS (SELECT 1
                   FROM @LINEAS AS L
                   LEFT JOIN DBO.PRODUCTO AS P
                       ON P.ID_PRODUCTO = L.ID_PRODUCTO
                   WHERE P.ID_PRODUCTO IS NULL OR P.ESTADO_PRODUCTO = 0)
            THROW 50106, N'Un producto no existe o está inactivo.', 1;

        -- El Rubro de la empresa: primera palabra del nombre comercial
        SELECT @RUBRO_EMPRESA = R.CODIGO
        FROM DBO.EMPRESA AS E
        INNER JOIN (VALUES
            (N'Moda',        'MOD'),
            (N'Electro',     'ELE'),
            (N'Tecno',       'TEC'),
            (N'Súper',       'SUP'),
            (N'Ferretería',  'FER'),
            (N'Clínica',     'CLI'),
            (N'Instituto',   'INS'),
            (N'Muebles',     'MUE'),
            (N'Consultores', 'CON'),
            (N'Transportes', 'TRA')
        ) AS R (PREFIJO, CODIGO)
            ON R.PREFIJO = LEFT(E.NOMBRE_COMERCIAL,
                                CHARINDEX(N' ', E.NOMBRE_COMERCIAL + N' ') - 1)
        WHERE E.ID_EMPRESA = @ID_EMPRESA;

        -- Rubro del producto: segmento del medio del código (PRD-MOD-00101)
        IF @RUBRO_EMPRESA IS NULL
            OR EXISTS (SELECT 1
                       FROM @LINEAS AS L
                       INNER JOIN DBO.PRODUCTO AS P
                           ON P.ID_PRODUCTO = L.ID_PRODUCTO
                       WHERE SUBSTRING(P.CODIGO_INTERNO, 5, 3) <> @RUBRO_EMPRESA)
            THROW 50107, N'Un producto no pertenece al rubro de la empresa.', 1;

        IF EXISTS (SELECT 1
                   FROM @LINEAS AS L
                   INNER JOIN DBO.PRODUCTO AS P
                       ON P.ID_PRODUCTO = L.ID_PRODUCTO
                   WHERE LEFT(P.CODIGO_INTERNO, 3) = 'PRD'
                     AND L.CANTIDAD <> FLOOR(L.CANTIDAD))
            THROW 50110, N'Un bien (PRD) debe facturarse en cantidades enteras.', 1;

        --Cálculo de las líneas: 
        INSERT INTO @CALC
            (NUMERO_LINEA, ID_PRODUCTO, DESCRIPCION_LINEA, CANTIDAD,
             PRECIO_UNITARIO, TASA_IMPUESTO, MONTO_DESCUENTO,
             SUBTOTAL_LINEA, MONTO_IMPUESTO_LINEA, MONTO_TOTAL_LINEA)
        SELECT B.NUMERO_LINEA,
               B.ID_PRODUCTO,
               B.DESCRIPCION_PRODUCTO,
               B.CANTIDAD,
               B.PRECIO_UNITARIO,
               B.TASA_IMPUESTO,
               B.MONTO_DESCUENTO,
               S.SUBTOTAL,
               I.IMPUESTO,
               S.SUBTOTAL - B.MONTO_DESCUENTO + I.IMPUESTO
        FROM (
            SELECT CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT)
                       AS NUMERO_LINEA,
                   L.ID_PRODUCTO,
                   P.DESCRIPCION_PRODUCTO,
                   L.CANTIDAD,
                   P.PRECIO_UNITARIO,
                   P.TASA_IMPUESTO,
                   L.MONTO_DESCUENTO
            FROM @LINEAS AS L
            INNER JOIN DBO.PRODUCTO AS P
                ON P.ID_PRODUCTO = L.ID_PRODUCTO
        ) AS B
        CROSS APPLY (
            SELECT CAST(ROUND(B.CANTIDAD * B.PRECIO_UNITARIO, 2)
                        AS DECIMAL(18, 2)) AS SUBTOTAL
        ) AS S
        CROSS APPLY (
            SELECT CAST(ROUND((S.SUBTOTAL - B.MONTO_DESCUENTO)
                              * B.TASA_IMPUESTO, 2)
                        AS DECIMAL(18, 2)) AS IMPUESTO
        ) AS I;

        --Validaciones de los cálculos de arriba: 
        IF EXISTS (SELECT 1 FROM @CALC
                   WHERE SUBTOTAL_LINEA <= 0
                      OR MONTO_DESCUENTO >= SUBTOTAL_LINEA)
            THROW 50108,
                N'Un subtotal redondea a 0,00 o el descuento no es menor que el subtotal.',
                1;

        --Totales del encabezado, la suma de las líneas: 
        SELECT @SUBTOTAL = SUM(SUBTOTAL_LINEA),
               @DESCUENTOS = SUM(MONTO_DESCUENTO),
               @IMPUESTOS = SUM(MONTO_IMPUESTO_LINEA),
               @MONTO_FINAL = SUM(MONTO_TOTAL_LINEA)
        FROM @CALC;

        --Transacción: encabezado más líneas: 
        BEGIN TRANSACTION;

        INSERT INTO DBO.FACTURA
            (ID_TIPO_DOCUMENTO, ID_EMPRESA_EMISORA, ID_CLIENTE_COMPRADOR,
             ID_ESTADO_FACTURA, ID_MONEDA, SUBTOTAL_FACTURA, TOTAL_DESCUENTOS,
             TOTAL_IMPUESTOS, MONTO_FINAL, OBSERVACIONES)
        VALUES
            (@ID_TIPO_DOCUMENTO, @ID_EMPRESA, @ID_CLIENTE,
             @ID_BORRADOR, @ID_MONEDA, @SUBTOTAL, @DESCUENTOS,
             @IMPUESTOS, @MONTO_FINAL, @OBSERVACIONES);

        SET @NUEVO_ID = SCOPE_IDENTITY();

        INSERT INTO DBO.DETALLE_FACTURA
            (ID_FACTURA, ID_PRODUCTO, NUMERO_LINEA, DESCRIPCION_LINEA,
             CANTIDAD_FACTURADA, PRECIO_UNITARIO, TASA_IMPUESTO,
             MONTO_DESCUENTO, MONTO_IMPUESTO_LINEA, SUBTOTAL_LINEA,
             MONTO_TOTAL_LINEA)
        SELECT @NUEVO_ID, ID_PRODUCTO, NUMERO_LINEA, DESCRIPCION_LINEA,
               CANTIDAD, PRECIO_UNITARIO, TASA_IMPUESTO,
               MONTO_DESCUENTO, MONTO_IMPUESTO_LINEA, SUBTOTAL_LINEA,
               MONTO_TOTAL_LINEA
        FROM @CALC;

        COMMIT TRANSACTION;

        SET @ID_FACTURA = @NUEVO_ID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @ID_FACTURA = NULL;
        SET @CODIGO_ERROR = ERROR_NUMBER();
        SET @MENSAJE = ERROR_MESSAGE();
    END CATCH;
END;
GO