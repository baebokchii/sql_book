-- Active: 1767840625700@@127.0.0.1@3306@sql_for_data_analysis
-- Basic retention
SELECT id_bioguide, MIN(term_start) AS first_term
FROM legislators_terms
GROUP BY
    1;

SELECT TIMESTAMPDIFF(
        YEAR, a.first_term, b.term_start
    ) AS periods, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) AS a
    JOIN legislators_terms AS b ON a.id_bioguide = b.id_bioguide
GROUP BY
    1
ORDER BY periods;

SELECT
    period,
    FIRST_VALUE(cohort_retained) OVER (
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
        ORDER BY period
    ) AS pct_retained
FROM (
        SELECT TIMESTAMPDIFF(
                YEAR, a.first_term, b.term_start
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY
                    id_bioguide
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
        GROUP BY
            TIMESTAMPDIFF(
                YEAR, a.first_term, b.term_start
            )
    ) aa
ORDER BY period

SELECT
    cohort_size,
    MAX(
        CASE
            WHEN period = 0 THEN pct_retained
        END
    ) AS yr0,
    MAX(
        CASE
            WHEN period = 1 THEN pct_retained
        END
    ) AS yr1,
    MAX(
        CASE
            WHEN period = 2 THEN pct_retained
        END
    ) AS yr2,
    MAX(
        CASE
            WHEN period = 3 THEN pct_retained
        END
    ) AS yr3,
    MAX(
        CASE
            WHEN period = 4 THEN pct_retained
        END
    ) AS yr4
FROM (
        SELECT
            period, FIRST_VALUE(cohort_retained) OVER (
                ORDER BY period
            ) AS cohort_size, cohort_retained, cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
                ORDER BY period
            ) AS pct_retained
        FROM (
                SELECT TIMESTAMPDIFF(
                        YEAR, a.first_term, b.term_start
                    ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
                FROM (
                        SELECT id_bioguide, MIN(term_start) AS first_term
                        FROM legislators_terms
                        GROUP BY
                            id_bioguide
                    ) a
                    JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
                GROUP BY
                    TIMESTAMPDIFF(
                        YEAR, a.first_term, b.term_start
                    )
            ) aa
    ) aaa
GROUP BY
    cohort_size;

-- Time adjustments
SELECT a.id_bioguide, a.first_term, b.term_start, b.term_end, c.date, TIMESTAMPDIFF(YEAR, a.first_term, c.date) AS period
FROM (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) a
    JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
    LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
    AND c.month_name = 'December'
    AND c.day_of_month = 31;

SELECT COALESCE(
        TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
    ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) a
    JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
    LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
    AND c.month_name = 'December'
    AND c.day_of_month = 31
GROUP BY
    COALESCE(
        TIMESTAMPDIFF(YEAR, a.first_term, c.date),
        0
    );

SELECT
    period,
    FIRST_VALUE(cohort_retained) OVER (
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
        ORDER BY period
    ) AS pct_retained
FROM (
        SELECT COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY
                    id_bioguide
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
            LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
            AND c.month_name = 'December'
            AND c.day_of_month = 31
        GROUP BY
            COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            )
    ) aa
ORDER BY period;

SELECT
    a.id_bioguide,
    a.first_term,
    b.term_start,
    CASE
        WHEN b.term_type = 'rep' THEN DATE_ADD(b.term_start, INTERVAL 2 YEAR)
        WHEN b.term_type = 'sen' THEN DATE_ADD(b.term_start, INTERVAL 6 YEAR)
        ELSE NULL
    END AS term_end
FROM (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) a
    JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide;

SELECT a.id_bioguide, a.first_term, b.term_start, DATE_SUB(
        LEAD(b.term_start) OVER (
            PARTITION BY
                a.id_bioguide
            ORDER BY b.term_start
        ), INTERVAL 1 DAY
    ) AS term_end
FROM (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) a
    JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
ORDER BY a.id_bioguide, b.term_start;

-- Time-based cohorts derived from the time-series

SELECT
    YEAR(a.first_term) AS first_year,
    COALESCE(
        TIMESTAMPDIFF(YEAR, a.first_term, c.date),
        0
    ) AS period,
    COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) a
    JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
    LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
    AND c.month_name = 'December'
    AND c.day_of_month = 31
GROUP BY
    YEAR(a.first_term),
    COALESCE(
        TIMESTAMPDIFF(YEAR, a.first_term, c.date),
        0
    )
