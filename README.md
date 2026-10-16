# A/B Testing & Product Experimentation Analytics Using MySQL

## Project Overview

This project analyzes a hypothetical A/B test for a checkout page redesign using MySQL. The objective is to evaluate whether the redesigned checkout experience (Variant B) improves user conversion compared with the existing checkout experience (Variant A), while monitoring revenue and order-quality metrics.

The project demonstrates how SQL can be used to generate experiment data, validate data quality, calculate key performance indicators (KPIs), conduct statistical analysis, and translate results into actionable product recommendations.

## Business Problem

A product team wants to determine whether a redesigned checkout experience improves the purchase conversion rate without negatively affecting revenue or order quality.

The analysis addresses the following questions:

- Does Variant B improve conversion compared with Variant A?
- Is the observed conversion lift statistically significant?
- How does revenue per assigned user differ between variants?
- Are cancellation and refund rates within acceptable guardrails?
- Should the redesigned checkout experience be rolled out?

## Tools & Technologies

- **Database:** MySQL 8.0+
- **SQL:** Data definition, data generation, joins, aggregations, CTEs, and statistical calculations
- **Analytics:** Conversion rate, absolute lift, relative lift, revenue metrics, confidence intervals, and p-values
- **Data Quality:** Duplicate checks, assignment balance, order validation, and revenue checks
- **Version Control:** Git and GitHub

## Dataset

The project uses synthetically generated data across four relational tables:

| Table | Description |
|---|---|
| `users` | User-level information |
| `experiment_assignments` | Experiment assignment and variant |
| `sessions` | User session activity |
| `orders` | Order status and revenue |

The dataset contains approximately 2,000 users, 2,000 experiment assignments, 6,820 sessions, and 869 orders.

**Note:** The data is synthetic and is intended for demonstrating experimentation analytics rather than representing a real company's results.

## Methodology

1. **Database Design:** Created relational tables with appropriate keys and relationships.
2. **Data Generation:** Generated synthetic users, experiment assignments, sessions, and orders.
3. **Data Quality Validation:** Checked assignment balance, duplicate records, order timing, and revenue validity.
4. **Experiment Metrics:** Calculated conversion rates, absolute lift, relative lift, and revenue metrics.
5. **Statistical Analysis:** Evaluated the conversion difference using a hypothesis test, p-value, and 95% confidence interval.
6. **Revenue Guardrails:** Compared order completion, cancellation, and refund rates across variants.
7. **Business Recommendation:** Combined conversion, statistical evidence, and guardrail metrics to assess the redesign.

## Key Results

| Metric | Variant A | Variant B |
|---|---:|---:|
| Assigned users | 999 | 1,001 |
| Converted users | 322 | 343 |
| Conversion rate | 32.23% | 34.27% |
| Revenue per assigned user | $54.70 | $62.17 |
| Average completed order value | $154.81 | $158.35 |
| Cancellation rate | 7.75% | 9.43% |
| Refund rate | 6.78% | 4.39% |

### Conversion Analysis

- **Absolute conversion lift:** Approximately +2.04 percentage points.
- **Relative conversion lift:** Approximately +6.33%.
- **Statistical significance:** The estimated two-sided p-value is approximately 0.334, above the conventional 0.05 significance threshold.

Although Variant B has a higher observed conversion rate, the available synthetic sample does not provide sufficient statistical evidence to conclude that the redesign improves conversion.

### Revenue and Order Guardrails

Variant B shows higher revenue per assigned user and a higher average completed order value in this dataset. It also has a lower order-level refund rate but a higher order-level cancellation rate.

These metrics should be interpreted together rather than relying on conversion rate alone. Revenue figures should not be interpreted as net revenue after refunds because refund amounts are not separately recorded in the dataset.

## Business Recommendation

**Recommendation: Continue testing before making a full rollout decision.**

Variant B shows promising directional results, including a higher observed conversion rate and higher revenue per assigned user. However, the conversion difference is not statistically significant at the 5% level, and the cancellation rate is higher for Variant B.

A follow-up experiment with a larger sample size and a predefined test duration would help determine whether the observed differences are reliable. The product team should also investigate cancellations and define clear revenue and order-quality guardrails before rollout.

## Repository Structure

```text
ab-testing-product-analytics/
├── sql/
│   ├── 01_create_schema.sql
│   ├── 02_generate_dataset.sql
│   ├── 03_data_quality.sql
│   ├── 04_experiment_metrics.sql
│   ├── 05_statistical_analysis.sql
│   └── 06_revenue_guardrails.sql
├── README.md
└── .gitignore
```

## Connect with Me

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://www.linkedin.com/in/mahitha-kalinathabotla/)
