-- ══════════════════════════════════════════
-- Ventas_Tech_DB — Checkpoint: Script SQL de Ingeniería de Datos
-- Proyecto: TechStore — modelo de ventas de tecnología
-- Autora: Gilda Frías
-- Fecha: 15 de julio de 2026
-- Motor objetivo: PostgreSQL (sintaxis validada también contra SQL Server;
-- las diferencias puntuales entre motores quedan documentadas en
-- comentarios donde corresponde)
-- ══════════════════════════════════════════

-- ── PASO 1: CREAR LA BASE DE DATOS ───────
CREATE DATABASE Ventas_Tech_DB;

-- Después de crear la base, hay que conectarse a ella antes de correr el
-- resto del script (no se puede hacer en la misma sentencia):
--   PostgreSQL (psql):  \c Ventas_Tech_DB
--   SQL Server:         USE Ventas_Tech_DB;  GO
-- Todo lo que sigue asume que ya estás conectado a Ventas_Tech_DB.

-- ── SECCIÓN DDL ──────────────────────────

-- DROP TABLES, en orden inverso de dependencias: primero la tabla de
-- hechos (ventas, que tiene FK hacia clientes y productos), después
-- productos (que tiene FK hacia categorias), y por último las tablas
-- sin dependencias. Así ninguna sentencia intenta borrar una tabla
-- todavía referenciada por otra.
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS categorias;

-- CREATE TABLES, en orden directo de dependencias: primero las
-- dimensiones (categorias, clientes), después productos (depende de
-- categorias) y al final ventas, la tabla de hechos que depende de
-- todas las anteriores. Crear ventas antes que sus referencias haría
-- fallar las FOREIGN KEY ("error del huevo y la gallina").

CREATE TABLE categorias (
    id_categoria      INT PRIMARY KEY,
    -- Identificador simple; solo hay un puñado de categorías, un
    -- entero alcanza y sobra como clave.
    nombre_categoria  VARCHAR(50) NOT NULL,
    descripcion       VARCHAR(200)
);

CREATE TABLE clientes (
    id_cliente      INT PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    email           VARCHAR(100) UNIQUE,
    -- UNIQUE (no PK) porque el email identifica al cliente en el mundo
    -- real pero la clave primaria sigue siendo el id_cliente numérico;
    -- UNIQUE evita que dos clientes queden cargados con el mismo email.
    ciudad          VARCHAR(50),
    fecha_registro  DATE NOT NULL
);

CREATE TABLE productos (
    id_producto      INT PRIMARY KEY,
    nombre_producto  VARCHAR(100) NOT NULL,
    id_categoria     INT,
    precio           DECIMAL(10,2) NOT NULL,
    -- DECIMAL(10,2) y no FLOAT: el precio necesita precisión exacta de
    -- 2 decimales; FLOAT introduce errores de redondeo binario
    -- inaceptables para valores monetarios, e impediría hacer SUM/AVG
    -- confiables más adelante.
    stock            INT DEFAULT 0,
    activo           SMALLINT DEFAULT 1,
    -- 1 = activo, 0 = descontinuado. La consigna sugiere TINYINT(1),
    -- pero ese tipo con parámetro es específico de MySQL; no existe
    -- así en PostgreSQL ni en SQL Server. Se usa SMALLINT porque es un
    -- número pequeño portable entre ambos motores con la misma lógica.
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria)
    -- Garantiza integridad referencial: no puede existir un producto
    -- con una categoría que no está dada de alta en "categorias".
);

CREATE TABLE ventas (
    id_venta          INT PRIMARY KEY,
    id_cliente        INT,
    id_producto       INT,
    cantidad          INT NOT NULL,
    precio_unitario   DECIMAL(10,2) NOT NULL,
    fecha_venta       DATE NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
    -- Estas dos FOREIGN KEY son las que impiden vender un producto o
    -- facturarle a un cliente que no existe en sus tablas respectivas.
);

-- ── SECCIÓN DML ──────────────────────────

-- INSERT DATA, respetando el orden lógico: primero las tablas sin
-- dependencias (categorias, clientes), después productos (depende de
-- categorias) y por último ventas (depende de clientes y productos).

-- categorias — 4 registros
INSERT INTO categorias (id_categoria, nombre_categoria, descripcion) VALUES
    (1, 'Computación',    'Laptops, PCs y monitores'),
    (2, 'Accesorios',     'Periféricos y complementos'),
    (3, 'Audio',          'Auriculares y parlantes'),
    (4, 'Almacenamiento', 'Discos y memorias');

-- clientes — 5 registros
INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro) VALUES
    (1, 'María López',  'maria@mail.com',  'Buenos Aires', '2024-01-05'),
    (2, 'Carlos Ruiz',  'carlos@mail.com', 'Córdoba',      '2024-01-10'),
    (3, 'Ana Gómez',    'ana@mail.com',    'Rosario',      '2024-02-01'),
    (4, 'Pedro Sanz',   'pedro@mail.com',  'Mendoza',      '2024-02-15'),
    (5, 'Laura Torres', 'laura@mail.com',  'Tucumán',      '2024-03-01');

-- productos — 6 registros
INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo) VALUES
    (1, 'Laptop Pro 15',      1, 1200.00, 15, 1),
    (2, 'Mouse Inalámbrico',  2,   28.00, 80, 1),
    (3, 'Monitor 4K 27"',     1,  450.00, 12, 1),
    (4, 'Auriculares BT Pro', 3,  120.00, 35, 1),
    (5, 'SSD Externo 1TB',    4,  130.00, 18, 1),
    (6, 'Teclado Mecánico',   2,   95.00, 40, 1);

-- ventas — 10 registros
INSERT INTO ventas (id_venta, id_cliente, id_producto, cantidad, precio_unitario, fecha_venta) VALUES
    (1,  1, 1, 2, 1200.00, '2024-03-05'),
    (2,  2, 2, 5,   28.00, '2024-03-06'),
    (3,  3, 3, 1,  450.00, '2024-03-07'),
    (4,  1, 4, 2,  120.00, '2024-03-08'),
    (5,  4, 5, 3,  130.00, '2024-03-10'),
    (6,  2, 6, 4,   95.00, '2024-03-11'),
    (7,  5, 1, 1, 1200.00, '2024-03-12'),
    (8,  3, 2, 8,   28.00, '2024-03-13'),
    (9,  4, 4, 1,  120.00, '2024-03-14'),
    (10, 5, 3, 2,  450.00, '2024-03-15');

-- ── PASO 3: VERIFICACIÓN DE INTEGRIDAD ───

-- Confirmá que cada tabla se cargó correctamente
SELECT * FROM categorias;
SELECT * FROM clientes;
SELECT * FROM productos;
SELECT * FROM ventas;

-- (Más adelante, en el Módulo 5, vamos a poder cruzar estas tablas con JOIN
--  para ver las ventas junto al nombre del cliente y del producto.
--  Por ahora alcanza con confirmar que las 4 tablas tienen sus datos.)