ORDER BY first_year, period;

SELECT
    first_year,
    period,
    FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            first_year
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    ROUND(
        cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
            PARTITION BY
                first_year
            ORDER BY period
        ),
        2
    ) AS pct_retained
FROM (
        SELECT
            YEAR(a.first_term) AS first_year, TIMESTAMPDIFF(
                YEAR, a.first_term, b.term_start
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY
                    id_bioguide
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
        GROUP BY
            YEAR(a.first_term), TIMESTAMPDIFF(
                YEAR, a.first_term, b.term_start
            )
    ) aa
ORDER BY first_year, period;

SELECT
    first_century,
    period,
    FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            first_century
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            first_century
        ORDER BY period
    ) AS pct_retained
FROM (
        SELECT
            FLOOR(
                (YEAR(a.first_term) - 1) / 100
            ) + 1 AS first_century, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY
                    id_bioguide
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
            LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
            AND c.month_name = 'December'
            AND c.day_of_month = 31
        GROUP BY
            FLOOR(
                (YEAR(a.first_term) - 1) / 100
            ) + 1, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            )
    ) aa
ORDER BY first_century, period;

SELECT DISTINCT
    id_bioguide,
    MIN(term_start) OVER (
        PARTITION BY
            id_bioguide
    ) AS first_term,
    FIRST_VALUE(state) OVER (
        PARTITION BY
            id_bioguide
        ORDER BY term_start
    ) AS first_state
FROM legislators_terms;

SELECT
    first_state,
    period,
    FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            first_state
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            first_state
        ORDER BY period
    ) AS pct_retained
FROM (
        SELECT a.first_state, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT DISTINCT
                    id_bioguide, MIN(term_start) OVER (
                        PARTITION BY
                            id_bioguide
                    ) AS first_term, FIRST_VALUE(state) OVER (
                        PARTITION BY
                            id_bioguide
                        ORDER BY term_start
                    ) AS first_state
                FROM legislators_terms
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
            LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
            AND c.month_name = 'December'
            AND c.day_of_month = 31
        GROUP BY
            a.first_state, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            )
    ) aa
ORDER BY first_state, period;

-- Defining the cohort from a separate table
SELECT d.gender, COALESCE(
        TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
    ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) a
    JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
    LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
    AND c.month_name = 'December'
    AND c.day_of_month = 31
    JOIN legislators d ON a.id_bioguide = d.id_bioguide
GROUP BY
    d.gender,
    COALESCE(
        TIMESTAMPDIFF(YEAR, a.first_term, c.date),
        0
    )
ORDER BY period, d.gender;

SELECT
    gender,
    period,
    FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            gender
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            gender
        ORDER BY period
    ) AS pct_retained
FROM (
        SELECT
            d.gender AS gender, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY
                    id_bioguide
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
            LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
            AND c.month_name = 'December'
            AND c.day_of_month = 31
            JOIN legislators d ON a.id_bioguide = d.id_bioguide
        GROUP BY
            d.gender, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            )
    ) aa
ORDER BY period, gender;

SELECT
    gender,
    period,
    FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            gender
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            gender
        ORDER BY period
    ) AS pct_retained
FROM (
        SELECT
            d.gender AS gender, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY
                    id_bioguide
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
            LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
            AND c.month_name = 'December'
            AND c.day_of_month = 31
            JOIN legislators d ON a.id_bioguide = d.id_bioguide
        WHERE
            a.first_term between '1917-01-01' and '1999-12-31'
        GROUP BY
            d.gender, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            )
    ) aa
ORDER BY period, gender;

----------- Dealing with sparse cohorts
SELECT
    first_state,
    gender,
    period,
    FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            first_state,
            gender
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            first_state,
            gender
        ORDER BY period
    ) AS pct_retained
FROM (
        SELECT a.first_state, d.gender, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT DISTINCT
                    id_bioguide, MIN(term_start) OVER (
                        PARTITION BY
                            id_bioguide
                    ) AS first_term, FIRST_VALUE(state) OVER (
                        PARTITION BY
                            id_bioguide
                        ORDER BY term_start
                    ) AS first_state
                FROM legislators_terms
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
            LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
            AND c.month_name = 'December'
            AND c.day_of_month = 31
            JOIN legislators d ON a.id_bioguide = d.id_bioguide
        WHERE
            a.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY
            a.first_state, d.gender, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            )
    ) aa;

