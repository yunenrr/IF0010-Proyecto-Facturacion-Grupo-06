--Tabla empresa: 

CREATE TABLE dbo.EMPRESA (

	id_empresa INT IDENTITY(1,1) NOT NULL, 
	nombre_comercial VARCHAR(100) NOT NULL, 
	razon_social VARCHAR(150)NOT NULL, 
	cedula_empresa VARCHAR(20)NOT NULL, 
	direccion_empresa VARCHAR(200)NOT NULL, 
	telefono_empresa VARCHAR(20)NOT NULL, 
	correo_electronico VARCHAR(100)NOT NULL, 
	fecha_creacion DATE NOT NULL, 
	indicador BIT NOT NULL, 

	CONSTRAINT PK_Empresa PRIMARY KEY (id_empresa),
	CONSTRAINT UQ_Empresa_cedula_empresa UNIQUE(cedula_empresa)
); 
