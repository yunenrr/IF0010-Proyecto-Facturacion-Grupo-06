USE Sistema_Facturacion;
GO

CREATE TABLE dbo.Producto (
    id_producto INT IDENTITY(1,1) NOT NULL,
    codigo_interno VARCHAR(20) NOT NULL,
    descripcion_producto NVARCHAR(150) NOT NULL,
    precio_unitario DECIMAL(18,5) NOT NULL,
    tasa_impuesto DECIMAL(5,4) NOT NULL, -- formato tasa: 0.13
    estado_producto BIT NOT NULL,
    fecha_creacion DATETIME2(3) NOT NULL,

    CONSTRAINT PK_Producto PRIMARY KEY (id_producto),

    CONSTRAINT UQ_Producto_codigo_interno UNIQUE (codigo_interno),
    
    CONSTRAINT CK_Producto_precio_unitario CHECK (precio_unitario >= 0),
    CONSTRAINT CK_Producto_tasa_impuesto CHECK (tasa_impuesto BETWEEN 0 AND 1)
);

ALTER TABLE dbo.Producto 
    ADD CONSTRAINT DF_Producto_fecha_creacion DEFAULT SYSDATETIME() FOR fecha_creacion;
GO