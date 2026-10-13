
USE ab_testing_project;

SHOW TABLES;

USE ab_testing_project;

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE orders;
TRUNCATE TABLE sessions;
TRUNCATE TABLE experiment_assignments;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;


USE ab_testing_project;

INSERT INTO users (
    user_id,
    signup_date,
    country,
    device_type
)
SELECT
    n,
    DATE_ADD(
        '2025-01-01',
        INTERVAL MOD(CRC32(CONCAT('signup', n)), 365) DAY
    ),
    CASE MOD(CRC32(CONCAT('country', n)), 5)
        WHEN 0 THEN 'US'
        WHEN 1 THEN 'UK'
        WHEN 2 THEN 'Canada'
        WHEN 3 THEN 'India'
        ELSE 'Australia'
    END,
    CASE MOD(CRC32(CONCAT('device', n)), 3)
        WHEN 0 THEN 'desktop'
        WHEN 1 THEN 'mobile'
        ELSE 'tablet'
    END
FROM (
    SELECT
        1 + d0.n + 10 * d1.n
          + 100 * d2.n + 1000 * d3.n AS n
    FROM
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL
         SELECT 4 UNION ALL SELECT 5 UNION ALL
         SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d0
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL
         SELECT 4 UNION ALL SELECT 5 UNION ALL
         SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d1
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL
         SELECT 4 UNION ALL SELECT 5 UNION ALL
         SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d2
    CROSS JOIN
        (SELECT 0 n UNION ALL SELECT 1 UNION ALL
         SELECT 2 UNION ALL SELECT 3 UNION ALL
         SELECT 4 UNION ALL SELECT 5 UNION ALL
         SELECT 6 UNION ALL SELECT 7 UNION ALL
         SELECT 8 UNION ALL SELECT 9) d3
) numbers
WHERE n <= 2000;


USE ab_testing_project;

INSERT INTO experiment_assignments (
    user_id,
    experiment_id,
    variant,
    assigned_at
)
SELECT
    user_id,
    'checkout_redesign_01',
    CASE
        WHEN MOD(
            CRC32(CONCAT('assignment', user_id)), 2
        ) = 0 THEN 'A'
        ELSE 'B'
    END,
    DATE_ADD(
        '2026-06-01 00:00:00',
        INTERVAL MOD(
            CRC32(CONCAT('assignment_date', user_id)), 30
        ) DAY
    )
FROM users;

SELECT COUNT(*) AS total_users FROM users;

SELECT variant, COUNT(*) AS assigned_users
FROM experiment_assignments
GROUP BY variant;


USE ab_testing_project;

INSERT INTO sessions (
    user_id,
    session_date,
    device_type
)
SELECT
    u.user_id,
    DATE_ADD(
        a.assigned_at,
        INTERVAL (
            s.session_num
            + MOD(
                CRC32(
                    CONCAT(
                        'session_day',
                        u.user_id,
                        s.session_num
                    )
                ),
                10
            )
        ) DAY
    ),
    CASE MOD(
        CRC32(
            CONCAT(
                'session_device',
                u.user_id,
                s.session_num
            )
        ),
        3
    )
        WHEN 0 THEN 'desktop'
        WHEN 1 THEN 'mobile'
        ELSE 'tablet'
    END
FROM users u
JOIN experiment_assignments a
    ON u.user_id = a.user_id
CROSS JOIN (
    SELECT 1 AS session_num
    UNION ALL SELECT 2
    UNION ALL SELECT 3
    UNION ALL SELECT 4
    UNION ALL SELECT 5
) s
WHERE MOD(
    CRC32(
        CONCAT('session', u.user_id, s.session_num)
    ),
    5
) < CASE
    WHEN s.session_num = 1 THEN 5
    ELSE 3
END;

SELECT
    COUNT(*) AS total_sessions,
    COUNT(DISTINCT user_id) AS users_with_sessions,
    MIN(session_date) AS first_session,
    MAX(session_date) AS last_session
FROM sessions;


USE ab_testing_project;

