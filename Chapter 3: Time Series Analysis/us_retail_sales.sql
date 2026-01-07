-- Trending the data
-- Simple trends

SELECT
  sales_month,
  sales
FROM
  retail_sales
WHERE
  kind_of_business = 'Retail and food services sales, total'
ORDER BY
  sales_month;

SELECT
  YEAR(sales_month) AS sales_year,
  SUM(sales) AS sales
FROM
  retail_sales
WHERE
  kind_of_business = 'Retail and food services sales, total'
GROUP BY
  YEAR(sales_month)
ORDER BY
  sales_year;

-- Comparing components
SELECT
  YEAR(sales_month) AS sales_year,
  kind_of_business,
  SUM(sales) AS sales
FROM
  retail_sales
WHERE
  kind_of_business IN (
    'Book stores',
    'Sporting goods stores',
    'Hobby, toy, and game stores'
  )
GROUP BY
  YEAR(sales_month),
  kind_of_business
ORDER BY
  sales_year,
  kind_of_business;

SELECT
  sales_month,
  kind_of_business,
  sales
FROM
  retail_sales
WHERE
  kind_of_business IN (
    'Men''s clothing stores',
    'Women''s clothing stores'
  )
ORDER BY
  sales_month,
  kind_of_business;

SELECT
  YEAR(sales_month) AS sales_year,
  kind_of_business,
  SUM(sales) AS sales
FROM
  retail_sales
WHERE
  kind_of_business IN (
    'Men''s clothing stores',
    'Women''s clothing stores'
  )
GROUP BY
  YEAR(sales_month),
  kind_of_business;

SELECT
  YEAR(sales_month) AS sales_year,
  SUM(
    CASE
      WHEN kind_of_business = 'Women''s clothing stores' THEN sales
      ELSE 0
    END
  ) AS womens_sales,
  SUM(
    CASE
      WHEN kind_of_business = 'Men''s clothing stores' THEN sales
      ELSE 0
    END
  ) AS mens_sales
FROM
  retail_sales
WHERE
  kind_of_business IN (
    'Men''s clothing stores',
    'Women''s clothing stores'
  )
GROUP BY
  YEAR(sales_month)
ORDER BY
  sales_year;

SELECT
  sales_year,
  womens_sales - mens_sales AS womens_minus_mens,
  mens_sales - womens_sales AS mens_minus_womens
FROM
  (
    SELECT
      YEAR(sales_month) AS sales_year,
      SUM(
        CASE
          WHEN kind_of_business = 'Women''s clothing stores' THEN sales
          ELSE 0
        END
      ) AS womens_sales,
      SUM(
        CASE
          WHEN kind_of_business = 'Men''s clothing stores' THEN sales
          ELSE 0
        END
      ) AS mens_sales
    FROM
      retail_sales
    WHERE
      kind_of_business IN (
        'Men''s clothing stores',
        'Women''s clothing stores'
      )
      AND sales_month <= '2019-12-01'
    GROUP BY
      YEAR(sales_month)
  ) a
ORDER BY
  sales_year;

SELECT
  YEAR(sales_month) AS sales_year,
  SUM(
    CASE
      WHEN kind_of_business = 'Women''s clothing stores' THEN sales
      ELSE 0
    END
  ) - SUM(
    CASE
      WHEN kind_of_business = 'Men''s clothing stores' THEN sales
      ELSE 0
    END
  ) AS womens_minus_mens
FROM
  retail_sales
WHERE
  kind_of_business IN (
    'Men''s clothing stores',
    'Women''s clothing stores'
  )
  AND sales_month <= '2019-12-01'
GROUP BY
  YEAR(sales_month)
ORDER BY
  sales_year;

SELECT
  sales_year,
  womens_sales / mens_sales AS womens_times_of_mens
FROM
  (
    SELECT
      YEAR(sales_month) AS sales_year,
      SUM(
        CASE
          WHEN kind_of_business = 'Women''s clothing stores' THEN sales
          ELSE 0
        END
      ) AS womens_sales,
      SUM(
        CASE
          WHEN kind_of_business = 'Men''s clothing stores' THEN sales
          ELSE 0
        END
      ) AS mens_sales
    FROM
      retail_sales
    WHERE
      kind_of_business IN (
        'Men''s clothing stores',
        'Women''s clothing stores'
      )
      AND sales_month <= '2019-12-01'
    GROUP BY
      YEAR(sales_month)
  ) a
ORDER BY
  sales_year;

SELECT
  sales_year,
  (womens_sales / mens_sales - 1) * 100 AS womens_pct_of_mens
