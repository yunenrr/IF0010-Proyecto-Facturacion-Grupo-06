USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER PROCEDURE DBO.USP_REGISTRAR_PRODUCTO (
    @TIPO CHAR(3),
    @CODIGO_RUBRO CHAR(3),
    @DESCRIPCION NVARCHAR(150),
    @PRECIO_UNITARIO DECIMAL(18, 5),
    @TASA_IMPUESTO DECIMAL(5, 4),
    @EXISTENCIA INT = 0,
    @ID_PRODUCTO INT OUTPUT,
    @CODIGO_INTERNO VARCHAR(20) OUTPUT,
    @CODIGO_ERROR INT OUTPUT,
    @MENSAJE NVARCHAR(4000) OUTPUT
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

    BEGIN TRY
        IF @TIPO IS NULL OR @TIPO NOT IN ('PRD', 'SRV')
            BEGIN
                THROW 50501, N'Tipo inválido (no es PRD ni SRV)', 1;
            END;

        IF
            @CODIGO_RUBRO IS NULL
            OR @CODIGO_RUBRO NOT IN (
                'MOD', 'ELE', 'TEC', 'SUP', 'FER',
                'CLI', 'INS', 'MUE', 'CON', 'TRA'
            )
            BEGIN
                THROW 50502, N'Rubro inválido', 1;
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
            OR (@TIPO = 'SRV' AND @EXISTENCIA <> 0)
            BEGIN
                THROW 50506,
                N'Existencia negativa, o distinta de 0 en un servicio',
                1;
            END;

        SET @PREFIJO = @TIPO + '-' + @CODIGO_RUBRO + '-';

        BEGIN TRANSACTION;

        SELECT @MAX_NUM = ISNULL(MAX(CAST(RIGHT(CODIGO_INTERNO, 5) AS INT)), 0)
        FROM DBO.PRODUCTO WITH (UPDLOCK, HOLDLOCK)
        WHERE CODIGO_INTERNO LIKE @PREFIJO + '%';

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
            DESCRIPCION_PRODUCTO,
            PRECIO_UNITARIO,
            EXISTENCIA,
            TASA_IMPUESTO,
            ESTADO_PRODUCTO,
            FECHA_CREACION
        )
        VALUES (
            @CODIGO_INTERNO,
            @DESCRIPCION,
            @PRECIO_UNITARIO,
            @EXISTENCIA,
            @TASA_IMPUESTO,
            1,
            SYSDATETIME()
        );

        SET @ID_PRODUCTO = SCOPE_IDENTITY();

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