INSERT INTO orders (
    user_id,
    order_date,
    revenue,
    order_status
)
SELECT
    u.user_id,
    DATE_ADD(
        a.assigned_at,
        INTERVAL (
            1 + MOD(
                CRC32(
                    CONCAT(
                        'order_day',
                        u.user_id,
                        o.order_num
                    )
                ),
                14
            )
        ) DAY
    ),
    ROUND(
        25
        + MOD(
            CRC32(
                CONCAT(
                    'order_revenue',
                    u.user_id,
                    o.order_num
                )
            ),
            276
        )
        + MOD(
            CRC32(
                CONCAT(
                    'order_cents',
                    u.user_id,
                    o.order_num
                )
            ),
            100
        ) / 100,
        2
    ),
    CASE
        WHEN MOD(
            CRC32(
                CONCAT(
                    'order_status',
                    u.user_id,
                    o.order_num
                )
            ),
            100
        ) < 8 THEN 'cancelled'
        WHEN MOD(
            CRC32(
                CONCAT(
                    'order_status',
                    u.user_id,
                    o.order_num
                )
            ),
            100
        ) < 13 THEN 'refunded'
        ELSE 'completed'
    END
FROM users u
JOIN experiment_assignments a
    ON u.user_id = a.user_id
CROSS JOIN (
    SELECT 1 AS order_num
    UNION ALL SELECT 2
    UNION ALL SELECT 3
) o
WHERE
    (
        o.order_num = 1
        AND MOD(
            CRC32(CONCAT('purchase', u.user_id)),
            100
        ) < CASE
            WHEN a.variant = 'A' THEN 13
            ELSE 16
        END
    )
    OR
    (
        o.order_num = 2
        AND MOD(
            CRC32(CONCAT('repeat2', u.user_id)),
            100
        ) < 20
    )
    OR
    (
        o.order_num = 3
        AND MOD(
            CRC32(CONCAT('repeat3', u.user_id)),
            100
        ) < 8
    );


SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(SUM(revenue), 2) AS recorded_revenue
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

SELECT
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM experiment_assignments)
        AS total_assignments,
    (SELECT COUNT(*) FROM sessions) AS total_sessions,
    (SELECT COUNT(*) FROM orders) AS total_orders;
    
USE ab_testing_project;

SELECT
    experiment_id,
    variant,
    COUNT(*) AS assigned_users,
    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (PARTITION BY experiment_id),
        2
    ) AS assignment_percentage
FROM experiment_assignments
GROUP BY experiment_id, variant
ORDER BY experiment_id, variant;

SELECT
    user_id,
    experiment_id,
    COUNT(*) AS assignment_count
FROM experiment_assignments
GROUP BY user_id, experiment_id
HAVING COUNT(*) > 1;

SELECT
    COUNT(*) AS orders_before_assignment
FROM orders o
JOIN experiment_assignments a
    ON o.user_id = a.user_id
   AND a.experiment_id = 'checkout_redesign_01'
WHERE o.order_date < a.assigned_at;

SELECT
    order_status,
    COUNT(*) AS order_count,
    SUM(revenue < 0) AS negative_revenue_orders,
    SUM(revenue IS NULL) AS missing_revenue_orders,
    ROUND(SUM(revenue), 2) AS recorded_revenue
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

SELECT
    a.variant,
    COUNT(DISTINCT a.user_id) AS assigned_users,
    COUNT(DISTINCT s.user_id) AS users_with_sessions,
    COUNT(s.session_id) AS total_sessions,
    ROUND(
        COUNT(s.session_id) /
        NULLIF(COUNT(DISTINCT a.user_id), 0),
        2
    ) AS sessions_per_assigned_user
FROM experiment_assignments a
LEFT JOIN sessions s
    ON a.user_id = s.user_id
WHERE a.experiment_id = 'checkout_redesign_01'
GROUP BY a.variant
ORDER BY a.variant;


USE ab_testing_project;

WITH user_metrics AS (
    SELECT
        a.user_id,
        a.variant,
        MAX(
            CASE
                WHEN o.order_status = 'completed'
                THEN 1
                ELSE 0
            END
        ) AS converted,
        COALESCE(
            SUM(
                CASE
                    WHEN o.order_status = 'completed'
                    THEN o.revenue
                    ELSE 0
                END
            ),
            0
        ) AS completed_revenue,
        COUNT(
            CASE
                WHEN o.order_status = 'completed'
                THEN o.order_id
            END
        ) AS completed_orders
    FROM experiment_assignments a
    LEFT JOIN orders o
        ON a.user_id = o.user_id
       AND o.order_date >= a.assigned_at
    WHERE a.experiment_id = 'checkout_redesign_01'
    GROUP BY a.user_id, a.variant
)
SELECT
    variant,
    COUNT(*) AS assigned_users,
    SUM(converted) AS converted_users,
    ROUND(
        100.0 * SUM(converted) / COUNT(*),
        2
    ) AS conversion_rate_pct,
    ROUND(AVG(completed_revenue), 2)
        AS revenue_per_assigned_user,
    ROUND(
        SUM(completed_revenue) /
        NULLIF(SUM(completed_orders), 0),
        2
    ) AS average_order_value
