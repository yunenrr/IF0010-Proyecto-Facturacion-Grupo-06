/* DATOS DE DBO.PRODUCTO — CATÁLOGO DE 1 000 PRODUCTOS Y SERVICIOS.

   FORMATO DE CODIGO_INTERNO: TIPO-RUBRO-NNNNN (EJ.: PRD-MOD-00001).
   - TIPO: PRD = PRODUCTO; SRV = SERVICIO (EXISTENCIA SIEMPRE 0 PARA SRV).
   - RUBRO: RELACIONA EL PRODUCTO CON EL RUBRO DE LA EMPRESA

   SUPUESTOS SEMÁNTICOS:
   - PRECIOS DE LISTA EN COLONES (CRC).
   - TODOS LOS PRODUCTOS SE CREAN en la fecha HOY - 1 AÑO.
   - EL 10 % DEL CATÁLOGO QUEDA INACTIVO. */

USE SISTEMA_FACTURACION;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM DBO.PRODUCTO)
    BEGIN
        PRINT 'DBO.PRODUCTO YA TIENE DATOS; NO SE INSERTA NADA.';
        RETURN;
    END;

-- INICIO DEL RANGO DE FACTURAS: ANCLA COMPARTIDA CON EL GENERADOR DE FACTURAS
DECLARE
    @INICIO_FACTURAS DATETIME2(3)
    = DATEADD(YEAR, -1, CAST(CAST(SYSDATETIME() AS DATE) AS DATETIME2(3)));

-- SEGUNDOS EN DOS AÑOS: CADA PRODUCTO SE CREA DENTRO DE LOS 2 AÑOS PREVIOS
-- AL INICIO DEL RANGO DE FACTURAS
DECLARE @SEGUNDOS_RANGO_CREACION INT = 730 * 86400;

WITH RUBRO AS (
    -- TRAMO [DESDE, HASTA] DEL NÚMERO DE SERIE = CANTIDAD EXACTA DE PRODUCTOS
    SELECT
        R.ID_RUBRO,
        R.CODIGO_RUBRO,
        R.DESDE,
        R.HASTA,
        R.REDONDEO
    FROM (
        VALUES
        (1, 'MOD', 1, 100, 100),      -- MODA: ROPA Y VESTIMENTA
        (2, 'ELE', 101, 200, 500),    -- ELECTRO: ELECTRODOMÉSTICOS
        (3, 'TEC', 201, 300, 100),    -- TECNO: TECNOLOGÍA Y COMPUTACIÓN
        (4, 'SUP', 301, 400, 5),      -- SÚPER: SUPERMERCADO Y ALIMENTOS
        (5, 'FER', 401, 500, 50),     -- FERRETERÍA Y CONSTRUCCIÓN
        (6, 'CLI', 501, 600, 500),    -- CLÍNICA: SALUD PRIVADA
        (7, 'INS', 601, 700, 500),    -- INSTITUTO: SERVICIOS EDUCATIVOS
        (8, 'MUE', 701, 800, 500),    -- MUEBLES Y HOGAR
        (9, 'CON', 801, 900, 1000),   -- CONSULTORES: SERVICIOS PROFESIONALES
        (10, 'TRA', 901, 1000, 500)   -- TRANSPORTES Y LOGÍSTICA
    ) AS R (ID_RUBRO, CODIGO_RUBRO, DESDE, HASTA, REDONDEO)
),

