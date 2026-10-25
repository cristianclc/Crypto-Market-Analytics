-- fct_market_daily.sql

with int_daily_coin_return as (
    SELECT *,
    from {{ref('int_daily_coin_return')}}
),

vol_cap_total as (
    SELECT
    snapshot_date,
    COUNT(DISTINCT(coin_id)) as coins_day, --numero de monedas distintas en el snapshot del día
    SUM(coin_total_volume) as total_volume, --valor total de todas las compras (en un dia)
    SUM(coin_market_cap) as total_market_cap, --valor total de todas las monedas (en un dia)
    SUM(CASE WHEN coin_id = "bitcoin" THEN coin_market_cap ELSE 0 END) as bitcoin_total_market_cap --valor total SOLO de bitcoin
    FROM int_daily_coin_return
    GROUP BY snapshot_date
),

prev_volume_cap as (
    SELECT *, 
    LAG(total_volume) OVER(ORDER BY snapshot_date) as previous_total_volume, --anterior volumen diario
    LAG(total_market_cap) OVER(ORDER BY snapshot_date) as previous_total_market_cap, --anterior market cap diario 
    LAG(bitcoin_total_market_cap) OVER(ORDER BY snapshot_date) as btc_previous_total_market_cap --anterior market cap de bitcoin
    FROM vol_cap_total
),

bitcoin_cap_vol_change as (
    SELECT *, 
    (total_volume - previous_total_volume) as daily_total_volume_change, --cambio en volumen diario
    (total_market_cap - previous_total_market_cap) as daily_total_market_cap_change, --cambio en market cap diario 
    SAFE_DIVIDE(bitcoin_total_market_cap, total_market_cap) as bitcoin_cap_participation_pct, --participacion de bitcoin en market cap total
    snapshot_date = MAX(snapshot_date) OVER() as is_latest_day --comparación de si la fecha actual es igual a la maxima (como es tabla, se reecriben todas las filas)
    FROM prev_volume_cap
),

bitcoin_cap_vol_change_pct as (
    SELECT *,
    LAG(bitcoin_cap_participation_pct) OVER(ORDER BY snapshot_date) as previous_bitcoin_cap_participation_pct, -- % participacion de bitcoin anterior
    SAFE_DIVIDE(daily_total_volume_change, previous_total_volume) as daily_total_volume_change_pct, --cambio en volumen diario en pct
    SAFE_DIVIDE(daily_total_market_cap_change, previous_total_market_cap) as daily_total_market_cap_change_pct --cambio en market cap diario en pct
    FROM bitcoin_cap_vol_change
)

SELECT * from bitcoin_cap_vol_change_pct