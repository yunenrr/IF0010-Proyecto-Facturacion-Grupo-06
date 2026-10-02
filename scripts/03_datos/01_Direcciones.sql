USE SISTEMA_FACTURACION;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM DBO.DIRECCION)
BEGIN
    PRINT 'La tabla dbo.DIRECCION ya tiene datos. No se cargó nada.';
END
ELSE
BEGIN
    DECLARE @TotalFilas INT = 50100;

    DECLARE @Ubicaciones TABLE (
        ID_UBICACION INT NOT NULL PRIMARY KEY,
        PROVINCIA NVARCHAR(50) NOT NULL,
        CANTON NVARCHAR(50) NOT NULL,
        DISTRITO NVARCHAR(50) NOT NULL
    );

    INSERT INTO @Ubicaciones (ID_UBICACION, PROVINCIA, CANTON, DISTRITO)
    VALUES
        (0,  N'San José',   N'San José',      N'Carmen'),
        (1,  N'San José',   N'Escazú',        N'Escazú'),
        (2,  N'San José',   N'Desamparados',  N'San Miguel'),
        (3,  N'San José',   N'Goicoechea',    N'Guadalupe'),
        (4,  N'Alajuela',   N'Alajuela',      N'Alajuela'),
        (5,  N'Alajuela',   N'San Ramón',     N'San Ramón'),
        (6,  N'Alajuela',   N'Grecia',        N'Grecia'),
        (7,  N'Alajuela',   N'Atenas',        N'Atenas'),
        (8,  N'Cartago',    N'Cartago',       N'Oriental'),
        (9,  N'Cartago',    N'Paraíso',       N'Paraíso'),
        (10, N'Cartago',    N'La Unión',      N'Tres Ríos'),
        (11, N'Cartago',    N'Turrialba',     N'Turrialba'),
        (12, N'Heredia',    N'Heredia',       N'Heredia'),
        (13, N'Heredia',    N'Barva',         N'Barva'),
        (14, N'Heredia',    N'Santo Domingo', N'Santo Domingo'),
        (15, N'Heredia',    N'San Rafael',    N'San Rafael'),
        (16, N'Guanacaste', N'Liberia',       N'Liberia'),
        (17, N'Guanacaste', N'Nicoya',        N'Nicoya'),
        (18, N'Guanacaste', N'Santa Cruz',    N'Santa Cruz'),
        (19, N'Guanacaste', N'Cañas',         N'Cañas'),
        (20, N'Puntarenas', N'Puntarenas',    N'Puntarenas'),
        (21, N'Puntarenas', N'Esparza',       N'Espíritu Santo'),
        (22, N'Puntarenas', N'Quepos',        N'Quepos'),
        (23, N'Puntarenas', N'Golfito',       N'Golfito'),
        (24, N'Limón',      N'Limón',         N'Limón'),
        (25, N'Limón',      N'Pococí',        N'Guápiles'),
        (26, N'Limón',      N'Siquirres',     N'Siquirres'),
        (27, N'Limón',      N'Talamanca',     N'Bratsi');

    
    ;WITH NUMEROS AS (
        SELECT TOP (@TotalFilas)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
        FROM sys.all_objects AS A
        CROSS JOIN sys.all_objects AS B
    )
    INSERT INTO DBO.DIRECCION (PROVINCIA, CANTON, DISTRITO, OTRAS_SENAS)
    SELECT U.PROVINCIA,
           U.CANTON,
           U.DISTRITO,
           CONCAT(N'Calle ', (NUM.N % 50) + 1, N', casa #', NUM.N)
    FROM NUMEROS AS NUM
    INNER JOIN @Ubicaciones AS U
        ON U.ID_UBICACION = NUM.N % 28;

    PRINT CONCAT('Direcciones cargadas: ', @@ROWCOUNT);
END
GO

SET NOCOUNT OFF;
GO