WITH RECURSIVE
    cc AS (
        SELECT 0 AS period
        UNION ALL
        SELECT period + 1
        FROM cc
        WHERE
            period < 20
    ),
    aa AS (
        SELECT b.gender, a.first_state, COUNT(DISTINCT a.id_bioguide) AS cohort_size
        FROM (
                SELECT DISTINCT
                    id_bioguide, MIN(term_start) OVER (
                        PARTITION BY
                            id_bioguide
                    ) AS first_term, FIRST_VALUE(state) OVER (
                        PARTITION BY
                            id_bioguide
                        ORDER BY term_start
                    ) AS first_state
                FROM legislators_terms
            ) a
            JOIN legislators b ON a.id_bioguide = b.id_bioguide
        WHERE
            a.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY
            b.gender,
            a.first_state
    )
SELECT aa.gender, aa.first_state, cc.period, aa.cohort_size
FROM aa
    JOIN cc ON 1 = 1
ORDER BY aa.gender, aa.first_state, cc.period;

WITH RECURSIVE
    periods AS (
        SELECT 0 AS period
        UNION ALL
        SELECT period + 1
        FROM periods
        WHERE
            period < 20
    ),
    base_people AS (
        SELECT DISTINCT
            id_bioguide,
            MIN(term_start) OVER (
                PARTITION BY
                    id_bioguide
            ) AS first_term,
            FIRST_VALUE(state) OVER (
                PARTITION BY
                    id_bioguide
                ORDER BY term_start
            ) AS first_state
        FROM legislators_terms
    ),
    cohort_sizes AS (
        SELECT l.gender, p.first_state, COUNT(DISTINCT p.id_bioguide) AS cohort_size
        FROM base_people p
            JOIN legislators l ON p.id_bioguide = l.id_bioguide
        WHERE
            p.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY
            l.gender,
            p.first_state
    ),
    grid AS (
        SELECT cs.gender, cs.first_state, pr.period, cs.cohort_size
        FROM cohort_sizes cs
            JOIN periods pr ON 1 = 1
    ),
    retained AS (
        SELECT p.first_state, l.gender, COALESCE(
                TIMESTAMPDIFF(YEAR, p.first_term, dd.date), 0
            ) AS period, COUNT(DISTINCT p.id_bioguide) AS cohort_retained
        FROM
            base_people p
            JOIN legislators_terms t ON p.id_bioguide = t.id_bioguide
            LEFT JOIN date_dim dd ON dd.date BETWEEN t.term_start AND t.term_end
            AND dd.month_name = 'December'
            AND dd.day_of_month = 31
            JOIN legislators l ON p.id_bioguide = l.id_bioguide
        WHERE
            p.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY
            p.first_state,
            l.gender,
            COALESCE(
                TIMESTAMPDIFF(YEAR, p.first_term, dd.date),
                0
            )
    )
SELECT
    g.gender,
    g.first_state,
    g.period,
    g.cohort_size,
    COALESCE(r.cohort_retained, 0) AS cohort_retained,
    COALESCE(r.cohort_retained, 0) * 1.0 / g.cohort_size AS pct_retained
FROM grid g
    LEFT JOIN retained r ON g.gender = r.gender
    AND g.first_state = r.first_state
    AND g.period = r.period
ORDER BY g.gender, g.first_state, g.period;

