-- ============================================================
-- PRE-ENTREGA: SCRIPT DE ANALISIS AVANZADO CON WINDOW FUNCTIONS
-- Base de datos: retail_project_preentrega2
-- Motor: PostgreSQL
-- ============================================================

-- 1. CTE: ventas_mensuales
-- Agrupa las ventas por mes y categoria.
-- Se utilizan JOIN para relacionar ventas, productos y categorias.
-- El importe de cada venta se calcula multiplicando cantidad
-- por precio_unitario.

with ventas_mensuales as (
    select
        date_trunc('month', v.fecha_venta) AS mes,
        c.nombre as categoria,
        sum (v.cantidad * v.precio_unitario) AS monto
    from ventas v
    inner join productos p
        on v.id_producto = p.id_producto
    inner join categorias c
        on p.id_categoria = c.id_categoria
    group by
        date_trunc('month', v.fecha_venta),
        c.nombre
),
-- 2. CTE: metricas_ventana
-- Calcula dos metricas mediante Window Functions:
-- RANK(): establece el ranking de categorias por mes,
-- ordenando de mayor a menor segun las ventas.
-- SUM() OVER(): calcula el acumulado de ventas de cada
-- categoria a traves de los meses.

metricas_ventana as (
    select
        mes,
        categoria,
        monto,

       rank() over (
            partition by mes
            order by monto desc
        ) as ranking,

        sum (monto) over (
            partition by categoria
            order by mes
            rows between unbounded preceding
            and current row
        ) as venta_acumulada

    from ventas_mensuales
)

-- 3. CONSULTA FINAL
-- Muestra el reporte mensual por categoria.
-- AVG() OVER() calcula el promedio historico de ventas
-- de cada categoria considerando todos los meses.
-- CASE WHEN compara la venta mensual contra ese promedio
-- y devuelve las etiquetas solicitadas por la consigna.

select
    mes,
    categoria,
    monto as venta_total,
    ranking,
    venta_acumulada,

    case
        when monto >= avg(monto) over (
            partition by categoria
        )
        then 'Exitoso'
        else 'Bajo el promedio'
    end as comparativa

from metricas_ventana

order by
    mes,
    ranking;