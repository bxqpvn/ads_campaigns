with ads as (
	select
		ad_date,
		url_parameters,
		fc.campaign_name,
		fa.adset_name,
		spend,
		impressions,
		reach,
		clicks,
		leads,
		value
from facebook_ads_basic_daily fabd 
	join facebook_adset fa 						-- JOIN
		on fabd.adset_id = fa.adset_id
	join facebook_campaign fc					-- JOIN
		on fabd.campaign_id = fc.campaign_id
union all 										-- UNION
	select
		ad_date,
		url_parameters,
		campaign_name,
		adset_name,
		spend,
		impressions,
		reach,
		clicks,
		leads,
		value
	from google_ads_basic_daily gabd
),
ads_campaings as ( 
	select
	ad_date,
	to_date(concat(extract(year from ad_date), '-', extract(month from ad_date)), 'YYYY-MM') as ad_month,	-- EXTRACT
	date_trunc('month', ad_date)::date as truncated_date,													-- date_trunct
 	sum(spend) as total_spend,	
	sum(impressions) as total_impressions,																	-- agg functions
	sum(reach) as total_each,
	sum(clicks) as total_clicks,
	sum(leads) as total_leads,
	sum(value) as total_value,
	case																									-- CASE
		when lower(substring(url_parameters, 'utm_campaign=([^\&]+)')) = 'nan' then null
		when lower(substring(url_parameters, 'utm_campaign=([^\&]*)')) = '' then null
		else lower(substring(url_parameters, 'utm_campaign=([^\&]+)'))
	end as utm_campaign,
	case 																									-- CASE
		when sum(clicks) > 0 then sum(spend)/sum(clicks)
	end as cpc,
	case 
		when sum(impressions) > 0 then round(sum(spend)::numeric/sum(impressions)*1000)
	end as cpm,
	case 
		when sum(impressions) > 0 then round(sum(clicks)::numeric/sum(impressions)*100, 2)
	end as ctr,
	case 
		when sum(spend) > 0 then round((sum(value)::numeric-sum(spend))/sum(spend)*100, 2)
	end as romi
from ads
where 
	spend > 0 and
	impressions > 0 and 
	clicks > 0
group by 
	ad_date, 
	url_parameters)
select
	ad_month,
	utm_campaign,
	round(avg(cpm), 2) as cpm,		-- CPM
	round(avg(ctr), 2) as ctr,		-- CTR
	round(avg(romi), 2) as romi,	-- ROMI
	round(avg(cpm)) - lag(round(avg(cpm)), 1) over (
		partition by utm_campaign
		order by ad_month) as cpm_diff,						-- diferenta CPM luna curenta - CPM luna anterioara
	round((round(avg(cpm)) - lag(round(avg(cpm)), 1) over (
		partition by utm_campaign
		order by ad_month
	))/ lag(round(avg(cpm)), 1) over (
		partition by utm_campaign
		order by ad_month) *100, 2) as cpm_diff_percent,	-- diferenta CPM luna curenta - CPM luna anterioara (exprimata in procente %)
	round(avg(ctr) - lag(avg(ctr), 1) over (
		partition by utm_campaign
		order by ad_month), 3) as ctr_dif,					-- diferenta CTR luna curenta - CTR luna anterioara
	round((avg(ctr) - lag(avg(ctr), 1) over (
		partition by utm_campaign
		order by ad_month
	))/ lag(avg(ctr), 1) over (
		partition by utm_campaign
		order by ad_month) *100, 2) as ctr_diff_percent,	-- diferenta CTR luna curenta - CTR luna anterioara (exprimata in procente %)
	round(avg(romi) - lag(avg(romi), 1) over (
		partition by utm_campaign
		order by ad_month), 3) as romi_diff,				-- diferenta ROMI luna curenta - ROMI luna anterioara
	round((avg(romi) - lag(avg(romi), 1) over (
		partition by utm_campaign
		order by ad_month
	))/ lag(avg(romi), 1) over(
		partition by utm_campaign
		order by ad_month)*100, 2) as romi_diff_percent		-- diferenta ROMI luna curenta - ROMI luna anterioara (exprimata in procente %)
from ads_campaings
group by ad_month, utm_campaign
order by ad_month;