FROM user_metrics
GROUP BY variant
ORDER BY variant;


WITH user_metrics AS (
    SELECT
        a.user_id,
        a.variant,
        MAX(
            CASE WHEN o.order_status = 'completed'
                 THEN 1 ELSE 0 END
        ) AS converted
    FROM experiment_assignments a
    LEFT JOIN orders o
        ON a.user_id = o.user_id
       AND o.order_date >= a.assigned_at
    WHERE a.experiment_id = 'checkout_redesign_01'
    GROUP BY a.user_id, a.variant
),
variant_metrics AS (
    SELECT
        variant,
        COUNT(*) AS assigned_users,
        AVG(converted) AS conversion_rate
    FROM user_metrics
    GROUP BY variant
)
SELECT
    MAX(CASE WHEN variant = 'A'
        THEN assigned_users END) AS control_users,
    MAX(CASE WHEN variant = 'B'
        THEN assigned_users END) AS treatment_users,
    ROUND(
        100 * MAX(CASE WHEN variant = 'A'
            THEN conversion_rate END),
        2
    ) AS control_conversion_pct,
    ROUND(
        100 * MAX(CASE WHEN variant = 'B'
            THEN conversion_rate END),
        2
    ) AS treatment_conversion_pct,
    ROUND(
        100 * (
            MAX(CASE WHEN variant = 'B'
                THEN conversion_rate END)
            -
            MAX(CASE WHEN variant = 'A'
                THEN conversion_rate END)
        ),
        2
    ) AS absolute_lift_percentage_points,
    ROUND(
        100 * (
            MAX(CASE WHEN variant = 'B'
                THEN conversion_rate END)
            /
            NULLIF(
                MAX(CASE WHEN variant = 'A'
                    THEN conversion_rate END),
                0
            ) - 1
        ),
        2
    ) AS relative_lift_pct
FROM variant_metrics;


USE ab_testing_project;

WITH user_conversions AS (
    SELECT
        a.user_id,
        a.variant,
        MAX(
            CASE
                WHEN o.order_status = 'completed'
                THEN 1
                ELSE 0
            END
        ) AS converted
    FROM experiment_assignments a
    LEFT JOIN orders o
        ON a.user_id = o.user_id
       AND o.order_date >= a.assigned_at
    WHERE a.experiment_id = 'checkout_redesign_01'
    GROUP BY a.user_id, a.variant
),
group_stats AS (
    SELECT
        variant,
        COUNT(*) AS n,
        SUM(converted) AS conversions,
        AVG(converted) AS p
    FROM user_conversions
    GROUP BY variant
),
pivot_stats AS (
    SELECT
        MAX(CASE WHEN variant = 'A' THEN n END) AS n_a,
        MAX(CASE WHEN variant = 'B' THEN n END) AS n_b,
        MAX(CASE WHEN variant = 'A'
            THEN conversions END) AS x_a,
        MAX(CASE WHEN variant = 'B'
            THEN conversions END) AS x_b,
        MAX(CASE WHEN variant = 'A' THEN p END) AS p_a,
        MAX(CASE WHEN variant = 'B' THEN p END) AS p_b
    FROM group_stats
),
test_stats AS (
    SELECT *,
        p_b - p_a AS difference,
        (x_a + x_b) / (n_a + n_b) AS pooled_p
    FROM pivot_stats
)
SELECT
    n_a AS control_users,
    x_a AS control_conversions,
    n_b AS treatment_users,
    x_b AS treatment_conversions,

    ROUND(100 * p_a, 2) AS control_rate_pct,
    ROUND(100 * p_b, 2) AS treatment_rate_pct,

    ROUND(100 * difference, 2)
        AS lift_percentage_points,

    ROUND(
        100 * difference / NULLIF(p_a, 0),
        2
    ) AS relative_lift_pct,

    ROUND(
        100 * (
            difference
            - 1.96 * SQRT(
                p_a * (1 - p_a) / n_a
                + p_b * (1 - p_b) / n_b
            )
        ),
        2
    ) AS ci_95_lower_pp,

    ROUND(
        100 * (
            difference
            + 1.96 * SQRT(
                p_a * (1 - p_a) / n_a
                + p_b * (1 - p_b) / n_b
            )
        ),
        2
    ) AS ci_95_upper_pp,

    ROUND(
        difference / SQRT(
            pooled_p * (1 - pooled_p)
            * (1.0 / n_a + 1.0 / n_b)
        ),
        3
    ) AS z_statistic

FROM test_stats;