WITH RECURSIVE
    periods AS (
        SELECT 0 AS period
        UNION ALL
        SELECT period + 1
        FROM periods
        WHERE
            period < 20
    ),
    base_people AS (
        SELECT DISTINCT
            id_bioguide,
            MIN(term_start) OVER (
                PARTITION BY
                    id_bioguide
            ) AS first_term,
            FIRST_VALUE(state) OVER (
                PARTITION BY
                    id_bioguide
                ORDER BY term_start
            ) AS first_state
        FROM legislators_terms
    ),
    cohort_sizes AS (
        SELECT l.gender, p.first_state, COUNT(DISTINCT p.id_bioguide) AS cohort_size
        FROM base_people p
            JOIN legislators l ON p.id_bioguide = l.id_bioguide
        WHERE
            p.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY
            l.gender,
            p.first_state
    ),
    grid AS (
        SELECT cs.gender, cs.first_state, pr.period, cs.cohort_size
        FROM cohort_sizes cs
            JOIN periods pr ON 1 = 1
    ),
    retained AS (
        SELECT p.first_state, l.gender, COALESCE(
                TIMESTAMPDIFF(YEAR, p.first_term, dd.date), 0
            ) AS period, COUNT(DISTINCT p.id_bioguide) AS cohort_retained
        FROM
            base_people p
            JOIN legislators_terms t ON p.id_bioguide = t.id_bioguide
            LEFT JOIN date_dim dd ON dd.date BETWEEN t.term_start AND t.term_end
            AND dd.month_name = 'December'
            AND dd.day_of_month = 31
            JOIN legislators l ON p.id_bioguide = l.id_bioguide
        WHERE
            p.first_term BETWEEN '1917-01-01' AND '1999-12-31'
        GROUP BY
            p.first_state,
            l.gender,
            COALESCE(
                TIMESTAMPDIFF(YEAR, p.first_term, dd.date),
                0
            )
    ),
    final AS (
        SELECT
            g.gender,
            g.first_state,
            g.period,
            g.cohort_size,
            COALESCE(r.cohort_retained, 0) AS cohort_retained,
            COALESCE(r.cohort_retained, 0) * 1.0 / g.cohort_size AS pct_retained
        FROM grid g
            LEFT JOIN retained r ON g.gender = r.gender
            AND g.first_state = r.first_state
            AND g.period = r.period
    )
SELECT
    gender,
    first_state,
    cohort_size,
    MAX(
        CASE
            WHEN period = 0 THEN pct_retained
        END
    ) AS yr0,
    MAX(
        CASE
            WHEN period = 2 THEN pct_retained
        END
    ) AS yr2,
    MAX(
        CASE
            WHEN period = 4 THEN pct_retained
        END
    ) AS yr4,
    MAX(
        CASE
            WHEN period = 6 THEN pct_retained
        END
    ) AS yr6,
    MAX(
        CASE
            WHEN period = 8 THEN pct_retained
        END
    ) AS yr8,
    MAX(
        CASE
            WHEN period = 10 THEN pct_retained
        END
    ) AS yr10
FROM final
GROUP BY
    gender,
    first_state,
    cohort_size
ORDER BY gender, first_state;

----------- Defining cohorts from dates other than the first date ----------------------------------

SELECT
    id_bioguide,
    term_type,
    DATE('2000-01-01') AS snapshot_date,
    MIN(term_start) AS active_term_start
FROM legislators_terms
WHERE
    term_start <= '2000-12-31'
    AND term_end >= '2000-01-01'
GROUP BY
    id_bioguide,
    term_type;

SELECT
    term_type,
    period,
    FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            term_type
        ORDER BY period
    ) AS cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / FIRST_VALUE(cohort_retained) OVER (
        PARTITION BY
            term_type
        ORDER BY period
    ) AS pct_retained
FROM (
        SELECT a.term_type, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            ) AS period, COUNT(DISTINCT a.id_bioguide) AS cohort_retained
        FROM (
                SELECT
                    id_bioguide, term_type, DATE('2000-01-01') AS first_term, MIN(term_start) AS min_start
                FROM legislators_terms
                WHERE
                    term_start <= '2000-12-31'
                    AND term_end >= '2000-01-01'
                GROUP BY
                    id_bioguide, term_type, DATE('2000-01-01')
            ) a
            JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
            AND b.term_start >= a.min_start
            LEFT JOIN date_dim c ON c.date BETWEEN b.term_start AND b.term_end
            AND c.month_name = 'December'
            AND c.day_of_month = 31
            AND c.year >= 2000
        GROUP BY
            a.term_type, COALESCE(
                TIMESTAMPDIFF(YEAR, a.first_term, c.date), 0
            )
    ) aa;

----------- Survivorship ----------------------------------
SELECT
    id_bioguide,
    MIN(term_start) AS first_term,
    MAX(term_start) AS last_term
FROM legislators_terms
GROUP BY
    id_bioguide;

SELECT
    id_bioguide,
    CEILING(YEAR(MIN(term_start)) / 100) AS first_century,
    MIN(term_start) AS first_term,
    MAX(term_start) AS last_term,
    TIMESTAMPDIFF(
        YEAR,
        MIN(term_start),
        MAX(term_start)
    ) AS tenure
FROM legislators_terms
GROUP BY
    id_bioguide;

