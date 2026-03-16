DROP DATABASE IF EXISTS pjupiter;
CREATE DATABASE pjupiter;
USE pjupiter;

CREATE TABLE proveedores (
id_proveedor INT PRIMARY KEY,
proveedor VARCHAR(36)
);

CREATE TABLE clientes (
id_cliente INT PRIMARY KEY,
cliente VARCHAR(26)
);

CREATE TABLE marcas (
id_marca INT PRIMARY KEY,
marca VARCHAR(19)
);

CREATE TABLE productos (
lote VARCHAR(47),
id_marca INT,
tipo VARCHAR(11),
t_id VARCHAR(60) PRIMARY KEY,
peso FLOAT,
id_proveedor INT,
FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor),
FOREIGN KEY (id_marca) REFERENCES marcas (id_marca)
);

CREATE TABLE ventas (
t_id VARCHAR(60),
lote VARCHAR(47),
fecha_hora_recogida DATETIME,
fecha_hora_venta DATETIME,
coste_inicial FLOAT NULL,
precio_venta FLOAT,
id_cliente INT,
FOREIGN KEY (t_id) REFERENCES productos(t_id),
FOREIGN KEY (id_cliente) REFERENCES clientes (id_cliente)
);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/proveedores.csv'
INTO TABLE proveedores
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(proveedor, id_proveedor);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/clientes.csv'
INTO TABLE clientes
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(cliente, id_cliente);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/marcas.csv'
INTO TABLE marcas
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(marca, id_marca);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/productos.csv'
INTO TABLE productos
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(lote, id_marca, tipo, t_id, peso, id_proveedor);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ventas.csv'
INTO TABLE ventas
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(t_id, lote, fecha_hora_recogida, fecha_hora_venta, coste_inicial, precio_venta, id_cliente);

-- ANÁLISIS INICIAL DE KPIS

-- Media diaria de la cuantía de las distribuciones

SELECT ROUND(AVG(total_dia), 2) AS total_venta_media_diaria
FROM (
  SELECT fecha_hora_venta AS DATE,
         SUM(precio_venta) AS total_dia
  FROM ventas
  WHERE precio_venta IS NOT NULL
    AND fecha_hora_venta  IS NOT NULL
  GROUP BY fecha_hora_venta
) AS venta_por_dia;

-- Cuantía total de las distribuciones

SELECT ROUND(SUM(precio_venta),2) AS cuantia_total_distribuciones
FROM VENTAS
WHERE precio_venta IS NOT NULL;


-- ¿A qué horas del día se producen más recogidas de alimentos y cuántas? 

SELECT 
  HOUR(fecha_hora_recogida) AS hora, 
  COUNT(*) AS total_recogidas
FROM ventas
WHERE fecha_hora_recogida IS NOT NULL
  AND fecha_hora_recogida >= '2022-09-01'
GROUP BY HOUR(fecha_hora_recogida)
HAVING COUNT(*) = (
  SELECT MAX(recogidas_por_hora)
  FROM (
    SELECT COUNT(*) AS recogidas_por_hora
    FROM ventas
    WHERE fecha_hora_recogida IS NOT NULL
      AND fecha_hora_recogida >= '2022-09-01'
    GROUP BY HOUR(fecha_hora_recogida)
  ) AS cantidad_maxima_recogida
) 
ORDER BY hora;

-- ¿Cuáles son los 5 clientes que más dinero han gastado comprando la fruta y cuánto?

SELECT c.cliente AS nombre_cliente,
       ROUND(SUM(v.precio_venta), 2) AS total_gastado
FROM ventas v
INNER JOIN clientes c ON v.id_cliente = c.id_cliente
WHERE v.precio_venta IS NOT NULL
  AND v.precio_venta > 0
GROUP BY c.cliente
ORDER BY total_gastado DESC
LIMIT 5;

-- ¿Cuáles son los 5 clientes que menos dinero han gastado comprando la fruta y cuánto?

SELECT c.cliente AS nombre_cliente,
       ROUND(SUM(v.precio_venta), 2) AS total_gastado
FROM ventas v
JOIN clientes c ON v.id_cliente = c.id_cliente
WHERE v.precio_venta IS NOT NULL
  AND v.precio_venta > 0
GROUP BY c.cliente
ORDER BY total_gastado ASC
LIMIT 5;

-- ¿Cuáles son los 10 proveedores que han recibido más dinero y cuánto?

SELECT pr.proveedor AS nombre_proveedor,
       ROUND(SUM(v.coste_inicial), 2) AS total_proveedor
FROM ventas v
JOIN productos p   ON v.lote = p.lote
JOIN proveedores pr ON p.id_proveedor = pr.id_proveedor
WHERE v.coste_inicial IS NOT NULL
  AND v.coste_inicial > 0
GROUP BY pr.proveedor
ORDER BY total_proveedor DESC
LIMIT 10;

-- ¿Cuáles son los 3 productos con mayor beneficio a lo largo del mes de septiembre y cuál ha sido su balance?

