
/* dbo.Estado_Factura — catálogo del ciclo de vida del comprobante. */

USE Sistema_Facturacion;
GO

CREATE TABLE dbo.Estado_Factura(
	id_estado_factura TINYINT NOT NULL, -- PK de Estado_Factura
	estado VARCHAR(10) NOT NULL, -- Ej: BORRADOR | EMITIDA | PAGADA | CANCELADA
	descripcion_estado NVARCHAR(50),
	CONSTRAINT PK_Estado_Factura PRIMARY KEY (id_estado_factura),
	CONSTRAINT UQ_Estado_Factura_estado UNIQUE (estado),
	CONSTRAINT UQ_Estado_Factura_descripcion_estado UNIQUE (descripcion_estado)
);
GO