SELECT
    first_century,
    COUNT(DISTINCT id_bioguide) AS cohort_size,
    COUNT(
        DISTINCT CASE
            WHEN tenure >= 10 THEN id_bioguide
        END
    ) AS survived_10,
    COUNT(
        DISTINCT CASE
            WHEN tenure >= 10 THEN id_bioguide
        END
    ) * 1.0 / COUNT(DISTINCT id_bioguide) AS pct_survived_10
FROM (
        SELECT
            id_bioguide, CEILING(YEAR(MIN(term_start)) / 100) AS first_century, MIN(term_start) AS first_term, MAX(term_start) AS last_term, TIMESTAMPDIFF(
                YEAR, MIN(term_start), MAX(term_start)
            ) AS tenure
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) a
GROUP BY
    first_century
ORDER BY first_century;

SELECT
    id_bioguide,
    CEILING(YEAR(MIN(term_start)) / 100) AS first_century,
    COUNT(term_start) AS total_terms
FROM legislators_terms
GROUP BY
    id_bioguide

SELECT
    first_century,
    COUNT(DISTINCT id_bioguide) AS cohort_size,
    COUNT(
        DISTINCT CASE
            WHEN total_terms >= 5 THEN id_bioguide
        END
    ) AS survived_5,
    COUNT(
        DISTINCT CASE
            WHEN total_terms >= 5 THEN id_bioguide
        END
    ) * 1.0 / COUNT(DISTINCT id_bioguide) AS pct_survived_5_terms
FROM (
        SELECT
            id_bioguide, CEILING(YEAR(MIN(term_start)) / 100) AS first_century, COUNT(term_start) AS total_terms
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) a
GROUP BY
    first_century
ORDER BY first_century;

WITH RECURSIVE
    terms AS (
        SELECT 1 AS terms
        UNION ALL
        SELECT terms + 1
        FROM terms
        WHERE
            terms < 20
    ),
    base AS (
        SELECT
            id_bioguide,
            CEILING(YEAR(MIN(term_start)) / 100) AS first_century,
            COUNT(term_start) AS total_terms
        FROM legislators_terms
        GROUP BY
            id_bioguide
    )
SELECT
    a.first_century,
    t.terms,
    COUNT(DISTINCT a.id_bioguide) AS cohort,
    COUNT(
        DISTINCT CASE
            WHEN a.total_terms >= t.terms THEN a.id_bioguide
        END
    ) AS cohort_survived,
    COUNT(
        DISTINCT CASE
            WHEN a.total_terms >= t.terms THEN a.id_bioguide
        END
    ) * 1.0 / COUNT(DISTINCT a.id_bioguide) AS pct_survived
FROM base a
    JOIN terms t ON 1 = 1
GROUP BY
    a.first_century,
    t.terms
ORDER BY a.first_century, t.terms;

----------- Returnship / repeat purchase behavior ----------------------------------
SELECT CEILING(YEAR(a.first_term) / 100) AS cohort_century, COUNT(a.id_bioguide) AS reps
FROM (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        WHERE
            term_type = 'rep'
        GROUP BY
            id_bioguide
    ) a
GROUP BY
    CEILING(YEAR(a.first_term) / 100)
ORDER BY cohort_century;

SELECT aa.cohort_century, bb.rep_and_sen * 1.0 / aa.reps AS pct_rep_and_sen
FROM (
        SELECT CEILING(YEAR(a.first_term) / 100) AS cohort_century, COUNT(a.id_bioguide) AS reps
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE
                    term_type = 'rep'
                GROUP BY
                    id_bioguide
            ) a
        GROUP BY
            CEILING(YEAR(a.first_term) / 100)
    ) aa
    LEFT JOIN (
        SELECT CEILING(YEAR(b.first_term) / 100) AS cohort_century, COUNT(DISTINCT b.id_bioguide) AS rep_and_sen
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE
                    term_type = 'rep'
                GROUP BY
                    id_bioguide
            ) b
            JOIN legislators_terms c ON b.id_bioguide = c.id_bioguide
            AND c.term_type = 'sen'
            AND c.term_start > b.first_term
        GROUP BY
            CEILING(YEAR(b.first_term) / 100)
    ) bb ON aa.cohort_century = bb.cohort_century
ORDER BY aa.cohort_century;

