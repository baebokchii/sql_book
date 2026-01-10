-- Active: 1767840625700@@127.0.0.1@3306@sql_for_data_analysis -- Basic retentionSELECT id_bioguide,
         min(term_start) AS first_term
FROM legislators_terms
GROUP BY  1 ;SELECT TIMESTAMPDIFF(YEAR,
         a.first_term,
         b.term_start) AS periods,
         COUNT(DISTINCT a.id_bioguide) AS cohort_retained
FROM 
    (SELECT id_bioguide,
         MIN(term_start) AS first_term
    FROM legislators_terms
    GROUP BY  id_bioguide ) AS a
JOIN legislators_terms AS b
    ON a.id_bioguide = b.id_bioguide
GROUP BY  1
ORDER BY  periods;SELECT period ,
         first_value(cohort_retained)
    OVER (order by period) AS cohort_size ,cohort_retained ,cohort_retained * 1.0 / first_value(cohort_retained)
    OVER (order by period) AS pct_retained
FROM 
    (SELECT date_part('year',age(b.term_start,a.first_term)) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT id_bioguide ,
         min(term_start) AS first_term
        FROM legislators_terms
        GROUP BY  1 ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
        GROUP BY  1 ) aa ;SELECT cohort_size ,
        max(case
            WHEN period = 0 THEN
            pct_retained end) AS yr0 ,max(case
            WHEN period = 1 THEN
            pct_retained end) AS yr1 ,max(case
            WHEN period = 2 THEN
            pct_retained end) AS yr2 ,max(case
            WHEN period = 3 THEN
            pct_retained end) AS yr3 ,max(case
            WHEN period = 4 THEN
            pct_retained end) AS yr4
    FROM 
    (SELECT period ,
        first_value(cohort_retained)
        OVER (order by period) AS cohort_size ,cohort_retained ,cohort_retained * 1.0 / first_value(cohort_retained)
        OVER (order by period) AS pct_retained
    FROM 
        (SELECT date_part('year',age(b.term_start,a.first_term)) AS period ,count(*) AS cohort_retained
        FROM 
            (SELECT id_bioguide ,
        min(term_start) AS first_term
            FROM legislators_terms
            GROUP BY  1 ) a
            JOIN legislators_terms b
                ON a.id_bioguide = b.id_bioguide
            GROUP BY  1 ) aa ) aaa
        GROUP BY  1 ; -- Time adjustmentsSELECT a.id_bioguide,
         a.first_term ,
        b.term_start,
         b.term_end ,
        c.date ,
        date_part('year',age(c.date,a.first_term)) AS period
    FROM 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    GROUP BY  1 ) a
JOIN legislators_terms b
    ON a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c
    ON c.date
    BETWEEN b.term_start
        AND b.term_end
        AND c.month_name = 'December'
        AND c.day_of_month = 31 ;SELECT coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
FROM 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    GROUP BY  1 ) a
JOIN legislators_terms b
    ON a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c
    ON c.date
    BETWEEN b.term_start
        AND b.term_end
        AND c.month_name = 'December'
        AND c.day_of_month = 31
GROUP BY  1 ;SELECT period ,
        first_value(cohort_retained)
    OVER (order by period) AS cohort_size ,cohort_retained ,cohort_retained * 1.0 / first_value(cohort_retained)
    OVER (order by period) AS pct_retained
FROM 
    (SELECT coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        GROUP BY  1 ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
        LEFT JOIN date_dim c
            ON c.date
            BETWEEN b.term_start
                AND b.term_end
                AND c.month_name = 'December'
                AND c.day_of_month = 31
        GROUP BY  1 ) aa ;SELECT a.id_bioguide,
         a.first_term ,
        b.term_start ,
        case
        WHEN b.term_type = 'rep' THEN
    b.term_start + interval '2 years'
    WHEN b.term_type = 'sen' THEN
    b.term_start + interval '6 years'
    END AS term_end
