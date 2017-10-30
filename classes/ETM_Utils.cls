public with sharing class ETM_Utils {

    public static Set<Id> getSetOfIds(List<Sobject> records, String fieldName)
    {
        Set<Id> valueSet = new Set<Id>();
        for (Sobject rec : records)
        {
            if (rec.get(fieldName) != null) valueSet.add((Id)rec.get(fieldName));
        }

        return valueSet;
    }

    public static Set<String> getSetOfStrings(List<Sobject> records, String fieldName)
    {
        Set<String> valueSet = new Set<String>();
        for (Sobject rec : records)
        {
            if (rec.get(fieldName) != null) valueSet.add((String)rec.get(fieldName));
        }

        return valueSet;
    }

    public static Map<Id, Set<Id>> getMapOfIdToIds(List<Sobject> objs, String keyFieldName, String valueFieldName)
    {
        Map<Id, Set<Id>> m = new Map<Id, Set<Id>>();
        for (Sobject so : objs)
            if (so.get(keyFieldName) != null && so.get(valueFieldName) != null)
            {
                Id keyVal = (Id)so.get(keyFieldName);
                if (!m.containsKey(keyVal))
                    m.put(keyVal, new Set<Id>());
                m.get(keyVal).add((Id)so.get(valueFieldName));
            }

        return m;
    }

    public static Map<String, String> getCustomMetadataMap(String developerName)
    {
        Map<String, String> params = new Map<String, String>();

        List<ETM_Parameters__mdt> paramList =
            [SELECT Id, MasterLabel, DeveloperName, Value__c, Description__c
            FROM ETM_Parameters__mdt
            WHERE DeveloperName = :developerName];

        if (paramList.size() > 0)
        {
            Matcher matched = pattern.compile('(.+?):\\s*(.+?)(?:\\r*\\n|$)').matcher(paramList.get(0).Value__c);

            while (matched.find())
            {
                params.put(matched.group(1).trim(), matched.group(2).trim());
            }
        }

        return params;
    }

    public static String getDeepValueFromObject(Sobject rec, List<String> deepFieldList)
    {
        for (Integer i = 0; i < deepFieldList.size(); i++)
        {
            if (i == deepFieldList.size() - 1)
            {
                return (String)rec.get(deepFieldList.get(i));
            }
            else
            {
                rec = rec.getSobject(deepFieldList.get(i));
                if (rec == null) return null;
            }
        }
        return null;
    }

}
