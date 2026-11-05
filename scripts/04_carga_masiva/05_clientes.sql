/* CARGA DE CLIENTES — PERSONAS FÍSICAS Y JURÍDICAS.
   PARA CADA CLIENTE, SUS DATOS COMUNES SE INSERTAN EN DBO.CLIENTE
   Y LOS DEMÁS DATOS EN SU SUBTIPO (FISICO O JURIDICO). */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_CLIENTE
    @TOTAL_CLIENTES INT = 50000, -- PERSONAS FÍSICAS
    @TOTAL_JURIDICOS INT = 5000,
    @FILAS_INSERTADAS INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @FILAS_INSERTADAS = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Clientes cargados.';

    DECLARE @AHORA DATETIME2(3) = SYSDATETIME();
    DECLARE @FISICOS_INSERTADOS INT;
    DECLARE @JURIDICOS_INSERTADOS INT;

    DECLARE @NOMBRES TABLE (
        ID INT NOT NULL PRIMARY KEY,
        NOMBRE NVARCHAR(40) NOT NULL
    );

    DECLARE @APELLIDOS TABLE (
        ID INT NOT NULL PRIMARY KEY,
        APELLIDO NVARCHAR(40) NOT NULL
    );

    DECLARE @GIROS TABLE (
        ID INT NOT NULL PRIMARY KEY,
        GIRO NVARCHAR(40) NOT NULL
    );

    DECLARE @LUGARES TABLE (
        ID INT NOT NULL PRIMARY KEY,
        LUGAR NVARCHAR(40) NOT NULL
    );

    DECLARE @SOCIEDADES TABLE (
        ID INT NOT NULL PRIMARY KEY,
        SOCIEDAD NVARCHAR(40) NOT NULL
    );

    CREATE TABLE #FISICOS (
        N INT NOT NULL PRIMARY KEY,
        CEDULA VARCHAR(12) NOT NULL,
        NOMBRE NVARCHAR(50) NOT NULL,
        PRIMER_APELLIDO NVARCHAR(50) NOT NULL,
        SEGUNDO_APELLIDO NVARCHAR(50) NOT NULL,
        CORREO VARCHAR(254) NOT NULL,
        TELEFONO VARCHAR(12) NOT NULL,
        ID_DIRECCION INT NOT NULL,
        FECHA_REGISTRO DATETIME2(3) NOT NULL,
        FECHA_ACTUALIZACION DATETIME2(3) NOT NULL
    );

    CREATE TABLE #JURIDICOS (
        N INT NOT NULL PRIMARY KEY,
        CEDULA VARCHAR(12) NOT NULL,
        RAZON_SOCIAL NVARCHAR(150) NOT NULL,
        NOMBRE_COMERCIAL NVARCHAR(150) NOT NULL,
        CORREO VARCHAR(254) NOT NULL,
        TELEFONO VARCHAR(12) NOT NULL,
        ID_DIRECCION INT NOT NULL,
        FECHA_REGISTRO DATETIME2(3) NOT NULL,
        FECHA_ACTUALIZACION DATETIME2(3) NOT NULL
    );

    BEGIN TRY
        IF @TOTAL_CLIENTES < 1
            THROW 50761, N'El total de clientes debe ser mayor a 0.', 1;

        IF @TOTAL_JURIDICOS < 1 OR @TOTAL_JURIDICOS > 15600
            THROW 50764,
            N'El total de jurídicos debe estar entre 1 y 15 600.',
            1;

        IF EXISTS (SELECT 1 FROM DBO.CLIENTE)
            BEGIN
                SET @MENSAJE = N'dbo.CLIENTE ya tiene datos. No se cargó nada.';
                RETURN;
            END;

        IF
            (SELECT COUNT(*) FROM DBO.DIRECCION)
            < @TOTAL_CLIENTES + @TOTAL_JURIDICOS + 100
            THROW 50762,
            N'Faltan direcciones. Ejecute primero la carga de dbo.DIRECCION.',
            1;

        INSERT INTO @NOMBRES (ID, NOMBRE)
        VALUES
        (0, N'Juan'), (1, N'María'), (2, N'José'), (3, N'Ana'),
        (4, N'Carlos'), (5, N'Laura'), (6, N'Luis'), (7, N'Sofía'),
        (8, N'Andrés'), (9, N'Daniela'), (10, N'Diego'), (11, N'Valeria'),
        (12, N'Jorge'), (13, N'Carolina'), (14, N'Mauricio'), (15, N'Paola'),
        (16, N'Esteban'),
        (17, N'Fernanda'),
        (18, N'Ricardo'),
        (19, N'Gabriela'),
        (20, N'Alejandro'), (21, N'Natalia'), (22, N'Fabián'), (23, N'Mariana'),
        (24, N'Sebastián'), (25, N'Camila'), (26, N'Gustavo'), (27, N'Andrea'),
        (28, N'Roberto'), (29, N'Melissa'), (30, N'Adrián'), (31, N'Karla'),
        (32, N'Pablo'), (33, N'Tatiana'), (34, N'Kevin'), (35, N'Silvia'),
        (36, N'Óscar'), (37, N'Verónica'), (38, N'Manuel'), (39, N'Adriana');

        INSERT INTO @APELLIDOS (ID, APELLIDO)
        VALUES
        (0, N'Rodríguez'), (1, N'Jiménez'), (2, N'Mora'), (3, N'Vargas'),
        (4, N'Solís'), (5, N'Rojas'), (6, N'Araya'), (7, N'Chaves'),
        (8, N'Hernández'), (9, N'Castro'), (10, N'Gómez'), (11, N'Fernández'),
        (12, N'Calderón'), (13, N'Ramírez'), (14, N'Quesada'), (15, N'Salazar'),
        (16, N'Alvarado'), (17, N'Bonilla'), (18, N'Cordero'), (19, N'Segura'),
        (20, N'Zúñiga'), (21, N'Núñez'), (22, N'Villalobos'), (23, N'Méndez'),
        (24, N'Brenes'),
        (25, N'Sánchez'), (26, N'Pérez'), (27, N'Campos'), (28, N'Arias'),
        (29, N'Herrera'), (30, N'Ulate'), (31, N'Porras'), (32, N'Montero'),
        (33, N'Madrigal'), (34, N'Badilla'), (35, N'Vega'), (36, N'Sibaja'),
        (37, N'Carvajal'), (38, N'Acuña'), (39, N'Murillo');

        -- NOMBRE COMERCIAL = GIRO + LUGAR
        INSERT INTO @GIROS (ID, GIRO)
        VALUES
        (0, N'Ferretería'), (1, N'Soda'), (2, N'Librería'), (3, N'Farmacia'),
        (4, N'Panadería'), (5, N'Taller'), (6, N'Óptica'), (7, N'Floristería'),
        (8, N'Veterinaria'), (9, N'Pulpería'), (10, N'Distribuidora'),
        (11, N'Constructora'), (12, N'Consultores'), (13, N'Transportes'),
        (14, N'Importadora'), (15, N'Agroservicios'), (16, N'Repuestos'),
        (17, N'Clínica'), (18, N'Academia'), (19, N'Mueblería');

        INSERT INTO @LUGARES (ID, LUGAR)
        VALUES
        (0, N'El Roble'), (1, N'La Esperanza'), (2, N'San Martín'),
        (3, N'Los Pinos'), (4, N'El Faro'), (5, N'La Montaña'),
        (6, N'Del Valle'), (7, N'Las Palmas'), (8, N'El Sol'),
        (9, N'La Costa'), (10, N'Monteverde'), (11, N'Río Claro'),
        (12, N'Santa Fe'), (13, N'El Cedro'), (14, N'La Sabana'),
        (15, N'Bella Vista'), (16, N'El Prado'), (17, N'Las Brisas'),
        (18, N'La Fuente'), (19, N'Cerro Azul'), (20, N'Arenal'),
        (21, N'Tortuguero'), (22, N'Irazú'), (23, N'Turrialba'),
        (24, N'Barva');

        -- RAZÓN SOCIAL = SOCIEDAD + APELLIDO + APELLIDO + S.R.L.
        INSERT INTO @SOCIEDADES (ID, SOCIEDAD)
        VALUES
        (0, N'Inversiones'), (1, N'Comercializadora'), (2, N'Corporación'),
        (3, N'Desarrollos'), (4, N'Servicios Integrales'),
        (5, N'Grupo Empresarial'), (6, N'Representaciones'),
        (7, N'Inmobiliaria'), (8, N'Soluciones'), (9, N'Importaciones');

        -- 1. PERSONAS FÍSICAS: CÉDULA DE 9 DÍGITOS
        WITH NUMEROS AS (
            SELECT TOP (@TOTAL_CLIENTES)
                ROW_NUMBER()
                    OVER (ORDER BY (SELECT NULL)) AS N
            FROM SYS.ALL_OBJECTS AS A
            CROSS JOIN SYS.ALL_OBJECTS AS B
        ),

        DIR AS (
            SELECT
                ID_DIRECCION,
                ROW_NUMBER() OVER (ORDER BY ID_DIRECCION) AS RN
            FROM DBO.DIRECCION
        ),

        X AS (
            SELECT
                NUMEROS.N,
                CAST(366 + NUMEROS.N % 1095 AS INT) AS DIAS_REG
            FROM NUMEROS
        ),

        Y AS (
            SELECT
                X.N,
                X.DIAS_REG,
                CAST((X.N * 31) % (X.DIAS_REG + 1) AS INT) AS DIAS_ACT
            FROM X
        )

        INSERT INTO #FISICOS (
            N, CEDULA, NOMBRE, PRIMER_APELLIDO, SEGUNDO_APELLIDO, CORREO,
            TELEFONO, ID_DIRECCION, FECHA_REGISTRO, FECHA_ACTUALIZACION
        )
        SELECT
            NUM.N,
            CONCAT(
                NUM.N % 7 + 1,
                RIGHT(CONCAT('00000000', (NUM.N * 7919) % 100000000), 8)
            ) AS CEDULA,
            NB.NOMBRE,
            A1.APELLIDO AS PRIMER_APELLIDO,
            A2.APELLIDO AS SEGUNDO_APELLIDO,
            CONCAT(
                'cliente', NUM.N, '@',
                CHOOSE(
                    CAST(NUM.N % 4 AS INT) + 1,
                    'gmail.com', 'hotmail.com', 'outlook.com', 'yahoo.com'
                )
            ) AS CORREO,
            CONCAT(
                CHOOSE(CAST(NUM.N % 3 AS INT) + 1, '6', '7', '8'),
                RIGHT(CONCAT('0000000', (NUM.N * 7919) % 10000000), 7)
            ) AS TELEFONO,
            D.ID_DIRECCION,
            DATEADD(DAY, -NUM.DIAS_REG, @AHORA) AS FECHA_REGISTRO,
            DATEADD(DAY, -NUM.DIAS_ACT, @AHORA) AS FECHA_ACTUALIZACION
        FROM Y AS NUM
        INNER JOIN @NOMBRES AS NB ON NUM.N % 40 = NB.ID
        INNER JOIN @APELLIDOS AS A1 ON (NUM.N / 40) % 40 = A1.ID
        INNER JOIN @APELLIDOS AS A2 ON (NUM.N / 1600) % 40 = A2.ID
        INNER JOIN DIR AS D ON NUM.N + 100 = D.RN;

        -- 2. PERSONAS JURÍDICAS: CÉDULA 3102 + 6 DÍGITOS (S.R.L.).
        WITH NUMEROS AS (
            SELECT TOP (@TOTAL_JURIDICOS)
                ROW_NUMBER()
                    OVER (ORDER BY (SELECT NULL)) AS N
            FROM SYS.ALL_OBJECTS AS A
            CROSS JOIN SYS.ALL_OBJECTS AS B
        ),

        DIR AS (
            SELECT
                ID_DIRECCION,
                ROW_NUMBER() OVER (ORDER BY ID_DIRECCION) AS RN
            FROM DBO.DIRECCION
        ),

        X AS (
            SELECT
                NUMEROS.N,
                CAST((NUMEROS.N / 10) % 40 AS INT) AS ID_AP1,
                CAST(366 + (NUMEROS.N * 7) % 1095 AS INT) AS DIAS_REG
            FROM NUMEROS
        ),

        Y AS (
            SELECT
                X.N,
                X.ID_AP1,
                X.DIAS_REG,
                -- EL SEGUNDO APELLIDO NUNCA ES IGUAL AL PRIMERO
                CAST((X.ID_AP1 + 1 + (X.N / 400) % 39) % 40 AS INT) AS ID_AP2,
                CAST((X.N * 31) % (X.DIAS_REG + 1) AS INT) AS DIAS_ACT
            FROM X
        )

        INSERT INTO #JURIDICOS (
            N, CEDULA, RAZON_SOCIAL, NOMBRE_COMERCIAL, CORREO, TELEFONO,
            ID_DIRECCION, FECHA_REGISTRO, FECHA_ACTUALIZACION
        )
        SELECT
            NUM.N,
            CONCAT(
                '3102',
                RIGHT(CONCAT('000000', (NUM.N * 7919) % 1000000), 6)
            ) AS CEDULA,
            CONCAT(
                S.SOCIEDAD, N' ', A1.APELLIDO, N' y ', A2.APELLIDO, N' S.R.L.'
            ) AS RAZON_SOCIAL,
            CONCAT(G.GIRO, N' ', L.LUGAR) AS NOMBRE_COMERCIAL,
            CONCAT(
                'facturacion', NUM.N, '@',
                CHOOSE(
                    CAST(NUM.N % 3 AS INT) + 1,
                    'empresa.cr', 'negocios.cr', 'comercial.cr'
                )
            ) AS CORREO,
            CONCAT(
                '2', RIGHT(CONCAT('0000000', (NUM.N * 7919) % 10000000), 7)
            ) AS TELEFONO,
            D.ID_DIRECCION,
            DATEADD(DAY, -NUM.DIAS_REG, @AHORA) AS FECHA_REGISTRO,
            DATEADD(DAY, -NUM.DIAS_ACT, @AHORA) AS FECHA_ACTUALIZACION
        FROM Y AS NUM
        INNER JOIN @SOCIEDADES AS S ON NUM.N % 10 = S.ID
        INNER JOIN @APELLIDOS AS A1 ON NUM.ID_AP1 = A1.ID
        INNER JOIN @APELLIDOS AS A2 ON NUM.ID_AP2 = A2.ID
        INNER JOIN @GIROS AS G ON NUM.N % 20 = G.ID
        INNER JOIN @LUGARES AS L ON (NUM.N / 20) % 25 = L.ID
        INNER JOIN DIR AS D ON @TOTAL_CLIENTES + 100 + NUM.N = D.RN;

        BEGIN TRANSACTION;

        -- 3. FÍSICOS: SUPERTIPO Y LUEGO SUBTIPO
        INSERT INTO DBO.CLIENTE (
            CEDULA_CLIENTE, CORREO_CLIENTE, TELEFONO_CLIENTE, ID_DIRECCION,
            FECHA_REGISTRO, FECHA_ACTUALIZACION
        )
        SELECT
            F.CEDULA,
            F.CORREO,
            F.TELEFONO,
            F.ID_DIRECCION,
            F.FECHA_REGISTRO,
            F.FECHA_ACTUALIZACION
        FROM #FISICOS AS F
        ORDER BY F.N;

        INSERT INTO DBO.CLIENTE_FISICO (
            ID_CLIENTE, NOMBRE, PRIMER_APELLIDO, SEGUNDO_APELLIDO
        )
        SELECT
            C.ID_CLIENTE,
            F.NOMBRE,
            F.PRIMER_APELLIDO,
            F.SEGUNDO_APELLIDO
        FROM #FISICOS AS F
        INNER JOIN DBO.CLIENTE AS C
            ON F.CEDULA = C.CEDULA_CLIENTE;

        SET @FISICOS_INSERTADOS = @@ROWCOUNT;

        -- 4. JURÍDICOS: SUPERTIPO Y LUEGO SUBTIPO
        INSERT INTO DBO.CLIENTE (
            CEDULA_CLIENTE, CORREO_CLIENTE, TELEFONO_CLIENTE, ID_DIRECCION,
            FECHA_REGISTRO, FECHA_ACTUALIZACION
        )
        SELECT
            J.CEDULA,
            J.CORREO,
            J.TELEFONO,
            J.ID_DIRECCION,
            J.FECHA_REGISTRO,
            J.FECHA_ACTUALIZACION
        FROM #JURIDICOS AS J
        ORDER BY J.N;

        INSERT INTO DBO.CLIENTE_JURIDICO (
            ID_CLIENTE, RAZON_SOCIAL, NOMBRE_COMERCIAL
        )
        SELECT
            C.ID_CLIENTE,
            J.RAZON_SOCIAL,
            J.NOMBRE_COMERCIAL
        FROM #JURIDICOS AS J
        INNER JOIN DBO.CLIENTE AS C
            ON J.CEDULA = C.CEDULA_CLIENTE;

        SET @JURIDICOS_INSERTADOS = @@ROWCOUNT;

        IF
            @FISICOS_INSERTADOS <> @TOTAL_CLIENTES
            OR @JURIDICOS_INSERTADOS <> @TOTAL_JURIDICOS
            THROW 50763,
            N'Los clientes insertados no coinciden con los solicitados.',
            1;

        SET @FILAS_INSERTADAS = @FISICOS_INSERTADOS + @JURIDICOS_INSERTADOS;

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

DECLARE @FILAS INT, @CODIGO INT, @MENSAJE NVARCHAR(4000);

EXEC DBO.USP_CARGAR_CLIENTE
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('CLIENTE: ', @FILAS, ' FILAS NUEVAS. ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
