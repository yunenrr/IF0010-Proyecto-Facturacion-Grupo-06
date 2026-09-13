
/* dbo.Factura — encabezado del comprobante: guarda los datos principales de la compra. */

USE Sistema_Facturacion;
GO

DROP TABLE IF EXISTS dbo.Factura;
GO

CREATE TABLE dbo.Factura (
	id_factura INT IDENTITY(1,1) NOT NULL, -- PK de Factura
	id_tipo_documento TINYINT NOT NULL, -- FK a Tipo_Documento
	id_empresa_emisora INT NOT NULL, -- FK a Empresa
	id_cliente_comprador INT NOT NULL, -- FK a Cliente
	id_estado_factura TINYINT NOT NULL, -- FK a Estado_Factura
	id_moneda TINYINT NOT NULL, -- Divisa. FK a Moneda
	consecutivo CHAR(20), -- AAAAMMDDHHMMSS-TipoDocumento
	fecha_creacion DATETIME2(3) NOT NULL 
		CONSTRAINT DF_Factura_fecha_creacion DEFAULT (SYSDATETIME()), -- Cuándo la fila entró a la base de datos
	fecha_modificacion DATETIME2(3) NOT NULL 
		CONSTRAINT DF_Factura_fecha_modificacion DEFAULT (SYSDATETIME()), -- Cuándo cambió desde la última vez
	fecha_emision DATETIME2(0), -- Cuándo el comprobante cobró validez frente al cliente
	subtotal_factura DECIMAL(18,2) NOT NULL,
	total_descuentos DECIMAL(18,2) NOT NULL,
	total_impuestos DECIMAL(18,2) NOT NULL,
	monto_final DECIMAL(18,2) NOT NULL,
	observaciones NVARCHAR(500),
	CONSTRAINT PK_Factura PRIMARY KEY (id_factura),
	CONSTRAINT FK_Factura_Cliente FOREIGN KEY (id_cliente_comprador)
		REFERENCES dbo.Cliente (id_cliente),
	CONSTRAINT FK_Factura_Estado_Factura FOREIGN KEY (id_estado_factura) 
		REFERENCES dbo.Estado_Factura (codigo_estado),
	CONSTRAINT FK_Factura_Tipo_Documento FOREIGN KEY (id_tipo_documento) 
		REFERENCES dbo.Tipo_Documento (codigo_identificador),
	CONSTRAINT FK_Factura_Empresa FOREIGN KEY (id_empresa_emisora) 
		REFERENCES dbo.Empresa (id_empresa),
	CONSTRAINT FK_Factura_Moneda FOREIGN KEY (id_moneda) 
		REFERENCES dbo.Moneda (codigo_moneda),
	CONSTRAINT CK_Factura_subtotal_positivo CHECK (subtotal_factura >= 0),
	CONSTRAINT CK_Factura_total_descuentos CHECK (total_descuentos >= 0),
	CONSTRAINT CK_Factura_total_impuestos CHECK (total_impuestos >= 0),
	CONSTRAINT CK_Factura_monto_final CHECK (monto_final >= 0)
);
GO