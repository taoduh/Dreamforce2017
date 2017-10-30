@isTest
private class ETM_Batch_CopyShadowFields_Tests {

    @isTest
    static void executeMethodCopies()
    {
        // retrieve field map metadata
        Map<String, String> visibleFieldToShadowField = ETM_Utils.getCustomMetadataMap('Account_Visible_To_Shadow');

        // create test account
        Account a = new Account(Name = 'Test Me');
        for (String visibleField : visibleFieldToShadowField.keySet())
        {
            a.put(visibleField, getRandom());
        }
        // use required value. NOTE: something more elegant would be nice
        a.Account_Tier__c = 'Tier 1';
        insert a;

        Test.startTest();
        Database.executebatch(new ETM_Batch_CopyShadowFields(), 1);
        Test.stopTest();

        // TODO: create query builder method in batch class
        // build query of visible and shadow fields
        String visibleFields = String.join(new List<String>(visibleFieldToShadowField.keySet()), ', ');
        String shadowFields = String.join(visibleFieldToShadowField.values(), ', ');
        String soql = 'SELECT Id, ' + visibleFields + ', ' + shadowFields + ' FROM Account';
        Account afterBatch = (Account)Database.query(soql);

        // validate all were copied
        for (String visibleField : visibleFieldToShadowField.keySet())
        {
            String shadowField = visibleFieldToShadowField.get(visibleField);
            System.assertEquals(afterBatch.get(visibleField), afterBatch.get(shadowField));
        }
    }

    // TODO: move below to ETM_TestData
    public static String getRandom()
    {
        return getRandom(6);
    }

    public static String getRandom(Integer len)
    {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len)
        {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), 62);
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

}