FROM
  (
    SELECT
      YEAR(sales_month) AS sales_year,
      SUM(
        CASE
          WHEN kind_of_business = 'Women''s clothing stores' THEN sales
          ELSE 0
        END
      ) AS womens_sales,
      SUM(
        CASE
          WHEN kind_of_business = 'Men''s clothing stores' THEN sales
          ELSE 0
        END
      ) AS mens_sales
    FROM
      retail_sales
    WHERE
      kind_of_business IN (
        'Men''s clothing stores',
        'Women''s clothing stores'
      )
      AND sales_month <= '2019-12-01'
    GROUP BY
      YEAR(sales_month)
  ) a
ORDER BY
  sales_year;

-- Percent of total calculations

SELECT
  sales_month,
  kind_of_business,
  sales * 100 / total_sales AS pct_total_sales
FROM
  (
    SELECT
      a.sales_month,
      a.kind_of_business,
      a.sales,
      SUM(b.sales) AS total_sales
    FROM
      retail_sales a
      JOIN retail_sales b ON a.sales_month = b.sales_month
      AND b.kind_of_business IN (
        'Men''s clothing stores',
        'Women''s clothing stores'
      )
    WHERE
      a.kind_of_business IN (
        'Men''s clothing stores',
        'Women''s clothing stores'
      )
    GROUP BY
      a.sales_month,
      a.kind_of_business,
      a.sales
  ) aa
ORDER BY
  sales_month,
  kind_of_business;

SELECT
  sales_month,
  kind_of_business,
  sales,
  SUM(sales) OVER (
    PARTITION BY
      sales_month
  ) AS total_sales,
  sales * 100 / SUM(sales) OVER (
    PARTITION BY
      sales_month
  ) AS pct_total
FROM
  retail_sales
WHERE
  kind_of_business IN (
    'Men''s clothing stores',
    'Women''s clothing stores'
  )
ORDER BY
  sales_month;

SELECT
  sales_month,
  kind_of_business,
  sales * 100 / yearly_sales AS pct_yearly
FROM
  (
    SELECT
      a.sales_month,
      a.kind_of_business,
      a.sales,
      SUM(b.sales) AS yearly_sales
    FROM
      retail_sales a
      JOIN retail_sales b ON YEAR(a.sales_month) = YEAR(b.sales_month)
      AND a.kind_of_business = b.kind_of_business
      AND b.kind_of_business IN (
        'Men''s clothing stores',
        'Women''s clothing stores'
      )
    WHERE
      a.kind_of_business IN (
        'Men''s clothing stores',
        'Women''s clothing stores'
      )
    GROUP BY
      a.sales_month,
      a.kind_of_business,
      a.sales
  ) aa
ORDER BY
  sales_month,
  kind_of_business;

SELECT
  sales_month,
  kind_of_business,
  sales,
  SUM(sales) OVER (
    PARTITION BY
      YEAR(sales_month),
      kind_of_business
  ) AS yearly_sales,
  sales * 100 / SUM(sales) OVER (
    PARTITION BY
      YEAR(sales_month),
      kind_of_business
  ) AS pct_yearly
FROM
  retail_sales
WHERE
  kind_of_business IN (
    'Men''s clothing stores',
    'Women''s clothing stores'
  )
ORDER BY
  sales_month,
  kind_of_business;

SELECT
  sales_year,
  sales,
  FIRST_VALUE(sales) OVER (
    ORDER BY
      sales_year
  ) AS index_sales
FROM
  (
    SELECT
      YEAR(sales_month) AS sales_year,
      SUM(sales) AS sales
    FROM
      retail_sales
    WHERE
      kind_of_business = 'Women''s clothing stores'
    GROUP BY
      YEAR(sales_month)
  ) a;

SELECT
  sales_year,
  sales,
  (sales / index_sales - 1) * 100 AS pct_from_index
FROM
  (
    SELECT
      YEAR(aa.sales_month) AS sales_year,
      bb.index_sales,
      SUM(aa.sales) AS sales
    FROM
      retail_sales aa
      JOIN (
        SELECT
          first_year,
          SUM(a.sales) AS index_sales
        FROM
          retail_sales a
          JOIN (
            SELECT
              MIN(YEAR(sales_month)) AS first_year
            FROM
              retail_sales
            WHERE
              kind_of_business = 'Women''s clothing stores'
          ) b ON YEAR(a.sales_month) = b.first_year
        WHERE
          a.kind_of_business = 'Women''s clothing stores'
        GROUP BY
          first_year
      ) bb ON 1 = 1
    WHERE
      aa.kind_of_business = 'Women''s clothing stores'
    GROUP BY
      YEAR(aa.sales_month),
      bb.index_sales
  ) aaa
ORDER BY
  sales_year;

SELECT
  sales_year,
  kind_of_business,
  sales,
  (
    sales / FIRST_VALUE(sales) OVER (
      PARTITION BY
        kind_of_business
      ORDER BY
        sales_year
    ) - 1
  ) * 100 AS pct_from_index
