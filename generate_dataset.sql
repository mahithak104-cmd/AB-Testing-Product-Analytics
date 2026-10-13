
USE ab_testing_project;

WITH user_conversions AS (
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
),
z_stats AS (
    SELECT *,
        difference / SQRT(
            pooled_p * (1 - pooled_p)
            * (1.0 / n_a + 1.0 / n_b)
        ) AS z_statistic
    FROM test_stats
),
p_value_stats AS (
    SELECT *,
        1.0 / (
            1.0 + 0.2316419 * ABS(z_statistic)
        ) AS t
    FROM z_stats
)
SELECT
    n_a AS control_users,
    x_a AS control_conversions,
    n_b AS treatment_users,
    x_b AS treatment_conversions,

    ROUND(100 * p_a, 2) AS control_conversion_pct,
    ROUND(100 * p_b, 2) AS treatment_conversion_pct,
    ROUND(100 * difference, 2) AS absolute_lift_pp,

    ROUND(
        100 * difference / NULLIF(p_a, 0), 2
    ) AS relative_lift_pct,

    ROUND(
        100 * (
            difference - 1.96 * SQRT(
                p_a * (1 - p_a) / n_a
                + p_b * (1 - p_b) / n_b
            )
        ), 2
    ) AS ci_95_lower_pp,

    ROUND(
        100 * (
            difference + 1.96 * SQRT(
                p_a * (1 - p_a) / n_a
                + p_b * (1 - p_b) / n_b
            )
        ), 2
    ) AS ci_95_upper_pp,

    ROUND(z_statistic, 4) AS z_statistic,

    ROUND(
        2 * EXP(-0.5 * POW(z_statistic, 2))
        / SQRT(2 * PI())
        * (
            0.319381530 * t
            - 0.356563782 * POW(t, 2)
            + 1.781477937 * POW(t, 3)
            - 1.821255978 * POW(t, 4)
            + 1.330274429 * POW(t, 5)
        ),
        4
    ) AS two_sided_p_value

FROM p_value_stats;


USE ab_testing_project;

WITH user_order_metrics AS (
    SELECT
        a.user_id,
        a.variant,

        MAX(
            CASE WHEN o.order_status = 'completed'
                 THEN 1 ELSE 0 END
        ) AS completed_converter,

        SUM(
            CASE WHEN o.order_status = 'completed'
                 THEN o.revenue ELSE 0 END
        ) AS completed_revenue,

        SUM(
            CASE WHEN o.order_status = 'completed'
                 THEN 1 ELSE 0 END
        ) AS completed_orders,

        SUM(
            CASE WHEN o.order_status = 'cancelled'
                 THEN 1 ELSE 0 END
        ) AS cancelled_orders,

        SUM(
            CASE WHEN o.order_status = 'refunded'
                 THEN 1 ELSE 0 END
        ) AS refunded_orders,

        MAX(
            CASE WHEN o.order_status = 'cancelled'
                 THEN 1 ELSE 0 END
        ) AS user_cancelled,

        MAX(
            CASE WHEN o.order_status = 'refunded'
                 THEN 1 ELSE 0 END
        ) AS user_refunded,

        COUNT(o.order_id) AS total_orders

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

    SUM(completed_converter) AS converted_users,

    ROUND(
        100.0 * SUM(completed_converter) / COUNT(*),
        2
    ) AS conversion_rate_pct,

    ROUND(
        SUM(completed_revenue) / COUNT(*),
        2
    ) AS revenue_per_assigned_user,

    ROUND(
        SUM(completed_revenue)
        / NULLIF(SUM(completed_orders), 0),
        2
    ) AS average_completed_order_value,

    SUM(total_orders) AS total_orders,
    SUM(completed_orders) AS completed_orders,
    SUM(cancelled_orders) AS cancelled_orders,
    SUM(refunded_orders) AS refunded_orders,

    ROUND(
        100.0 * SUM(cancelled_orders)
        / NULLIF(SUM(total_orders), 0),
        2
    ) AS cancellation_rate_pct,

    ROUND(
        100.0 * SUM(refunded_orders)
        / NULLIF(SUM(total_orders), 0),
        2
    ) AS refund_rate_pct,

    SUM(user_cancelled) AS users_with_cancellations,
    SUM(user_refunded) AS users_with_refunds

FROM user_order_metrics
GROUP BY variant
ORDER BY variant;


SELECT
    a.variant,
    o.order_status,
    COUNT(*) AS order_count,
    ROUND(SUM(o.revenue), 2) AS recorded_revenue
FROM experiment_assignments a
JOIN orders o
    ON a.user_id = o.user_id
   AND o.order_date >= a.assigned_at
WHERE a.experiment_id = 'checkout_redesign_01'
GROUP BY a.variant, o.order_status
ORDER BY a.variant, o.order_status;


USE ab_testing_project;

WITH order_summary AS (
    SELECT
        a.variant,
        COUNT(o.order_id) AS total_orders,
        SUM(o.order_status = 'completed') AS completed_orders,
        SUM(o.order_status = 'cancelled') AS cancelled_orders,
        SUM(o.order_status = 'refunded') AS refunded_orders
    FROM experiment_assignments a
    LEFT JOIN orders o
        ON a.user_id = o.user_id
       AND o.order_date >= a.assigned_at
    WHERE a.experiment_id = 'checkout_redesign_01'
    GROUP BY a.variant
)
SELECT
    variant,
    total_orders,
    completed_orders,
    cancelled_orders,
    refunded_orders,
    ROUND(
        100.0 * cancelled_orders /
        NULLIF(total_orders, 0),
        2
    ) AS cancellation_rate_pct,
    ROUND(
        100.0 * refunded_orders /
        NULLIF(total_orders, 0),
        2
    ) AS refund_rate_pct
FROM order_summary
ORDER BY variant;

