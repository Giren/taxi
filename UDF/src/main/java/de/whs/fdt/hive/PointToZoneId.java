/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package de.whs.fdt.hive;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FSDataInputStream;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.hive.ql.exec.Description;
import org.apache.hadoop.hive.ql.exec.UDFArgumentException;
import org.apache.hadoop.hive.ql.exec.UDFArgumentTypeException;
import org.apache.hadoop.hive.ql.metadata.HiveException;
import org.apache.hadoop.hive.ql.udf.generic.GenericUDF;
import org.apache.hadoop.hive.serde2.io.DoubleWritable;
import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspector;
import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspector.Category;
import org.apache.hadoop.hive.serde2.objectinspector.ObjectInspectorConverters;
import org.apache.hadoop.hive.serde2.objectinspector.PrimitiveObjectInspector;
import org.apache.hadoop.hive.serde2.objectinspector.PrimitiveObjectInspector.PrimitiveCategory;
import org.apache.hadoop.hive.serde2.objectinspector.primitive.PrimitiveObjectInspectorFactory;
import org.apache.hadoop.hive.serde2.objectinspector.primitive.StringObjectInspector;

@Description(
        name = "getzone",
        value = "_FUNC_(double, double, string) - return zone id in NYC for given longitude and latitude",
        extended = "Example: \n"
        + " SELECT getzone(-73.822378, 40.640619, '/user/hue/zonemapping.csv') FROM taxi.data;"
)
public class PointToZoneId extends GenericUDF {

    private ObjectInspectorConverters.Converter[] converters;
    private StringObjectInspector fileLocation;
    private Map<Integer, ArrayList<Double>> zones;

    /**
     * Diese Funktion wird beim Überprüfen der Query Syntax ausgeführt.
     * Sie wird nicht beim Ausführen der Query ausgeführt, dafür exisitiert die  {@link #evaluate} Funktion.
     * 
     * @param args Typangaben der Übergabeparameter
     * @return Typ des Rückgabewerts
     * @throws UDFArgumentException 
     */
    @Override
    public ObjectInspector initialize(ObjectInspector[] args) throws UDFArgumentException {

        // die Funktion muss aus 3 Argumenten bestehen
        if (args.length != 3) {
            throw new UDFArgumentException("_FUNC_ must have 3 arguments!");
        }

        for (int i = 0; i < args.length; i++) {
            // alle Argumente müssen einen primitiven Datentyp aufweisen (keine Liste, Map, o.ä.)
            if (args[i].getCategory() != Category.PRIMITIVE) {
                throw new UDFArgumentTypeException(i,
                        "An argument of primitive type was expected but an argument of type " + args[i].getTypeName()
                        + " was given.");

            }

            // genauen Datentypen erhalten
            PrimitiveCategory primitiveCategory = ((PrimitiveObjectInspector) args[i])
                    .getPrimitiveCategory();

            // die ersten beiden Parameter müssen vom Typen DOUBLE sein (longitude und latitude)
            if ((primitiveCategory != PrimitiveCategory.DOUBLE) && (i == 0 || i == 1)) {
                throw new UDFArgumentTypeException(i,
                        "A double argument was expected but an argument of type " + args[i].getTypeName()
                        + " was given.");

            }
            
            // der dritte Parameter ist der Pfad zur der ZoneMapping-Datei, daher vom Typ STRING
            if((primitiveCategory != PrimitiveCategory.STRING) && (i == 2)) {
                throw new UDFArgumentTypeException(i,
                        "A string argument was expected but an argument of type " + args[i].getTypeName()
                        + " was given.");
            }
        }
        
        // konvertiere die ersten beiden Datentypen, damit sie als DoubleWritable behandelt werden können
        converters = new ObjectInspectorConverters.Converter[args.length-1];
        for (int i = 0; i < args.length-1; i++) {
            converters[i] = ObjectInspectorConverters.getConverter(args[i],
                PrimitiveObjectInspectorFactory.writableDoubleObjectInspector);
        }
        
        // konvertiere den dritten Parameter zu einem StringObjectInspecctor
        fileLocation = (StringObjectInspector)args[2];

        // der Rückgabewert ist vom Typen Integer
        return PrimitiveObjectInspectorFactory.javaIntObjectInspector;
    }

