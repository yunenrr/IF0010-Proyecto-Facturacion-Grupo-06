--Tabla tipo_documento: 

CREATE TABLE dbo.TIPO_DOCUMENTO(

	codigo_identificador CHAR(3) NOT NULL, 
	descripcion VARCHAR(20) NOT NULL, 

	CONSTRAINT PK_TipoDocumento PRIMARY KEY(codigo_identificador)
);
