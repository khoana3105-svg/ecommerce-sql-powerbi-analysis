# E-commerce Sales Analysis — SQL Server & Power BI

**Nguyễn Anh Khoa** · [Tiếng Việt](README.md)

I am learning basic SQL with a multi-table synthetic sales database. I focus on SELECT, WHERE, GROUP BY, HAVING and JOIN, and on understanding order, product and customer summaries. The Kaggle sales notebook is a workflow reference only; this project uses different data and results.

AI helped prepare the Power BI data model, DAX, export scripts and automated checks. These are learning resources, not claims of independent advanced proficiency. The Power BI dashboard is not finished. See [learning and contribution notes](docs/LEARNING_AND_CONTRIBUTIONS.md).

The database has 31 tables, 360 orders, 1,000 order lines, 400 products and 70 accounts. An eligible order must be paid/shipped/delivered with a completed payment. Currency is unspecified; figures are not real business impact.

## Verified baseline

250 eligible orders, 66 purchasing customers, SalesValue 61,041.13, TotalBilled 70,317.71, item gross 61,632.94 and 56 repeat purchasers in the full observed window. SalesValue excludes order discounts but precedes tax/shipping; item gross precedes order discounts. Partial refunds are not allocated. No cost data supports profit calculation.

Run `sql/01_tao_va_nap.sql` once in SSMS to create the isolated `EcommerceSalesPortfolio` database, then `02_thuc_hanh.sql` and `03_powerbi_views.sql`. Source tables are protected against accidental reload; no existing practice database is overwritten.

## Power BI handoff

[Five input tables](powerbi/data), [measures](powerbi/measures.dax), [product-label column](powerbi/columns.dax), [build guide](powerbi/BUILD_GUIDE.md) and [expected unfiltered KPIs](powerbi/validation.json) are supplied. These are build-ready inputs and instructions, **not an executed PBIX or finished Power BI dashboard**. Build two pages: order-level overview and item-level product mix. Single-direction relationships intentionally prevent product filtering from silently changing order-level revenue.

## Quality and interpretation

108 orders precede account creation, 56 cancelled/refunded orders have completed payment and 22 orders have no items. Keep these anomalies visible; do not infer real customer cohorts, retention or marketing effects. The source header states synthetic data and CC0-1.0; publisher identity and license attribution have not been independently verified.

See [metric definitions](docs/METRIC_DEFINITIONS.md), [validation](docs/VALIDATION.md) and [upload/CV guide](docs/UPLOAD_AND_CV.md). The author should rerun and explain each query before describing independent SQL proficiency.
