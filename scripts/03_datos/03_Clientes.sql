USE SISTEMA_FACTURACION;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM DBO.CLIENTE)
BEGIN
    PRINT 'La tabla dbo.CLIENTE ya tiene datos. No se cargó nada.';
END
ELSE IF (SELECT COUNT(*) FROM DBO.DIRECCION) < 50100
BEGIN
    PRINT 'Faltan direcciones: dbo.DIRECCION debe tener al menos 50100 filas.';
END
ELSE
BEGIN
    DECLARE @TotalClientes INT = 50000;
    DECLARE @Ahora DATETIME2(3) = SYSDATETIME();

    
    DECLARE @Nombres TABLE (
        ID INT NOT NULL PRIMARY KEY,
        NOMBRE NVARCHAR(40) NOT NULL
    );

    INSERT INTO @Nombres (ID, NOMBRE)
    VALUES
        (0,  N'Juan'),     (1,  N'María'),    (2,  N'José'),     (3,  N'Ana'),
        (4,  N'Carlos'),   (5,  N'Laura'),    (6,  N'Luis'),     (7,  N'Sofía'),
        (8,  N'Andrés'),   (9,  N'Daniela'),  (10, N'Diego'),    (11, N'Valeria'),
        (12, N'Jorge'),    (13, N'Carolina'), (14, N'Mauricio'), (15, N'Paola'),
        (16, N'Esteban'),  (17, N'Fernanda'), (18, N'Ricardo'),  (19, N'Gabriela');

   
    DECLARE @Apellidos TABLE (
        ID INT NOT NULL PRIMARY KEY,
        APELLIDO NVARCHAR(40) NOT NULL
    );

    INSERT INTO @Apellidos (ID, APELLIDO)
    VALUES
        (0,  N'Rodríguez'), (1,  N'Jiménez'),   (2,  N'Mora'),      (3,  N'Vargas'),
        (4,  N'Solís'),     (5,  N'Rojas'),     (6,  N'Araya'),     (7,  N'Chaves'),
        (8,  N'Hernández'), (9,  N'Castro'),    (10, N'Gómez'),     (11, N'Fernández'),
        (12, N'Calderón'),  (13, N'Ramírez'),   (14, N'Quesada'),   (15, N'Salazar'),
        (16, N'Alvarado'),  (17, N'Bonilla'),   (18, N'Cordero'),   (19, N'Segura'),
        (20, N'Zúñiga'),    (21, N'Núñez'),     (22, N'Villalobos'),(23, N'Méndez'),
        (24, N'Brenes');

    
    ;WITH NUMEROS AS (
        SELECT TOP (@TotalClientes)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
        FROM sys.all_objects AS A
        CROSS JOIN sys.all_objects AS B
    ),
    DIR AS (
        SELECT ID_DIRECCION,
               ROW_NUMBER() OVER (ORDER BY ID_DIRECCION) AS RN
        FROM DBO.DIRECCION
    )
    INSERT INTO DBO.CLIENTE
        (CEDULA_CLIENTE, NOMBRE_CLIENTE, CORREO_CLIENTE, TELEFONO_CLIENTE,
         ID_DIRECCION, FECHA_REGISTRO, FECHA_ACTUALIZACION)
    SELECT CONCAT(NUM.N % 7 + 1,
                  RIGHT(CONCAT('00000000', (NUM.N * 7919) % 100000000), 8)),
           CONCAT(NB.NOMBRE, N' ', A1.APELLIDO, N' ', A2.APELLIDO),
           CONCAT('cliente', NUM.N, '@',
                  CHOOSE(CAST(NUM.N % 4 AS INT) + 1,
                         'gmail.com', 'hotmail.com', 'outlook.com', 'yahoo.com')),
           CONCAT(CHOOSE(CAST(NUM.N % 3 AS INT) + 1, '6', '7', '8'),
                  RIGHT(CONCAT('0000000', (NUM.N * 7919) % 10000000), 7)),
           D.ID_DIRECCION,
           DATEADD(DAY, -X.DIAS_REG, @Ahora),
           DATEADD(DAY, -Y.DIAS_ACT, @Ahora)
    FROM NUMEROS AS NUM
    INNER JOIN @Nombres   AS NB ON NB.ID = NUM.N % 20
    INNER JOIN @Apellidos AS A1 ON A1.ID = (NUM.N / 20) % 25
    INNER JOIN @Apellidos AS A2 ON A2.ID = (NUM.N / 500) % 25
    INNER JOIN DIR        AS D  ON D.RN = NUM.N + 100
    CROSS APPLY (SELECT CAST(366 + NUM.N % 1095 AS INT) AS DIAS_REG) AS X
    CROSS APPLY (SELECT CAST((NUM.N * 31) % (X.DIAS_REG + 1) AS INT) AS DIAS_ACT) AS Y;

    PRINT CONCAT('Clientes cargados: ', @@ROWCOUNT);
END
GO

SET NOCOUNT OFF;
GO
                                   