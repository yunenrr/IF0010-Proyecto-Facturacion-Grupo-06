USE Sistema_Facturacion;

CREATE TABLE Moneda(
	codigo_moneda CHAR(3) NOT NULL,
	simbolo VARCHAR(5) NOT NULL,
	descripcion NVARCHAR(50) NOT NULL,

	CONSTRAINT PK_Moneda PRIMARY KEY (codigo_moneda),
	CONSTRAINT UQ_Moneda_simbolo UNIQUE (simbolo)
);

