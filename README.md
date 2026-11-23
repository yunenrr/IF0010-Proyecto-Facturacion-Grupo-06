**IF0010 · Proyecto Sistema de Facturación · Grupo 06**

**Título del proyecto**

Sistema de Facturación Electrónica (base de datos SISTEMA_FACTURACION).

**Descripción general**

Este proyecto implementa en Microsoft SQL Server la base de datos de un sistema de facturación electrónica inspirado en los comprobantes de Hacienda de Costa Rica. En el sistema, varias empresas emisoras, cada una dedicada a un rubro de actividad, emiten facturas y tiquetes a clientes que pueden ser personas físicas o jurídicas. Cada comprobante tiene un encabezado, sus líneas de detalle y, si hace falta, una observación, y recorre un ciclo de vida de cuatro estados: BORRADOR, EMITIDA, PAGADA y CANCELADA. El catálogo de productos distingue entre bienes, que manejan inventario, y servicios, que no.

Además del modelo de datos, el proyecto incluye una carga masiva de datos de prueba, auditoría completa de los cambios mediante triggers, índices para las consultas más frecuentes, procedimientos almacenados que concentran las reglas de negocio, funciones y vistas de consulta, y un esquema de seguridad por roles que enmascara los datos sensibles según quién consulta. El diagrama entidad-relación y el estándar de nomenclatura del grupo están en las carpetas diagrama_ER y estandar_nomenclatura.

Es el proyecto del curso IF0010 Bases de Datos II de la Universidad de Costa Rica, Sede del Atlántico, II Ciclo 2026, a cargo del profesor Yunen Ramos Ramírez.

**Integrantes del grupo**

- Dayanna Romero Jiménez, carné C4J440
- Brayan Valverde Ramírez, carné C4K619
- Daniel Cordero Solano, carné C4E444

**Requisitos**

- SQL Server 2022 o una versión posterior. SQL Server 2019 no alcanza, porque la carga de productos usa la función GENERATE_SERIES, que existe a partir de 2022 con el nivel de compatibilidad 160 (el que trae por defecto una base creada en esa versión). El grupo probó todo en SQL Server 2022 corriendo en un contenedor Docker, pero funciona igual en una instalación local.
- SQL Server Management Studio (el grupo trabajó con SSMS 22) para abrir y ejecutar los scripts.
- Un inicio de sesión con permiso para crear bases de datos, roles y usuarios, por ejemplo uno que pertenezca a sysadmin.
- Espacio en disco y algo de paciencia para la carga masiva: genera medio millón de comprobantes con sus líneas y sus registros de auditoría, así que tarda varios minutos.

**Instrucciones de ejecución**

Los scripts están numerados. Se ejecutan carpeta por carpeta en orden y, dentro de cada carpeta, siguiendo el número con que empieza cada archivo. Todos los archivos se posicionan por sí mismos en la base SISTEMA_FACTURACION, así que basta con abrir cada uno en SSMS y ejecutarlo completo.

- **00_utility**: 00_CrearDB crea la base si todavía no existe y 01_drops elimina las tablas en orden inverso de dependencia. El script de drops se corre siempre antes de crear las tablas, incluso la primera vez.
- **01_tablas**: crea las 27 tablas, desde 00_PROVINCIA hasta 26_SERVICIO_HISTORIAL.
- **02_funciones**: crea las funciones. Van antes de la carga porque la generación de facturas usa UFN_CLAVE_COMPROBANTE para armar los consecutivos.
- **03_triggers**: crea los triggers de auditoría. Van antes de la carga, por indicación del profesor, para que los historiales también registren los datos cargados.
- **04_carga_masiva**: llena los catálogos y los datos de prueba, desde 00_tipo_operacion hasta 13_servicios.
- **05_indices**: crea los índices no agrupados cuando las tablas ya tienen datos.
- **06_procedimientos**: crea los procedimientos almacenados de negocio.
- **07_vistas**: crea las dos vistas.
- **08_seguridad**: 01_roles crea los roles y los usuarios de prueba, y después 02_permisos otorga los permisos sobre los objetos ya creados.
- **09_demostraciones**: scripts opcionales que prueban el sistema de punta a punta. Se pueden correr en cualquier orden una vez terminada la instalación.

