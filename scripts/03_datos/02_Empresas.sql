USE SISTEMA_FACTURACION;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM DBO.EMPRESA)
BEGIN
    PRINT 'La tabla dbo.EMPRESA ya tiene datos. No se cargó nada.';
END
ELSE
BEGIN
    
    DECLARE @Rubros TABLE (
        ID_RUBRO INT NOT NULL PRIMARY KEY,
        PREFIJO NVARCHAR(50) NOT NULL,
        ACTIVIDAD NVARCHAR(60) NOT NULL
    );

    INSERT INTO @Rubros (ID_RUBRO, PREFIJO, ACTIVIDAD)
    VALUES
        (1,  N'Moda',        N'Ropa y Vestimenta'),
        (2,  N'Electro',     N'Electrodomésticos'),
        (3,  N'Tecno',       N'Tecnología y Computación'),
        (4,  N'Súper',       N'Supermercado y Alimentos'),
        (5,  N'Ferretería',  N'Ferretería y Construcción'),
        (6,  N'Clínica',     N'Salud Privada'),
        (7,  N'Instituto',   N'Servicios Educativos'),
        (8,  N'Muebles',     N'Muebles y Hogar'),
        (9,  N'Consultores', N'Servicios Profesionales'),
        (10, N'Transportes', N'Transporte y Logística');

    
    DECLARE @Sufijos TABLE (
        ID_SUFIJO INT NOT NULL PRIMARY KEY,
        SUFIJO NVARCHAR(50) NOT NULL
    );

    INSERT INTO @Sufijos (ID_SUFIJO, SUFIJO)
    VALUES
        (1,  N'Los Alpes'),
        (2,  N'El Roble'),
        (3,  N'La Estrella'),
        (4,  N'Del Valle'),
        (5,  N'Central'),
        (6,  N'Pacífico'),
        (7,  N'Cordillera'),
        (8,  N'Real'),
        (9,  N'Sol'),
        (10, N'Horizonte');

    
    ;WITH DIR AS (
        SELECT ID_DIRECCION,
               ROW_NUMBER() OVER (ORDER BY ID_DIRECCION) AS RN
        FROM DBO.DIRECCION
    ),
    BASE AS (
        SELECT ROW_NUMBER() OVER (ORDER BY R.ID_RUBRO, S.ID_SUFIJO) AS N,
               R.PREFIJO,
               R.ACTIVIDAD,
               S.SUFIJO
        FROM @Rubros AS R
        CROSS JOIN @Sufijos AS S
    )
    INSERT INTO DBO.EMPRESA
        (NOMBRE_COMERCIAL, RAZON_SOCIAL, CEDULA_EMPRESA, ID_DIRECCION,
         TELEFONO_EMPRESA, CORREO_ELECTRONICO, FECHA_CREACION, ESTA_ACTIVA)
    SELECT CONCAT(B.PREFIJO, N' ', B.SUFIJO),
           CONCAT(N'Grupo ', B.SUFIJO, N' ', B.ACTIVIDAD, N' S.A.'),
           CONCAT('3101', RIGHT(CONCAT('000000', B.N), 6)),
           D.ID_DIRECCION,
           CONCAT('22', RIGHT(CONCAT('000000', B.N), 6)),
           CONCAT('contacto', B.N, '@empresas.cr'),
           DATEADD(DAY, -CAST(730 + (B.N * 13) % 1000 AS INT), SYSDATETIME()),
           CASE WHEN B.N % 10 = 0 THEN 0 ELSE 1 END
    FROM BASE AS B
    INNER JOIN DIR AS D
        ON D.RN = B.N;

    PRINT CONCAT('Empresas cargadas: ', @@ROWCOUNT);
END
GO

SET NOCOUNT OFF;
GO