    /**
     * Diese Funktion wird für jeden Datensatz der Hive Query ausgeführt.
     * 
     * @param args Die Werte des aktuellen Datensatzes
     * @return zoneid
     * @throws HiveException 
     */
    @Override
    public Object evaluate(DeferredObject[] args) throws HiveException {
        // jeder Durchlauf muss 3 Parameter übergeben bekommen
        assert (args.length == 3);
        
        if (args[0].get() == null || args[1].get() == null || args[2].get() == null) {
            return null;
        }
        
        // dritter Übergabeparameter ist der Pfad zur ZoneMapping-Datei
        String zoneMappingFile = fileLocation.getPrimitiveJavaObject(args[2].get());
        
        setZonesMap(zoneMappingFile);

        // latitude und longitude aus Übergabeparameter extrahieren
        Double latitude = ((DoubleWritable) converters[0].convert(args[0].get())).get();
        Double longitude = ((DoubleWritable) converters[1].convert(args[1].get())).get();
        
        // standardmäßig ist die zoneID -1
        Integer zoneid = -1;
        
        // überprüfen, ob longitude und latitude innerhalb einer der deklariterten Zonen der ZoneMapping-Datei liegt
        for (Map.Entry<Integer, ArrayList<Double>> entry : zones.entrySet())
        {
            // wenn der Punkt in einer Zone liegt, extrahiere zoneID aus ZoneMapping-Datei
            if(pointInArea(latitude, longitude, entry.getValue())) {
                zoneid = entry.getKey();
                break;
            }
        }

        // gebe aktuelle zoneID zurück
        return zoneid;
    }

    /**
     * Diese Funktion gibt eine Beschreibung der Funktion zurück.
     * 
     * @param args 
     * @return Beschreibung der Funktion
     */
    @Override
    public String getDisplayString(String[] args) {
        assert (args.length == 3);
        return String.format("getzone(%s,%s,%s)", args[0], args[1], args[2]);
    }

    /**
     * Diese Funktion prüft, ob ein übergebener Punkt (gekennzeichnet durch Longitude und Latitude)
     * in einer Zone liegt, die in der ZoneMapping-Datei deklariert wurde.
     * 
     * @param latitude Latitude
     * @param longitude Longitude
     * @param area aktueller Eintrag in ZoneMapping-Datei (eine Zone)
     * @return Gibt true zurück, wenn der übergebene Punkt in der aktuellen Zone liegt.
     */
    private boolean pointInArea(Double latitude, Double longitude, ArrayList<Double> area) {
        Double topLeftLat = area.get(0);
        Double topLeftLon = area.get(1);

        Double botRightLat = area.get(2);
        Double botRightLon = area.get(3);
        
        // latitude between topLeftLat and botRightLat; longitude between topLeftLon and botRightLon
        return (topLeftLat >= latitude) && (botRightLat <= latitude) && (topLeftLon <= longitude) && (botRightLon >= longitude);
    }

    /**
     * Diese Funktion liest die ZoneMapping-Datei ein und speichert diese in einer HashMap
     * (gekennzeichnet durch &lt;zoneID,zone&gt;.
     * 
     * @param zoneMappingFile Pfad zur ZoneMapping-Datei (Übergabeparameter der UDF)
     * @throws HiveException 
     */
    private void setZonesMap(String zoneMappingFile) throws HiveException {
        // wenn die HashMap bereits deklariert wurde, überspringe Auslesen der Datei
        if(zones != null)
            return;
        
        zones = new HashMap<>();
        
        try {
            // Datei aus dem HDFS einlesen
            FileSystem fs = FileSystem.get(new Configuration());
            FSDataInputStream in = fs.open(new Path(zoneMappingFile));
            BufferedReader br = new BufferedReader(new InputStreamReader(in));

            // Header überspringen
            String line = br.readLine();
            
            // jede Zone einlesen (eine pro Zeile)
            while ((line = br.readLine()) != null) {
                String[] zone = line.split(",");
                
                Integer zoneid = Integer.parseInt(zone[0]);
                
                Double topLeftLat = Double.parseDouble(zone[1]);
                Double topLeftLon = Double.parseDouble(zone[2]);
                
                Double botRightLat = Double.parseDouble(zone[3]);
                Double botRightLon = Double.parseDouble(zone[4]);
                
                // füge obere linke und untere rechte Ecke der Zone einer ArrayList hinzu
                ArrayList<Double> area = new ArrayList<>();
                area.add(topLeftLat);
                area.add(topLeftLon);
                area.add(botRightLat);
                area.add(botRightLon);
                
                // Zone in HashMap eintragen
                zones.put(zoneid, area);
            }
            
            br.close();
        } catch (Exception e) {
            throw new HiveException("Error: cannot find zone mapping file " + zoneMappingFile + "!\n" + e.getMessage());
        }
    }
}