FROM 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    GROUP BY  1 ) a
JOIN legislators_terms b
    ON a.id_bioguide = b.id_bioguide ;SELECT a.id_bioguide,
         a.first_term ,
        b.term_start ,
        lead(b.term_start)
    OVER (partition by a.id_bioguide
ORDER BY  b.term_start) - interval '1 day' AS term_end
FROM 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    GROUP BY  1 ) a
JOIN legislators_terms b
    ON a.id_bioguide = b.id_bioguide
ORDER BY  1,3 ; -- Time-based cohorts derived
FROM the time-seriesSELECT date_part('year',a.first_term) AS first_year ,coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
FROM 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    GROUP BY  1 ) a
JOIN legislators_terms b
    ON a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c
    ON c.date
    BETWEEN b.term_start
        AND b.term_end
        AND c.month_name = 'December'
        AND c.day_of_month = 31
GROUP BY  1,
        2 ;SELECT first_year ,
        period ,
        first_value(cohort_retained)
    OVER (partition by first_year
ORDER BY  period) AS cohort_size ,cohort_retained ,round(cohort_retained * 1.0 / first_value(cohort_retained)
    OVER (partition by first_year
ORDER BY  period),2) AS pct_retained
FROM 
    (SELECT date_part('year',first_term) AS first_year ,date_part('year',age(b.term_start,a.first_term)) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT id_bioguide ,
        min(term_start) AS first_term
        FROM legislators_terms
        GROUP BY  1 ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
        GROUP BY  1,
        2 ) aa ;SELECT first_century,
         period ,
        first_value(cohort_retained)
        OVER (partition by first_century
    ORDER BY  period) AS cohort_size ,cohort_retained ,cohort_retained * 1.0 / first_value(cohort_retained)
    OVER (partition by first_century
ORDER BY  period) AS pct_retained
FROM 
    (SELECT date_part('century',a.first_term) AS first_century ,coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        GROUP BY  1 ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
        LEFT JOIN date_dim c
            ON c.date
            BETWEEN b.term_start
                AND b.term_end
                AND c.month_name = 'December'
                AND c.day_of_month = 31
        GROUP BY  1,2 ) aa
    ORDER BY  1,
        2 ;SELECT DISTINCT id_bioguide ,
        min(term_start)
    OVER (partition by id_bioguide) AS first_term ,first_value(state)
    OVER (partition by id_bioguide
ORDER BY  term_start) AS first_state
FROM legislators_terms ;SELECT first_state,
         period ,
        first_value(cohort_retained)
    OVER (partition by first_state
ORDER BY  period) AS cohort_size ,cohort_retained ,cohort_retained * 1.0 / first_value(cohort_retained)
    OVER (partition by first_state
ORDER BY  period) AS pct_retained
FROM 
    (SELECT a.first_state ,
        coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT DISTINCT id_bioguide ,
        min(term_start)
            OVER (partition by id_bioguide) AS first_term ,first_value(state)
            OVER (partition by id_bioguide
        ORDER BY  term_start) AS first_state
        FROM legislators_terms ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
        LEFT JOIN date_dim c
            ON c.date
            BETWEEN b.term_start
                AND b.term_end
                AND c.month_name = 'December'
                AND c.day_of_month = 31
        GROUP BY  1,2 ) aa
    ORDER BY  1,2 ; -- Defining the cohort
FROM a separate tableSELECT d.gender ,
        coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
FROM 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    GROUP BY  1 ) a
JOIN legislators_terms b
    ON a.id_bioguide = b.id_bioguide
LEFT JOIN date_dim c
    ON c.date
    BETWEEN b.term_start
        AND b.term_end
        AND c.month_name = 'December'
        AND c.day_of_month = 31
JOIN legislators d
    ON a.id_bioguide = d.id_bioguide
