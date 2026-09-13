USE Sistema_Facturacion;
GO


CREATE TABLE dbo.Moneda(
	id_moneda TINYINT NOT NULL,
	codigo_moneda CHAR(3) NOT NULL,
	simbolo NVARCHAR(5) NOT NULL,
	descripcion NVARCHAR(50) NOT NULL,

	CONSTRAINT PK_Moneda PRIMARY KEY (id_moneda),
	CONSTRAINT UQ_Moneda_codigo_moneda UNIQUE (codigo_moneda)
);
GO

