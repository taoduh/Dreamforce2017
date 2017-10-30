global with sharing class ETM_Batch_CopyShadowFields implements Database.Batchable<sObject> {

    public ETM_Batch_CopyShadowFields() { }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        Map<String, String> visibleFieldToShadowField = ETM_AccountsService.getVisibleFieldToShadowFieldMap();

        String visibleFields = String.join(new List<String>(visibleFieldToShadowField.keySet()), ', ');
        String shadowFields = String.join(visibleFieldToShadowField.values(), ', ');

        String soql = 'SELECT Id, ' +
            visibleFields + ', ' +
            shadowFields +
            ' FROM Account';

        return Database.getQueryLocator(soql);
    }

    // NOTE: this logic will only work for like types
    // you may want to use schema to verify that or try/catch it
    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        for (Account a : (List<Account>)scope)
        {
            ETM_AccountsService.updateAccountShadowFields(a);
        }

        update scope;
    }

    global void finish(Database.BatchableContext bc) { }

}
