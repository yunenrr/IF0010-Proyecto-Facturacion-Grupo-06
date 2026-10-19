/* DATOS DE DBO.PRODUCTO: 1 000 PRODUCTOS Y SERVICIOS EN 10 RUBROS. */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_PRODUCTOS
    @FILAS_INSERTADAS INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- INICIO DEL RANGO DE FACTURAS (ANCLA COMPARTIDA): HOY - 1 AÑO
    DECLARE
        @INICIO_FACTURAS DATETIME2(3)
        = DATEADD(YEAR, -1, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(3)));

    -- VENTANA DE CREACIÓN: LOS 2 AÑOS PREVIOS AL ANCLA, EN SEGUNDOS
    DECLARE @SEGUNDOS_RANGO_CREACION INT = 730 * 86400;
    DECLARE @EXISTENTES INT;

    SET @FILAS_INSERTADAS = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Productos cargados.';

    BEGIN TRY
        SELECT @EXISTENTES = COUNT(*) FROM DBO.PRODUCTO;

        IF @EXISTENTES = 1000
            BEGIN
                SET @MENSAJE = N'PRODUCTO ya tenía los 1 000 productos.';
                RETURN;
            END;

        IF @EXISTENTES > 0
            THROW 50721,
            N'PRODUCTO tiene datos parciales; vaciar la tabla antes de cargar.',
            1;

        IF
            (SELECT COUNT(*) FROM DBO.RUBRO) < 10
            OR (SELECT COUNT(*) FROM DBO.TIPO_PRODUCTO) < 2
            THROW 50724,
            N'Cargue primero dbo.RUBRO y dbo.TIPO_PRODUCTO.',
            1;

        BEGIN TRANSACTION;

        WITH RUBRO AS (
            SELECT
                R.ID_RUBRO,
                R.CODIGO_RUBRO,
                R.TIPO,
                R.DESDE,
                R.HASTA,
                R.REDONDEO
            FROM (
                VALUES
                (1, 'MOD', 'PRD', 1, 100, 100),
                (2, 'ELE', 'PRD', 101, 200, 500),
                (3, 'TEC', 'PRD', 201, 300, 100),
                (4, 'SUP', 'PRD', 301, 400, 5),
                (5, 'FER', 'PRD', 401, 500, 50),
                (6, 'CLI', 'SRV', 501, 600, 500),
                (7, 'INS', 'SRV', 601, 700, 500),
                (8, 'MUE', 'PRD', 701, 800, 500),
                (9, 'CON', 'SRV', 801, 900, 1000),
                (10, 'TRA', 'SRV', 901, 1000, 500)
            ) AS R(ID_RUBRO, CODIGO_RUBRO, TIPO, DESDE, HASTA, REDONDEO)
        ),

        BASE AS (
            SELECT
                B.ID_RUBRO,
                B.ORDEN,
                B.NOMBRE,
                B.TASA,
                B.PRECIO_MIN,
                B.PRECIO_MAX
            FROM (
                VALUES
                (1, 0, N'Camiseta de algodón', 0.13, 3500, 12000),
                (1, 1, N'Camisa manga larga', 0.13, 8000, 28000),
                (1, 2, N'Blusa casual', 0.13, 6000, 22000),
                (1, 3, N'Pantalón de mezclilla', 0.13, 12000, 38000),
                (1, 4, N'Pantalón de vestir', 0.13, 15000, 45000),
                (1, 5, N'Pantaloneta deportiva', 0.13, 4000, 15000),
                (1, 6, N'Falda casual', 0.13, 7000, 25000),
                (1, 7, N'Vestido casual', 0.13, 12000, 48000),
                (1, 8, N'Sudadera con capucha', 0.13, 10000, 35000),
                (1, 9, N'Chaqueta impermeable', 0.13, 18000, 65000),
                (2, 0, N'Plancha de ropa', 0.13, 9000, 35000),
                (2, 1, N'Licuadora', 0.13, 15000, 60000),
                (2, 2, N'Olla arrocera', 0.13, 12000, 45000),
                (2, 3, N'Cafetera', 0.13, 12000, 80000),
                (2, 4, N'Freidora de aire', 0.13, 30000, 120000),
                (2, 5, N'Aspiradora', 0.13, 35000, 200000),
                (2, 6, N'Horno de microondas', 0.13, 45000, 150000),
                (2, 7, N'Cocina eléctrica 4 discos', 0.13, 180000, 550000),
                (2, 8, N'Lavadora', 0.13, 220000, 750000),
                (2, 9, N'Refrigeradora', 0.13, 250000, 900000),
                (3, 0, N'Memoria USB 64 GB', 0.13, 4500, 12000),
                (3, 1, N'Mouse inalámbrico', 0.13, 5000, 25000),
                (3, 2, N'Cargador USB-C 65 W', 0.13, 9000, 30000),
                (3, 3, N'Teclado mecánico', 0.13, 18000, 75000),
                (3, 4, N'Audífonos inalámbricos', 0.13, 12000, 120000),
                (3, 5, N'Disco SSD 1 TB', 0.13, 35000, 95000),
                (3, 6, N'Router Wi-Fi 6', 0.13, 30000, 120000),
                (3, 7, N'Monitor 24 pulgadas', 0.13, 70000, 180000),
                (3, 8, N'Tablet 10 pulgadas', 0.13, 90000, 450000),
                (3, 9, N'Laptop 14 pulgadas', 0.13, 280000, 1200000),
                (4, 0, N'Arroz 99 % grano entero', 0.01, 900, 5500),
                (4, 1, N'Frijoles negros', 0.01, 900, 4000),
                (4, 2, N'Azúcar blanca', 0.01, 700, 3800),
                (4, 3, N'Aceite vegetal', 0.01, 1500, 7500),
                (4, 4, N'Café molido', 0.01, 1800, 12000),
                (4, 5, N'Leche entera', 0.01, 700, 3500),
                (4, 6, N'Huevos', 0.01, 1200, 6500),
                (4, 7, N'Refresco gaseoso', 0.13, 700, 2500),
                (4, 8, N'Galletas rellenas', 0.13, 500, 2200),
                (4, 9, N'Papas tostadas', 0.13, 600, 3000),
                (5, 0, N'Caja de clavos 1 kg', 0.13, 1500, 4000),
                (5, 1, N'Varilla corrugada #3', 0.13, 2500, 5000),
                (5, 2, N'Tubo PVC 1/2 pulgada', 0.13, 2500, 9000),
                (5, 3, N'Martillo', 0.13, 4000, 15000),
                (5, 4, N'Llave ajustable', 0.13, 5000, 18000),
                (5, 5, N'Saco de cemento 50 kg', 0.13, 7000, 10000),
                (5, 6, N'Lámina de zinc', 0.13, 8000, 25000),
                (5, 7, N'Pintura látex galón', 0.13, 12000, 35000),
                (5, 8, N'Rollo de cable eléctrico', 0.13, 25000, 90000),
                (5, 9, N'Taladro eléctrico', 0.13, 25000, 120000),
                (6, 0, N'Consulta de medicina general', 0.04, 25000, 45000),
                (6, 1, N'Consulta con especialista', 0.04, 45000, 90000),
                (6, 2, N'Consulta odontológica', 0.04, 20000, 40000),
                (6, 3, N'Limpieza dental', 0.04, 25000, 50000),
                (6, 4, N'Sesión de fisioterapia', 0.04, 20000, 40000),
                (6, 5, N'Consulta psicológica', 0.04, 30000, 60000),
                (6, 6, N'Examen de laboratorio', 0.04, 15000, 60000),
                (6, 7, N'Radiografía', 0.04, 20000, 55000),
                (6, 8, N'Ultrasonido', 0.04, 40000, 95000),
                (6, 9, N'Procedimiento ambulatorio', 0.04, 150000, 600000),
                (7, 0, N'Matrícula anual', 0.02, 60000, 250000),
                (7, 1, N'Mensualidad primaria', 0.02, 120000, 350000),
                (7, 2, N'Mensualidad secundaria', 0.02, 150000, 450000),
                (7, 3, N'Curso de inglés mensual', 0.02, 35000, 90000),
                (7, 4, N'Curso de programación', 0.02, 60000, 250000),
                (7, 5, N'Taller de Excel', 0.02, 25000, 80000),
                (7, 6, N'Tutoría de matemática', 0.02, 8000, 20000),
                (7, 7, N'Preparación para admisión', 0.02, 40000, 150000),
                (7, 8, N'Curso de cocina', 0.02, 30000, 120000),
                (7, 9, N'Diplomado en administración', 0.02, 150000, 450000),
                (8, 0, N'Juego de sábanas', 0.13, 12000, 45000),
                (8, 1, N'Lámpara de pie', 0.13, 15000, 60000),
                (8, 2, N'Silla de comedor', 0.13, 25000, 75000),
                (8, 3, N'Mueble para TV', 0.13, 40000, 160000),
                (8, 4, N'Escritorio', 0.13, 45000, 180000),
                (8, 5, N'Ropero 2 puertas', 0.13, 90000, 300000),
                (8, 6, N'Colchón matrimonial', 0.13, 90000, 350000),
                (8, 7, N'Cama matrimonial', 0.13, 120000, 400000),
                (8, 8, N'Mesa de comedor 6 puestos', 0.13, 150000, 550000),
                (8, 9, N'Sofá 3 plazas', 0.13, 180000, 650000),
                (9, 0, N'Soporte técnico por hora', 0.13, 15000, 40000),
                (9, 1, N'Consultoría contable', 0.13, 25000, 60000),
                (9, 2, N'Asesoría legal por hora', 0.13, 35000, 90000),
                (9, 3, N'Declaración de impuestos', 0.13, 30000, 150000),
                (9, 4, N'Redacción de contrato', 0.13, 50000, 250000),
                (9, 5, N'Diseño de logotipo', 0.13, 60000, 300000),
                (9, 6, N'Capacitación empresarial', 0.13, 150000, 600000),
                (9, 7, N'Estudio de mercado', 0.13, 300000, 1500000),
                (9, 8, N'Desarrollo de sitio web', 0.13, 400000, 2500000),
                (9, 9, N'Auditoría financiera', 0.13, 400000, 2500000),
                (10, 0, N'Envío de paquete local', 0.13, 2500, 8000),
                (10, 1, N'Mensajería express', 0.13, 3000, 12000),
                (10, 2, N'Envío de paquete nacional', 0.13, 3500, 15000),
                (10, 3, N'Envío internacional', 0.13, 25000, 150000),
                (10, 4, N'Almacenaje mensual', 0.13, 50000, 350000),
                (10, 5, N'Flete de carga 1 tonelada', 0.13, 60000, 250000),
                (10, 6, N'Transporte de personal', 0.13, 70000, 250000),
                (10, 7, N'Distribución a comercios', 0.13, 80000, 400000),
                (10, 8, N'Camión con chofer por día', 0.13, 90000, 300000),
                (10, 9, N'Mudanza residencial', 0.13, 120000, 500000)
            ) AS B(ID_RUBRO, ORDEN, NOMBRE, TASA, PRECIO_MIN, PRECIO_MAX)
        ),

        ATRIBUTO_A AS (
            SELECT
                A.ID_RUBRO,
                A.ORDEN,
                A.TEXTO
            FROM (
                VALUES
                (1, 0, N'talla S'),
                (1, 1, N'talla M'),
                (1, 2, N'talla L'),
                (1, 3, N'talla XL'),
                (1, 4, N'talla XXL'),
                (2, 0, N'Voltek'),
                (2, 1, N'Nexa'),
                (2, 2, N'Orbis'),
                (2, 3, N'Kairo'),
                (2, 4, N'Lumen'),
                (3, 0, N'Voltek'),
                (3, 1, N'Nexa'),
                (3, 2, N'Orbis'),
                (3, 3, N'Kairo'),
                (3, 4, N'Lumen'),
                (4, 0, N'Tico Fresco'),
                (4, 1, N'La Cosecha'),
                (4, 2, N'Don Campo'),
                (4, 3, N'Buen Precio'),
                (4, 4, N'Sabor Tico'),
                (5, 0, N'Fortex'),
                (5, 1, N'Maxiobra'),
                (5, 2, N'Construmax'),
                (5, 3, N'Ferrotico'),
                (5, 4, N'Duramet'),
                (6, 0, N'Horario regular'),
                (6, 1, N'Fin de semana'),
                (7, 0, N'Presencial'),
                (7, 1, N'Virtual'),
                (8, 0, N'color Café'),
                (8, 1, N'color Blanco'),
                (8, 2, N'color Gris'),
                (8, 3, N'color Negro'),
                (8, 4, N'color Natural'),
                (9, 0, N'Presencial'),
                (9, 1, N'Virtual'),
                (10, 0, N'- Ruta GAM'),
                (10, 1, N'- Ruta Zona Norte'),
                (10, 2, N'- Ruta Zona Sur'),
                (10, 3, N'- Ruta Caribe'),
                (10, 4, N'- Ruta Pacífico')
            ) AS A(ID_RUBRO, ORDEN, TEXTO)
        ),

        ATRIBUTO_B AS (
            SELECT
                B.ID_RUBRO,
                B.ORDEN,
                B.TEXTO
            FROM (
                VALUES
                (1, 0, N'Negro'),
                (1, 1, N'Azul'),
                (2, 0, N'Negro'),
                (2, 1, N'Acero inoxidable'),
                (3, 0, N'Negro'),
                (3, 1, N'Blanco'),
                (4, 0, N'presentación Mediana'),
                (4, 1, N'presentación Familiar'),
                (5, 0, N'línea Estándar'),
                (5, 1, N'línea Profesional'),
                (6, 0, N'Sede San José'),
                (6, 1, N'Sede Heredia'),
                (6, 2, N'Sede Alajuela'),
                (6, 3, N'Sede Cartago'),
                (6, 4, N'Sede Limón'),
                (7, 0, N'Sede San José'),
                (7, 1, N'Sede Heredia'),
                (7, 2, N'Sede Alajuela'),
                (7, 3, N'Sede Cartago'),
                (7, 4, N'Sede Limón'),
                (8, 0, N'línea Clásica'),
                (8, 1, N'línea Moderna'),
                (9, 0, N'plan Básico'),
                (9, 1, N'plan Estándar'),
                (9, 2, N'plan Avanzado'),
                (9, 3, N'plan Premium'),
                (9, 4, N'plan Corporativo'),
                (10, 0, N'servicio Estándar'),
                (10, 1, N'servicio Express')
            ) AS B(ID_RUBRO, ORDEN, TEXTO)
        ),

        CONTEO AS (
            SELECT
                R.ID_RUBRO,
                R.CODIGO_RUBRO,
                R.TIPO,
                R.DESDE,
                R.HASTA,
                R.REDONDEO,
                (
                    SELECT COUNT(*) FROM BASE AS B
                    WHERE B.ID_RUBRO = R.ID_RUBRO
                ) AS N_BASES,
                (
                    SELECT COUNT(*) FROM ATRIBUTO_A AS A
                    WHERE A.ID_RUBRO = R.ID_RUBRO
                ) AS N_ATRIBUTO_A
            FROM RUBRO AS R
        ),

        SERIE AS (
            SELECT
                S.VALUE AS N,
                C.ID_RUBRO,
                C.CODIGO_RUBRO,
                C.TIPO,
                C.REDONDEO,
                C.N_BASES,
                C.N_ATRIBUTO_A,
                CAST(CAST(
                    HASHBYTES('SHA2_256', CONCAT('PRECIO|', S.VALUE))
                    AS BINARY(4)
                ) AS BIGINT) AS H_PRECIO,
                CAST(CAST(
                    HASHBYTES('SHA2_256', CONCAT('EXISTENCIA|', S.VALUE))
                    AS BINARY(4)
                ) AS BIGINT) AS H_EXISTENCIA,
                CAST(CAST(
                    HASHBYTES('SHA2_256', CONCAT('FECHA|', S.VALUE))
                    AS BINARY(4)
                ) AS BIGINT) AS H_FECHA,
                CAST(CAST(
                    HASHBYTES('SHA2_256', CONCAT('ESTADO|', S.VALUE))
                    AS BINARY(4)
                ) AS BIGINT) AS H_ESTADO,
                S.VALUE - C.DESDE AS K
            FROM GENERATE_SERIES(1, 1000) AS S
            INNER JOIN CONTEO AS C
                ON S.VALUE BETWEEN C.DESDE AND C.HASTA
        ),

        ARMADO AS (
            SELECT
                S.N,
                S.ID_RUBRO,
                S.CODIGO_RUBRO,
                S.TIPO,
                B.TASA,
                S.H_EXISTENCIA,
                S.H_FECHA,
                S.H_ESTADO,
                CONCAT_WS(N' ', B.NOMBRE, A.TEXTO, AB.TEXTO) AS DESCRIPCION,
                ROUND(
                    (
                        B.PRECIO_MIN
                        + (B.PRECIO_MAX - B.PRECIO_MIN)
                        * SQUARE(CAST(S.H_PRECIO AS FLOAT) / 4294967296.0)
                    ) / S.REDONDEO, 0
                ) * S.REDONDEO AS PRECIO
            FROM SERIE AS S
            INNER JOIN BASE AS B
                ON
                    S.ID_RUBRO = B.ID_RUBRO
                    AND (S.K % S.N_BASES) = B.ORDEN
            INNER JOIN ATRIBUTO_A AS A
                ON
                    S.ID_RUBRO = A.ID_RUBRO
                    AND ((S.K / S.N_BASES) % S.N_ATRIBUTO_A) = A.ORDEN
            INNER JOIN ATRIBUTO_B AS AB
                ON
                    S.ID_RUBRO = AB.ID_RUBRO
                    AND (S.K / (S.N_BASES * S.N_ATRIBUTO_A)) = AB.ORDEN
        )

        INSERT INTO DBO.PRODUCTO (
            CODIGO_INTERNO,
            ID_TIPO_PRODUCTO,
            ID_RUBRO,
            DESCRIPCION_PRODUCTO,
            PRECIO_UNITARIO,
            EXISTENCIA,
            TASA_IMPUESTO,
            ESTADO_PRODUCTO,
            FECHA_CREACION
        )
        SELECT
            CONCAT(
                AR.TIPO, '-', AR.CODIGO_RUBRO, '-',
                RIGHT(
                    CONCAT(
                        '00000',
                        ROW_NUMBER() OVER (
                            PARTITION BY AR.CODIGO_RUBRO ORDER BY AR.N
                        )
                    ),
                    5
                )
            ) AS CODIGO_INTERNO,
            TP.ID_TIPO_PRODUCTO,
            AR.ID_RUBRO,
            AR.DESCRIPCION AS DESCRIPCION_PRODUCTO,
            CAST(AR.PRECIO AS DECIMAL(18, 5)) AS PRECIO_UNITARIO,
            CASE
                WHEN AR.TIPO = 'SRV' THEN 0
                ELSE CAST(AR.H_EXISTENCIA % 501 AS INT)
            END AS EXISTENCIA,
            CAST(AR.TASA AS DECIMAL(5, 4)) AS TASA_IMPUESTO,
            CAST(
                CASE
                    WHEN
                        ROW_NUMBER() OVER (ORDER BY AR.H_ESTADO)
                        <= COUNT(*) OVER () / 10
                        THEN 0
                    ELSE 1
                END AS BIT
            ) AS ESTADO_PRODUCTO,
            DATEADD(
                SECOND,
                -CAST(1 + AR.H_FECHA % @SEGUNDOS_RANGO_CREACION AS INT),
                @INICIO_FACTURAS
            ) AS FECHA_CREACION
        FROM ARMADO AS AR
        INNER JOIN DBO.TIPO_PRODUCTO AS TP
            ON AR.TIPO = TP.CODIGO_TIPO;

        SET @FILAS_INSERTADAS = @@ROWCOUNT;

        IF @FILAS_INSERTADAS <> 1000
            THROW 50722, N'No se insertaron exactamente 1 000 productos.', 1;

        -- REGLAS QUE ANTES GARANTIZABAN LOS CHECK DE LA TABLA
        IF
            EXISTS (
                SELECT 1
                FROM DBO.PRODUCTO AS PR
                INNER JOIN DBO.TIPO_PRODUCTO AS TP
                    ON PR.ID_TIPO_PRODUCTO = TP.ID_TIPO_PRODUCTO
                WHERE
                    PR.PRECIO_UNITARIO <= 0
                    OR PR.EXISTENCIA < 0
                    OR PR.TASA_IMPUESTO NOT IN (0, 0.01, 0.02, 0.04, 0.13)
                    OR (TP.CODIGO_TIPO = 'SRV' AND PR.EXISTENCIA <> 0)
                    OR PR.FECHA_CREACION >= @INICIO_FACTURAS
            )
            THROW 50723,
            N'Algún producto generado no cumple las reglas de negocio.',
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

EXEC DBO.USP_CARGAR_PRODUCTOS
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('PRODUCTO: ', @FILAS, ' FILA(S) NUEVA(S). ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
