USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.DATOS_DIRECCIONES
    @FILAS_INSERTADAS INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @FILAS_INSERTADAS = 0;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'División territorial cargada.';

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO DBO.PROVINCIA (ID_PROVINCIA, NOMBRE_PROVINCIA)
        SELECT
            V.ID_PROVINCIA,
            V.NOMBRE_PROVINCIA
        FROM (
            VALUES
            (1, N'San José'),
            (2, N'Alajuela'),
            (3, N'Cartago'),
            (4, N'Heredia'),
            (5, N'Guanacaste'),
            (6, N'Puntarenas'),
            (7, N'Limón')
        ) AS V (ID_PROVINCIA, NOMBRE_PROVINCIA)
        WHERE NOT EXISTS (
            SELECT 1 FROM DBO.PROVINCIA AS P
            WHERE P.ID_PROVINCIA = V.ID_PROVINCIA
        );

        SET @FILAS_INSERTADAS = @@ROWCOUNT;

        INSERT INTO DBO.CANTON (ID_CANTON, ID_PROVINCIA, NOMBRE_CANTON)
        SELECT
            V.ID_CANTON,
            V.ID_PROVINCIA,
            V.NOMBRE_CANTON
        FROM (
            VALUES
            (101, 1, N'San José'),
            (102, 1, N'Escazú'),
            (103, 1, N'Desamparados'),
            (108, 1, N'Goicoechea'),
            (115, 1, N'Montes de Oca'),
            (201, 2, N'Alajuela'),
            (202, 2, N'San Ramón'),
            (203, 2, N'Grecia'),
            (301, 3, N'Cartago'),
            (302, 3, N'Paraíso'),
            (305, 3, N'Turrialba'),
            (401, 4, N'Heredia'),
            (402, 4, N'Barva'),
            (403, 4, N'Santo Domingo'),
            (501, 5, N'Liberia'),
            (502, 5, N'Nicoya'),
            (503, 5, N'Santa Cruz'),
            (601, 6, N'Puntarenas'),
            (602, 6, N'Esparza'),
            (606, 6, N'Quepos'),
            (701, 7, N'Limón'),
            (702, 7, N'Pococí'),
            (703, 7, N'Siquirres')
        ) AS V (ID_CANTON, ID_PROVINCIA, NOMBRE_CANTON)
        WHERE NOT EXISTS (
            SELECT 1 FROM DBO.CANTON AS C
            WHERE C.ID_CANTON = V.ID_CANTON
        );

        SET @FILAS_INSERTADAS = @FILAS_INSERTADAS + @@ROWCOUNT;

        INSERT INTO DBO.DISTRITO (ID_DISTRITO, ID_CANTON, NOMBRE_DISTRITO)
        SELECT
            V.ID_DISTRITO,
            V.ID_CANTON,
            V.NOMBRE_DISTRITO
        FROM (
            VALUES
            (10101, 101, N'Carmen'),
            (10102, 101, N'Merced'),
            (10103, 101, N'Hospital'),
            (10104, 101, N'Catedral'),
            (10201, 102, N'Escazú'),
            (10202, 102, N'San Antonio'),
            (10203, 102, N'San Rafael'),
            (10301, 103, N'Desamparados'),
            (10302, 103, N'San Miguel'),
            (10303, 103, N'San Juan de Dios'),
            (10801, 108, N'Guadalupe'),
            (10802, 108, N'San Francisco'),
            (10803, 108, N'Calle Blancos'),
            (11501, 115, N'San Pedro'),
            (11502, 115, N'Sabanilla'),
            (11503, 115, N'Mercedes'),
            (11504, 115, N'San Rafael'),
            (20101, 201, N'Alajuela'),
            (20102, 201, N'San José'),
            (20103, 201, N'Carrizal'),
            (20104, 201, N'San Antonio'),
            (20105, 201, N'Guácima'),
            (20201, 202, N'San Ramón'),
            (20202, 202, N'Santiago'),
            (20203, 202, N'San Juan'),
            (20301, 203, N'Grecia'),
            (20302, 203, N'San Isidro'),
            (20303, 203, N'San José'),
            (30101, 301, N'Oriental'),
            (30102, 301, N'Occidental'),
            (30103, 301, N'Carmen'),
            (30104, 301, N'San Nicolás'),
            (30201, 302, N'Paraíso'),
            (30202, 302, N'Santiago'),
            (30203, 302, N'Orosi'),
            (30501, 305, N'Turrialba'),
            (30502, 305, N'La Suiza'),
            (30503, 305, N'Peralta'),
            (40101, 401, N'Heredia'),
            (40102, 401, N'Mercedes'),
            (40103, 401, N'San Francisco'),
            (40104, 401, N'Ulloa'),
            (40105, 401, N'Varablanca'),
            (40201, 402, N'Barva'),
            (40202, 402, N'San Pedro'),
            (40203, 402, N'San Pablo'),
            (40301, 403, N'Santo Domingo'),
            (40302, 403, N'San Vicente'),
            (40303, 403, N'San Miguel'),
            (50101, 501, N'Liberia'),
            (50102, 501, N'Cañas Dulces'),
            (50103, 501, N'Mayorga'),
            (50104, 501, N'Nacascolo'),
            (50105, 501, N'Curubandé'),
            (50201, 502, N'Nicoya'),
            (50202, 502, N'Mansión'),
            (50203, 502, N'San Antonio'),
            (50301, 503, N'Santa Cruz'),
            (50302, 503, N'Bolsón'),
            (50303, 503, N'Veintisiete de Abril'),
            (60101, 601, N'Puntarenas'),
            (60102, 601, N'Pitahaya'),
            (60103, 601, N'Chomes'),
            (60201, 602, N'Espíritu Santo'),
            (60202, 602, N'San Juan Grande'),
            (60203, 602, N'Macacona'),
            (60601, 606, N'Quepos'),
            (60602, 606, N'Savegre'),
            (60603, 606, N'Naranjito'),
            (70101, 701, N'Limón'),
            (70102, 701, N'Valle La Estrella'),
            (70103, 701, N'Río Blanco'),
            (70104, 701, N'Matama'),
            (70201, 702, N'Guápiles'),
            (70202, 702, N'Jiménez'),
            (70203, 702, N'Rita'),
            (70204, 702, N'Roxana'),
            (70205, 702, N'Cariari'),
            (70301, 703, N'Siquirres'),
            (70302, 703, N'Pacuarito'),
            (70303, 703, N'Florida')
        ) AS V (ID_DISTRITO, ID_CANTON, NOMBRE_DISTRITO)
        WHERE NOT EXISTS (
            SELECT 1 FROM DBO.DISTRITO AS D
            WHERE D.ID_DISTRITO = V.ID_DISTRITO
        );

        SET @FILAS_INSERTADAS = @FILAS_INSERTADAS + @@ROWCOUNT;

        IF
            (SELECT COUNT(*) FROM DBO.PROVINCIA) < 7
            OR (SELECT COUNT(*) FROM DBO.CANTON) < 23
            OR (SELECT COUNT(*) FROM DBO.DISTRITO) < 81
            THROW 50731,
            N'El catálogo de la división territorial quedó incompleto.',
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

EXEC DBO.DATOS_DIRECCIONES
    @FILAS_INSERTADAS = @FILAS OUTPUT,
    @CODIGO_ERROR = @CODIGO OUTPUT,
    @MENSAJE = @MENSAJE OUTPUT;

PRINT CONCAT('DIVISIÓN TERRITORIAL: ', @FILAS, ' FILA(S) NUEVA(S). ', @MENSAJE);

IF @CODIGO <> 0
    THROW 50700, @MENSAJE, 1;
GO