BASE AS (
    -- ARTÍCULO BASE CON SU TIPO, TASA DE IVA Y RANGO DE PRECIO (ORDEN DESDE 0)
    SELECT
        B.ID_RUBRO,
        B.ORDEN,
        B.NOMBRE,
        B.TIPO,
        B.TASA,
        B.PRECIO_MIN,
        B.PRECIO_MAX
    FROM (
        VALUES
        (1, 0, N'Camiseta de algodón', 'PRD', 0.1300, 3500, 12000),
        (1, 1, N'Camisa manga larga', 'PRD', 0.1300, 8000, 28000),
        (1, 2, N'Blusa casual', 'PRD', 0.1300, 6000, 22000),
        (1, 3, N'Pantalón de mezclilla', 'PRD', 0.1300, 12000, 38000),
        (1, 4, N'Pantalón de vestir', 'PRD', 0.1300, 15000, 45000),
        (1, 5, N'Pantaloneta deportiva', 'PRD', 0.1300, 4000, 15000),
        (1, 6, N'Falda casual', 'PRD', 0.1300, 7000, 25000),
        (1, 7, N'Vestido casual', 'PRD', 0.1300, 12000, 48000),
        (1, 8, N'Sudadera con capucha', 'PRD', 0.1300, 10000, 35000),
        (1, 9, N'Chaqueta impermeable', 'PRD', 0.1300, 18000, 65000),
        (2, 0, N'Plancha de ropa', 'PRD', 0.1300, 9000, 35000),
        (2, 1, N'Licuadora', 'PRD', 0.1300, 15000, 60000),
        (2, 2, N'Olla arrocera', 'PRD', 0.1300, 12000, 45000),
        (2, 3, N'Cafetera', 'PRD', 0.1300, 12000, 80000),
        (2, 4, N'Freidora de aire', 'PRD', 0.1300, 30000, 120000),
        (2, 5, N'Aspiradora', 'PRD', 0.1300, 35000, 200000),
        (2, 6, N'Horno de microondas', 'PRD', 0.1300, 45000, 150000),
        (2, 7, N'Cocina eléctrica 4 discos', 'PRD', 0.1300, 180000, 550000),
        (2, 8, N'Lavadora', 'PRD', 0.1300, 220000, 750000),
        (2, 9, N'Refrigeradora', 'PRD', 0.1300, 250000, 900000),
        (3, 0, N'Memoria USB 64 GB', 'PRD', 0.1300, 4500, 12000),
        (3, 1, N'Mouse inalámbrico', 'PRD', 0.1300, 5000, 25000),
        (3, 2, N'Cargador USB-C 65 W', 'PRD', 0.1300, 9000, 30000),
        (3, 3, N'Teclado mecánico', 'PRD', 0.1300, 18000, 75000),
        (3, 4, N'Audífonos inalámbricos', 'PRD', 0.1300, 12000, 120000),
        (3, 5, N'Disco SSD 1 TB', 'PRD', 0.1300, 35000, 95000),
        (3, 6, N'Router Wi-Fi 6', 'PRD', 0.1300, 30000, 120000),
        (3, 7, N'Monitor 24 pulgadas', 'PRD', 0.1300, 70000, 180000),
        (3, 8, N'Tablet 10 pulgadas', 'PRD', 0.1300, 90000, 450000),
        (3, 9, N'Laptop 14 pulgadas', 'PRD', 0.1300, 280000, 1200000),
        (4, 0, N'Arroz 99 % grano entero', 'PRD', 0.0100, 900, 5500),
        (4, 1, N'Frijoles negros', 'PRD', 0.0100, 900, 4000),
        (4, 2, N'Azúcar blanca', 'PRD', 0.0100, 700, 3800),
        (4, 3, N'Aceite vegetal', 'PRD', 0.0100, 1500, 7500),
        (4, 4, N'Café molido', 'PRD', 0.0100, 1800, 12000),
        (4, 5, N'Leche entera', 'PRD', 0.0100, 700, 3500),
        (4, 6, N'Huevos', 'PRD', 0.0100, 1200, 6500),
        (4, 7, N'Refresco gaseoso', 'PRD', 0.1300, 700, 2500),
        (4, 8, N'Galletas rellenas', 'PRD', 0.1300, 500, 2200),
        (4, 9, N'Papas tostadas', 'PRD', 0.1300, 600, 3000),
        (5, 0, N'Caja de clavos 1 kg', 'PRD', 0.1300, 1500, 4000),
        (5, 1, N'Varilla corrugada #3', 'PRD', 0.1300, 2500, 5000),
        (5, 2, N'Tubo PVC 1/2 pulgada', 'PRD', 0.1300, 2500, 9000),
        (5, 3, N'Martillo', 'PRD', 0.1300, 4000, 15000),
        (5, 4, N'Llave ajustable', 'PRD', 0.1300, 5000, 18000),
        (5, 5, N'Saco de cemento 50 kg', 'PRD', 0.1300, 7000, 10000),
        (5, 6, N'Lámina de zinc', 'PRD', 0.1300, 8000, 25000),
        (5, 7, N'Pintura látex galón', 'PRD', 0.1300, 12000, 35000),
        (5, 8, N'Rollo de cable eléctrico', 'PRD', 0.1300, 25000, 90000),
        (5, 9, N'Taladro eléctrico', 'PRD', 0.1300, 25000, 120000),
        (6, 0, N'Consulta de medicina general', 'SRV', 0.0400, 25000, 45000),
        (6, 1, N'Consulta con especialista', 'SRV', 0.0400, 45000, 90000),
        (6, 2, N'Consulta odontológica', 'SRV', 0.0400, 20000, 40000),
        (6, 3, N'Limpieza dental', 'SRV', 0.0400, 25000, 50000),
        (6, 4, N'Sesión de fisioterapia', 'SRV', 0.0400, 20000, 40000),
        (6, 5, N'Consulta psicológica', 'SRV', 0.0400, 30000, 60000),
        (6, 6, N'Examen de laboratorio', 'SRV', 0.0400, 15000, 60000),
        (6, 7, N'Radiografía', 'SRV', 0.0400, 20000, 55000),
        (6, 8, N'Ultrasonido', 'SRV', 0.0400, 40000, 95000),
        (6, 9, N'Procedimiento ambulatorio', 'SRV', 0.0400, 150000, 600000),
        (7, 0, N'Matrícula anual', 'SRV', 0.0200, 60000, 250000),
        (7, 1, N'Mensualidad primaria', 'SRV', 0.0200, 120000, 350000),
        (7, 2, N'Mensualidad secundaria', 'SRV', 0.0200, 150000, 450000),
        (7, 3, N'Curso de inglés mensual', 'SRV', 0.0200, 35000, 90000),
        (7, 4, N'Curso de programación', 'SRV', 0.0200, 60000, 250000),
        (7, 5, N'Taller de Excel', 'SRV', 0.0200, 25000, 80000),
        (7, 6, N'Tutoría de matemática', 'SRV', 0.0200, 8000, 20000),
        (7, 7, N'Preparación para admisión', 'SRV', 0.0200, 40000, 150000),
        (7, 8, N'Curso de cocina', 'SRV', 0.0200, 30000, 120000),
        (7, 9, N'Diplomado en administración', 'SRV', 0.0200, 150000, 450000),
        (8, 0, N'Juego de sábanas', 'PRD', 0.1300, 12000, 45000),
        (8, 1, N'Lámpara de pie', 'PRD', 0.1300, 15000, 60000),
        (8, 2, N'Silla de comedor', 'PRD', 0.1300, 25000, 75000),
        (8, 3, N'Mueble para TV', 'PRD', 0.1300, 40000, 160000),
        (8, 4, N'Escritorio', 'PRD', 0.1300, 45000, 180000),
        (8, 5, N'Ropero 2 puertas', 'PRD', 0.1300, 90000, 300000),
        (8, 6, N'Colchón matrimonial', 'PRD', 0.1300, 90000, 350000),
        (8, 7, N'Cama matrimonial', 'PRD', 0.1300, 120000, 400000),
        (8, 8, N'Mesa de comedor 6 puestos', 'PRD', 0.1300, 150000, 550000),
        (8, 9, N'Sofá 3 plazas', 'PRD', 0.1300, 180000, 650000),
        (9, 0, N'Soporte técnico por hora', 'SRV', 0.1300, 15000, 40000),
        (9, 1, N'Consultoría contable', 'SRV', 0.1300, 25000, 60000),
        (9, 2, N'Asesoría legal por hora', 'SRV', 0.1300, 35000, 90000),
        (9, 3, N'Declaración de impuestos', 'SRV', 0.1300, 30000, 150000),
        (9, 4, N'Redacción de contrato', 'SRV', 0.1300, 50000, 250000),
        (9, 5, N'Diseño de logotipo', 'SRV', 0.1300, 60000, 300000),
        (9, 6, N'Capacitación empresarial', 'SRV', 0.1300, 150000, 600000),
        (9, 7, N'Estudio de mercado', 'SRV', 0.1300, 300000, 1500000),
        (9, 8, N'Desarrollo de sitio web', 'SRV', 0.1300, 400000, 2500000),
        (9, 9, N'Auditoría financiera', 'SRV', 0.1300, 400000, 2500000),
        (10, 0, N'Envío de paquete local', 'SRV', 0.1300, 2500, 8000),
        (10, 1, N'Mensajería express', 'SRV', 0.1300, 3000, 12000),
        (10, 2, N'Envío de paquete nacional', 'SRV', 0.1300, 3500, 15000),
        (10, 3, N'Envío internacional', 'SRV', 0.1300, 25000, 150000),
        (10, 4, N'Almacenaje mensual', 'SRV', 0.1300, 50000, 350000),
        (10, 5, N'Flete de carga 1 tonelada', 'SRV', 0.1300, 60000, 250000),
        (10, 6, N'Transporte de personal', 'SRV', 0.1300, 70000, 250000),
        (10, 7, N'Distribución a comercios', 'SRV', 0.1300, 80000, 400000),
        (10, 8, N'Camión con chofer por día', 'SRV', 0.1300, 90000, 300000),
        (10, 9, N'Mudanza residencial', 'SRV', 0.1300, 120000, 500000)
    ) AS B (ID_RUBRO, ORDEN, NOMBRE, TIPO, TASA, PRECIO_MIN, PRECIO_MAX)
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
    ) AS A (ID_RUBRO, ORDEN, TEXTO)
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
    ) AS B (ID_RUBRO, ORDEN, TEXTO)
),

