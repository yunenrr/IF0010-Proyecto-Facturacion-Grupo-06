/* DBO.USP_REGISTRAR_CLIENTE_JURIDICO — REGISTRA UNA PERSONA JURÍDICA, SU
   DIRECCIÓN, SUS DATOS COMUNES EN DBO.CLIENTE, SU RAZÓN SOCIAL Y NOMBRE
   COMERCIAL EN DBO.CLIENTE_JURIDICO */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_REGISTRAR_CLIENTE_JURIDICO
    @CEDULA VARCHAR(12),
    @RAZON_SOCIAL NVARCHAR(150),
    @NOMBRE_COMERCIAL NVARCHAR(150),
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
        SET @RAZON_SOCIAL = LTRIM(RTRIM(@RAZON_SOCIAL));
        SET @NOMBRE_COMERCIAL = LTRIM(RTRIM(@NOMBRE_COMERCIAL));
        SET @CORREO = LTRIM(RTRIM(@CORREO));
        SET @TELEFONO = LTRIM(RTRIM(@TELEFONO));
        SET @OTRAS_SENAS = LTRIM(RTRIM(@OTRAS_SENAS));

        IF
            NULLIF(@CEDULA, '') IS NULL
            OR NULLIF(@RAZON_SOCIAL, N'') IS NULL
            OR NULLIF(@NOMBRE_COMERCIAL, N'') IS NULL
            OR NULLIF(@CORREO, '') IS NULL
            OR NULLIF(@TELEFONO, '') IS NULL
            OR NULLIF(@OTRAS_SENAS, N'') IS NULL
            OR @ID_DISTRITO IS NULL
            THROW 51001, N'Falta un campo obligatorio.', 1;

        IF
            @CEDULA LIKE '%[^0-9]%'
            OR LEN(@CEDULA) <> 10
            OR LEFT(@CEDULA, 1) <> '3'
            THROW 51002,
            N'La cédula jurídica debe tener 10 dígitos y empezar con 3.',
            1;

        IF
            EXISTS (
                SELECT 1 FROM DBO.CLIENTE
                WHERE CEDULA_CLIENTE = @CEDULA
            )
            THROW 51003, N'Ya existe un cliente con esa cédula.', 1;

        IF @TELEFONO LIKE '%[^0-9]%' OR LEN(@TELEFONO) <> 8
            THROW 51004, N'El teléfono debe tener exactamente 8 dígitos.', 1;

        IF
            @CORREO LIKE '% %'
            OR @CORREO LIKE '%@%@%'
            OR @CORREO NOT LIKE '_%@_%._%'
            THROW 51005, N'El correo no tiene un formato válido.', 1;

        IF
            EXISTS (
                SELECT 1 FROM DBO.CLIENTE
                WHERE CORREO_CLIENTE = @CORREO
            )
            THROW 51006, N'Ese correo ya pertenece a otro cliente.', 1;

        IF
            NOT EXISTS (
                SELECT 1 FROM DBO.DISTRITO
                WHERE ID_DISTRITO = @ID_DISTRITO
            )
            THROW 51007, N'El distrito no existe.', 1;

        BEGIN TRANSACTION;

        INSERT INTO DBO.DIRECCION (ID_DISTRITO, OTRAS_SENAS)
        VALUES (@ID_DISTRITO, @OTRAS_SENAS);

        SET @ID_DIRECCION = SCOPE_IDENTITY();

        INSERT INTO DBO.CLIENTE
        (
            CEDULA_CLIENTE, CORREO_CLIENTE, TELEFONO_CLIENTE, ID_DIRECCION,
            FECHA_REGISTRO, FECHA_ACTUALIZACION
        )
        VALUES
        (
            @CEDULA, @CORREO, @TELEFONO, @ID_DIRECCION,
            SYSDATETIME(), SYSDATETIME()
        );

        SET @NUEVO_ID = SCOPE_IDENTITY();

        INSERT INTO DBO.CLIENTE_JURIDICO
        (
            ID_CLIENTE, RAZON_SOCIAL, NOMBRE_COMERCIAL
        )
        VALUES
        (
            @NUEVO_ID, @RAZON_SOCIAL, @NOMBRE_COMERCIAL
        );

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