**Componentes de la base de datos**

**Tablas**

El modelo tiene 27 tablas. Los catálogos (MONEDA, TIPO_DOCUMENTO, ESTADO_FACTURA, RUBRO, TIPO_PRODUCTO y TIPO_OPERACION) usan una llave sustituta con valores fijos y su código de negocio como clave alterna. La división territorial (PROVINCIA, CANTON y DISTRITO) alimenta a DIRECCION, que guarda la ubicación de empresas y clientes. CLIENTE es un supertipo con los datos comunes de todo comprador, y sus subtipos CLIENTE_FISICO y CLIENTE_JURIDICO guardan el nombre y los apellidos o la razón social y el nombre comercial. De la misma forma, PRODUCTO guarda todo lo que se factura y su subtipo SERVICIO agrega la duración estimada y si se brinda a domicilio. FACTURA es el encabezado del comprobante, DETALLE_FACTURA sus líneas y FACTURA_OBSERVACION una nota opcional. Por último, ocho tablas de historial guardan la bitácora de cambios de las tablas auditadas.

**Procedimientos almacenados de negocio**

Todos siguen el mismo patrón. Validan las reglas de negocio y, si una no se cumple, lanzan un error con un código propio. Hacen los cambios dentro de una transacción, de modo que o se guarda todo o no se guarda nada, y en lugar de propagar el error lo devuelven en los parámetros de salida CODIGO_ERROR (que vale 0 cuando todo sale bien) y MENSAJE.

- **USP_CREAR_FACTURA**: crea un comprobante en estado BORRADOR a partir de la empresa, el cliente, el tipo de documento, la moneda y una lista de líneas que recibe en el tipo tabla TT_LINEA_FACTURA (producto, cantidad y descuento). Verifica que la empresa esté activa, que el cliente exista, que haya entre 1 y 255 líneas, que cada producto exista, esté activo y pertenezca al rubro de la empresa, que los bienes se facturen en cantidades enteras y que ningún descuento iguale o supere el subtotal de su línea. Toma el precio y la tasa vigentes de cada producto, calcula y redondea cada línea, suma las líneas para obtener los totales del encabezado y guarda encabezado, detalle y observación juntos.
- **USP_CAMBIAR_ESTADO_FACTURA**: mueve un comprobante por su ciclo de vida. Desde BORRADOR solo se puede pasar a EMITIDA o CANCELADA, desde EMITIDA solo a PAGADA o CANCELADA, y PAGADA y CANCELADA son estados finales. Al emitir exige que el comprobante tenga líneas, le asigna el consecutivo y la fecha de emisión definitivos y descuenta la existencia de los bienes; si la existencia no alcanza, rechaza la emisión. Al cancelar una factura ya emitida devuelve esa existencia al inventario. Antes de guardar comprueba que nadie haya cambiado el estado al mismo tiempo.
- **USP_REGISTRAR_EMPRESA**: registra una empresa emisora junto con su dirección. Valida que la cédula jurídica tenga 10 dígitos, empiece con 3 y no esté repetida, que el teléfono tenga 8 dígitos, que el correo tenga un formato válido y que el rubro y el distrito existan.
- **USP_ACTUALIZAR_EMPRESA**: cambia solo los datos de la empresa que se envían (nombres, teléfono, correo, dirección o si está activa) y conserva los demás. La dirección se actualiza sobre la misma fila y su versión anterior queda en el historial.
- **USP_REGISTRAR_CLIENTE_FISICO**: registra una persona física creando su dirección, sus datos comunes en CLIENTE y su nombre y apellidos en CLIENTE_FISICO. Valida que no falte ningún dato, que la cédula tenga entre 9 y 12 dígitos y no sea jurídica, que ni la cédula ni el correo estén ya registrados, el formato del teléfono y del correo, y que el distrito exista.
- **USP_REGISTRAR_CLIENTE_JURIDICO**: hace lo mismo para una persona jurídica, con una cédula de 10 dígitos que empieza con 3, su razón social y su nombre comercial.
- **USP_ACTUALIZAR_CLIENTE**: actualiza los datos comunes de cualquier cliente, es decir, el correo, el teléfono y la dirección. Solo cambia lo que se envía, valida los formatos, evita que el correo quede repetido con otro cliente y exige el distrito y las otras señas juntos. Igual que con las empresas, la dirección se actualiza sobre la misma fila.
- **USP_ACTUALIZAR_CLIENTE_FISICO**: cambia el nombre o los apellidos de una persona física y actualiza la fecha de última modificación del cliente.
- **USP_ACTUALIZAR_CLIENTE_JURIDICO**: cambia la razón social o el nombre comercial de una persona jurídica y actualiza la fecha de última modificación del cliente.
- **USP_REGISTRAR_PRODUCTO**: registra un bien (PRD) o un servicio (SRV). Valida el tipo, el rubro, la descripción, que el precio sea mayor que cero y que la tasa sea una tarifa oficial de IVA (0 %, 1 %, 2 %, 4 % o 13 %). Genera el código interno con el tipo, el rubro y un número consecutivo de cinco dígitos, y bloquea ese rango mientras lo calcula para que dos registros simultáneos no obtengan el mismo número. Un servicio lleva existencia cero y se registra también en SERVICIO con su duración y su modalidad a domicilio; un bien no admite esos dos datos.
- **USP_ACTUALIZAR_PRECIO_PRODUCTO**: cambia el precio unitario, la tasa de impuesto o ambos, con las mismas validaciones del registro. Como cada línea de factura guarda el precio y la tasa del momento en que se facturó, el cambio no altera los comprobantes anteriores.
- **USP_ACTUALIZAR_SERVICIO**: cambia la duración estimada o la modalidad a domicilio de un servicio. El precio y la tasa de un servicio se cambian con el procedimiento anterior.