GROUP BY  1,2
ORDER BY  2,
        1 ;SELECT gender,
         period ,
        first_value(cohort_retained)
    OVER (partition by gender
ORDER BY  period) AS cohort_size ,cohort_retained ,cohort_retained * 1.0 / first_value(cohort_retained)
    OVER (partition by gender
ORDER BY  period) AS pct_retained
FROM 
    (SELECT d.gender ,
        coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        GROUP BY  1 ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
        LEFT JOIN date_dim c
            ON c.date
            BETWEEN b.term_start
                AND b.term_end
                AND c.month_name = 'December'
                AND c.day_of_month = 31
        JOIN legislators d
            ON a.id_bioguide = d.id_bioguide
        GROUP BY  1,2 ) aa
    ORDER BY  2,
        1 ;SELECT gender,
         period ,
        first_value(cohort_retained)
    OVER (partition by gender
ORDER BY  period) AS cohort_size ,cohort_retained ,cohort_retained * 1.0 / first_value(cohort_retained)
    OVER (partition by gender
ORDER BY  period) AS pct_retained
FROM 
    (SELECT d.gender ,
        coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        GROUP BY  1 ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
        LEFT JOIN date_dim c
            ON c.date
            BETWEEN b.term_start
                AND b.term_end
                AND c.month_name = 'December'
                AND c.day_of_month = 31
        JOIN legislators d
            ON a.id_bioguide = d.id_bioguide
        WHERE a.first_term
            BETWEEN '1917-01-01'
                AND '1999-12-31'
        GROUP BY  1,2 ) aa
    ORDER BY  2,1 ; ----------- Dealing
WITH sparse cohortsSELECT first_state,
         gender,
         period ,
        first_value(cohort_retained)
    OVER (partition by first_state, gender
ORDER BY  period) AS cohort_size ,cohort_retained ,cohort_retained / first_value(cohort_retained)
    OVER (partition by first_state, gender
ORDER BY  period) AS pct_retained
FROM 
    (SELECT a.first_state,
         d.gender ,
        coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT DISTINCT id_bioguide ,
        min(term_start)
            OVER (partition by id_bioguide) AS first_term ,first_value(state)
            OVER (partition by id_bioguide
        ORDER BY  term_start) AS first_state
        FROM legislators_terms ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
        LEFT JOIN date_dim c
            ON c.date
            BETWEEN b.term_start
                AND b.term_end
                AND c.month_name = 'December'
                AND c.day_of_month = 31
        JOIN legislators d
            ON a.id_bioguide = d.id_bioguide
        WHERE a.first_term
            BETWEEN '1917-01-01'
                AND '1999-12-31'
        GROUP BY  1,
        2,
        3 ) aa ;SELECT aa.gender,
         aa.first_state,
         cc.period,
         aa.cohort_size
    FROM 
    (SELECT b.gender,
         a.first_state ,
        count(distinct a.id_bioguide) AS cohort_size
    FROM 
        (SELECT DISTINCT id_bioguide ,
        min(term_start)
            OVER (partition by id_bioguide) AS first_term ,first_value(state)
            OVER (partition by id_bioguide
        ORDER BY  term_start) AS first_state
        FROM legislators_terms ) a
        JOIN legislators b
            ON a.id_bioguide = b.id_bioguide
        WHERE a.first_term
            BETWEEN '1917-01-01'
                AND '1999-12-31'
        GROUP BY  1,2 ) aa
    JOIN 
    (SELECT generate_series AS period
    FROM generate_series(0,20,1) ) cc
    ON 1 = 1 ;SELECT aaa.gender,
         aaa.first_state,
         aaa.period,
         aaa.cohort_size ,
        coalesce(ddd.cohort_retained,
        0) AS cohort_retained ,
        coalesce(ddd.cohort_retained,
        0) * 1.0 / aaa.cohort_size AS pct_retained
