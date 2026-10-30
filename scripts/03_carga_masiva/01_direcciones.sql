USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_DIRECCION
    @TOTAL_FILAS INT = 55100, -- 100 EMPRESAS + 55 000 CLIENTES
    @FILAS_INSERTADAS INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @FILAS_INSERTADAS = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Direcciones cargadas.';

    DECLARE @TOTAL_DISTRITOS INT;

    BEGIN TRY
        IF @TOTAL_FILAS < 1
            THROW 50741, N'El total de filas debe ser mayor que 0.', 1;

        SELECT @TOTAL_DISTRITOS = COUNT(*) FROM DBO.DISTRITO;

        IF @TOTAL_DISTRITOS = 0
            THROW 50742,
            N'dbo.DISTRITO está vacía. Cargue primero los distritos.',
            1;

        IF EXISTS (SELECT 1 FROM DBO.DIRECCION)
            BEGIN
                SET @MENSAJE = N'DIRECCION ya tiene datos. No se cargó nada.';
                RETURN;
            END;

        BEGIN TRANSACTION;

        WITH NUMEROS AS (
            SELECT TOP (@TOTAL_FILAS)
                ROW_NUMBER()
                    OVER (ORDER BY (SELECT NULL)) AS N
            FROM SYS.ALL_OBJECTS AS A
            CROSS JOIN SYS.ALL_OBJECTS AS B
        ),

        DIST AS (
            SELECT
                ID_DISTRITO,
                ROW_NUMBER() OVER (ORDER BY ID_DISTRITO) - 1 AS IDX
            FROM DBO.DISTRITO
        )

        INSERT INTO DBO.DIRECCION (ID_DISTRITO, OTRAS_SENAS)
        SELECT
            D.ID_DISTRITO,
            CONCAT(
                N'Calle ', (NUM.N % 50) + 1, N', casa #', NUM.N
            ) AS OTRAS_SENAS
        FROM NUMEROS AS NUM
        INNER JOIN DIST AS D
            ON D.IDX = NUM.N % @TOTAL_DISTRITOS;

        SET @FILAS_INSERTADAS = @@ROWCOUNT;

        IF @FILAS_INSERTADAS <> @TOTAL_FILAS
            THROW 50743,
            N'Las direcciones insertadas no coinciden con las solicitadas.',
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

EXEC DBO.USP_CARGAR_DIRECCION
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('DIRECCION: ', @FILAS, ' FILAS NUEVAS. ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