**Procedimientos de carga masiva**

Cada script de la carpeta 04_carga_masiva crea un procedimiento y lo ejecuta de inmediato. Si la tabla ya tiene sus datos, el procedimiento no vuelve a cargarlos, y si algo falla el script termina con error para que no pase desapercibido. Al final, cada carga verifica que se insertó la cantidad esperada y que los datos cumplen las reglas de negocio.

- **USP_CARGAR_TIPO_OPERACION**: carga las operaciones INSERT, UPDATE y DELETE. Va de primera porque los triggers la necesitan para registrar cualquier cambio.
- **DATOS_DIRECCIONES**: carga las 7 provincias, 23 cantones y 81 distritos de Costa Rica.
- **USP_CARGAR_DIRECCION**: genera 55 100 direcciones repartidas entre los distritos, 100 para las empresas y 55 000 para los clientes.
- **USP_CARGAR_RUBRO**: carga los 10 rubros de actividad.
- **USP_CARGAR_EMPRESA**: genera 100 empresas, diez por rubro, de las cuales una de cada diez queda inactiva.
- **USP_CARGAR_CLIENTE**: genera 50 000 personas físicas y 5 000 personas jurídicas, insertando primero el supertipo y luego el subtipo de cada una.
- **USP_CARGAR_TIPO_DOCUMENTO**, **USP_CARGAR_ESTADO_FACTURA**, **USP_REGISTRAR_MONEDAS_BASE** y **USP_CARGAR_TIPO_PRODUCTO**: cargan los catálogos de tipos de comprobante (FAC y TIQ), estados de factura, monedas (CRC, USD y EUR) y tipos de producto (PRD y SRV).
- **USP_CARGAR_PRODUCTOS**: genera 1 000 productos, 600 bienes en seis rubros y 400 servicios en cuatro. Cerca de un 10 % queda inactivo, los servicios llevan existencia cero y todos se crean antes del periodo de las facturas, para que ningún producto aparezca en un comprobante anterior a su fecha de creación.
- **USP_CARGAR_FACTURAS**: genera 500 000 comprobantes en colones distribuidos a lo largo del último año, en lotes de 25 000 para no saturar el registro de transacciones. Aproximadamente el 70 % son facturas y el 30 % tiquetes; el 5 % queda en borrador, el 15 % emitido, el 70 % pagado y el 10 % cancelado.
- **USP_CARGAR_DETALLES**: agrega de 3 a 5 líneas a cada comprobante con productos activos del rubro de la empresa emisora, aplica descuentos a cerca de una cuarta parte de las líneas y recalcula los totales de cada encabezado como la suma de sus líneas. Al terminar muestra consultas de control que confirman que no hay facturas sin líneas ni facturas descuadradas.
- **USP_CARGAR_SERVICIO**: crea en SERVICIO una fila por cada producto de tipo servicio, con su duración estimada y si se brinda a domicilio.

