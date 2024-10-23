# Campaigns v1

In this script, marketing campaigns from Facebook and Google Ads are analyzed by performing aggregations and calculations to determine key metrics such as total spend, impressions, clicks, and campaign value. Formulas are also applied to calculate cost per click (CPC), cost per thousand impressions (CPM), click-through rate (CTR), and return on marketing investment (ROMI).
- SUM function: Used to aggregate spend, impressions, clicks, and other metrics by day and by campaign.
- CASE function: Applied to handle special values and calculate indicators such as CPC and ROMI, based on specific conditions.
- EXTRACT and DATE_TRUNC functions: Utilize dates to extract and truncate to the month level, aiding in aggregation over time periods.


# Campaigns v2

The script in campaigns v2.sql continues the campaign analysis, applying a series of calculations and percentage differences over time to assess the evolution of CPM, CTR, and ROMI. Functions are included to compare campaign performance over different periods.
- LAG function: Used to compare CPM, CTR, and ROMI values from one month to the previous month, calculating percentage differences.
- ROUND function: Ensures that calculated values, such as CPM, CTR, and ROMI, are rounded for easier interpretation.
- PARTITION BY function: Organizes data by UTM campaign to compute monthly variations at the campaign level.
