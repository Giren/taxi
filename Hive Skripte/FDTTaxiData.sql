DROP FUNCTION IF EXISTS getzone;
CREATE FUNCTION getzone AS 'de.whs.fdt.hive.PointToZoneId' USING JAR 's3://de.whs.fdb.taxi/libs/FDTTaxiData.jar';

DROP TABLE IF EXISTS taxi.data_prog_month;
DROP TABLE IF EXISTS taxi.data_prog_dayOfMonth;
DROP TABLE IF EXISTS taxi.data_prog_dayOfWeek;
DROP TABLE IF EXISTS taxi.data_prog_hourOfDayOfWeek;

CREATE TABLE taxi.data_prog_month (
    zone_id INT,
    year INT,
    month INT,
    count BIGINT
);

CREATE TABLE taxi.data_prog_dayOfMonth (
    zone_id INT,
    year INT,
    month INT,
    day INT,
    count BIGINT
);

CREATE TABLE taxi.data_prog_dayOfWeek (
    zone_id INT,
    year INT,
    month INT,
    dayOfWeek INT,
    count BIGINT
);

CREATE TABLE taxi.data_prog_hourOfDayOfWeek(
    zone_id INT,
    year INT,
    month INT,
    dayOfWeek INT,
    hourOfDay INT,
    count BIGINT
);


FROM (
    SELECT year(pickup_datetime) AS y, month(pickup_datetime) AS m,  getzone(pickup_latitude, pickup_longitude, '/user/taxi/zonemapping.csv') AS area
    FROM taxi.taxi_data
) area_jfk
INSERT INTO TABLE taxi.data_prog_month
SELECT area,  y, m, count(*) AS count
WHERE area != -1
GROUP BY area, y, m;


FROM (
    SELECT year(pickup_datetime) AS y, month(pickup_datetime) AS m, dayofmonth(pickup_datetime) AS d,  getzone(pickup_latitude, pickup_longitude, '/user/taxi/zonemapping.csv') AS area
    FROM taxi.taxi_data
) area_jfk
INSERT INTO TABLE taxi.data_prog_dayOfMonth
SELECT area,  y, m, d, count(*) AS count
WHERE area != -1
GROUP BY area, y, m, d;


FROM (
    SELECT year(pickup_datetime) AS y, month(pickup_datetime) AS m, from_unixtime(unix_timestamp(pickup_datetime,'yyyy-MM-dd hh:mm:ss'),'u') AS d,  getzone(pickup_latitude, pickup_longitude, '/user/taxi/zonemapping.csv') AS area
    FROM taxi.taxi_data
) area_jfk
INSERT INTO TABLE taxi.data_prog_dayOfWeek
SELECT area,  y, m, d, count(*) AS count
WHERE area != -1
GROUP BY area, y, m, d;


FROM (
    SELECT year(pickup_datetime) AS y, month(pickup_datetime) AS m, from_unixtime(unix_timestamp(pickup_datetime,'yyyy-MM-dd hh:mm:ss'),'u') AS d, hour(pickup_datetime) AS h,  getzone(pickup_latitude, pickup_longitude, '/user/taxi/zonemapping.csv') AS area
    FROM taxi.taxi_data
) area_jfk
INSERT INTO TABLE taxi.data_prog_hourOfDayOfWeek
SELECT area,  y, m, d, h, count(*) AS count
WHERE area != -1
GROUP BY area, y, m, d, h;
