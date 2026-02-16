/* АНАЛИЗ ДАННЫХ МАРКЕТПЛЕЙСА OLIST 
Этот скрипт содержит ключевые запросы для анализа продаж, 
логистики и поведения клиентов.
*/

-- 1. Расчет выручки по категориям (ТОП-10 на английском)
-- Показывает самые прибыльные ниши
SELECT 
    t.product_category_name_english AS category, 
    ROUND(SUM(i.price), 2) AS total_revenue
FROM olist_order_items i
JOIN olist_products p ON i.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- 2. Динамика продаж по месяцам
-- Позволяет увидеть сезонность и пики продаж (например, Black Friday)
SELECT 
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS monthly_revenue
FROM olist_orders o
JOIN olist_order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- 3. Анализ среднего времени доставки по штатам (в днях)
-- Оценка эффективности логистики в разных регионах
SELECT 
    c.customer_state,
    ROUND(AVG(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp)), 2) AS avg_delivery_days
FROM olist_orders o
JOIN olist_customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days ASC;

-- 4. Влияние своевременной доставки на удовлетворенность клиентов
-- Анализ корреляции между скоростью доставки и средней оценкой (review_score)
SELECT 
    CASE 
        WHEN julianday(o.order_delivered_customer_date) <= julianday(o.order_estimated_delivery_date) THEN 'Вовремя или раньше'
        ELSE 'Опоздание'
    END AS delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_rating,
    COUNT(*) AS total_orders
FROM olist_orders o
JOIN olist_order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;
