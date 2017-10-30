trigger ETM_Account on Account (before insert, before update) {

    List<Account> postalCodesToConvert = new List<Account>();

    // collect new postal code values
    for (Account rec : Trigger.new)
    {
        if (Trigger.isInsert)
        {
            if (!String.isBlank(rec.BillingPostalCode))
            {
                postalCodesToConvert.add(rec);
            }
        }
        else if (Trigger.isUpdate)
        {
            if (String.isBlank(rec.BillingPostalCode) && rec.BillingPostalCode != Trigger.oldMap.get(rec.Id).BillingPostalCode)
            {
                postalCodesToConvert.add(rec);
            }
        }
    }

    // extract the numbers in the new values
    for (Account rec : postalCodesToConvert)
    {
        rec.ETM_Postal_Code_Numbers__c = ETM_AccountsService.firstNumbersInString(rec.BillingPostalCode);
    }


    // copy ETM logical rule values from lookup table using postal code values
    Set<String> postalCodes = ETM_Utils.getSetOfStrings(postalCodesToConvert, 'BillingPostalCode');
    if (Trigger.isInsert && postalCodes.size() > 0)
    {
        // group accounts by postal code
        Map<String, List<Account>> postalCodeToAccounts = new Map<String, List<Account>>();
        for (Account rec : Trigger.new)
        {
            if (String.isBlank(rec.BillingPostalCode)) continue;

            if (!postalCodeToAccounts.containsKey(rec.BillingPostalCode))
            {
                postalCodeToAccounts.put(rec.BillingPostalCode, new List<Account>());
            }
            postalCodeToAccounts.get(rec.BillingPostalCode).add(rec);
        }

        // retrieve rule values
        List<ETM_Rule_Value__c> allRuleValues =
            [SELECT Id, Territory_Model_Name__c, Postal_Code__c, Rule_Logical_Value__c
                FROM ETM_Rule_Value__c
                WHERE Postal_Code__c IN :postalCodes];

        // group rule values by postal code
        Map<String, List<ETM_Rule_Value__c>> postalCodeToRuleValues = new Map<String, List<ETM_Rule_Value__c>>();
        for (ETM_Rule_Value__c val : allRuleValues)
        {
            if (!postalCodeToRuleValues.containsKey(val.Postal_Code__c))
            {
                postalCodeToRuleValues.put(val.Postal_Code__c, new List<ETM_Rule_Value__c>());
            }
            postalCodeToRuleValues.get(val.Postal_Code__c).add(val);
        }

        // retrieve list of model names to account target fields
        Map<String, String> modelNameToAccountField = ETM_Utils.getCustomMetadataMap('Model_Name_To_Account_Field');

        // update account field values
        for (String postalCode : postalCodeToAccounts.keySet())
        {
            List<Account> affectedAccounts = postalCodeToAccounts.get(postalCode);
            List<ETM_Rule_Value__c> ruleValues = postalCodeToRuleValues.get(postalCode);

            for (ETM_Rule_Value__c val : ruleValues)
            {
                String modelName = val.Territory_Model_Name__c;
                String logicalValue = val.Rule_Logical_Value__c;
                if (String.isBlank(modelName) || !modelNameToAccountField.containsKey(modelName)) continue;
                String accountField = modelNameToAccountField.get(modelName);

                for (Account rec : affectedAccounts)
                {
                    rec.put(accountField, logicalValue);
                }
            }
        }
    }

}