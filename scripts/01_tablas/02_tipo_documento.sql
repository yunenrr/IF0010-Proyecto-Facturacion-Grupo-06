--Tabla tipo_documento: 

USE Sistema_Facturacion; 
GO

CREATE TABLE dbo.Tipo_Documento(

	id_tipo_documento TINYINT NOT NULL,
	codigo_identificador CHAR(3) NOT NULL, --FAC | TIQ para identificar formato del código
	descripcion NVARCHAR(50) NOT NULL, 

	CONSTRAINT PK_Tipo_Documento PRIMARY KEY(id_tipo_documento),
	CONSTRAINT UQ_Tipo_Documento_codigo_identificador UNIQUE (codigo_identificador)
);
GO
