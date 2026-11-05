/* DBO.UFN_HISTORIAL_CAMBIOS — CONSULTA UNIFICADA DEL HISTORIAL DE CAMBIOS.
   UNE LAS OCHO TABLAS DE AUDITORÍA (FACTURA, DETALLE_FACTURA, CLIENTE,
   CLIENTE_FISICO, CLIENTE_JURIDICO, DIRECCION, SERVICIO Y PRODUCTO) EN UNA
   SOLA LÍNEA DE TIEMPO CON COLUMNAS COMUNES. EN INSERT EL DETALLE MUESTRA LA
   VERSIÓN NUEVA; EN UPDATE, LA VERSIÓN ANTERIOR AL CAMBIO; EN DELETE, LA
   ÚLTIMA VERSIÓN. */

USE SISTEMA_FACTURACION;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER FUNCTION DBO.UFN_HISTORIAL_CAMBIOS(
    @FECHA_DESDE DATE = NULL,
    @FECHA_HASTA DATE = NULL
)
RETURNS TABLE
AS
RETURN (
    SELECT
        H.TABLA,
        H.ID_REGISTRO,
        T.CODIGO_OPERACION AS OPERACION,
        H.USUARIO_RESPONSABLE,
        H.FECHA_CAMBIO,
        H.DETALLE
    FROM (
        SELECT
            'FACTURA' AS TABLA,
            FH.ID_FACTURA AS ID_REGISTRO,
            FH.ID_TIPO_OPERACION,
            FH.USUARIO_RESPONSABLE,
            FH.FECHA_CAMBIO,
            CONCAT(
                N'Consecutivo ', RTRIM(FH.CONSECUTIVO),
                N' | Estado ', E.ESTADO,
                N' | Monto ', FH.MONTO_FINAL
            ) AS DETALLE
        FROM DBO.FACTURA_HISTORIAL AS FH
        INNER JOIN DBO.ESTADO_FACTURA AS E
            ON FH.ID_ESTADO_FACTURA = E.ID_ESTADO_FACTURA

        UNION ALL

        SELECT
            'DETALLE_FACTURA' AS TABLA,
            DH.ID_DETALLE AS ID_REGISTRO,
            DH.ID_TIPO_OPERACION,
            DH.USUARIO_RESPONSABLE,
            DH.FECHA_CAMBIO,
            CONCAT(
                N'Factura ', DH.ID_FACTURA,
                N' | Línea ', DH.NUMERO_LINEA,
                N' | Cantidad ', DH.CANTIDAD_FACTURADA,
                N' | Precio ', DH.PRECIO_UNITARIO,
                N' | Total ', DH.MONTO_TOTAL_LINEA
            ) AS DETALLE
        FROM DBO.DETALLE_FACTURA_HISTORIAL AS DH

        UNION ALL

        SELECT
            'CLIENTE' AS TABLA,
            CH.ID_CLIENTE AS ID_REGISTRO,
            CH.ID_TIPO_OPERACION,
            CH.USUARIO_RESPONSABLE,
            CH.FECHA_CAMBIO,
            CONCAT(
                N'Cédula ', CH.CEDULA_CLIENTE,
                N' | Correo ',
                CASE
                    WHEN IS_ROLEMEMBER('DBA') = 1 THEN CH.CORREO_CLIENTE
                    WHEN CHARINDEX('@', CH.CORREO_CLIENTE) > 1
                        THEN
                            LEFT(CH.CORREO_CLIENTE, 1) + '***'
                            + SUBSTRING(
                                CH.CORREO_CLIENTE,
                                CHARINDEX('@', CH.CORREO_CLIENTE),
                                254
                            )
                    ELSE '***'
                END,
                N' | Teléfono ',
                CASE
                    WHEN IS_ROLEMEMBER('DBA') = 1 THEN CH.TELEFONO_CLIENTE
                    WHEN LEN(CH.TELEFONO_CLIENTE) > 4
                        THEN
                            REPLICATE('*', LEN(CH.TELEFONO_CLIENTE) - 4)
                            + RIGHT(CH.TELEFONO_CLIENTE, 4)
                    ELSE '****'
                END
            ) AS DETALLE
        FROM DBO.CLIENTE_HISTORIAL AS CH

        UNION ALL

        SELECT
            'CLIENTE_FISICO' AS TABLA,
            CFH.ID_CLIENTE AS ID_REGISTRO,
            CFH.ID_TIPO_OPERACION,
            CFH.USUARIO_RESPONSABLE,
            CFH.FECHA_CAMBIO,
            CONCAT(
                N'Nombre ', CFH.NOMBRE,
                N' | Primer apellido ', CFH.PRIMER_APELLIDO,
                N' | Segundo apellido ', CFH.SEGUNDO_APELLIDO
            ) AS DETALLE
        FROM DBO.CLIENTE_FISICO_HISTORIAL AS CFH

        UNION ALL

        SELECT
            'CLIENTE_JURIDICO' AS TABLA,
            CJH.ID_CLIENTE AS ID_REGISTRO,
            CJH.ID_TIPO_OPERACION,
            CJH.USUARIO_RESPONSABLE,
            CJH.FECHA_CAMBIO,
            CONCAT(
                N'Razón social ', CJH.RAZON_SOCIAL,
                N' | Nombre comercial ', CJH.NOMBRE_COMERCIAL
            ) AS DETALLE
        FROM DBO.CLIENTE_JURIDICO_HISTORIAL AS CJH

        UNION ALL

        SELECT
            'DIRECCION' AS TABLA,
            DRH.ID_DIRECCION AS ID_REGISTRO,
            DRH.ID_TIPO_OPERACION,
            DRH.USUARIO_RESPONSABLE,
            DRH.FECHA_CAMBIO,
            CONCAT(
                N'Distrito ', DI.NOMBRE_DISTRITO,
                N' | Otras señas ',
                CASE
                    WHEN IS_ROLEMEMBER('DBA') = 1 THEN DRH.OTRAS_SENAS
                    ELSE N'***'
                END
            ) AS DETALLE
        FROM DBO.DIRECCION_HISTORIAL AS DRH
        INNER JOIN DBO.DISTRITO AS DI
            ON DRH.ID_DISTRITO = DI.ID_DISTRITO

        UNION ALL

        SELECT
            'SERVICIO' AS TABLA,
            SH.ID_PRODUCTO AS ID_REGISTRO,
            SH.ID_TIPO_OPERACION,
            SH.USUARIO_RESPONSABLE,
            SH.FECHA_CAMBIO,
            CONCAT(
                N'Duración ', SH.DURACION_ESTIMADA_MIN,
                N' min | A domicilio ',
                CASE WHEN SH.SE_BRINDA_A_DOMICILIO = 1 THEN N'Sí' ELSE N'No' END
            ) AS DETALLE
        FROM DBO.SERVICIO_HISTORIAL AS SH

        UNION ALL

        SELECT
            'PRODUCTO' AS TABLA,
            PH.ID_PRODUCTO AS ID_REGISTRO,
            PH.ID_TIPO_OPERACION,
            PH.USUARIO_RESPONSABLE,
            PH.FECHA_CAMBIO,
            CONCAT(
                N'Precio ', PH.PRECIO_UNITARIO,
                N' | Tasa ', PH.TASA_IMPUESTO
            ) AS DETALLE
        FROM DBO.PRODUCTO_HISTORIAL AS PH
    ) AS H
    INNER JOIN DBO.TIPO_OPERACION AS T
        ON H.ID_TIPO_OPERACION = T.ID_TIPO_OPERACION
    WHERE
        (IS_ROLEMEMBER('AUDITOR') = 1 OR IS_ROLEMEMBER('DBA') = 1)
        AND (@FECHA_DESDE IS NULL OR H.FECHA_CAMBIO >= @FECHA_DESDE)
        AND (
            @FECHA_HASTA IS NULL
            OR H.FECHA_CAMBIO < DATEADD(DAY, 1, @FECHA_HASTA)
        )
);
GO
