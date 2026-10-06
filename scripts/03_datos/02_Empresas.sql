USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_EMPRESA
    @FILAS_INSERTADAS INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @FILAS_INSERTADAS = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Empresas cargadas.';

    DECLARE @Rubros TABLE (
        ID_RUBRO INT NOT NULL PRIMARY KEY,
        PREFIJO NVARCHAR(50) NOT NULL,
        ACTIVIDAD NVARCHAR(60) NOT NULL
    );

    DECLARE @Sufijos TABLE (
        ID_SUFIJO INT NOT NULL PRIMARY KEY,
        SUFIJO NVARCHAR(50) NOT NULL
    );

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM DBO.EMPRESA)
            BEGIN
                SET @MENSAJE = N'dbo.EMPRESA ya tiene datos. No se cargó nada.';
                RETURN;
            END;

        IF (SELECT COUNT(*) FROM DBO.DIRECCION) < 100
            THROW 50751,
            N'Se necesitan al menos 100 direcciones.',
            1;

        INSERT INTO @Rubros (ID_RUBRO, PREFIJO, ACTIVIDAD)
        VALUES
        (1, N'Moda', N'Ropa y Vestimenta'),
        (2, N'Electro', N'Electrodomésticos'),
        (3, N'Tecno', N'Tecnología y Computación'),
        (4, N'Súper', N'Supermercado y Alimentos'),
        (5, N'Ferretería', N'Ferretería y Construcción'),
        (6, N'Clínica', N'Salud Privada'),
        (7, N'Instituto', N'Servicios Educativos'),
        (8, N'Muebles', N'Muebles y Hogar'),
        (9, N'Consultores', N'Servicios Profesionales'),
        (10, N'Transportes', N'Transporte y Logística');

        INSERT INTO @Sufijos (ID_SUFIJO, SUFIJO)
        VALUES
        (1, N'Los Alpes'),
        (2, N'El Roble'),
        (3, N'La Estrella'),
        (4, N'Del Valle'),
        (5, N'Central'),
        (6, N'Pacífico'),
        (7, N'Cordillera'),
        (8, N'Real'),
        (9, N'Sol'),
        (10, N'Horizonte');

        BEGIN TRANSACTION;

        WITH DIR AS (
            SELECT
                ID_DIRECCION,
                ROW_NUMBER() OVER (ORDER BY ID_DIRECCION) AS RN
            FROM DBO.DIRECCION
        ),

        BASE AS (
            SELECT
                R.PREFIJO,
                R.ACTIVIDAD,
                S.SUFIJO,
                ROW_NUMBER() OVER (ORDER BY R.ID_RUBRO, S.ID_SUFIJO) AS N
            FROM @Rubros AS R
            CROSS JOIN @Sufijos AS S
        )

        INSERT INTO DBO.EMPRESA
        (
            NOMBRE_COMERCIAL, RAZON_SOCIAL, CEDULA_EMPRESA, ID_DIRECCION,
            TELEFONO_EMPRESA, CORREO_ELECTRONICO, FECHA_CREACION, ESTA_ACTIVA
        )
        SELECT
            CONCAT(B.PREFIJO, N' ', B.SUFIJO) AS NOMBRE_COMERCIAL,
            CONCAT(
                N'Grupo ', B.SUFIJO, N' ', B.ACTIVIDAD, N' S.A.'
            ) AS RAZON_SOCIAL,
            CONCAT(
                '3101', RIGHT(CONCAT('000000', B.N), 6)
            ) AS CEDULA_EMPRESA,
            D.ID_DIRECCION,
            CONCAT(
                '22', RIGHT(CONCAT('000000', B.N), 6)
            ) AS TELEFONO_EMPRESA,
            CONCAT('contacto', B.N, '@empresas.cr') AS CORREO_ELECTRONICO,
            DATEADD(
                DAY, -CAST(730 + (B.N * 13) % 1000 AS INT), SYSDATETIME()
            ) AS FECHA_CREACION,
            CASE WHEN B.N % 10 = 0 THEN 0 ELSE 1 END AS ESTA_ACTIVA
        FROM BASE AS B
        INNER JOIN DIR AS D
            ON B.N = D.RN;

        SET @FILAS_INSERTADAS = @@ROWCOUNT;

        IF @FILAS_INSERTADAS <> 100
            THROW 50752,
            N'Las empresas insertadas no son las 100 esperadas.',
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

EXEC DBO.USP_CARGAR_EMPRESA
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('EMPRESA: ', @FILAS, ' FILAS NUEVAS. ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
