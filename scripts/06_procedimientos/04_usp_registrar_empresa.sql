/* DBO.USP_REGISTRAR_EMPRESA — REGISTRA UNA EMPRESA EMISORA JUNTO CON SU
   DIRECCIÓN, EN UNA SOLA TRANSACCIÓN. */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_REGISTRAR_EMPRESA
    @NOMBRE_COMERCIAL NVARCHAR(150),
    @RAZON_SOCIAL NVARCHAR(150),
    @ID_RUBRO TINYINT,
    @CEDULA_EMPRESA VARCHAR(12),
    @TELEFONO_EMPRESA VARCHAR(12),
    @CORREO_ELECTRONICO VARCHAR(254),
    @ID_DISTRITO INT,
    @OTRAS_SENAS NVARCHAR(250),
    @ID_EMPRESA INT OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ID_DIRECCION INT;

    SET @ID_EMPRESA = NULL;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Empresa registrada.';

    BEGIN TRY
        SET @NOMBRE_COMERCIAL = NULLIF(TRIM(@NOMBRE_COMERCIAL), N'');
        SET @RAZON_SOCIAL = NULLIF(TRIM(@RAZON_SOCIAL), N'');
        SET @CEDULA_EMPRESA = NULLIF(TRIM(@CEDULA_EMPRESA), '');
        SET @TELEFONO_EMPRESA = NULLIF(TRIM(@TELEFONO_EMPRESA), '');
        SET @CORREO_ELECTRONICO = NULLIF(TRIM(@CORREO_ELECTRONICO), '');
        SET @OTRAS_SENAS = NULLIF(TRIM(@OTRAS_SENAS), N'');

        IF
            @NOMBRE_COMERCIAL IS NULL
            OR @RAZON_SOCIAL IS NULL
            OR @ID_RUBRO IS NULL
            OR @CEDULA_EMPRESA IS NULL
            OR @TELEFONO_EMPRESA IS NULL
            OR @CORREO_ELECTRONICO IS NULL
            OR @ID_DISTRITO IS NULL
            OR @OTRAS_SENAS IS NULL
            THROW 50401, N'Falta un campo obligatorio.', 1;

        IF
            LEN(@CEDULA_EMPRESA) <> 10
            OR @CEDULA_EMPRESA LIKE '%[^0-9]%'
            OR LEFT(@CEDULA_EMPRESA, 1) <> '3'
            THROW 50402,
            N'La cédula jurídica debe tener 10 dígitos y empezar con 3.',
            1;

        IF
            EXISTS (
                SELECT 1 FROM DBO.EMPRESA
                WHERE CEDULA_EMPRESA = @CEDULA_EMPRESA
            )
            THROW 50403, N'Ya existe una empresa con esa cédula.', 1;

        IF
            LEN(@TELEFONO_EMPRESA) <> 8
            OR @TELEFONO_EMPRESA LIKE '%[^0-9]%'
            THROW 50404, N'El teléfono debe tener exactamente 8 dígitos.', 1;

        IF
            @CORREO_ELECTRONICO NOT LIKE '_%@_%._%'
            OR @CORREO_ELECTRONICO LIKE '%@%@%'
            OR @CORREO_ELECTRONICO LIKE '% %'
            THROW 50405, N'El correo no tiene un formato válido.', 1;

        IF
            NOT EXISTS (
                SELECT 1 FROM DBO.RUBRO
                WHERE ID_RUBRO = @ID_RUBRO
            )
            THROW 50406, N'El rubro no existe.', 1;

        IF
            NOT EXISTS (
                SELECT 1 FROM DBO.DISTRITO
                WHERE ID_DISTRITO = @ID_DISTRITO
            )
            THROW 50407, N'El distrito no existe.', 1;

        BEGIN TRANSACTION;

        INSERT INTO DBO.DIRECCION (ID_DISTRITO, OTRAS_SENAS)
        VALUES (@ID_DISTRITO, @OTRAS_SENAS);

        SET @ID_DIRECCION = SCOPE_IDENTITY();

        INSERT INTO DBO.EMPRESA (
            NOMBRE_COMERCIAL,
            RAZON_SOCIAL,
            CEDULA_EMPRESA,
            ID_DIRECCION,
            ID_RUBRO,
            TELEFONO_EMPRESA,
            CORREO_ELECTRONICO,
            FECHA_CREACION,
            ESTA_ACTIVA
        )
        VALUES (
            @NOMBRE_COMERCIAL,
            @RAZON_SOCIAL,
            @CEDULA_EMPRESA,
            @ID_DIRECCION,
            @ID_RUBRO,
            @TELEFONO_EMPRESA,
            @CORREO_ELECTRONICO,
            SYSDATETIME(),
            1
        );

        SET @ID_EMPRESA = SCOPE_IDENTITY();

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @ID_EMPRESA = NULL;
        SET @CODIGO_ERROR = ERROR_NUMBER();
        SET @MENSAJE = ERROR_MESSAGE();
    END CATCH;
END;
GO