SELECT aa.cohort_century, bb.rep_and_sen * 1.0 / aa.reps AS pct_10_yrs
FROM (
        SELECT CEILING(YEAR(a.first_term) / 100) AS cohort_century, COUNT(a.id_bioguide) AS reps
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE
                    term_type = 'rep'
                GROUP BY
                    id_bioguide
            ) a
        WHERE
            a.first_term <= '2009-12-31'
        GROUP BY
            CEILING(YEAR(a.first_term) / 100)
    ) aa
    LEFT JOIN (
        SELECT CEILING(YEAR(b.first_term) / 100) AS cohort_century, COUNT(DISTINCT b.id_bioguide) AS rep_and_sen
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE
                    term_type = 'rep'
                GROUP BY
                    id_bioguide
            ) b
            JOIN legislators_terms c ON b.id_bioguide = c.id_bioguide
            AND c.term_type = 'sen'
            AND c.term_start > b.first_term
        WHERE
            c.term_start <= DATE_ADD(
                b.first_term, INTERVAL 10 YEAR
            )
        GROUP BY
            CEILING(YEAR(b.first_term) / 100)
    ) bb ON aa.cohort_century = bb.cohort_century
ORDER BY cohort_century;

SELECT
    aa.cohort_century AS cohort_century,
    ROUND(
        bb.rep_and_sen_5_yrs * 1.0 / aa.reps,
        4
    ) AS pct_5_yrs,
    ROUND(
        bb.rep_and_sen_10_yrs * 1.0 / aa.reps,
        4
    ) AS pct_10_yrs,
    ROUND(
        bb.rep_and_sen_15_yrs * 1.0 / aa.reps,
        4
    ) AS pct_15_yrs
FROM (
        SELECT CEILING(YEAR(a.first_term) / 100) AS cohort_century, COUNT(a.id_bioguide) AS reps
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE
                    term_type = 'rep'
                GROUP BY
                    id_bioguide
            ) a
        WHERE
            a.first_term <= '2009-12-31'
        GROUP BY
            CEILING(YEAR(a.first_term) / 100)
    ) aa
    LEFT JOIN (
        SELECT
            CEILING(YEAR(b.first_term) / 100) AS cohort_century, COUNT(
                DISTINCT CASE
                    WHEN c.term_start <= DATE_ADD(b.first_term, INTERVAL 5 YEAR) THEN b.id_bioguide
                END
            ) AS rep_and_sen_5_yrs, COUNT(
                DISTINCT CASE
                    WHEN c.term_start <= DATE_ADD(
                        b.first_term, INTERVAL 10 YEAR
                    ) THEN b.id_bioguide
                END
            ) AS rep_and_sen_10_yrs, COUNT(
                DISTINCT CASE
                    WHEN c.term_start <= DATE_ADD(
                        b.first_term, INTERVAL 15 YEAR
                    ) THEN b.id_bioguide
                END
            ) AS rep_and_sen_15_yrs
        FROM (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                WHERE
                    term_type = 'rep'
                GROUP BY
                    id_bioguide
            ) b
            JOIN legislators_terms c ON b.id_bioguide = c.id_bioguide
            AND c.term_type = 'sen'
            AND c.term_start > b.first_term
        GROUP BY
            CEILING(YEAR(b.first_term) / 100)
    ) bb ON aa.cohort_century = bb.cohort_century
ORDER BY cohort_century;

----------- Cumulative calculations ----------------------------------
SELECT CEILING(YEAR(a.first_term) / 100) AS century, a.first_type, COUNT(DISTINCT a.id_bioguide) AS cohort, COUNT(b.term_start) AS terms
FROM (
        SELECT DISTINCT
            id_bioguide, FIRST_VALUE(term_type) OVER (
                PARTITION BY
                    id_bioguide
                ORDER BY term_start
            ) AS first_type, MIN(term_start) OVER (
                PARTITION BY
                    id_bioguide
            ) AS first_term, DATE_ADD(
                MIN(term_start) OVER (
                    PARTITION BY
                        id_bioguide
                ), INTERVAL 10 YEAR
            ) AS first_plus_10
        FROM legislators_terms
    ) a
    LEFT JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
    AND b.term_start BETWEEN a.first_term AND a.first_plus_10
GROUP BY
    CEILING(YEAR(a.first_term) / 100),
    a.first_type
ORDER BY century, a.first_type;

