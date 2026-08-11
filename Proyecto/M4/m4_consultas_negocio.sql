-- ══════════════════════════════════════════
-- Ventas_Tech_DB — Pre-entrega M4: Consultas SQL de negocio
-- Extrayendo métricas clave con funciones de agregación
-- Autora: Gilda Frías
-- Fecha: 25 de julio de 2026
-- Motor objetivo: SQL Server (T-SQL). Nota: si algún día trabajamos esto
-- en PostgreSQL (que no lo vimos), MONTH(fecha_venta) pasa a ser EXTRACT(MONTH FROM
-- fecha_venta), y "SELECT TOP N" pasa a ser "... ORDER BY ... LIMIT N".
-- Se trabaja únicamente sobre la tabla "ventas" (id_cliente,
-- id_producto, cantidad, precio_unitario, fecha_venta), creada en M3. 
-- ══════════════════════════════════════════

-- Asegurando que las consultas corran contra Ventas_Tech_DB y no contra
-- "master" (la base por defecto de SQL Server).
USE Ventas_Tech_DB;
GO

-- ── CONSULTA 1: Resumen ejecutivo mensual ────────────────────────
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
SELECT
    MONTH(fecha_venta)               AS mes,
    SUM(cantidad * precio_unitario)  AS total_facturado,
    COUNT(*)                         AS cantidad_pedidos,
    AVG(cantidad * precio_unitario)  AS ticket_promedio
FROM ventas
GROUP BY MONTH(fecha_venta)
ORDER BY mes;


-- ── CONSULTA 2: Ranking de productos (Top 5) ─────────────────────
-- Los 5 productos que más facturaron, con sus unidades vendidas.
-- En T-SQL, TOP va pegado al SELECT (no existe LIMIT al final).
SELECT TOP 5
    id_producto,
    SUM(cantidad)                    AS unidades_vendidas,
    SUM(cantidad * precio_unitario)  AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;


-- ── CONSULTA 3: Clientes recurrentes ─────────────────────────────
-- Clientes con más de un pedido, con su cantidad de compras y gasto total.
SELECT
    id_cliente,
    COUNT(*)                         AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)  AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
-- HAVING filtra sobre el resultado ya agrupado (no se puede usar WHERE
-- acá porque COUNT(*) todavía no existe antes de agrupar).
ORDER BY total_gastado DESC;


-- ── CONSULTA 4: Meses por encima / por debajo del promedio ───────
-- Total facturado por mes, comparado contra el promedio mensual general.
WITH ventas_por_mes AS (
    SELECT
        MONTH(fecha_venta) AS mes,
        SUM(cantidad * precio_unitario) AS total_facturado
    FROM ventas
    GROUP BY MONTH(fecha_venta)
)
SELECT
    mes,
    total_facturado,
    CASE
        WHEN total_facturado >= (SELECT AVG(total_facturado) FROM ventas_por_mes)
            THEN 'Por encima'
        ELSE 'Por debajo'
    END AS comparacion_promedio
FROM ventas_por_mes
ORDER BY mes;


-- ══════════════════════════════════════════
-- HALLAZGOS
-- ══════════════════════════════════════════
-- 1. El producto 1 concentra el 55,9% de toda la facturación cargada
--    ($3.600 de $6.444 en total) muy por delante del segundo puesto
--    (producto 3, con $1.350) — vale la pena confirmar si ese volumen
--    depende de pocos clientes puntuales o es un producto realmente
--    masivo antes de tomarlo como referencia para stock o promociones.
--
-- 2. El 100% de los clientes cargados son recurrentes: los 5 hicieron
--    exactamente 2 compras cada uno. El cliente 1 es el que más gastó
--    en total ($2.640), seguido de cerca por el cliente 5 ($2.100) —
--    entre los dos concentran casi el 74% del gasto total.
--
-- 3. Las 10 ventas cargadas hasta ahora caen todas en marzo de 2024
--    (un solo mes), así que la Consulta 4 todavía no es representativa:
--    con un único mes, ese mes siempre va a quedar "en el promedio".
--    Esta comparación va a empezar a aportar valor real cuando se
--    carguen ventas de más meses.
