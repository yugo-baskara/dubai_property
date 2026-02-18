
-- =============== --
-- Create Database --
-- =============== --

create database if not exists portofolio;
use portofolio;


-- ========================= --
-- (Optional) Rerun Pipeline --
-- ========================= --

-- Optional: uncomment if you want to rerun the pipeline

drop view if exists portofolio.v_dubai_property_unit_only;
drop view if exists portofolio.v_dubai_property_with_flags;
drop table if exists portofolio.dubai_property_raw;
drop table if exists portofolio.dubai_property_clean;


-- ============ --
-- CREATE TABLE --
-- ============ --

create table portofolio.dubai_property_raw 
(
Type varchar(35),
Purpose varchar(35),
Furnishing varchar(35),
Price varchar(35),
Beds varchar(35),
Baths varchar(35),
Area_sqft varchar(35),
Address text
);


-- ======================= --
-- LOADING DATA INTO TABLE --
-- ======================= --

load data infile
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dubai_property.csv'
into table
portofolio.dubai_property_raw
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 rows
;

-- Windows line ending (\r\n)
-- path depends on local MySQL secure_file_priv configuration


-- ================== --
-- CREATE CLEAN TABLE --
-- ================== --

create table portofolio.dubai_property_clean as
select 
trim(Type) as Type,
trim(Purpose) as Purpose,
trim(Furnishing) as Furnishing,
cast(nullif(regexp_replace(price, '[^0-9.]', ''), '') as decimal(18,2)) as Price,
case
	when lower(Beds) like '%studio%' then 0
    else cast(nullif(regexp_replace(Beds, '[^0-9]',''), '') as unsigned)
end as Beds,
cast(nullif(regexp_replace(Baths, '[^0-9]', ''), '') as unsigned) as Baths,
cast(nullif(regexp_replace(Area_sqft, '[^0-9.]', ''), '') as decimal(10,2)) as Area_sqft,
trim(Address) as Address
from portofolio.dubai_property_raw
;

-- assumes dot (.) as decimal separator


-- ========== --
-- Data Check --
-- ========== --

select
	count(*) as total_rows,
    count(distinct Address) as distinct_address,
    min(price) as min_price,
    max(price) as max_price,
    min(Area_sqft) as min_area,
    max(Area_sqft) as max_area
from
	portofolio.dubai_property_clean
;


-- ========================================= --
-- Create Semantic View - Bulk Property Flag --
-- ========================================= --

create or replace view
	portofolio.v_dubai_property_with_flags as
select
	c.*,
case
	when lower(c.type) in ('residential building','residential floor')
    then 1
    else 0
	end as is_bulk_property
from
	portofolio.dubai_property_clean c
;


-- ====================================== --
-- Create Semantic View - Unit Level Only --
-- ====================================== --

create or replace view portofolio.v_dubai_property_unit_only as
select
	Type,
	Purpose,
	Furnishing,
	Price,
	Beds,
	Baths,
	Area_sqft,
	Address
from
	portofolio.v_dubai_property_with_flags
where
	is_bulk_property = 0
;


-- ================ --
-- Value Validation --
-- ================ --

select
	*
from
	portofolio.v_dubai_property_unit_only
where
	beds is null;


select
	*
from
	portofolio.v_dubai_property_with_flags
where
	baths is null;


-- ================================ --
-- Check Invalid and Missing Values --
-- ================================ --

select
	count(*) as total_rows,
    sum(case when Price is null then 1 else 0 end) as null_price,
    sum(case when Area_sqft is null then 1 else 0 end) as null_Area,
    sum(case when Beds is null then 1 else 0 end) as null_beds,
	sum(case when Baths is null then 1 else 0 end) as null_baths
from
	portofolio.dubai_property_clean
;


-- ============== --
-- View Unit Only --
-- ============== --

select
	*
from
	portofolio.v_dubai_property_unit_only
;


-- ============================ --
-- Check Invalid Price On Table --
-- ============================ --

select
	*
from
	portofolio.dubai_property_clean
where
	price <= 0 or price is null
;


-- ============================== --
-- Check Invalid Area On Property --
-- ============================== --

select
	*
from
	portofolio.dubai_property_clean
where
	Area_sqft <= 0 or Area_sqft is null
;


-- ====================== --
-- Average Price Property --
-- ====================== --

select
	Type,
    count(*) as total_listing,
    avg(price) as avg_price
from
	portofolio.dubai_property_clean
where
	Price is not null
group by
	Type
order by
	avg_price desc
;


-- ====================== --
-- Average Price Per Room --
-- ====================== --

select
	Beds,
	count(*) as total_listing,
	avg(price) as avg_price
from
	portofolio.v_dubai_property_unit_only
where
	Price is not null
    and
    Beds is not null
group by
	Beds
order by
	Beds
;


select
	Type,
	Beds
from
	portofolio.v_dubai_property_unit_only
where
	beds is null 
;


-- ============================ --
-- Price Sqft For Each Property --
-- ============================ --

select
	type,
    avg(Price/nullif(Area_sqft, 0)) as avg_price_sqft
from
	portofolio.v_dubai_property_unit_only
where
	Price is not null
	and Area_sqft is not null
	and Area_sqft > 0	
group by
	Type
order by
	avg_price_sqft desc
;


-- ================================ --
-- Furnishing Distribution VS Price --
-- ================================ --

select
	Furnishing,
	count(*) as total_listing,
    avg(Price) as avg_price
from
	portofolio.dubai_property_clean
where
	Price is not null
group by
	Furnishing
order by
	avg_price desc
;