SELECT
    century,
    MAX(
        CASE
            WHEN first_type = 'rep' THEN cohort
        END
    ) AS rep_cohort,
    MAX(
        CASE
            WHEN first_type = 'rep' THEN terms_per_leg
        END
    ) AS avg_rep_terms,
    MAX(
        CASE
            WHEN first_type = 'sen' THEN cohort
        END
    ) AS sen_cohort,
    MAX(
        CASE
            WHEN first_type = 'sen' THEN terms_per_leg
        END
    ) AS avg_sen_terms
FROM (
        SELECT
            CEILING(YEAR(a.first_term) / 100) AS century, a.first_type, COUNT(DISTINCT a.id_bioguide) AS cohort, COUNT(b.term_start) AS terms, COUNT(b.term_start) * 1.0 / COUNT(DISTINCT a.id_bioguide) AS terms_per_leg
        FROM (
                SELECT DISTINCT
                    id_bioguide, FIRST_VALUE(term_type) OVER (
                        PARTITION BY
                            id_bioguide
                        ORDER BY term_start
                    ) AS first_type, MIN(term_start) OVER (
                        PARTITION BY
                            id_bioguide
                    ) AS first_term, DATE_ADD(
                        MIN(term_start) OVER (
                            PARTITION BY
                                id_bioguide
                        ), INTERVAL 10 YEAR
                    ) AS first_plus_10
                FROM legislators_terms
            ) a
            LEFT JOIN legislators_terms b ON a.id_bioguide = b.id_bioguide
            AND b.term_start BETWEEN a.first_term AND a.first_plus_10
        GROUP BY
            CEILING(YEAR(a.first_term) / 100), a.first_type
    ) aa
GROUP BY
    century
ORDER BY century;

----------- Cross-section analysis, with a cohort lens ----------------------------------
SELECT b.date, COUNT(DISTINCT a.id_bioguide) AS legislators
FROM
    legislators_terms a
    JOIN date_dim b ON b.date BETWEEN a.term_start AND a.term_end
    AND b.month_name = 'December'
    AND b.day_of_month = 31
    AND b.year <= 2019
GROUP BY
    b.date
ORDER BY b.date;

SELECT b.date, CEILING(YEAR(c.first_term) / 100) AS century, COUNT(DISTINCT a.id_bioguide) AS legislators
FROM
    legislators_terms a
    JOIN date_dim b ON b.date BETWEEN a.term_start AND a.term_end
    AND b.month_name = 'December'
    AND b.day_of_month = 31
    AND b.year <= 2019
    JOIN (
        SELECT id_bioguide, MIN(term_start) AS first_term
        FROM legislators_terms
        GROUP BY
            id_bioguide
    ) c ON a.id_bioguide = c.id_bioguide
GROUP BY
    b.date,
    CEILING(YEAR(c.first_term) / 100)
ORDER BY b.date, century;

SELECT
    `date`,
    century,
    legislators,
    SUM(legislators) OVER (
        PARTITION BY
            `date`
    ) AS cohort,
    legislators * 1.0 / SUM(legislators) OVER (
        PARTITION BY
            `date`
    ) AS pct_century
FROM (
        SELECT
            b.date AS `date`, CEILING(YEAR(c.first_term) / 100) AS century, COUNT(DISTINCT a.id_bioguide) AS legislators
        FROM
            legislators_terms a
            JOIN date_dim b ON b.date BETWEEN a.term_start AND a.term_end
            AND b.month_name = 'December'
            AND b.day_of_month = 31
            AND b.year <= 2019
            JOIN (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY
                    id_bioguide
            ) c ON a.id_bioguide = c.id_bioguide
        GROUP BY
            b.date, CEILING(YEAR(c.first_term) / 100)
    ) a
ORDER BY `date`, century;

SELECT
    `date`,
    COALESCE(
        SUM(
            CASE
                WHEN century = 18 THEN legislators
            END
        ) * 100.0 / SUM(legislators),
        0
    ) AS pct_18,
    COALESCE(
        SUM(
            CASE
                WHEN century = 19 THEN legislators
            END
        ) * 100.0 / SUM(legislators),
        0
    ) AS pct_19,
    COALESCE(
        SUM(
            CASE
                WHEN century = 20 THEN legislators
            END
        ) * 100.0 / SUM(legislators),
        0
    ) AS pct_20,
    COALESCE(
        SUM(
            CASE
                WHEN century = 21 THEN legislators
            END
        ) * 100.0 / SUM(legislators),
        0
    ) AS pct_21