**Funciones**

- **UFN_MONTO_FINAL_FACTURA**: devuelve el monto a pagar de una factura (subtotal menos descuentos más impuestos), o un valor nulo si la factura no existe.
- **UFN_CLAVE_COMPROBANTE**: arma el consecutivo de un comprobante con la fecha y hora (año, mes, día, hora, minuto y segundo) seguidas del código del tipo de documento. La usan la creación, la emisión y la carga de facturas.
- **UFN_FACTURA_ES_BORRADOR**: recibe un consecutivo e indica si ese comprobante todavía se puede modificar. Devuelve 1 si está en borrador, 0 si está en otro estado y nulo si no existe.
- **UFN_HISTORIAL_CAMBIOS**: une las ocho tablas de auditoría en una sola línea de tiempo con columnas comunes (tabla, registro, operación, usuario, fecha y un resumen del cambio) y permite filtrar por un rango de fechas. Solo devuelve filas a los roles AUDITOR y DBA; el DBA ve los datos completos, mientras que el auditor ve el correo, el teléfono y las señas de la dirección enmascarados. Para cualquier otro usuario no devuelve filas, pero tampoco da error.
- **UFN_INFO_CLIENTE**: devuelve la información de contacto de un cliente a partir de su cédula. Los roles ADMINISTRATIVO y DBA ven el correo y el teléfono completos, los roles CAJERO y CONSULTA los ven enmascarados, y cualquier otro usuario no obtiene filas.
- **UFN_FACTURAS_PERSONA_FISICA** y **UFN_FACTURAS_PERSONA_JURIDICA**: listan los comprobantes de un cliente a partir de su cédula, con su estado, empresa, moneda y totales, sin incluir los borradores. Cada una solo responde a su tipo de persona, así que una cédula del otro tipo o inexistente devuelve cero filas.
- **UFN_BUSCAR_FISICA_PRIMER_APELLIDO** y **UFN_BUSCAR_FISICA_SEGUNDO_APELLIDO**: buscan personas físicas por nombre y primer apellido, o por nombre y segundo apellido, y se apoyan en los índices creados para esas búsquedas.
- **UFN_BUSCAR_JURIDICA_RAZON_SOCIAL** y **UFN_BUSCAR_JURIDICA_NOMBRE_COMERCIAL**: buscan personas jurídicas cuya razón social o nombre comercial contenga el texto indicado, sin importar mayúsculas ni tildes. No devuelven correo ni teléfono.
- **UFN_TOTALES_CLIENTE_ANIO**: suma lo facturado a un cliente durante el año en curso, separado por moneda, contando solo los comprobantes emitidos o pagados.
- **UFN_VENTAS_PRODUCTO_RANGO**: lista las líneas en que se vendió un producto, identificado por su código interno, entre dos fechas incluidas, también contando solo comprobantes emitidos o pagados.

**Triggers**