FROM 
    (SELECT aa.gender,
         aa.first_state,
         cc.period,
         aa.cohort_size
    FROM 
        (SELECT b.gender,
         a.first_state ,
        count(distinct a.id_bioguide) AS cohort_size
        FROM 
            (SELECT DISTINCT id_bioguide ,
        min(term_start)
                OVER (partition by id_bioguide) AS first_term ,first_value(state)
                OVER (partition by id_bioguide
            ORDER BY  term_start) AS first_state
            FROM legislators_terms ) a
            JOIN legislators b
                ON a.id_bioguide = b.id_bioguide
            WHERE a.first_term
                BETWEEN '1917-01-01'
                    AND '1999-12-31'
            GROUP BY  1,2 ) aa
            JOIN 
                (SELECT generate_series AS period
                FROM generate_series(0,20,1) ) cc
                    ON 1 = 1 ) aaa
            LEFT JOIN 
            (SELECT d.first_state,
         g.gender ,
        coalesce(date_part('year',age(f.date,d.first_term)),0) AS period ,count(distinct d.id_bioguide) AS cohort_retained
            FROM 
                (SELECT DISTINCT id_bioguide ,
        min(term_start)
                    OVER (partition by id_bioguide) AS first_term ,first_value(state)
                    OVER (partition by id_bioguide
                ORDER BY  term_start) AS first_state
                FROM legislators_terms ) d
                JOIN legislators_terms e
                    ON d.id_bioguide = e.id_bioguide
                LEFT JOIN date_dim f
                    ON f.date
                    BETWEEN e.term_start
                        AND e.term_end
                        AND f.month_name = 'December'
                        AND f.day_of_month = 31
                JOIN legislators g
                    ON d.id_bioguide = g.id_bioguide
                WHERE d.first_term
                    BETWEEN '1917-01-01'
                        AND '1999-12-31'
                GROUP BY  1,2,3 ) ddd
                ON aaa.gender = ddd.gender
                AND aaa.first_state = ddd.first_state
            AND aaa.period = ddd.period
ORDER BY  1,
        2,
        3 ;SELECT gender,
         first_state,
         cohort_size ,
        max(case
    WHEN period = 0 THEN
    pct_retained end) AS yr0 ,max(case
    WHEN period = 2 THEN
    pct_retained end) AS yr2 ,max(case
    WHEN period = 4 THEN
    pct_retained end) AS yr4 ,max(case
    WHEN period = 6 THEN
    pct_retained end) AS yr6 ,max(case
    WHEN period = 8 THEN
    pct_retained end) AS yr8 ,max(case
    WHEN period = 10 THEN
    pct_retained end) AS yr10
FROM 
    (SELECT aaa.gender,
         aaa.first_state,
         aaa.period,
         aaa.cohort_size ,
        coalesce(ddd.cohort_retained,
        0) AS cohort_retained ,
        coalesce(ddd.cohort_retained,
        0) * 1.0 / aaa.cohort_size AS pct_retained
    FROM 
        (SELECT aa.gender,
         aa.first_state,
         cc.period,
         aa.cohort_size
        FROM 
            (SELECT b.gender,
         a.first_state ,
        count(distinct a.id_bioguide) AS cohort_size
            FROM 
                (SELECT DISTINCT id_bioguide ,
        min(term_start)
                    OVER (partition by id_bioguide) AS first_term ,first_value(state)
                    OVER (partition by id_bioguide
                ORDER BY  term_start) AS first_state
                FROM legislators_terms ) a
                JOIN legislators b
                    ON a.id_bioguide = b.id_bioguide
                WHERE a.first_term
                    BETWEEN '1917-01-01'
                        AND '1999-12-31'
                GROUP BY  1,2 ) aa
                JOIN 
                    (SELECT generate_series AS period
                    FROM generate_series(0,20,1) ) cc
                        ON 1 = 1 ) aaa
                    LEFT JOIN 
                        (SELECT d.first_state,
         g.gender ,
        coalesce(date_part('year',age(f.date,d.first_term)),0) AS period ,count(distinct d.id_bioguide) AS cohort_retained
                        FROM 
                            (SELECT DISTINCT id_bioguide ,
        min(term_start)
                                OVER (partition by id_bioguide) AS first_term ,first_value(state)
                                OVER (partition by id_bioguide
                            ORDER BY  term_start) AS first_state
                            FROM legislators_terms ) d
                            JOIN legislators_terms e
                                ON d.id_bioguide = e.id_bioguide
                            LEFT JOIN date_dim f
                                ON f.date
                                BETWEEN e.term_start
                                    AND e.term_end
                                    AND f.month_name = 'December'
                                    AND f.day_of_month = 31
                            JOIN legislators g
                                ON d.id_bioguide = g.id_bioguide
                            WHERE d.first_term
                                BETWEEN '1917-01-01'
                                    AND '1999-12-31'
                            GROUP BY  1,2,3 ) ddd
                                ON aaa.gender = ddd.gender
                                    AND aaa.first_state = ddd.first_state
                                    AND aaa.period = ddd.period ) a
                        GROUP BY  1,2,3 ; ----------- Defining cohorts
                    FROM dates other than the first date ----------------------------------SELECT DISTINCT id_bioguide,
         term_type,
         date('2000-01-01') AS first_term ,min(term_start) AS min_start
                FROM legislators_terms
            WHERE term_start <= '2000-12-31'
        AND term_end >= '2000-01-01'
