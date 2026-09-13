
/* dbo.Producto_Historial — auditoría del catálogo de productos.
   Sin FK hacia dbo.Producto porque debe registrar el DELETE de productos que ya no existen. */

USE Sistema_Facturacion;
GO

DROP TABLE IF EXISTS dbo.Producto_Historial;
GO

CREATE TABLE dbo.Producto_Historial(
	id_historial BIGINT IDENTITY(1,1) NOT NULL,
	id_producto INT NOT NULL,
	operacion CHAR(6) NOT NULL, -- INSERT | DELETE | UPDATE
	usuario_responsable SYSNAME NOT NULL 
		CONSTRAINT DF_Producto_Historial_usuario_responsable DEFAULT ORIGINAL_LOGIN(),
	fecha_cambio DATETIME2(3) NOT NULL 
		CONSTRAINT DF_Producto_Historial_fecha_cambio DEFAULT (SYSDATETIME()),
	descripcion_cambio NVARCHAR(500),
	precio_unitario_anterior DECIMAL(18,5),
	precio_unitario_nuevo DECIMAL(18,5),
	porcentaje_impuesto_anterior DECIMAL(5,4),
	porcentaje_impuesto_nuevo DECIMAL(5,4),
	CONSTRAINT PK_Producto_Historial PRIMARY KEY (id_historial),
	CONSTRAINT CK_Producto_Historial_operacion CHECK (operacion IN ('INSERT','UPDATE','DELETE'))
);
GO