Hay un trigger de auditoría por cada tabla auditada: TR_FACTURA_AUDITORIA, TR_DETALLE_FACTURA_AUDITORIA, TR_CLIENTE_AUDITORIA, TR_CLIENTE_FISICO_AUDITORIA, TR_CLIENTE_JURIDICO_AUDITORIA, TR_DIRECCION_AUDITORIA, TR_PRODUCTO_AUDITORIA y TR_SERVICIO_AUDITORIA. Todos funcionan igual. Se disparan después de cada inserción, actualización o eliminación y escriben en la tabla de historial correspondiente qué operación ocurrió, qué usuario la hizo y en qué momento. En una inserción guardan la versión nueva de la fila, en una actualización guardan la versión anterior al cambio y en una eliminación guardan la última versión que existió. En las actualizaciones solo dejan registro si de verdad cambió alguna columna auditada, de modo que un cambio que deja los mismos valores no llena el historial. Trabajan por conjuntos, así que registran correctamente las operaciones que afectan muchas filas a la vez, como la carga masiva.

**Índices**

Todos son no agrupados; los índices agrupados son los de las llaves primarias.

- **NC_FACTURA_CONSECUTIVO**: índice único sobre el consecutivo. Garantiza que no haya dos comprobantes con el mismo identificador e incluye los totales, de modo que consultar los montos de una factura por su consecutivo no tiene que ir a la tabla.
- **NC_FACTURA_CLIENTE_FECHA**: ordena las facturas por comprador y de la más reciente a la más antigua, e incluye el estado, el consecutivo y el monto final. Atiende las consultas de facturas por cliente.
- **NC_FACTURA_ID_EMPRESA_EMISORA_FECHA_EMISION**: agiliza las consultas de comprobantes emitidos por una empresa en un periodo.
- **NC_FACTURA_FECHA_EMISION**: agiliza las consultas por rango de fechas, como los totales diarios, e incluye el monto final.
- **NC_FACTURAHISTORIAL_ID_FACTURA_FECHA_CAMBIO**: permite recorrer en orden cronológico los cambios de un comprobante.
- **NC_DETALLE_FACTURA_ID_PRODUCTO**: localiza rápido las líneas de un producto e incluye la factura, la cantidad y el total de la línea. Lo usa la consulta de ventas por producto.
- **NC_DETALLE_FACTURA_FACTURA_LINEA**: recupera las líneas de un comprobante en su orden.
- **NC_CLIENTE_FISICO_NOMBRE_PRIMER_APELLIDO** y **NC_CLIENTE_FISICO_NOMBRE_SEGUNDO_APELLIDO**: cubren las dos búsquedas de personas físicas por nombre y apellido, para que no haya que recorrer toda la tabla.

**Vistas**

- **VW_TOTALES_DIARIOS_FACTURADOS**: resume por día, empresa y tipo de documento cuántos comprobantes se emitieron y cuánto sumaron en subtotal, descuentos, impuestos y monto final. Solo toma comprobantes emitidos o pagados y agrupa por los identificadores, no por el nombre, para no mezclar empresas con nombres parecidos.
- **VW_CLIENTES**: muestra cada cliente con su cédula, su nombre completo o razón social, la cantidad de comprobantes que tiene (sin contar borradores) y si es un cliente frecuente, que en este sistema significa tener más de cinco comprobantes emitidos o pagados en los últimos seis meses.

**Roles y permisos**

El script 01_roles crea cinco roles de base de datos y un usuario de prueba para cada uno (USR_AUDITOR, USR_DBA, USR_ADMINISTRATIVO, USR_CAJERO y USR_CONSULTA). Los usuarios se crean sin inicio de sesión, porque su único fin es probar los permisos suplantándolos desde los scripts de demostración. Todos los permisos se otorgan en un solo lugar, el script 02_permisos, y ningún rol recibe acceso directo a las tablas: todo pasa por procedimientos, funciones y vistas, que son los que aplican las validaciones y el enmascaramiento.

- **AUDITOR**: es un rol de solo lectura. Consulta el historial de cambios con los datos sensibles enmascarados y puede usar las funciones de consulta y la vista de totales diarios, pero no puede modificar nada.
- **DBA**: es un rol propio del sistema, distinto de db_owner. Puede ejecutar todos los procedimientos y consultas, y es el único que ve el historial de cambios sin enmascarar.
- **ADMINISTRATIVO**: gestiona todo el negocio. Registra y actualiza empresas, clientes, productos, precios y servicios, crea y cambia el estado de los comprobantes, y ve la información de los clientes completa.
- **CAJERO**: atiende la venta del día a día. Registra y actualiza clientes, crea comprobantes y cambia su estado, y usa las consultas con los datos de contacto enmascarados. No administra empresas ni el catálogo de productos y no tiene acceso a los totales diarios.
- **CONSULTA**: solo lee. Usa las funciones de consulta, la vista de clientes y la de totales diarios, con los datos de contacto enmascarados.