SELECT p.tipo AS tipo_producto,
       ROUND(SUM(v.precio_venta - v.coste_inicial), 2) AS balance_total
FROM productos p
JOIN ventas v ON p.lote = v.lote
WHERE v.precio_venta IS NOT NULL
  AND v.precio_venta > 0
  AND v.coste_inicial IS NOT NULL
  AND v.coste_inicial > 0
  AND MONTH(v.fecha_hora_venta) = 9
  AND MONTH(v.fecha_hora_recogida) = 9
GROUP BY p.tipo
ORDER BY balance_total DESC
LIMIT 3;

-- ¿Cuáles son los 3 productos con peor beneficio a lo largo del mes y cuál ha sido?

SELECT p.tipo AS tipo_producto,
       ROUND(SUM(v.precio_venta - v.coste_inicial), 2) AS balance_total
FROM productos p
JOIN ventas v ON p.lote = v.lote
WHERE v.precio_venta IS NOT NULL
  AND v.precio_venta > 0
  AND v.coste_inicial IS NOT NULL
  AND v.coste_inicial > 0
  AND MONTH(v.fecha_hora_venta) = 9
  AND MONTH(v.fecha_hora_recogida) = 9
GROUP BY p.tipo
ORDER BY balance_total ASC
LIMIT 3;

-- ¿Cuál es el precio de venta medio de cada fruta?

SELECT p.tipo AS tipo_producto,
       ROUND(AVG(v.precio_venta), 2) AS precio_medio_venta
FROM productos p
JOIN ventas v ON p.lote = v.lote
WHERE v.precio_venta IS NOT NULL
  AND v.precio_venta > 0
  AND MONTH(v.fecha_hora_venta) = 9
GROUP BY p.tipo
ORDER BY precio_medio_venta ASC;

-- Suponiendo que si no se dispone de información de venta se trata de una fruta que no 
-- ha podido venderse por haber sido dañada durante la distribución, ¿cuánta fruta de cada tipo ha sido dañada?

SELECT 
    p.tipo AS tipo_producto,
    ROUND(SUM(p.peso), 2) AS cantidad_danyada_gr,
    COUNT(p.t_id) AS productos_danyados
FROM 
    productos p
LEFT JOIN 
    ventas v ON p.t_id = v.t_id
WHERE 
    v.fecha_hora_venta IS NULL
GROUP BY 
    p.tipo
ORDER BY 
    cantidad_danyada_gr DESC;
    
  -- ¿Cuál ha sido la pérdida total de la fruta dañada?
  
    SELECT 
    ROUND(SUM(p.peso), 2) AS cantidad_danyada_gr,
    COUNT(p.t_id) AS productos_danyados,
    ROUND(SUM(p.peso * IFNULL(v.coste_inicial, 2)), 2) AS perdida_total
FROM 
    productos p
LEFT JOIN 
    ventas v ON p.t_id = v.t_id
WHERE 
    v.fecha_hora_venta IS NULL;
    
    -- ¿Cuál es la cuantía total de cada tipo de fruta que han comprado
-- los 5 clientes que más dinero han gastado?

WITH top5_clientes AS (
  SELECT id_cliente
  FROM ventas
  WHERE precio_venta IS NOT NULL AND precio_venta > 0
  GROUP BY id_cliente
  ORDER BY SUM(precio_venta) DESC
  LIMIT 5
)
SELECT p.tipo AS tipo_fruta,
       ROUND(SUM(p.peso), 2) AS cantidad_gr
FROM productos p
JOIN ventas v         ON p.lote = v.lote
JOIN top5_clientes t5 ON v.id_cliente = t5.id_cliente
WHERE p.peso IS NOT NULL AND p.peso > 0
  AND v.precio_venta IS NOT NULL AND v.precio_venta > 0
GROUP BY p.tipo
ORDER BY cantidad_gr DESC;

-- Para cada producto, calcular el porcentaje medio de beneficio.

SELECT 
    p.tipo AS tipo_fruta,
    ROUND(AVG((v.precio_venta - v.coste_inicial) / v.coste_inicial) * 100, 2) AS porcentaje_beneficio_medio
FROM 
    productos p
INNER JOIN 
    ventas v ON p.lote = v.lote
WHERE 
    v.coste_inicial IS NOT NULL AND v.coste_inicial > 0
    AND v.precio_venta IS NOT NULL AND v.precio_venta > 0
GROUP BY 
    p.tipo
ORDER BY 
    porcentaje_beneficio_medio DESC
LIMIT 1000;

-- Media diaria de ventas.

SELECT 
    DATE(fecha_hora_venta) AS fecha,
    ROUND(AVG(precio_venta), 2) AS media_diaria_ventas
FROM 
    ventas
WHERE 
    precio_venta IS NOT NULL
    AND fecha_hora_venta IS NOT NULL
GROUP BY 
    DATE(fecha_hora_venta)
ORDER BY 
    fecha;
    
    