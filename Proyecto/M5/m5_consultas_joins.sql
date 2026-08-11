-- ══════════════════════════════════════════
-- Ventas_Tech_DB — Pre-entrega M5: Consultas con JOINs
-- Cruzando tablas para enriquecer el análisis
-- Autora: Gilda Frías
-- Fecha: 01 de agosto de 2026
-- Motor objetivo: SQL Server (T-SQL)
--
-- NOTA IMPORTANTE sobre el esquema: la consigna original de M5 pide
-- cruzar ventas/clientes/productos/territorios y traer segmento,
-- región y canal. Esas columnas y la tabla "territorios" pertenecen
-- al modelo conceptual del brief de M1/M2, pero nunca se implementaron
-- así en Ventas_Tech_DB (la base real, creada en M3 con solo
-- categorias/clientes/productos/ventas). Se adaptaron las 4 consultas
-- a las columnas que sí existen hoy en la base, documentando en cada
-- caso qué campo pedido no está disponible.
-- ══════════════════════════════════════════

USE Ventas_Tech_DB;
GO

-- ── CONSULTA 1: Vista base del proyecto (INNER JOIN) ─────────────
-- Combina ventas + clientes + productos + categorias (reemplaza a
-- "territorios", que no existe) en una sola fila por venta.
-- No incluye segmento, región ni canal porque esas columnas no
-- existen en clientes/ventas en el esquema actual.
SELECT
    v.fecha_venta,
    c.nombre                          AS nombre_cliente,
    p.nombre_producto,
    cat.nombre_categoria              AS categoria,
    v.cantidad,
    v.precio_unitario,
    (v.cantidad * v.precio_unitario)  AS total_venta
FROM ventas v
INNER JOIN clientes   c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  p   ON v.id_producto  = p.id_producto
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta;


-- ── CONSULTA 2: Clientes sin ventas (LEFT JOIN) ───────────────────
-- LEFT JOIN conserva todos los clientes aunque no tengan ventas; en
-- esas filas las columnas de "ventas" quedan en NULL, así que
-- filtrar por v.id_venta IS NULL aísla justo a los que nunca compraron.
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;
-- Con los datos cargados en M3 (5 clientes, 10 ventas repartidas
-- 2 a 2), esta consulta devuelve 0 filas: los 5 clientes ya compraron
-- al menos una vez. Es el resultado esperado, no un error.


-- ── CONSULTA 3: Productos sin ventas (LEFT JOIN) ──────────────────
SELECT
    p.nombre_producto,
    cat.nombre_categoria AS categoria,
    p.precio
FROM productos p
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas v ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL;
-- Igual que en la Consulta 2: con los 6 productos cargados y las 10
-- ventas de M3, todos tienen al menos una venta registrada, así que
-- esta consulta también devuelve 0 filas por ahora.


-- ── CONSULTA 4: Consolidado por grupo (UNION ALL) ─────────────────
-- La consigna original pedía separar por canal (Online / Presencial),
-- columna que no existe en ventas. Se adaptó el ejercicio separando
-- las ventas en dos grupos por categoría (Computación vs. el resto),
-- para mantener la misma técnica: UNION ALL apila ambos subconjuntos
-- sin eliminar duplicados (a diferencia de UNION), y después se
-- agrega con GROUP BY sobre la columna que identifica el origen.
WITH ventas_por_grupo AS (
    SELECT
        'Computación' AS grupo,
        v.cantidad,
        (v.cantidad * v.precio_unitario) AS total_venta
    FROM ventas v
    INNER JOIN productos  p   ON v.id_producto  = p.id_producto
    INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
    WHERE cat.nombre_categoria = 'Computación'

    UNION ALL

    SELECT
        'Otras categorías' AS grupo,
        v.cantidad,
        (v.cantidad * v.precio_unitario) AS total_venta
    FROM ventas v
    INNER JOIN productos  p   ON v.id_producto  = p.id_producto
    INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
    WHERE cat.nombre_categoria <> 'Computación'
)
SELECT
    grupo,
    SUM(cantidad)    AS unidades_vendidas,
    SUM(total_venta) AS total_facturado
FROM ventas_por_grupo
GROUP BY grupo;
-- Resultado esperado con los datos de M3: Computación = 6 unidades /
-- $4.950; Otras categorías = 23 unidades / $1.494. Suman $6.444, el
-- mismo total facturado que ya habíamos calculado en M4.