GROUP BY  1,
        2,
        3 ;SELECT term_type,
         period ,
        first_value(cohort_retained)
    OVER (partition by term_type
ORDER BY  period) AS cohort_size ,cohort_retained ,cohort_retained * 1.0 / first_value(cohort_retained)
    OVER (partition by term_type
ORDER BY  period) AS pct_retained
FROM 
    (SELECT a.term_type ,
        coalesce(date_part('year',age(c.date,a.first_term)),0) AS period ,count(distinct a.id_bioguide) AS cohort_retained
    FROM 
        (SELECT DISTINCT id_bioguide,
         term_type,
         date('2000-01-01') AS first_term
        FROM legislators_terms
        WHERE term_start <= '2000-12-31'
                AND term_end >= '2000-01-01' ) a
        JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide --and b.term_start >= a.first_term
        LEFT JOIN date_dim c
            ON c.date
            BETWEEN b.term_start
                AND b.term_end
                AND c.month_name = 'December'
                AND c.day_of_month = 31
        GROUP BY  1,
        2 ) aa ; ----------- Survivorship ----------------------------------SELECT id_bioguide ,
        min(term_start) AS first_term ,
        max(term_start) AS last_term
    FROM legislators_terms
GROUP BY  1 ;SELECT id_bioguide ,
        date_part('century',min(term_start)) AS first_century ,min(term_start) AS first_term ,max(term_start) AS last_term ,date_part('year',age(max(term_start),min(term_start))) AS tenure
FROM legislators_terms
GROUP BY  1 ;SELECT first_century ,
        count(distinct id_bioguide) AS cohort_size ,
        count(distinct
    CASE
    WHEN tenure >= 10 THEN
    id_bioguide end) AS survived_10 ,count(distinct
    CASE
    WHEN tenure >= 10 THEN
    id_bioguide end) * 1.0 / count(distinct id_bioguide) AS pct_survived_10
FROM 
    (SELECT id_bioguide ,
        date_part('century',min(term_start)) AS first_century ,min(term_start) AS first_term ,max(term_start) AS last_term ,date_part('year',age(max(term_start),min(term_start))) AS tenure
    FROM legislators_terms
    GROUP BY  1 ) a
GROUP BY  1 ;SELECT id_bioguide ,
        date_part('century',min(term_start)) AS first_century ,min(term_start) AS first_term ,max(term_start) AS last_term ,date_part('year',age(max(term_start),min(term_start))) AS tenure
FROM legislators_terms
GROUP BY  1 ;SELECT first_century ,
        count(distinct id_bioguide) AS cohort_size ,
        count(distinct
    CASE
    WHEN total_terms >= 5 THEN
    id_bioguide end) AS survived_5 ,count(distinct
    CASE
    WHEN total_terms >= 5 THEN
    id_bioguide end) * 1.0 / count(distinct id_bioguide) AS pct_survived_5_terms
FROM 
    (SELECT id_bioguide ,
        date_part('century',min(term_start)) AS first_century ,count(term_start) AS total_terms
    FROM legislators_terms
    GROUP BY  1 ) a
GROUP BY  1 ;SELECT a.first_century ,
        b.terms ,
        count(distinct id_bioguide) AS cohort ,
        count(distinct
    CASE
    WHEN a.total_terms >= b.terms THEN
    id_bioguide end) AS cohort_survived ,count(distinct
    CASE
    WHEN a.total_terms >= b.terms THEN
    id_bioguide end) * 1.0 / count(distinct id_bioguide) AS pct_survived