FROM
  (
    SELECT
      YEAR(sales_month) AS sales_year,
      kind_of_business,
      SUM(sales) AS sales
    FROM
      retail_sales
    WHERE
      kind_of_business IN (
        'Men''s clothing stores',
        'Women''s clothing stores'
      )
      AND sales_month <= '2019-12-31'
    GROUP BY
      YEAR(sales_month),
      kind_of_business
  ) a
ORDER BY
  sales_year,
  kind_of_business;

-- Rolling time windows
-- Calculating rolling time windows

SELECT
  a.sales_month,
  a.sales,
  b.sales_month AS rolling_sales_month,
  b.sales AS rolling_sales
FROM
  retail_sales a
  JOIN retail_sales b ON a.kind_of_business = b.kind_of_business
  AND b.sales_month BETWEEN DATE_SUB(a.sales_month, INTERVAL 11 MONTH) AND a.sales_month
  AND b.kind_of_business = 'Women''s clothing stores'
WHERE
  a.kind_of_business = 'Women''s clothing stores'
  AND a.sales_month = '2019-12-01';

SELECT
  a.sales_month,
  a.sales,
  AVG(b.sales) AS moving_avg,
  COUNT(b.sales) AS records_count
FROM
  retail_sales a
  JOIN retail_sales b ON a.kind_of_business = b.kind_of_business
  AND b.sales_month BETWEEN DATE_SUB(a.sales_month, INTERVAL 11 MONTH) AND a.sales_month
  AND b.kind_of_business = 'Women''s clothing stores'
WHERE
  a.kind_of_business = 'Women''s clothing stores'
  AND a.sales_month >= '1993-01-01'
GROUP BY
  a.sales_month,
  a.sales
ORDER BY
  a.sales_month;

SELECT
  sales_month,
  AVG(sales) OVER (
    ORDER BY
      sales_month ROWS BETWEEN 11 PRECEDING
      AND CURRENT ROW
  ) AS moving_avg,
  COUNT(sales) OVER (
    ORDER BY
      sales_month ROWS BETWEEN 11 PRECEDING
      AND CURRENT ROW
  ) AS records_count
FROM
  retail_sales
WHERE
  kind_of_business = 'Women''s clothing stores'
ORDER BY
  sales_month;

-- Rolling time windows with sparse data

SELECT
  a.date,
  b.sales_month,
  b.sales
FROM
  date_dim a
  JOIN (
    SELECT
      sales_month,
      sales
    FROM
      retail_sales
    WHERE
      kind_of_business = 'Women''s clothing stores'
      AND MONTH(sales_month) IN (1, 7)
  ) b ON b.sales_month BETWEEN DATE_SUB(a.date, INTERVAL 11 MONTH) AND a.date
WHERE
  a.date = a.first_day_of_month
  AND a.date BETWEEN '1993-01-01' AND '2020-12-01'
ORDER BY
  a.date,
  b.sales_month;

SELECT
  a.date,
  AVG(b.sales) AS moving_avg,
  COUNT(b.sales) AS records
FROM
  date_dim a
  JOIN (
    SELECT
      sales_month,
      sales
    FROM
      retail_sales
    WHERE
      kind_of_business = 'Women''s clothing stores'
      AND MONTH(sales_month) IN (1, 7)
  ) b ON b.sales_month BETWEEN DATE_SUB(a.date, INTERVAL 11 MONTH) AND a.date
WHERE
  a.date = a.first_day_of_month
  AND a.date BETWEEN '1993-01-01' AND '2020-12-01'
GROUP BY
  a.date
ORDER BY
  a.date;

SELECT
  a.sales_month,
  AVG(b.sales) AS moving_avg
FROM
  (
    SELECT DISTINCT
      sales_month
    FROM
      retail_sales
    WHERE
      sales_month BETWEEN '1993-01-01' AND '2020-12-01'
  ) a
  JOIN retail_sales b ON b.sales_month BETWEEN DATE_SUB(a.sales_month, INTERVAL 11 MONTH) AND a.sales_month
  AND b.kind_of_business = 'Women''s clothing stores'
GROUP BY
  a.sales_month
ORDER BY
  a.sales_month;

-- Calculating cumulative values

SELECT
  sales_month,
  sales,
  SUM(sales) OVER (
    PARTITION BY
      YEAR(sales_month)
    ORDER BY
      sales_month
  ) AS sales_ytd
FROM
  retail_sales
WHERE
  kind_of_business = 'Women''s clothing stores'
ORDER BY
  sales_month;

SELECT
  a.sales_month,
  a.sales,
  SUM(b.sales) AS sales_ytd
FROM
  retail_sales a
  JOIN retail_sales b ON YEAR(a.sales_month) = YEAR(b.sales_month)
  AND b.sales_month <= a.sales_month
  AND b.kind_of_business = 'Women''s clothing stores'
