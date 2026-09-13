USE Sistema_Facturacion;
GO

DROP TABLE IF EXISTS dbo.Cliente;
GO

CREATE TABLE dbo.Cliente (
    id_cliente INT IDENTITY(1,1) NOT NULL,
    cedula_cliente VARCHAR(12) NOT NULL,
    nombre_cliente NVARCHAR(150) NOT NULL,
    correo_cliente VARCHAR(254) NOT NULL,
    telefono_cliente VARCHAR(12) NOT NULL,
    direccion_cliente NVARCHAR(200) NOT NULL,
    fecha_registro DATETIME2(3) NOT NULL CONSTRAINT DF_Cliente_fecha_registro DEFAULT SYSDATETIME(),
    fecha_actualizacion DATETIME2(3) NOT NULL CONSTRAINT DF_Cliente_fecha_actualizacion DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Cliente PRIMARY KEY (id_cliente),

    CONSTRAINT UQ_Cliente_cedula_cliente UNIQUE (cedula_cliente),
    CONSTRAINT UQ_Cliente_correo_cliente UNIQUE (correo_cliente)
);
GO