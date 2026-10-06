/* DBO.USP_ACTUALIZAR_EMPRESA — ACTUALIZA LOS DATOS EDITABLES DE UNA EMPRESA
   EMISORA, EN UNA SOLA TRANSACCIÓN. SOLO CAMBIA LOS PARÁMETROS QUE SE ENVÍAN;
   LOS QUE LLEGAN EN NULL O VACÍOS CONSERVAN SU VALOR ACTUAL. */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_ACTUALIZAR_EMPRESA
    @ID_EMPRESA INT,
    @NOMBRE_COMERCIAL NVARCHAR(150) = NULL,
    @RAZON_SOCIAL NVARCHAR(150) = NULL,
    @TELEFONO_EMPRESA VARCHAR(12) = NULL,
    @CORREO_ELECTRONICO VARCHAR(254) = NULL,
    @ID_DISTRITO INT = NULL,
    @OTRAS_SENAS NVARCHAR(250) = NULL,
    @ESTA_ACTIVA BIT = NULL,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NOMBRE_ACTUAL NVARCHAR(150);
    DECLARE @PREFIJO_ACTUAL NVARCHAR(150);
    DECLARE @PREFIJO_NUEVO NVARCHAR(150);
    DECLARE @ID_DIRECCION_NUEVA INT = NULL;

    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Empresa actualizada.';

    BEGIN TRY
        SET @NOMBRE_COMERCIAL = NULLIF(TRIM(@NOMBRE_COMERCIAL), N'');
        SET @RAZON_SOCIAL = NULLIF(TRIM(@RAZON_SOCIAL), N'');
        SET @TELEFONO_EMPRESA = NULLIF(TRIM(@TELEFONO_EMPRESA), '');
        SET @CORREO_ELECTRONICO = NULLIF(TRIM(@CORREO_ELECTRONICO), '');
        SET @OTRAS_SENAS = NULLIF(TRIM(@OTRAS_SENAS), N'');

        SELECT @NOMBRE_ACTUAL = NOMBRE_COMERCIAL
        FROM DBO.EMPRESA
        WHERE ID_EMPRESA = @ID_EMPRESA;

        IF @NOMBRE_ACTUAL IS NULL
            THROW 50901, N'La empresa no existe.', 1;

        IF
            @NOMBRE_COMERCIAL IS NULL
            AND @RAZON_SOCIAL IS NULL
            AND @TELEFONO_EMPRESA IS NULL
            AND @CORREO_ELECTRONICO IS NULL
            AND @ID_DISTRITO IS NULL
            AND @OTRAS_SENAS IS NULL
            AND @ESTA_ACTIVA IS NULL
            THROW 50902, N'No se indicó ningún dato para actualizar.', 1;

        IF
            @TELEFONO_EMPRESA IS NOT NULL
            AND (
                LEN(@TELEFONO_EMPRESA) <> 8
                OR @TELEFONO_EMPRESA LIKE '%[^0-9]%'
            )
            THROW 50903, N'El teléfono debe tener exactamente 8 dígitos.', 1;

        IF
            @CORREO_ELECTRONICO IS NOT NULL
            AND (
                @CORREO_ELECTRONICO NOT LIKE '_%@_%._%'
                OR @CORREO_ELECTRONICO LIKE '%@%@%'
                OR @CORREO_ELECTRONICO LIKE '% %'
            )
            THROW 50904, N'El correo no tiene un formato válido.', 1;

        IF @NOMBRE_COMERCIAL IS NOT NULL
            BEGIN
                SET @PREFIJO_ACTUAL = LEFT(
                    @NOMBRE_ACTUAL,
                    CHARINDEX(N' ', @NOMBRE_ACTUAL + N' ') - 1
                );
                SET @PREFIJO_NUEVO = LEFT(
                    @NOMBRE_COMERCIAL,
                    CHARINDEX(N' ', @NOMBRE_COMERCIAL + N' ') - 1
                );

                IF @PREFIJO_NUEVO <> @PREFIJO_ACTUAL
                    THROW 50905,
                    N'El nombre comercial debe conservar el prefijo de rubro.',
                    1;
            END;

        IF
            (@ID_DISTRITO IS NULL AND @OTRAS_SENAS IS NOT NULL)
            OR (@ID_DISTRITO IS NOT NULL AND @OTRAS_SENAS IS NULL)
            THROW 50906,
            N'Para cambiar la dirección se indican el distrito y las señas.',
            1;

        IF
            @ID_DISTRITO IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM DBO.DISTRITO
                WHERE ID_DISTRITO = @ID_DISTRITO
            )
            THROW 50907, N'El distrito no existe.', 1;

        BEGIN TRANSACTION;

        IF @ID_DISTRITO IS NOT NULL
            BEGIN
                INSERT INTO DBO.DIRECCION (ID_DISTRITO, OTRAS_SENAS)
                VALUES (@ID_DISTRITO, @OTRAS_SENAS);

                SET @ID_DIRECCION_NUEVA = SCOPE_IDENTITY();
            END;

        UPDATE DBO.EMPRESA
        SET
            NOMBRE_COMERCIAL = COALESCE(@NOMBRE_COMERCIAL, NOMBRE_COMERCIAL),
            RAZON_SOCIAL = COALESCE(@RAZON_SOCIAL, RAZON_SOCIAL),
            TELEFONO_EMPRESA = COALESCE(@TELEFONO_EMPRESA, TELEFONO_EMPRESA),
            CORREO_ELECTRONICO = COALESCE(
                @CORREO_ELECTRONICO, CORREO_ELECTRONICO
            ),
            ID_DIRECCION = COALESCE(@ID_DIRECCION_NUEVA, ID_DIRECCION),
            ESTA_ACTIVA = COALESCE(@ESTA_ACTIVA, ESTA_ACTIVA)
        WHERE ID_EMPRESA = @ID_EMPRESA;

        IF @@ROWCOUNT = 0
            THROW 50901, N'La empresa no existe.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET @CODIGO_ERROR = ERROR_NUMBER();
        SET @MENSAJE = ERROR_MESSAGE();
    END CATCH;
END;
GO