FROM (
        SELECT
            b.date AS `date`, CEILING(YEAR(c.first_term) / 100) AS century, COUNT(DISTINCT a.id_bioguide) AS legislators
        FROM
            legislators_terms a
            JOIN date_dim b ON b.date BETWEEN a.term_start AND a.term_end
            AND b.month_name = 'December'
            AND b.day_of_month = 31
            AND b.year <= 2019
            JOIN (
                SELECT id_bioguide, MIN(term_start) AS first_term
                FROM legislators_terms
                GROUP BY
                    id_bioguide
            ) c ON a.id_bioguide = c.id_bioguide
        GROUP BY
            b.date, CEILING(YEAR(c.first_term) / 100)
    ) aa
GROUP BY
    `date`
ORDER BY `date`;

SELECT
    id_bioguide,
    `date`,
    COUNT(*) OVER (
        PARTITION BY
            id_bioguide
        ORDER BY
            `date` ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
    ) AS cume_years
FROM (
        SELECT DISTINCT
            lt.id_bioguide, dd.date AS `date`
        FROM
            legislators_terms lt
            JOIN date_dim dd ON dd.date BETWEEN lt.term_start AND lt.term_end
            AND dd.month_name = 'December'
            AND dd.day_of_month = 31
            AND dd.year <= 2019
    ) a
ORDER BY id_bioguide, `date`;

SELECT
    `date`,
    cume_years,
    COUNT(DISTINCT id_bioguide) AS legislators
FROM (
        SELECT
            id_bioguide, `date`, COUNT(*) OVER (
                PARTITION BY
                    id_bioguide
                ORDER BY
                    `date` ROWS BETWEEN UNBOUNDED PRECEDING
                    AND CURRENT ROW
            ) AS cume_years
        FROM (
                SELECT DISTINCT
                    lt.id_bioguide, dd.date AS `date`
                FROM
                    legislators_terms lt
                    JOIN date_dim dd ON dd.date BETWEEN lt.term_start AND lt.term_end
                    AND dd.month_name = 'December'
                    AND dd.day_of_month = 31
                    AND dd.year <= 2019
            ) aa
    ) aaa
GROUP BY
    `date`,
    cume_years
ORDER BY `date`, cume_years;

SELECT `date`, COUNT(*) AS tenures
FROM (
        SELECT
            `date`, cume_years, COUNT(DISTINCT id_bioguide) AS legislators
        FROM (
                SELECT
                    id_bioguide, `date`, COUNT(*) OVER (
                        PARTITION BY
                            id_bioguide
                        ORDER BY
                            `date` ROWS BETWEEN UNBOUNDED PRECEDING
                            AND CURRENT ROW
                    ) AS cume_years
                FROM (
                        SELECT DISTINCT
                            lt.id_bioguide, dd.date AS `date`
                        FROM
                            legislators_terms lt
                            JOIN date_dim dd ON dd.date BETWEEN lt.term_start AND lt.term_end
                            AND dd.month_name = 'December'
                            AND dd.day_of_month = 31
                            AND dd.year <= 2019
                    ) aa
            ) aaa
        GROUP BY
            `date`, cume_years
    ) aaaa
GROUP BY
    `date`
ORDER BY `date`;

SELECT
    `date`,
    tenure,
    legislators * 100.0 / SUM(legislators) OVER (
        PARTITION BY
            `date`
    ) AS pct_legislators
FROM (
        SELECT
            `date`, CASE
                WHEN cume_years <= 4 THEN '1 to 4'
                WHEN cume_years <= 10 THEN '5 to 10'
                WHEN cume_years <= 20 THEN '11 to 20'
                ELSE '21+'
            END AS tenure, COUNT(DISTINCT id_bioguide) AS legislators
        FROM (
                SELECT
                    id_bioguide, `date`, COUNT(*) OVER (
                        PARTITION BY
                            id_bioguide
                        ORDER BY
                            `date` ROWS BETWEEN UNBOUNDED PRECEDING
                            AND CURRENT ROW
                    ) AS cume_years
                FROM (
                        SELECT DISTINCT
                            lt.id_bioguide, dd.date AS `date`
                        FROM
                            legislators_terms lt
                            JOIN date_dim dd ON dd.date BETWEEN lt.term_start AND lt.term_end
                            AND dd.month_name = 'December'
                            AND dd.day_of_month = 31
                            AND dd.year <= 2019
                    ) a
            ) aa
        GROUP BY
            `date`, tenure
    ) aaa
ORDER BY `date`, tenure;