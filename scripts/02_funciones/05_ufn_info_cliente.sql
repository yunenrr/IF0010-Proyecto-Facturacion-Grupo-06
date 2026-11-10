USE SISTEMA_FACTURACION;
GO

CREATE OR ALTER FUNCTION DBO.UFN_INFO_CLIENTE(
    @CEDULA VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    WITH R AS (
        SELECT
            CASE
                WHEN
                    IS_ROLEMEMBER('ADMINISTRATIVO') = 1
                    OR IS_ROLEMEMBER('DBA') = 1
                    THEN 1
                ELSE 0
            END AS VE_TODO,
            CASE
                WHEN
                    IS_ROLEMEMBER('CAJERO') = 1
                    OR IS_ROLEMEMBER('CONSULTA') = 1
                    THEN 1
                ELSE 0
            END AS VE_ENMASCARADO
    ),

    CLIENTES AS (
        SELECT
            C.CEDULA_CLIENTE,
            C.CORREO_CLIENTE,
            C.TELEFONO_CLIENTE,
            C.FECHA_REGISTRO,
            C.FECHA_ACTUALIZACION,
            CASE
                WHEN CF.ID_CLIENTE IS NOT NULL
                    THEN
                        CONCAT(
                            CF.NOMBRE, N' ', CF.PRIMER_APELLIDO, N' ',
                            CF.SEGUNDO_APELLIDO
                        )
                ELSE CJ.RAZON_SOCIAL
            END AS NOMBRE
        FROM DBO.CLIENTE AS C
        LEFT JOIN DBO.CLIENTE_FISICO AS CF
            ON C.ID_CLIENTE = CF.ID_CLIENTE
        LEFT JOIN DBO.CLIENTE_JURIDICO AS CJ
            ON C.ID_CLIENTE = CJ.ID_CLIENTE
    )

    SELECT
        C.CEDULA_CLIENTE AS CEDULA,
        C.NOMBRE,
        C.FECHA_REGISTRO,
        C.FECHA_ACTUALIZACION,
        CASE
            WHEN R.VE_TODO = 1 THEN C.CORREO_CLIENTE
            ELSE
                LEFT(C.CORREO_CLIENTE, 2) + '***'
                + SUBSTRING(
                    C.CORREO_CLIENTE,
                    CHARINDEX('@', C.CORREO_CLIENTE),
                    254
                )
        END AS CORREO,
        CASE
            WHEN R.VE_TODO = 1 THEN C.TELEFONO_CLIENTE
            ELSE '****' + RIGHT(C.TELEFONO_CLIENTE, 4)
        END AS TELEFONO
    FROM CLIENTES AS C
    CROSS APPLY R
    WHERE
        C.CEDULA_CLIENTE = LTRIM(RTRIM(@CEDULA))
        AND (R.VE_TODO = 1 OR R.VE_ENMASCARADO = 1)
);
GO
