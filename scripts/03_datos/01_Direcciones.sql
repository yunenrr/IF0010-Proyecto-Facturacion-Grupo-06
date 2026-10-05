USE SISTEMA_FACTURACION;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM DBO.DIRECCION)
BEGIN
    PRINT 'La tabla dbo.DIRECCION ya tiene datos. No se cargó ninguno.';
END
ELSE IF NOT EXISTS (SELECT 1 FROM DBO.DISTRITO)
BEGIN
    PRINT 'La tabla dbo.DISTRITO está vacía. Ejecute primero la carga de la división por los territorios.';
END
ELSE
BEGIN
    DECLARE @TotalFilas INT = 50100;
    DECLARE @TotalDistritos INT = (SELECT COUNT(*) FROM DBO.DISTRITO);

    ;WITH NUMEROS AS (
        SELECT TOP (@TotalFilas)
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
        FROM sys.all_objects AS A
        CROSS JOIN sys.all_objects AS B
    ),
    DIST AS (
        SELECT ID_DISTRITO,
               ROW_NUMBER() OVER (ORDER BY ID_DISTRITO) - 1 AS IDX
        FROM DBO.DISTRITO
    )
    INSERT INTO DBO.DIRECCION (ID_DISTRITO, OTRAS_SENAS)
    SELECT D.ID_DISTRITO,
           CONCAT(N'Calle ', (NUM.N % 50) + 1, N', casa #', NUM.N)
    FROM NUMEROS AS NUM
    INNER JOIN DIST AS D
        ON D.IDX = NUM.N % @TotalDistritos;

    PRINT CONCAT('Direcciones cargadas: ', @@ROWCOUNT);
END
GO

SET NOCOUNT OFF;
GO