FROM 
    (SELECT id_bioguide ,
        date_part('century',min(term_start)) AS first_century ,count(term_start) AS total_terms
    FROM legislators_terms
    GROUP BY  1 ) a
JOIN 
    (SELECT generate_series AS terms
    FROM generate_series(1,20,1) ) b
    ON 1 = 1
GROUP BY  1,
        2 ; ----------- Returnship / repeat purchase behavior ----------------------------------SELECT date_part('century',a.first_term)::int AS cohort_century ,count(id_bioguide) AS reps
FROM 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    WHERE term_type = 'rep'
    GROUP BY  1 ) a
GROUP BY  1 ;SELECT date_part('century',a.first_term) AS cohort_century ,count(id_bioguide) AS reps
FROM 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    WHERE term_type = 'rep'
    GROUP BY  1 ) a
GROUP BY  1
ORDER BY  1 ;SELECT aa.cohort_century ,
        bb.rep_and_sen * 1.0 / aa.reps AS pct_rep_and_sen
FROM 
    (SELECT date_part('century',a.first_term) AS cohort_century ,count(id_bioguide) AS reps
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY  1 ) a
        GROUP BY  1 ) aa
    LEFT JOIN 
    (SELECT date_part('century',b.first_term) AS cohort_century ,count(distinct b.id_bioguide) AS rep_and_sen
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY  1 ) b
        JOIN legislators_terms c
            ON b.id_bioguide = c.id_bioguide
                AND c.term_type = 'sen'
                AND c.term_start > b.first_term
        GROUP BY  1 ) bb
        ON aa.cohort_century = bb.cohort_century ;SELECT aa.cohort_century ,
        bb.rep_and_sen * 1.0 / aa.reps AS pct_rep_and_sen
FROM 
    (SELECT date_part('century',a.first_term) AS cohort_century ,count(id_bioguide) AS reps
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY  1 ) a
        WHERE first_term <= '2009-12-31'
        GROUP BY  1 ) aa
    LEFT JOIN 
    (SELECT date_part('century',b.first_term) AS cohort_century ,count(distinct b.id_bioguide) AS rep_and_sen
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY  1 ) b
        JOIN legislators_terms c
            ON b.id_bioguide = c.id_bioguide
                AND c.term_type = 'sen'
                AND c.term_start > b.first_term
        WHERE age(c.term_start, b.first_term) <= interval '10 years'
        GROUP BY  1 ) bb
        ON aa.cohort_century = bb.cohort_century ;SELECT aa.cohort_century::int AS cohort_century ,
        round(bb.rep_and_sen_5_yrs * 1.0 / aa.reps,
        4) AS pct_5_yrs ,
        round(bb.rep_and_sen_10_yrs * 1.0 / aa.reps,
        4) AS pct_10_yrs ,
        round(bb.rep_and_sen_15_yrs * 1.0 / aa.reps,
        4) AS pct_15_yrs
FROM 
    (SELECT date_part('century',a.first_term) AS cohort_century ,count(id_bioguide) AS reps
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY  1 ) a
        WHERE first_term <= '2009-12-31'
        GROUP BY  1 ) aa
    LEFT JOIN 
    (SELECT date_part('century',b.first_term) AS cohort_century ,count(distinct
        CASE
        WHEN age(c.term_start, b.first_term) <= interval '5 years' THEN
        b.id_bioguide end) AS rep_and_sen_5_yrs ,count(distinct
        CASE
        WHEN age(c.term_start, b.first_term) <= interval '10 years' THEN
        b.id_bioguide end) AS rep_and_sen_10_yrs ,count(distinct
        CASE
        WHEN age(c.term_start, b.first_term) <= interval '15 years' THEN
        b.id_bioguide end) AS rep_and_sen_15_yrs
    FROM 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        WHERE term_type = 'rep'
        GROUP BY  1 ) b
        JOIN legislators_terms c
            ON b.id_bioguide = c.id_bioguide
                AND c.term_type = 'sen'
                AND c.term_start > b.first_term
        GROUP BY  1 ) bb
        ON aa.cohort_century = bb.cohort_century ; ----------- Cumulative calculations ----------------------------------SELECT date_part('century',a.first_term)::int AS century ,first_type ,count(distinct a.id_bioguide) AS cohort ,count(b.term_start) AS terms