CONTEO AS (
    -- CUÁNTAS BASES Y ATRIBUTOS TIENE CADA RUBRO (SIN NÚMEROS QUEMADOS)
    SELECT
        R.ID_RUBRO,
        R.CODIGO_RUBRO,
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
    -- N = NÚMERO GLOBAL (1..1000); K = POSICIÓN DENTRO DE SU RUBRO (0..99)
    SELECT
        S.VALUE AS N,
        C.ID_RUBRO,
        C.CODIGO_RUBRO,
        C.REDONDEO,
        C.N_BASES,
        C.N_ATRIBUTO_A,
        -- HASHES INDEPENDIENTES POR PROPÓSITO (4 BYTES -> 0..4 294 967 295)
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
    -- K SE DESCOMPONE EN (BASE, ATRIBUTO A, ATRIBUTO B) SIN REPETIR COMBINACIÓN
    SELECT
        S.N,
        S.CODIGO_RUBRO,
        B.TIPO,
        B.TASA,
        S.H_EXISTENCIA,
        S.H_FECHA,
        S.H_ESTADO,
        CONCAT_WS(N' ', B.NOMBRE, A.TEXTO, AB.TEXTO) AS DESCRIPCION,
        -- FRACCIÓN EN [0, 1) AL CUADRADO: SESGA LOS PRECIOS HACIA EL MÍNIMO
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
    DESCRIPCION_PRODUCTO,
    PRECIO_UNITARIO,
    EXISTENCIA,
    TASA_IMPUESTO,
    ESTADO_PRODUCTO,
    FECHA_CREACION
)
SELECT
    -- PRD-MOD-00001 ...: CONSECUTIVO PROPIO POR RUBRO
    CONCAT(
        AR.TIPO, '-', AR.CODIGO_RUBRO, '-',
        RIGHT(
            CONCAT(
                '00000',
                ROW_NUMBER() OVER (PARTITION BY AR.CODIGO_RUBRO ORDER BY AR.N)
            ),
            5
        )
    ) AS CODIGO_INTERNO,
    AR.DESCRIPCION AS DESCRIPCION_PRODUCTO,
    CAST(AR.PRECIO AS DECIMAL(18, 5)) AS PRECIO_UNITARIO,
    CASE
        WHEN AR.TIPO = 'SRV' THEN 0
        ELSE CAST(AR.H_EXISTENCIA % 501 AS INT)
    END AS EXISTENCIA,
    CAST(AR.TASA AS DECIMAL(5, 4)) AS TASA_IMPUESTO,
    -- EXACTAMENTE EL 10 % DEL CATÁLOGO INACTIVO, REPARTIDO SIN PATRÓN VISIBLE
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
FROM ARMADO AS AR;
GO
