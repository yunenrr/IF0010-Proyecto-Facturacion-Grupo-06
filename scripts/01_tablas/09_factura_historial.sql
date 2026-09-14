
/* dbo.Factura_Historial — auditoría del encabezado de comprobantes.
   Sin FK hacia Factura porque debe registrar el DELETE de facturas que ya no existen. */

USE Sistema_Facturacion;
GO

CREATE TABLE dbo.Factura_Historial(
	id_historial BIGINT IDENTITY(1,1) NOT NULL,
	id_factura INT NOT NULL,
	consecutivo CHAR(20) NOT NULL,
	operacion CHAR(6) NOT NULL, -- INSERT | DELETE | UPDATE
	usuario_responsable SYSNAME NOT NULL 
		CONSTRAINT DF_Factura_Historial_usuario_responsable DEFAULT ORIGINAL_LOGIN(),
	fecha_cambio DATETIME2(3) NOT NULL 
		CONSTRAINT DF_Factura_Historial_fecha_cambio DEFAULT (SYSDATETIME()),
	descripcion_cambio NVARCHAR(500),
	estado_anterior TINYINT,
	estado_nuevo TINYINT,
	monto_final_anterior DECIMAL(18,2),
	monto_final_nuevo DECIMAL(18,2),
	CONSTRAINT PK_Factura_Historial PRIMARY KEY (id_historial),
	CONSTRAINT CK_Factura_Historial_operacion CHECK (operacion IN ('INSERT','UPDATE','DELETE'))
);
GO