create database postcodelottery;
create extension postgis;


-- 
create table rural_urban (
	OA11CD character (9),
	RUC11CD character (2),
	RUC11 character varying (60),
	BOUND_CHGIND character varying (10),
	ASSIGN_CHGIND character varying (10),
	ASSIGN_CHREASON character varying (20)
);


-- 
copy rural_urban from 'C:\Development\LibrariesHacked\tutorial-postcodelottery\data\rural_urban_classifications.csv' csv header;


-- 
create table postcodes (
	postcode character varying (10),
	positional_quality integer,
	easting integer,
	northing integer,
	code1 character varying (9),
	code2 character varying (9),
	code3 character varying (9),
	code4 character varying (9),
	code5 character varying (9),
	code6 character varying (9)
);


--
copy postcodes from 'C:\Development\LibrariesHacked\tutorial-postcodelottery\data\postcodes.csv' csv;


-- 
copy (select postcode, easting, northing from postcodes where code1 = 'E92000001') to 'C:\Development\LibrariesHacked\tutorial-postcodelottery\data\england_postcodes.csv' csv header;


-- 
create table england_postcodes (
	postcode character varying (10),
	easting integer,
	northing integer
);


-- 
copy england_postcodes from 'C:\Development\LibrariesHacked\tutorial-postcodelottery\data\england_postcodes.csv' csv header;


-- 
select AddGeometryColumn ('public', 'england_postcodes', 'geom', 27700, 'POINT', 2);


-- 
update england_postcodes
set geom = st_setsrid(st_makepoint(easting, northing), 27700);


-- 
create index gix_englandpostcodes_geom ON england_postcodes USING GIST (geom);


-- 
create table libraries (
	name character varying (100),
	lng float,
	lat float
);


--
copy libraries from 'C:\Development\LibrariesHacked\tutorial-postcodelottery\data\libraries.csv' csv header;


-- 
select AddGeometryColumn ('public', 'libraries', 'geom', 27700, 'POINT', 2);

-- 
update libraries
set geom = st_transform(st_setsrid(st_makepoint(lng, lat), 4326), 27700);


-- 
create index gix_libraries_geom ON libraries USING GIST (geom);


-- After loading OAs
select UpdateGeometrySRID('oas', 'geom', 27700);


-- Index 
create index gix_oas_geom ON oas USING GIST (geom);


-- 
copy(select
	postcode,
	urban_code,
	ntile(7) over (partition by urban_code order by distance) as grade
from 
	(select 
	 	p.postcode as postcode,
	 	ru.RUC11CD as urban_code,
	 	(select st_distance(l.geom, p.geom) as distance from libraries l order by distance asc limit 1) as distance
	from england_postcodes p
	join oas o on st_within(p.geom, o.geom)
	join rural_urban ru on ru.OA11CD = o.oa11cd) as ranking
order by postcode, urban_code, grade) to 'C:\Development\LibrariesHacked\tutorial-postcodelottery\data\lottery.csv' csv header;