/* DBO.USP_REGISTRAR_PRODUCTO — REGISTRA UN BIEN (PRD) O UN SERVICIO (SRV).
   UN SERVICIO REQUIERE @DURACION_ESTIMADA_MIN Y @SE_BRINDA_A_DOMICILIO Y SE
   REGISTRA TAMBIÉN EN DBO.SERVICIO, EN LA MISMA TRANSACCIÓN. UN BIEN NO
   ADMITE ESOS DOS PARÁMETROS. */

USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_REGISTRAR_PRODUCTO (
    @ID_TIPO_PRODUCTO TINYINT,
    @ID_RUBRO TINYINT,
    @DESCRIPCION NVARCHAR(150),
    @PRECIO_UNITARIO DECIMAL(18, 5),
    @TASA_IMPUESTO DECIMAL(5, 4),
    @EXISTENCIA INT = 0,
    @ID_PRODUCTO INT OUTPUT,
    @CODIGO_INTERNO VARCHAR(20) OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT,
    @DURACION_ESTIMADA_MIN SMALLINT = NULL,
    @SE_BRINDA_A_DOMICILIO BIT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @ID_PRODUCTO = NULL;
    SET @CODIGO_INTERNO = NULL;
    SET @CODIGO_ERROR = 0;
    SET @MENSAJE = N'OK';

    DECLARE @MAX_NUM INT = 0;
    DECLARE @PREFIJO VARCHAR(8);
    DECLARE @CODIGO_TIPO CHAR(3);
    DECLARE @CODIGO_RUBRO CHAR(3);

    BEGIN TRY
        -- EL TIPO Y EL RUBRO SE VALIDAN CONTRA SUS CATÁLOGOS
        SELECT @CODIGO_TIPO = CODIGO_TIPO
        FROM DBO.TIPO_PRODUCTO
        WHERE ID_TIPO_PRODUCTO = @ID_TIPO_PRODUCTO;

        IF @CODIGO_TIPO IS NULL
            BEGIN
                THROW 50501, N'El tipo de producto no existe', 1;
            END;

        SELECT @CODIGO_RUBRO = CODIGO_RUBRO
        FROM DBO.RUBRO
        WHERE ID_RUBRO = @ID_RUBRO;

        IF @CODIGO_RUBRO IS NULL
            BEGIN
                THROW 50502, N'El rubro no existe', 1;
            END;

        IF LTRIM(RTRIM(ISNULL(@DESCRIPCION, ''))) = ''
            BEGIN
                THROW 50503, N'Descripción vacía', 1;
            END;

        IF @PRECIO_UNITARIO IS NULL OR @PRECIO_UNITARIO <= 0
            BEGIN
                THROW 50504, N'Precio nulo, menor o igual que 0', 1;
            END;

        IF
            @TASA_IMPUESTO IS NULL
            OR @TASA_IMPUESTO NOT IN (0.0000, 0.0100, 0.0200, 0.0400, 0.1300)
            BEGIN
                THROW 50505, N'La tasa no es una tarifa de IVA válida', 1;
            END;

        IF
            @EXISTENCIA IS NULL
            OR @EXISTENCIA < 0
            OR (@CODIGO_TIPO = 'SRV' AND @EXISTENCIA <> 0)
            BEGIN
                THROW 50506,
                N'Existencia negativa, o distinta de 0 en un servicio',
                1;
            END;

        IF
            @CODIGO_TIPO = 'SRV'
            AND (
                @DURACION_ESTIMADA_MIN IS NULL
                OR @SE_BRINDA_A_DOMICILIO IS NULL
            )
            BEGIN
                THROW 50508,
                N'Un servicio requiere duración y modalidad a domicilio',
                1;
            END;

        IF @CODIGO_TIPO = 'SRV' AND @DURACION_ESTIMADA_MIN <= 0
            BEGIN
                THROW 50509, N'La duración estimada debe ser mayor que 0', 1;
            END;

        IF
            @CODIGO_TIPO <> 'SRV'
            AND (
                @DURACION_ESTIMADA_MIN IS NOT NULL
                OR @SE_BRINDA_A_DOMICILIO IS NOT NULL
            )
            BEGIN
                THROW 50510,
                N'Un bien no admite duración ni modalidad a domicilio',
                1;
            END;

        SET @PREFIJO = @CODIGO_TIPO + '-' + @CODIGO_RUBRO + '-';

        BEGIN TRANSACTION;

        SELECT @MAX_NUM = ISNULL(MAX(CAST(RIGHT(CODIGO_INTERNO, 5) AS INT)), 0)
        FROM DBO.PRODUCTO WITH (UPDLOCK, HOLDLOCK)
        WHERE
            ID_RUBRO = @ID_RUBRO
            AND ID_TIPO_PRODUCTO = @ID_TIPO_PRODUCTO;

        SET @MAX_NUM = @MAX_NUM + 1;

        IF @MAX_NUM > 99999
            BEGIN
                THROW 50507, N'Se agotó la numeración para este rubro', 1;
            END;

        SET
            @CODIGO_INTERNO = @PREFIJO
            + RIGHT('00000' + CAST(@MAX_NUM AS VARCHAR(5)), 5);

        INSERT INTO DBO.PRODUCTO (
            CODIGO_INTERNO,
            ID_TIPO_PRODUCTO,
            ID_RUBRO,
            DESCRIPCION_PRODUCTO,
            PRECIO_UNITARIO,
            EXISTENCIA,
            TASA_IMPUESTO,
            ESTADO_PRODUCTO,
            FECHA_CREACION
        )
        VALUES (
            @CODIGO_INTERNO,
            @ID_TIPO_PRODUCTO,
            @ID_RUBRO,
            @DESCRIPCION,
            @PRECIO_UNITARIO,
            @EXISTENCIA,
            @TASA_IMPUESTO,
            1,
            SYSDATETIME()
        );

        SET @ID_PRODUCTO = SCOPE_IDENTITY();

        IF @CODIGO_TIPO = 'SRV'
            BEGIN
                INSERT INTO DBO.SERVICIO (
                    ID_PRODUCTO,
                    DURACION_ESTIMADA_MIN,
                    SE_BRINDA_A_DOMICILIO
                )
                VALUES (
                    @ID_PRODUCTO,
                    @DURACION_ESTIMADA_MIN,
                    @SE_BRINDA_A_DOMICILIO
                );
            END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            BEGIN
                ROLLBACK TRANSACTION;
            END;

        SET @ID_PRODUCTO = NULL;
        SET @CODIGO_INTERNO = NULL;
        SET @CODIGO_ERROR = ERROR_NUMBER();
        SET @MENSAJE = ERROR_MESSAGE();
    END CATCH;
END;
GO
