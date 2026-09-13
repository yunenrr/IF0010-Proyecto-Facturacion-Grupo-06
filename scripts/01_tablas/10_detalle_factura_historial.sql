
/* dbo.Detalle_Factura_Historial — auditoría del cuerpo de detalles de una factura.
   Sin FK hacia dbo.Detalle_Factura porque debe registrar el DELETE de detalles que ya no existen. */

USE Sistema_Facturacion;
GO

DROP TABLE IF EXISTS dbo.Detalle_Factura_Historial;
GO

CREATE TABLE dbo.Detalle_Factura_Historial(
	id_historial BIGINT IDENTITY(1,1) NOT NULL,
	id_detalle INT NOT NULL,
	id_factura INT NOT NULL,
	numero_linea TINYINT NOT NULL, -- numero correlativo
	operacion CHAR(6) NOT NULL, -- INSERT | DELETE | UPDATE 
	usuario_responsable SYSNAME NOT NULL CONSTRAINT DF_Detalle_Factura_Historial_usuario_responsable DEFAULT ORIGINAL_LOGIN(),
	fecha_cambio DATETIME2(3) NOT NULL CONSTRAINT DF_Detalle_Factura_Historial_fecha_cambio DEFAULT (SYSDATETIME()),
	descripcion_cambio NVARCHAR(500),
	cantidad_anterior DECIMAL(9,3),
	cantidad_nueva DECIMAL(9,3),
	precio_unitario_anterior DECIMAL(18,5),
	precio_unitario_nuevo DECIMAL(18,5),
	monto_descuento_anterior DECIMAL(18,2),
	monto_descuento_nuevo DECIMAL(18,2),
	porcentaje_impuesto_anterior DECIMAL(5,2),
	porcentaje_impuesto_nuevo DECIMAL(5,2),
	monto_linea_anterior DECIMAL(18,2),
	monto_linea_nuevo DECIMAL(18,2),
	monto_impuesto_linea_anterior DECIMAL(18,2),
	monto_impuesto_linea_nuevo DECIMAL(18,2),
	CONSTRAINT PK_Detalle_Factura_Historial PRIMARY KEY (id_historial),
	CONSTRAINT CK_Detalle_Factura_Historial_operacion CHECK (operacion IN ('INSERT','UPDATE','DELETE'))
);
GO