CREATE OR REPLACE FUNCTION pg_temp.decode_url_part3(p varchar) RETURNS varchar AS $$
SELECT convert_from(CAST(E'\\x' || array_to_string(ARRAY(
    SELECT CASE WHEN length(r.m[1]) = 1 THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex') ELSE substring(r.m[1] from 2 for 2) END
    FROM regexp_matches($1, '%[0-9a-f][0-9a-f]|.', 'gi') AS r(m)
), '') AS bytea), 'UTF8');
$$ LANGUAGE SQL IMMUTABLE STRICT;


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
	join facebook_adset fa                     -- JOIN
		on fabd.adset_id = fa.adset_id
	join facebook_campaign fc                  -- JOIN
		on fabd.campaign_id = fc.campaign_id
union all                                      -- UNION
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
ads_2 as ( 
	select
	ad_date,
	to_date(concat(extract(year from ad_date), '-', extract(month from ad_date)), 'YYYY-MM') as ad_month,	-- extragem luna cu EXTRACT
	date_trunc('month', ad_date)::date as truncated_date,													-- date_trunc
 	sum(spend) as total_spend,							--
	sum(impressions) as total_impressions,				--	functie
	sum(reach) as total_each,							--	  de
	sum(clicks) as total_clicks,						--	agregare
	sum(leads) as total_leads,							--
	sum(value) as total_value,							--	 sum()
	case
		when lower(substring(url_parameters, 'utm_campaign=([^\&]+)')) = 'nan' then null	-- CASE
		when lower(substring(url_parameters, 'utm_campaign=([^\&]*)')) = '' then null		
		else decode_url_part3((lower(substring(url_parameters, 'utm_campaign=([^\&]+)'))))	-- decode_url_part3
	end as utm_campaign,
	case 
		when sum(clicks) > 0 then sum(spend)/sum(clicks)
	end as cpc,																				-- CPC
	case 
		when sum(impressions) > 0 then round(sum(spend)::numeric/sum(impressions)*1000)
	end as cpm,																				-- CPM
	case 
		when sum(impressions) > 0 then round(sum(clicks)::numeric/sum(impressions)*100, 2)
	end as ctr,																				-- CTR
	case
		when sum(spend) > 0 then round((sum(value)::numeric-sum(spend))/sum(spend)*100, 2)
	end as romi																				-- ROMI
from ads
where 
	spend > 0 and
	impressions > 0 and 
	clicks > 0
group by 
	ad_date, 
	url_parameters
),
ads_campaings as (
select
	ad_month,
	utm_campaign,
	sum(total_spend) as total_spend,
	sum(total_impressions) as total_impressions,
	sum(total_clicks) as total_clicks,
	sum(total_value) as total_value,
	round(avg(cpc), 2) as cpc,
	round(avg(cpm), 2) as cpm,
	round(avg(ctr), 2) as ctr,
	round(avg(romi), 2) as romi
from ads_2
group by ad_month, utm_campaign
order by ad_month)
select 
	ad_month,
	utm_campaign,
	/*total_spend,
	total_impressions,
	total_clicks,
	total_value,
	cpc,*/
	cpm,
	ctr,
	romi,
	round((cpm - lag(cpm, 1) over (					--- lag function
		partition by utm_campaign
		order by ad_month
	))/ lag(cpm, 1) over (
		partition by utm_campaign
		order by ad_month) *100, 2) as cpm_diff,
	round((ctr - lag(ctr, 1) over (
		partition by utm_campaign
		order by ad_month
	))/ lag(ctr, 1) over (
		partition by utm_campaign
		order by ad_month) *100, 2) as ctr_diff,
	round((romi - lag(romi, 1) over (
		partition by utm_campaign
		order by ad_month
	))/ lag(romi, 1) over(
		partition by utm_campaign
		order by ad_month)*100, 2) as romi_diff
from ads_campaings
order by
	ad_month,
	utm_campaign;