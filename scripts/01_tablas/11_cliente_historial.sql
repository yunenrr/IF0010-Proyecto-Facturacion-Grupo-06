
/* dbo.Cliente_Historial — auditoría del registro de clientes.
   Sin FK hacia dbo.Cliente porque debe registrar el DELETE de clinetes que ya no existen. */

USE Sistema_Facturacion;
GO

DROP TABLE IF EXISTS dbo.Cliente_Historial;
GO

CREATE TABLE dbo.Cliente_Historial(
	id_historial INT IDENTITY(1,1) NOT NULL,
	id_cliente INT NOT NULL,
	operacion CHAR(6) NOT NULL, -- INSERT | DELETE | UPDATE
	usuario_responsable SYSNAME NOT NULL CONSTRAINT DF_Cliente_Historial_usuario_responsable DEFAULT ORIGINAL_LOGIN(),
	fecha_cambio DATETIME2(3) NOT NULL CONSTRAINT DF_Cliente_Historial_fecha_cambio DEFAULT (SYSDATETIME()),
	descripcion_cambio NVARCHAR(500),
	cedula_anterior VARCHAR(12),
	cedula_nueva VARCHAR(12),
	correo_anterior VARCHAR(254),
	correo_nuevo VARCHAR(254),
	telefono_anterior VARCHAR(12),
	telefono_nuevo VARCHAR(12),
	CONSTRAINT PK_Cliente_Historial PRIMARY KEY (id_historial),
	CONSTRAINT CK_Cliente_Historial_operacion CHECK (operacion IN ('INSERT','UPDATE','DELETE'))
);
GO