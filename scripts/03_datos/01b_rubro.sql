/* DATOS DE DBO.RUBRO — ACTIVIDADES ECONÓMICAS DE EMPRESAS Y PRODUCTOS. */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_CARGAR_RUBRO
    @FILAS_INSERTADAS INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @FILAS_INSERTADAS = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Rubros cargados.';

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO DBO.RUBRO (
            ID_RUBRO,
            CODIGO_RUBRO,
            NOMBRE_RUBRO
        )
        SELECT
            V.ID_RUBRO,
            V.CODIGO_RUBRO,
            V.NOMBRE_RUBRO
        FROM (
            VALUES
            (1, 'MOD', N'Ropa y Vestimenta'),
            (2, 'ELE', N'Electrodomésticos'),
            (3, 'TEC', N'Tecnología y Computación'),
            (4, 'SUP', N'Supermercado y Alimentos'),
            (5, 'FER', N'Ferretería y Construcción'),
            (6, 'CLI', N'Salud Privada'),
            (7, 'INS', N'Servicios Educativos'),
            (8, 'MUE', N'Muebles y Hogar'),
            (9, 'CON', N'Servicios Profesionales'),
            (10, 'TRA', N'Transporte y Logística')
        ) AS V(ID_RUBRO, CODIGO_RUBRO, NOMBRE_RUBRO)
        WHERE NOT EXISTS (
            SELECT 1
            FROM DBO.RUBRO AS T
            WHERE T.ID_RUBRO = V.ID_RUBRO
        );

        SET @FILAS_INSERTADAS = @@ROWCOUNT;

        IF (SELECT COUNT(*) FROM DBO.RUBRO) < 10
            THROW 50715,
            N'El catálogo de rubros quedó incompleto.',
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

EXEC DBO.USP_CARGAR_RUBRO
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('RUBRO: ', @FILAS, ' fila(s) nueva(s). ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
