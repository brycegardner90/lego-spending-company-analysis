-- ============================================================
-- LEGO Spending & Company Analysis
-- Bryce Gardner | github.com/brycegardner90
-- ============================================================
-- Tables:
--   my_collection   — Bryce's 30-set personal inventory
--   adult_sets      — All LEGO sets released 2018+ (Rebrickable)
--   all_sets        — Full LEGO catalog (Rebrickable)
--   themes          — Theme ID lookup
-- ============================================================


-- ============================================================
-- MY COLLECTION
-- ============================================================

-- Q1: ROI by set, ranked best to worst
-- Use: bar chart — gain/loss per set
SELECT
    set_num,
    name,
    subtheme,
    year_released,
    pieces,
    retail_price_usd,
    current_value_usd,
    gain_loss_usd,
    roi_pct,
    price_per_piece,
    is_18plus
FROM my_collection
ORDER BY roi_pct DESC;


-- Q2: ROI by subtheme
-- Use: bar chart — which category of set performs best
SELECT
    subtheme,
    COUNT(*)                                        AS set_count,
    ROUND(AVG(retail_price_usd), 2)                AS avg_retail_usd,
    ROUND(AVG(current_value_usd), 2)               AS avg_current_usd,
    ROUND(SUM(gain_loss_usd), 2)                   AS total_gain_loss_usd,
    ROUND(AVG(roi_pct), 2)                         AS avg_roi_pct,
    ROUND(AVG(price_per_piece), 4)                 AS avg_price_per_piece,
    SUM(pieces)                                     AS total_pieces
FROM my_collection
GROUP BY subtheme
ORDER BY avg_roi_pct DESC;


-- Q3: Collection summary (KPI cards)
-- Use: scorecard / summary tiles in dashboard header
SELECT
    COUNT(*)                                        AS total_sets,
    SUM(pieces)                                     AS total_pieces,
    SUM(minifigs)                                   AS total_minifigs,
    ROUND(SUM(retail_price_usd), 2)                AS total_paid_usd,
    ROUND(SUM(current_value_usd), 2)               AS total_current_value_usd,
    ROUND(SUM(gain_loss_usd), 2)                   AS total_gain_loss_usd,
    ROUND(
        (SUM(current_value_usd) - SUM(retail_price_usd))
        / SUM(retail_price_usd) * 100, 2
    )                                               AS overall_roi_pct,
    ROUND(AVG(price_per_piece), 4)                 AS avg_price_per_piece,
    COUNT(CASE WHEN is_18plus = 'Yes' THEN 1 END)  AS sets_18plus,
    COUNT(CASE WHEN gain_loss_usd > 0 THEN 1 END)  AS sets_appreciated
FROM my_collection;


-- Q4: Collection by theme
-- Use: donut chart — breakdown of investment by LEGO theme
SELECT
    theme,
    COUNT(*)                                AS set_count,
    SUM(pieces)                             AS total_pieces,
    ROUND(SUM(retail_price_usd), 2)        AS total_paid_usd,
    ROUND(SUM(current_value_usd), 2)       AS total_current_usd,
    ROUND(AVG(roi_pct), 2)                 AS avg_roi_pct,
    ROUND(AVG(price_per_piece), 4)         AS avg_price_per_piece
FROM my_collection
GROUP BY theme
ORDER BY total_paid_usd DESC;


-- Q5: Price per piece by subtheme
-- Use: bar chart — which subtheme costs most per brick
SELECT
    subtheme,
    COUNT(*)                                AS set_count,
    ROUND(AVG(price_per_piece), 4)         AS avg_ppp,
    ROUND(MIN(price_per_piece), 4)         AS min_ppp,
    ROUND(MAX(price_per_piece), 4)         AS max_ppp,
    ROUND(AVG(pieces), 0)                  AS avg_pieces
FROM my_collection
GROUP BY subtheme
ORDER BY avg_ppp DESC;


-- ============================================================
-- 18+ ERA MARKET (BROAD)
-- ============================================================

-- Q6: Adult-era set count and piece count by year
-- Use: dual-axis line chart — volume vs complexity over time
SELECT
    year,
    COUNT(*)                        AS set_count,
    ROUND(AVG(num_parts), 0)        AS avg_pieces,
    MAX(num_parts)                  AS max_pieces,
    SUM(num_parts)                  AS total_pieces
FROM adult_sets
WHERE year BETWEEN 2018 AND 2024
  AND num_parts > 0
GROUP BY year
ORDER BY year;


-- Q7: Top 20 themes by set count in adult era
-- Use: horizontal bar chart — dominant themes 2018-2024
SELECT
    theme_display                   AS theme,
    COUNT(*)                        AS set_count,
    ROUND(AVG(num_parts), 0)        AS avg_pieces,
    SUM(num_parts)                  AS total_pieces
FROM adult_sets
WHERE year BETWEEN 2018 AND 2024
  AND num_parts > 0
GROUP BY theme_display
ORDER BY set_count DESC
LIMIT 20;


-- Q8: Average pieces per set across all years 2010-2024
-- Use: line chart — long-term complexity trend
SELECT
    year,
    ROUND(AVG(num_parts), 0)        AS avg_pieces_per_set,
    COUNT(*)                        AS set_count
FROM all_sets
WHERE year BETWEEN 2010 AND 2024
  AND num_parts > 0
GROUP BY year
ORDER BY year;


-- ============================================================
-- STAR WARS LICENSING PREMIUM
-- ============================================================

-- Q9: Star Wars vs non-Star Wars in adult era
-- Use: side-by-side bar — does SW command a complexity premium?
SELECT
    CASE WHEN theme_name = 'Star Wars' THEN 'Star Wars'
         ELSE 'Non-Star Wars' END   AS category,
    COUNT(*)                        AS set_count,
    ROUND(AVG(num_parts), 0)        AS avg_pieces,
    SUM(num_parts)                  AS total_pieces
FROM adult_sets
WHERE year BETWEEN 2018 AND 2024
  AND num_parts > 0
GROUP BY category;


-- Q10: Star Wars set count and avg pieces by year
-- Use: line chart — SW output trend over adult era
SELECT
    year,
    COUNT(*)                        AS sw_set_count,
    ROUND(AVG(num_parts), 0)        AS avg_pieces
FROM adult_sets
WHERE theme_name = 'Star Wars'
  AND year BETWEEN 2018 AND 2024
  AND num_parts > 0
GROUP BY year
ORDER BY year;


-- Q11: My collection — Star Wars vs non-Star Wars
-- Use: comparison card — personal SW vs non-SW ROI and PPP
SELECT
    CASE WHEN theme = 'Star Wars' THEN 'Star Wars'
         ELSE 'Non-Star Wars' END   AS category,
    COUNT(*)                        AS set_count,
    ROUND(AVG(retail_price_usd), 2) AS avg_retail_usd,
    ROUND(AVG(price_per_piece), 4)  AS avg_ppp,
    ROUND(AVG(roi_pct), 2)          AS avg_roi_pct,
    ROUND(AVG(pieces), 0)           AS avg_pieces
FROM my_collection
GROUP BY category;


-- Q12: Total LEGO set catalog growth 2000-2024
-- Use: line chart — macro view of LEGO's output over time
--      overlay with company revenue for the business story
SELECT
    year,
    COUNT(*)                        AS total_sets,
    ROUND(AVG(num_parts), 0)        AS avg_pieces
FROM all_sets
WHERE year BETWEEN 2000 AND 2024
  AND num_parts > 0
GROUP BY year
ORDER BY year;
