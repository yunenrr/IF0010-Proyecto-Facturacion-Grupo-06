USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_CLIENTE
    @TOTAL_CLIENTES INT = 50000,
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
    DECLARE @TOTAL INT = @TOTAL_CLIENTES;

    DECLARE @Nombres TABLE (
        ID INT NOT NULL PRIMARY KEY,
        NOMBRE NVARCHAR(40) NOT NULL
    );

    DECLARE @Apellidos TABLE (
        ID INT NOT NULL PRIMARY KEY,
        APELLIDO NVARCHAR(40) NOT NULL
    );

    BEGIN TRY
        IF @TOTAL_CLIENTES < 1
            THROW 50761, N'El total de clientes debe ser mayor a 0.', 1;

        IF EXISTS (SELECT 1 FROM DBO.CLIENTE)
            BEGIN
                SET @MENSAJE = N'dbo.CLIENTE ya tiene datos. No se cargó nada.';
                RETURN;
            END;

        IF (SELECT COUNT(*) FROM DBO.DIRECCION) < @TOTAL_CLIENTES + 100
            THROW 50762,
            N'Faltan direcciones. Ejecute primero la carga de dbo.DIRECCION.',
            1;

        INSERT INTO @Nombres (ID, NOMBRE)
        VALUES
        (0, N'Juan'), (1, N'María'), (2, N'José'), (3, N'Ana'),
        (4, N'Carlos'), (5, N'Laura'), (6, N'Luis'), (7, N'Sofía'),
        (8, N'Andrés'), (9, N'Daniela'), (10, N'Diego'), (11, N'Valeria'),
        (12, N'Jorge'), (13, N'Carolina'), (14, N'Mauricio'), (15, N'Paola'),
        (16, N'Esteban'),
        (17, N'Fernanda'),
        (18, N'Ricardo'),
        (19, N'Gabriela');

        INSERT INTO @Apellidos (ID, APELLIDO)
        VALUES
        (0, N'Rodríguez'), (1, N'Jiménez'), (2, N'Mora'), (3, N'Vargas'),
        (4, N'Solís'), (5, N'Rojas'), (6, N'Araya'), (7, N'Chaves'),
        (8, N'Hernández'), (9, N'Castro'), (10, N'Gómez'), (11, N'Fernández'),
        (12, N'Calderón'), (13, N'Ramírez'), (14, N'Quesada'), (15, N'Salazar'),
        (16, N'Alvarado'), (17, N'Bonilla'), (18, N'Cordero'), (19, N'Segura'),
        (20, N'Zúñiga'), (21, N'Núñez'), (22, N'Villalobos'), (23, N'Méndez'),
        (24, N'Brenes');

        BEGIN TRANSACTION;

        WITH NUMEROS AS (
            SELECT TOP (@TOTAL) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
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

        INSERT INTO DBO.CLIENTE
        (
            CEDULA_CLIENTE, NOMBRE_CLIENTE, CORREO_CLIENTE, TELEFONO_CLIENTE,
            ID_DIRECCION, FECHA_REGISTRO, FECHA_ACTUALIZACION
        )
        SELECT
            CONCAT(
                NUM.N % 7 + 1,
                RIGHT(CONCAT('00000000', (NUM.N * 7919) % 100000000), 8)
            ) AS CEDULA_CLIENTE,
            CONCAT(
                NB.NOMBRE, N' ', A1.APELLIDO, N' ', A2.APELLIDO
            ) AS NOMBRE_CLIENTE,
            CONCAT(
                'cliente', NUM.N, '@',
                CHOOSE(
                    CAST(NUM.N % 4 AS INT) + 1,
                    'gmail.com', 'hotmail.com', 'outlook.com', 'yahoo.com'
                )
            ) AS CORREO_CLIENTE,
            CONCAT(
                CHOOSE(CAST(NUM.N % 3 AS INT) + 1, '6', '7', '8'),
                RIGHT(CONCAT('0000000', (NUM.N * 7919) % 10000000), 7)
            ) AS TELEFONO_CLIENTE,
            D.ID_DIRECCION,
            DATEADD(DAY, -NUM.DIAS_REG, @AHORA) AS FECHA_REGISTRO,
            DATEADD(DAY, -NUM.DIAS_ACT, @AHORA) AS FECHA_ACTUALIZACION
        FROM Y AS NUM
        INNER JOIN @Nombres AS NB ON NB.ID = NUM.N % 20
        INNER JOIN @Apellidos AS A1 ON A1.ID = (NUM.N / 20) % 25
        INNER JOIN @Apellidos AS A2 ON A2.ID = (NUM.N / 500) % 25
        INNER JOIN DIR AS D ON D.RN = NUM.N + 100;

        SET @FILAS_INSERTADAS = @@ROWCOUNT;

        IF @FILAS_INSERTADAS <> @TOTAL_CLIENTES
            THROW 50763,
            N'Los clientes insertados no coinciden con los solicitados.',
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

DECLARE @FILAS INT, @CODIGO INT, @MENSAJE NVARCHAR(4000);

EXEC DBO.USP_CARGAR_CLIENTE
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('CLIENTE: ', @FILAS, ' FILAS NUEVAS. ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
