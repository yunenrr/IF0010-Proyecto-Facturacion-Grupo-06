USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_REGISTRAR_CLIENTE
    @CEDULA VARCHAR(12),
    @NOMBRE NVARCHAR(150),
    @CORREO VARCHAR(254),
    @TELEFONO VARCHAR(12),
    @ID_DISTRITO INT,
    @OTRAS_SENAS NVARCHAR(250),
    @ID_CLIENTE INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ID_CLIENTE = NULL;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'OK';

    DECLARE @ID_DIRECCION INT;
    DECLARE @NUEVO_ID INT;

    BEGIN TRY
        SET @CEDULA = LTRIM(RTRIM(@CEDULA));
        SET @NOMBRE = LTRIM(RTRIM(@NOMBRE));
        SET @CORREO = LTRIM(RTRIM(@CORREO));
        SET @TELEFONO = LTRIM(RTRIM(@TELEFONO));
        SET @OTRAS_SENAS = LTRIM(RTRIM(@OTRAS_SENAS));

        IF NULLIF(@CEDULA, '') IS NULL
            OR NULLIF(@NOMBRE, N'') IS NULL
            OR NULLIF(@CORREO, '') IS NULL
            OR NULLIF(@TELEFONO, '') IS NULL
            OR NULLIF(@OTRAS_SENAS, N'') IS NULL
            OR @ID_DISTRITO IS NULL
            THROW 50801, N'Falta un campo obligatorio.', 1;

        IF @CEDULA LIKE '%[^0-9]%' OR LEN(@CEDULA) NOT BETWEEN 9 AND 12
            THROW 50802,
                N'La cédula debe tener solo dígitos y entre 9 y 12 caracteres.',
                1;

        IF EXISTS (SELECT 1 FROM DBO.CLIENTE WHERE CEDULA_CLIENTE = @CEDULA)
            THROW 50803, N'Ya existe un cliente con esa cédula.', 1;

        IF @TELEFONO LIKE '%[^0-9]%' OR LEN(@TELEFONO) NOT BETWEEN 8 AND 12
            THROW 50804,
                N'El teléfono debe tener solo dígitos y entre 8 y 12 caracteres.',
                1;

        IF @CORREO LIKE '% %'
            OR @CORREO LIKE '%@%@%'
            OR @CORREO NOT LIKE '_%@_%._%'
            THROW 50805, N'El correo no tiene un formato válido.', 1;

        IF EXISTS (SELECT 1 FROM DBO.CLIENTE WHERE CORREO_CLIENTE = @CORREO)
            THROW 50806, N'Ese correo ya pertenece a otro cliente.', 1;

        IF NOT EXISTS (SELECT 1 FROM DBO.DISTRITO
                       WHERE ID_DISTRITO = @ID_DISTRITO)
            THROW 50807, N'El distrito no existe.', 1;


        BEGIN TRANSACTION;

        INSERT INTO DBO.DIRECCION (ID_DISTRITO, OTRAS_SENAS)
        VALUES (@ID_DISTRITO, @OTRAS_SENAS);

        SET @ID_DIRECCION = SCOPE_IDENTITY();

        INSERT INTO DBO.CLIENTE
            (CEDULA_CLIENTE, NOMBRE_CLIENTE, CORREO_CLIENTE,
             TELEFONO_CLIENTE, ID_DIRECCION)
        VALUES
            (@CEDULA, @NOMBRE, @CORREO, @TELEFONO, @ID_DIRECCION);

        SET @NUEVO_ID = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SET @ID_CLIENTE = @NUEVO_ID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @ID_CLIENTE = NULL;
        SET @CODIGO_ERROR = ERROR_NUMBER();
        SET @MENSAJE = ERROR_MESSAGE();
    END CATCH;
END;
GO
