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

    @Override
    public ObjectInspector initialize(ObjectInspector[] args) throws UDFArgumentException {

        if (args.length != 3) {
            throw new UDFArgumentException("_FUNC_ must have 3 arguments!");
        }

        for (int i = 0; i < args.length; i++) {
            if (args[i].getCategory() != Category.PRIMITIVE) {
                throw new UDFArgumentTypeException(i,
                        "An argument of primitive type was expected but an argument of type " + args[i].getTypeName()
                        + " was given.");

            }

            // Now that we have made sure that the argument is of primitive type, we can get the primitive category
            PrimitiveCategory primitiveCategory = ((PrimitiveObjectInspector) args[i])
                    .getPrimitiveCategory();

            if ((primitiveCategory != PrimitiveCategory.DOUBLE) && (i == 0 || i == 1)) {
                throw new UDFArgumentTypeException(i,
                        "A double argument was expected but an argument of type " + args[i].getTypeName()
                        + " was given.");

            }
            
            if((primitiveCategory != PrimitiveCategory.STRING) && (i == 2)) {
                throw new UDFArgumentTypeException(i,
                        "A string argument was expected but an argument of type " + args[i].getTypeName()
                        + " was given.");
            }
        }
        
        converters = new ObjectInspectorConverters.Converter[args.length-1];
        for (int i = 0; i < args.length-1; i++) {
            converters[i] = ObjectInspectorConverters.getConverter(args[i],
                PrimitiveObjectInspectorFactory.writableDoubleObjectInspector);
        }
        
        fileLocation = (StringObjectInspector)args[2];

        return PrimitiveObjectInspectorFactory.javaIntObjectInspector;
    }

    @Override
    public Object evaluate(DeferredObject[] args) throws HiveException {
        assert (args.length == 3);
        
        if (args[0].get() == null || args[1].get() == null || args[2].get() == null) {
            return null;
        }
        
        String zoneMappingFile = fileLocation.getPrimitiveJavaObject(args[2].get());
        
        setZonesMap(zoneMappingFile);

        Double latitude = ((DoubleWritable) converters[0].convert(args[0].get())).get();
        Double longitude = ((DoubleWritable) converters[1].convert(args[1].get())).get();
        
        Integer zoneid = -1;
        
        // see if longitude and latitude is in one of the declared zones in zoneMappingFile and get the zoneid
        for (Map.Entry<Integer, ArrayList<Double>> entry : zones.entrySet())
        {
            if(pointInArea(latitude, longitude, entry.getValue())) {
                zoneid = entry.getKey();
                break;
            }
        }

        return zoneid;
    }

    @Override
    public String getDisplayString(String[] args) {
        assert (args.length == 3);
        return String.format("getzone(%s,%s,%s)", args[0], args[1], args[2]);
    }

    private boolean pointInArea(Double latitude, Double longitude, ArrayList<Double> area) {
        Double topLeftLat = area.get(0);
        Double topLeftLon = area.get(1);

        Double botRightLat = area.get(2);
        Double botRightLon = area.get(3);
        
        // latitude between topLeftLat and botRightLat; longitude between topLeftLon and botRightLon
        return (topLeftLat >= latitude) && (botRightLat <= latitude) && (topLeftLon <= longitude) && (botRightLon >= longitude);
    }

    private void setZonesMap(String zoneMappingFile) throws HiveException {
        if(zones != null)
            return;
        
        zones = new HashMap<>();
        
        try {
            FileSystem fs = FileSystem.get(new Configuration());
            FSDataInputStream in = fs.open(new Path(zoneMappingFile));
            BufferedReader br = new BufferedReader(new InputStreamReader(in));

            // skip first line
            String line = br.readLine();
            
            // read zoneMappingFile
            while ((line = br.readLine()) != null) {
                String[] zone = line.split(",");
                
                Integer zoneid = Integer.parseInt(zone[0]);
                
                Double topLeftLat = Double.parseDouble(zone[1]);
                Double topLeftLon = Double.parseDouble(zone[2]);
                
                Double botRightLat = Double.parseDouble(zone[3]);
                Double botRightLon = Double.parseDouble(zone[4]);
                
                ArrayList<Double> area = new ArrayList<>();
                area.add(topLeftLat);
                area.add(topLeftLon);
                area.add(botRightLat);
                area.add(botRightLon);
                
                zones.put(zoneid, area);
            }
            
            br.close();
        } catch (Exception e) {
            throw new HiveException("Error: cannot find zone mapping file " + zoneMappingFile + "!\n" + e.getMessage());
        }
    }
}
