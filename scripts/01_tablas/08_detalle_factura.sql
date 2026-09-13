--Tabla Detalle_Factura: 

USE Sistema_Facturacion; 
GO

DROP TABLE IF EXISTS dbo.Detalle_Factura; 
GO

CREATE TABLE dbo.Detalle_Factura(
	id_detalle INT IDENTITY(1,1) NOT NULL, 
	id_factura INT NOT NULL, 
	id_producto INT NOT NULL, 
	numero_linea TINYINT NOT NULL, --Una factura admite hasta 255 lineas
	descripcion_linea NVARCHAR(150) NOT NULL, 
	cantidad_facturada DECIMAL(9,3) NOT NULL, 
	precio_unitario DECIMAL(18,5) NOT NULL, 
	tasa_impuesto DECIMAL(5,4) NOT NULL, 
	monto_descuento DECIMAL(18,2) NOT NULL CONSTRAINT DF_Detalle_Factura_monto_descuento DEFAULT (0),
	monto_impuesto_linea DECIMAL (18,2) NOT NULL,
	subtotal_linea DECIMAL(18,2) NOT NULL, 
	monto_total_linea DECIMAL(18,2) NOT NULL, 

	CONSTRAINT PK_Detalle_Factura PRIMARY KEY (id_detalle), 
	CONSTRAINT FK_Detalle_Factura_Factura FOREIGN KEY (id_factura) REFERENCES dbo.Factura (id_factura), 
	CONSTRAINT FK_Detalle_Factura_Producto FOREIGN KEY (id_producto) REFERENCES dbo.Producto (codigo_interno), 
	CONSTRAINT UQ_Detalle_Factura_factura_linea UNIQUE(id_factura, numero_linea), 
	CONSTRAINT CK_Detalle_Factura_cantidad CHECK (cantidad_facturada > 0), 
	CONSTRAINT CK_Detalle_Factura_precio CHECK (precio_unitario >= 0), 
	CONSTRAINT CK_Detalle_Factura_descuento CHECK(monto_descuento >= 0), 
	CONSTRAINT CK_Detalle_Factura_subtotal CHECK (subtotal_linea >= 0), 
	CONSTRAINT CK_Detalle_Factura_impuesto CHECK (monto_impuesto_linea >= 0), 
	CONSTRAINT CK_Detalle_Factura_total CHECK (monto_total_linea >= 0)	
); 
GO