WHERE
  a.kind_of_business = 'Women''s clothing stores'
GROUP BY
  a.sales_month,
  a.sales
ORDER BY
  a.sales_month;

-- Analyzing with seasonality
-- Period over period comparisons

SELECT
  kind_of_business,
  sales_month,
  sales,
  LAG(sales_month) OVER (
    PARTITION BY
      kind_of_business
    ORDER BY
      sales_month
  ) AS prev_month,
  LAG(sales) OVER (
    PARTITION BY
      kind_of_business
    ORDER BY
      sales_month
  ) AS prev_month_sales
FROM
  retail_sales
WHERE
  kind_of_business = 'Book stores'
ORDER BY
  sales_month;

SELECT
  kind_of_business,
  sales_month,
  sales,
  (
    sales / LAG(sales) OVER (
      PARTITION BY
        kind_of_business
      ORDER BY
        sales_month
    ) - 1
  ) * 100 AS pct_growth_from_previous
FROM
  retail_sales
WHERE
  kind_of_business = 'Book stores'
ORDER BY
  sales_month;

SELECT
  sales_year,
  yearly_sales,
  LAG(yearly_sales) OVER (
    ORDER BY
      sales_year
  ) AS prev_year_sales,
  (
    yearly_sales / LAG(yearly_sales) OVER (
      ORDER BY
        sales_year
    ) - 1
  ) * 100 AS pct_growth_from_previous
FROM
  (
    SELECT
      YEAR(sales_month) AS sales_year,
      SUM(sales) AS yearly_sales
    FROM
      retail_sales
    WHERE
      kind_of_business = 'Book stores'
    GROUP BY
      YEAR(sales_month)
  ) a
ORDER BY
  sales_year;

-- Period over period comparisons - Same month vs. last year

SELECT
  sales_month,
  MONTH(sales_month) AS month_number
FROM
  retail_sales
WHERE
  kind_of_business = 'Book stores'
ORDER BY
  sales_month;

SELECT
  sales_month,
  sales,
  LAG(sales_month) OVER (
    PARTITION BY
      MONTH(sales_month)
    ORDER BY
      sales_month
  ) AS prev_year_month,
  LAG(sales) OVER (
    PARTITION BY
      MONTH(sales_month)
    ORDER BY
      sales_month
  ) AS prev_year_sales
FROM
  retail_sales
WHERE
  kind_of_business = 'Book stores'
ORDER BY
  sales_month;

SELECT
  sales_month,
  sales,
  sales - LAG(sales) OVER (
    PARTITION BY
      MONTH(sales_month)
    ORDER BY
      sales_month
  ) AS absolute_diff,
  (
    sales / LAG(sales) OVER (
      PARTITION BY
        MONTH(sales_month)
      ORDER BY
        sales_month
    ) - 1
  ) * 100 AS pct_diff
FROM
  retail_sales
WHERE
  kind_of_business = 'Book stores'
ORDER BY
  sales_month;

SELECT
  MONTH(sales_month) AS month_number,
  DATE_FORMAT(sales_month, '%M') AS month_name,
  MAX(
    CASE
      WHEN YEAR(sales_month) = 1992 THEN sales
    END
  ) AS sales_1992,
  MAX(
    CASE
      WHEN YEAR(sales_month) = 1993 THEN sales
    END
  ) AS sales_1993,
  MAX(
    CASE
      WHEN YEAR(sales_month) = 1994 THEN sales
    END
  ) AS sales_1994
FROM
  retail_sales
WHERE
  kind_of_business = 'Book stores'
  AND sales_month BETWEEN '1992-01-01' AND '1994-12-01'
GROUP BY
  MONTH(sales_month),
  DATE_FORMAT(sales_month, '%M')
ORDER BY
  month_number;

-- Comparing to multiple prior periods

SELECT
  sales_month,
  sales,
  LAG(sales, 1) OVER (
    PARTITION BY
      MONTH(sales_month)
    ORDER BY
      sales_month
  ) AS prev_sales_1,
  LAG(sales, 2) OVER (
    PARTITION BY
      MONTH(sales_month)
    ORDER BY
      sales_month
  ) AS prev_sales_2,
  LAG(sales, 3) OVER (
    PARTITION BY
      MONTH(sales_month)
    ORDER BY
      sales_month
  ) AS prev_sales_3
FROM
  retail_sales
WHERE
  kind_of_business = 'Book stores'
ORDER BY
  sales_month;

SELECT
  sales_month,
  sales,
  sales / AVG(sales) OVER (
    PARTITION BY
      MONTH(sales_month)
    ORDER BY
      sales_month ROWS BETWEEN 3 PRECEDING
      AND 1 PRECEDING
  ) AS pct_of_prev_3
FROM
  retail_sales
WHERE
  kind_of_business = 'Book stores'
ORDER BY
  sales_month;
