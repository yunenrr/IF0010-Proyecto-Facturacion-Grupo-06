/* DBO.USP_ACTUALIZAR_CLIENTE — ACTUALIZA CORREO, TELÉFONO Y DIRECCIÓN DEL
   COMPRADOR (REQUISITO FUNCIONAL 6). LA DIRECCIÓN SE ACTUALIZA SOBRE LA FILA
   EXISTENTE DE DBO.DIRECCION (LA VERSIÓN ANTERIOR QUEDA EN
   DBO.DIRECCION_HISTORIAL); CLIENTE.ID_DIRECCION NO CAMBIA. */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_ACTUALIZAR_CLIENTE
    @ID_CLIENTE INT,
    @CORREO VARCHAR(254) = NULL,
    @TELEFONO VARCHAR(12) = NULL,
    @ID_DISTRITO INT = NULL,
    @OTRAS_SENAS NVARCHAR(250) = NULL,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ID_DIRECCION_ACTUAL INT;

    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'Cliente actualizado.';

    BEGIN TRY
        SET @CORREO = NULLIF(TRIM(@CORREO), '');
        SET @TELEFONO = NULLIF(TRIM(@TELEFONO), '');
        SET @OTRAS_SENAS = NULLIF(TRIM(@OTRAS_SENAS), N'');

        SELECT @ID_DIRECCION_ACTUAL = ID_DIRECCION
        FROM DBO.CLIENTE
        WHERE ID_CLIENTE = @ID_CLIENTE;

        IF @ID_DIRECCION_ACTUAL IS NULL
            THROW 50301, N'El cliente no existe.', 1;

        IF
            @CORREO IS NULL
            AND @TELEFONO IS NULL
            AND @ID_DISTRITO IS NULL
            AND @OTRAS_SENAS IS NULL
            THROW 50302, N'No se envió ningún dato para actualizar.', 1;

        IF
            @TELEFONO IS NOT NULL
            AND (
                LEN(@TELEFONO) <> 8
                OR @TELEFONO LIKE '%[^0-9]%'
            )
            THROW 50303, N'El teléfono debe tener exactamente 8 dígitos.', 1;

        IF
            @CORREO IS NOT NULL
            AND (
                @CORREO NOT LIKE '_%@_%._%'
                OR @CORREO LIKE '%@%@%'
                OR @CORREO LIKE '% %'
            )
            THROW 50304, N'El correo no tiene un formato válido.', 1;

        IF
            @CORREO IS NOT NULL
            AND EXISTS (
                SELECT 1 FROM DBO.CLIENTE
                WHERE
                    CORREO_CLIENTE = @CORREO
                    AND ID_CLIENTE <> @ID_CLIENTE
            )
            THROW 50305, N'El correo ya pertenece a otro cliente.', 1;

        IF
            (@ID_DISTRITO IS NULL AND @OTRAS_SENAS IS NOT NULL)
            OR (@ID_DISTRITO IS NOT NULL AND @OTRAS_SENAS IS NULL)
            THROW 50306,
            N'La dirección debe incluir el distrito y las otras señas.',
            1;

        IF
            @ID_DISTRITO IS NOT NULL
            AND NOT EXISTS (
                SELECT 1 FROM DBO.DISTRITO
                WHERE ID_DISTRITO = @ID_DISTRITO
            )
            THROW 50307, N'El distrito no existe.', 1;

        BEGIN TRANSACTION;

        IF @ID_DISTRITO IS NOT NULL
            BEGIN
                UPDATE DBO.DIRECCION
                SET
                    ID_DISTRITO = @ID_DISTRITO,
                    OTRAS_SENAS = @OTRAS_SENAS
                WHERE ID_DIRECCION = @ID_DIRECCION_ACTUAL;
            END;

        UPDATE DBO.CLIENTE
        SET
            CORREO_CLIENTE = COALESCE(@CORREO, CORREO_CLIENTE),
            TELEFONO_CLIENTE = COALESCE(@TELEFONO, TELEFONO_CLIENTE),
            FECHA_ACTUALIZACION = SYSDATETIME()
        WHERE ID_CLIENTE = @ID_CLIENTE;

        IF @@ROWCOUNT = 0
            THROW 50301, N'El cliente no existe.', 1;

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
