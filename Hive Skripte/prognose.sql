add jar s3://de.whs.fdb.taxi/libs/FDTTaxiData.jar;

create temporary function getzone as 'de.whs.fdt.hive.PointToZoneId';


CREATE TABLE IF NOT EXISTS taxi.data_prog_final (
    zone_id INT,
    year INT,
    month INT,
    weekofyear INT,
    dayOfWeek INT,
    hourOfDay INT,
    count BIGINT
);


FROM (
    SELECT
        getzone(pickup_latitude, pickup_longitude, '/user/taxi/zonemapping.csv') AS area,
        year(pickup_datetime) AS y,
        month(pickup_datetime) AS m,
        weekofyear(pickup_datetime) AS w,
        from_unixtime(unix_timestamp(pickup_datetime,'yyyy-MM-dd hh:mm:ss'),'u') AS d,
        hour(pickup_datetime) AS h
    FROM
        taxi.taxi_data
) area_jfk

INSERT INTO
    TABLE taxi.data_prog_final
SELECT
    area,  y, m, w, d, h, count(*) AS count
WHERE
    area != -1
GROUP BY
    area, y, m, w, d, h;
