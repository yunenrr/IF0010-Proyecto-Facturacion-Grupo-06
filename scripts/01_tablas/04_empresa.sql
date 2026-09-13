--Tabla empresa: 

USE Sistema_Facturacion;
GO

DROP TABLE IF EXISTS dbo.Empresa;
GO

CREATE TABLE dbo.Empresa (

	id_empresa INT IDENTITY(1,1) NOT NULL, 
	nombre_comercial NVARCHAR(150) NOT NULL, 
	razon_social NVARCHAR(150) NOT NULL, 
	cedula_empresa VARCHAR(12) NOT NULL, --Utiliza formato sin guiones
	direccion_empresa NVARCHAR(200) NOT NULL, 
	telefono_empresa VARCHAR(12) NOT NULL, 
	correo_electronico VARCHAR(254) NOT NULL, 
	fecha_creacion DATETIME2(3) NOT NULL DEFAULT (SYSDATETIME()), 
	esta_activa BIT NOT NULL, 

	CONSTRAINT PK_Empresa PRIMARY KEY (id_empresa),
	CONSTRAINT UQ_Empresa_cedula_empresa UNIQUE(cedula_empresa)
); 
GO
