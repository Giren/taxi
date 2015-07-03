add jar /home/hadoop/libs/esri-geometry-api.jar;
add jar /home/hadoop/libs/spatial-sdk-hadoop.jar;

create temporary function ST_Bin as 'com.esri.hadoop.hive.ST_Bin';
create temporary function ST_Point as 'com.esri.hadoop.hive.ST_Point';
create temporary function ST_BinEnvelope as 'com.esri.hadoop.hive.ST_BinEnvelope';

CREATE TABLE taxi.data_agg(area BINARY, count DOUBLE)
ROW FORMAT SERDE 'com.esri.hadoop.hive.serde.JsonSerde'
STORED AS INPUTFORMAT 'com.esri.json.hadoop.EnclosedJsonInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat';

FROM (
    SELECT
        ST_Bin(0.001, ST_Point(dropoff_longitude,dropoff_latitude)) bin_id, 
        year(dropoff_datetime) AS y,
        month(dropoff_datetime) AS m
    FROM
        taxi.taxi_data
    WHERE
        (dropoff_longitude BETWEEN -74.255 AND -73.7) AND (dropoff_latitude BETWEEN 40.495 AND 40.92)
) bins
INSERT OVERWRITE TABLE taxi.data_agg
SELECT
    ST_BinEnvelope(0.001, bin_id) shape, y, m,
    COUNT(*) count
GROUP BY bin_id, y, m;