FROM 
    (SELECT DISTINCT id_bioguide ,
        first_value(term_type)
        OVER (partition by id_bioguide
    ORDER BY  term_start) AS first_type ,min(term_start)
        OVER (partition by id_bioguide) AS first_term ,min(term_start)
        OVER (partition by id_bioguide) + interval '10 years' AS first_plus_10
    FROM legislators_terms ) a
LEFT JOIN legislators_terms b
    ON a.id_bioguide = b.id_bioguide
        AND b.term_start
    BETWEEN a.first_term
        AND a.first_plus_10
GROUP BY  1,
        2 ;SELECT century ,
        max(case
    WHEN first_type = 'rep' THEN
    cohort end) AS rep_cohort ,max(case
    WHEN first_type = 'rep' THEN
    terms_per_leg end) AS avg_rep_terms ,max(case
    WHEN first_type = 'sen' THEN
    cohort end) AS sen_cohort ,max(case
    WHEN first_type = 'sen' THEN
    terms_per_leg end) AS avg_sen_terms
FROM 
    (SELECT date_part('century',a.first_term)::int AS century ,first_type ,count(distinct a.id_bioguide) AS cohort ,count(b.term_start) AS terms ,count(b.term_start) * 1.0 / count(distinct a.id_bioguide) AS terms_per_leg
    FROM 
        (SELECT DISTINCT id_bioguide ,
        first_value(term_type)
            OVER (partition by id_bioguide
        ORDER BY  term_start) AS first_type ,min(term_start)
            OVER (partition by id_bioguide) AS first_term ,min(term_start)
            OVER (partition by id_bioguide) + interval '10 years' AS first_plus_10
        FROM legislators_terms ) a
        LEFT JOIN legislators_terms b
            ON a.id_bioguide = b.id_bioguide
                AND b.term_start
            BETWEEN a.first_term
                AND a.first_plus_10
        GROUP BY  1,2 ) aa
    GROUP BY  1 ; ----------- Cross-section analysis,
WITH a cohort lens ----------------------------------SELECT b.date,
         count(distinct a.id_bioguide) AS legislators
FROM legislators_terms a
JOIN date_dim b
    ON b.date
    BETWEEN a.term_start
        AND a.term_end
        AND b.month_name = 'December'
        AND b.day_of_month = 31
        AND b.year <= 2019
GROUP BY  1 ;SELECT b.date ,
        date_part('century',first_term)::int AS century ,count(distinct a.id_bioguide) AS legislators
FROM legislators_terms a
JOIN date_dim b
    ON b.date
    BETWEEN a.term_start
        AND a.term_end
        AND b.month_name = 'December'
        AND b.day_of_month = 31
        AND b.year <= 2019
JOIN 
    (SELECT id_bioguide,
         min(term_start) AS first_term
    FROM legislators_terms
    GROUP BY  1 ) c
    ON a.id_bioguide = c.id_bioguide
GROUP BY  1,
        2 ;SELECT date ,
        century ,
        legislators ,
        sum(legislators)
    OVER (partition by date) AS cohort ,legislators * 100.0 / sum(legislators)
    OVER (partition by date) AS pct_century
FROM 
    (SELECT b.date ,
        date_part('century',first_term)::int AS century ,count(distinct a.id_bioguide) AS legislators
    FROM legislators_terms a
    JOIN date_dim b
        ON b.date
        BETWEEN a.term_start
            AND a.term_end
            AND b.month_name = 'December'
            AND b.day_of_month = 31
            AND b.year <= 2019
    JOIN 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        GROUP BY  1 ) c
            ON a.id_bioguide = c.id_bioguide
        GROUP BY  1,2 ) a
    ORDER BY  1,
        2 ;SELECT date ,
        coalesce(sum(case
        WHEN century = 18 THEN
        legislators end) * 100.0 / sum(legislators),0) AS pct_18 ,coalesce(sum(case
        WHEN century = 19 THEN
        legislators end) * 100.0 / sum(legislators),0) AS pct_19 ,coalesce(sum(case
        WHEN century = 20 THEN
        legislators end) * 100.0 / sum(legislators),0) AS pct_20 ,coalesce(sum(case
        WHEN century = 21 THEN
        legislators end) * 100.0 / sum(legislators),0) AS pct_21