**Scripts de demostración**

- **01_demo_roles**: verifica que los roles y membresías existen y suplanta a cada usuario de prueba para mostrar que el historial y la consulta de borradores responden según el rol, incluido un intento del cajero de leer una tabla directamente, que debe ser rechazado.
- **02_demo_info_cliente**: consulta el mismo cliente con cada usuario de prueba para comparar qué ve cada rol.
- **03_demo_clientes**: registra una persona física y una jurídica como administrativo, les cambia los nombres, muestra el rastro que dejan los triggers y cronometra las búsquedas por nombre y apellido.
- **04_demo_comprobantes**: crea y emite una factura como cajero, cambia el teléfono del cliente y revisa los historiales del encabezado, del detalle y del cliente.
- **05_demo_catalogo**: prueba los triggers de dirección, producto y servicio a través de los procedimientos y cronometra las consultas de personas jurídicas y de ventas por producto.

**Notas importantes o consideraciones especiales**

- Para reinstalar desde cero basta con volver a correr todo a partir de 01_drops. Al borrar las tablas también desaparecen sus triggers e índices, y el resto de objetos se crea con instrucciones que reemplazan la versión anterior. La base en sí no se elimina.
- El orden de las carpetas no es arbitrario. Los triggers se crean antes de la carga para que los historiales registren los datos iniciales, y por eso la tabla TIPO_OPERACION es lo primero que se carga. Los índices se crean después de la carga para no frenar las inserciones masivas, y los permisos se otorgan al final porque necesitan que los objetos ya existan.
- Como los triggers están activos durante la carga, las tablas de historial también quedan grandes. Cada comprobante deja un registro de inserción y otro de actualización, este último cuando la carga del detalle le calcula los totales. Mientras la carga avanza, SSMS muestra mensajes de progreso en la pestaña de mensajes.
- Por indicación del profesor, las reglas de negocio no están en restricciones CHECK de las tablas sino en los procedimientos almacenados, así que los datos deben modificarse siempre a través de ellos.
- Los montos de dinero se manejan con dos decimales y el precio unitario con hasta cinco, siguiendo los esquemas de factura electrónica de Hacienda. El redondeo se hace en cada línea y el encabezado es la suma exacta de sus líneas, para que el comprobante siempre cuadre. El impuesto se guarda como tasa (0.13) y no como porcentaje.
- El consecutivo tiene el formato año, mes, día, hora, minuto y segundo, un guion y el código del tipo de documento. Mientras un comprobante está en borrador su consecutivo y su fecha de emisión son provisionales, y se reemplazan por los definitivos al emitirlo. Como el consecutivo llega hasta el segundo, si dos comprobantes del mismo tipo coinciden en el mismo segundo el procedimiento devuelve un error controlado y basta con intentarlo de nuevo.
- Los bienes solo se facturan en cantidades enteras, mientras que los servicios admiten decimales. Los servicios no manejan existencia.
- Los datos de prueba se generan en relación con la fecha en que se ejecuta la carga. Por eso los resultados de la vista de clientes frecuentes y de los totales del año en curso dependen del día en que se instale la base.
- Los scripts de demostración crean registros nuevos cada vez que se ejecutan y los conservan, así que se pueden repetir sin errores, aunque los historiales van creciendo.
- Los errores de negocio usan un código propio con el formato 5BBNN, donde BB identifica el procedimiento que lo lanza. La tabla completa de bloques está en el documento del estándar de nomenclatura.
- Todos los objetos siguen el estándar de nomenclatura del grupo (identificadores en mayúsculas, esquema DBO y prefijos como USP_, UFN_, VW_, TR_ y NC_), y los scripts se revisan con las validaciones de SQLFluff del repositorio.
