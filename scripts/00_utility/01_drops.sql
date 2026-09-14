/* Dropea las tablas en orden inverso de dependencia.
   Correr SIEMPRE antes de la carpeta 01_tablas.*/

USE Sistema_Facturacion;
GO

-- 1. Auditoría
DROP TABLE IF EXISTS dbo.Detalle_Factura_Historial;
DROP TABLE IF EXISTS dbo.Factura_Historial;
DROP TABLE IF EXISTS dbo.Cliente_Historial;
DROP TABLE IF EXISTS dbo.Producto_Historial;
GO

-- 2. Transaccionales
DROP TABLE IF EXISTS dbo.Detalle_Factura;
DROP TABLE IF EXISTS dbo.Factura;
GO

-- 3. Maestros
DROP TABLE IF EXISTS dbo.Producto;
DROP TABLE IF EXISTS dbo.Cliente;
DROP TABLE IF EXISTS dbo.Empresa;
GO

-- 4. Catálogos
DROP TABLE IF EXISTS dbo.Estado_Factura;
DROP TABLE IF EXISTS dbo.Tipo_Documento;
DROP TABLE IF EXISTS dbo.Moneda;
GO