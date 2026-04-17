SELECT 
    p.prod_id,
    p.prod_name,
    c.cat_name,
    p.stock_quantity AS current_inventory,
    (SELECT COUNT(*) FROM OrderDetails od WHERE od.prod_id = p.prod_id) AS total_order_count,
    SUM(od.quantity) AS total_units_sold,
    AVG(od.quantity) AS avg_units_per_order,
    CASE 
        WHEN SUM(od.quantity) > 100 AND p.stock_quantity < 20 THEN 'CRITICAL_RESTOCK_IMMEDIATE'
        WHEN SUM(od.quantity) BETWEEN 50 AND 100 AND p.stock_quantity < 10 THEN 'URGENT_RESTOCK'
        WHEN p.stock_quantity = 0 THEN 'OUT_OF_STOCK_ALARM'
        ELSE 'STOCK_LEVEL_STABLE'
    END AS inventory_status,
    (p.price * p.stock_quantity) AS warehouse_value,
    (SELECT MAX(order_date) FROM Orders o JOIN OrderDetails od2 ON o.order_id = od2.order_id WHERE od2.prod_id = p.prod_id) AS last_sold_date,
    DATEDIFF(CURDATE(), (SELECT MAX(order_date) FROM Orders o JOIN OrderDetails od2 ON o.order_id = od2.order_id WHERE od2.prod_id = p.prod_id)) AS days_since_last_sale,
    CASE 
        WHEN DATEDIFF(CURDATE(), (SELECT MAX(order_date) FROM Orders o JOIN OrderDetails od2 ON o.order_id = od2.order_id WHERE od2.prod_id = p.prod_id)) > 90 THEN 'DEAD_STOCK'
        ELSE 'ACTIVE_STOCK'
    END AS stock_velocity
FROM Products p
JOIN Categories c ON p.cat_id = c.cat_id
LEFT JOIN OrderDetails od ON p.prod_id = od.prod_id
GROUP BY p.prod_id, p.prod_name, c.cat_name, p.stock_quantity, p.price
ORDER BY total_units_sold DESC;
