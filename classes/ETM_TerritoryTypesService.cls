public with sharing class ETM_TerritoryTypesService {

    public static String TYPE_TERRITORY = 'Territory';
    public static String TYPE_DISTRICT = 'District';
    public static String TYPE_REGION = 'Region';

    private static List<Territory2Type> territoryTypes;

    public static Id pickT2TypeIdFromList(String typeName)
    {
        retrieveTypes();

        for (Territory2Type type : territoryTypes)
            if (type.DeveloperName == typeName) return type.Id;
        return null;
    }

    public static String pickT2TypeFromList(Id typeId)
    {
        retrieveTypes();

        for (Territory2Type type : territoryTypes)
            if (type.Id == typeId) return type.DeveloperName;
        return null;
    }

    private static void retrieveTypes()
    {
        if (territoryTypes == null)
        {
            Set<String> knownTypes = new Set<String> { TYPE_TERRITORY, TYPE_DISTRICT, TYPE_REGION };
            territoryTypes = [SELECT Id, DeveloperName FROM Territory2Type WHERE DeveloperName IN :knownTypes];
        }
    }

}