FROM 
    (SELECT b.date ,
        date_part('century',first_term)::int AS century ,count(distinct a.id_bioguide) AS legislators
    FROM legislators_terms a
    JOIN date_dim b
        ON b.date
        BETWEEN a.term_start
            AND a.term_end
            AND b.month_name = 'December'
            AND b.day_of_month = 31
            AND b.year <= 2019
    JOIN 
        (SELECT id_bioguide,
         min(term_start) AS first_term
        FROM legislators_terms
        GROUP BY  1 ) c
            ON a.id_bioguide = c.id_bioguide
        GROUP BY  1,2 ) aa
    GROUP BY  1
ORDER BY  1 ;SELECT id_bioguide,
         date ,
        count(date)
    OVER (partition by id_bioguide
ORDER BY  date rows
    BETWEEN unbounded preceding
        AND current row) AS cume_years
FROM 
    (SELECT DISTINCT a.id_bioguide,
         b.date
    FROM legislators_terms a
    JOIN date_dim b
        ON b.date
        BETWEEN a.term_start
            AND a.term_end
            AND b.month_name = 'December'
            AND b.day_of_month = 31
            AND b.year <= 2019 ) a ;SELECT date,
         cume_years ,
        count(distinct id_bioguide) AS legislators
FROM 
    (SELECT id_bioguide,
         date ,
        count(date)
        OVER (partition by id_bioguide
    ORDER BY  date rows
        BETWEEN unbounded preceding
            AND current row) AS cume_years
    FROM 
        (SELECT DISTINCT a.id_bioguide,
         b.date
        FROM legislators_terms a
        JOIN date_dim b
            ON b.date
            BETWEEN a.term_start
                AND a.term_end
                AND b.month_name = 'December'
                AND b.day_of_month = 31
                AND b.year <= 2019
        GROUP BY  1,2 ) aa ) aaa
    GROUP BY  1,
        2 ;SELECT date,
         count(*) AS tenures
FROM 
    (SELECT date,
         cume_years ,
        count(distinct id_bioguide) AS legislators
    FROM 
        (SELECT id_bioguide,
         date ,
        count(date)
            OVER (partition by id_bioguide
        ORDER BY  date rows
            BETWEEN unbounded preceding
                AND current row) AS cume_years
        FROM 
            (SELECT DISTINCT a.id_bioguide,
         b.date
            FROM legislators_terms a
            JOIN date_dim b
                ON b.date
                BETWEEN a.term_start
                    AND a.term_end
                    AND b.month_name = 'December'
                    AND b.day_of_month = 31
                    AND b.year <= 2019
            GROUP BY  1,2 ) aa ) aaa
            GROUP BY  1,2 ) aaaa
        GROUP BY  1 ;SELECT date,
         tenure ,
        legislators * 100.0 / sum(legislators)
        OVER (partition by date) AS pct_legislators
FROM 
    (SELECT date ,
        case
        WHEN cume_years <= 4 THEN
        '1 to 4'
        WHEN cume_years <= 10 THEN
        '5 to 10'
        WHEN cume_years <= 20 THEN
        '11 to 20'
        ELSE '21+'
        END AS tenure ,count(distinct id_bioguide) AS legislators
    FROM 
        (SELECT id_bioguide,
         date ,
        count(date)
            OVER (partition by id_bioguide
        ORDER BY  date rows
            BETWEEN unbounded preceding
                AND current row) AS cume_years
        FROM 
            (SELECT DISTINCT a.id_bioguide,
         b.date
            FROM legislators_terms a
            JOIN date_dim b
                ON b.date
                BETWEEN a.term_start
                    AND a.term_end
                    AND b.month_name = 'December'
                    AND b.day_of_month = 31
                    AND b.year <= 2019
            GROUP BY  1,2 ) a ) aa
            GROUP BY  1,2 ) aaa ; 