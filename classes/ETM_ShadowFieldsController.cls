public with sharing class ETM_ShadowFieldsController {

    @AuraEnabled
    public static String updateOneAccount(String strAccountId)
    {
        Id accountId;
        try
        {
            accountId = (Id)strAccountId;
        }
        catch (Exception e)
        {
            return e.getMessage();
        }

        Account a = ETM_AccountsService.hydrateAccount(accountId);
        if (a == null)
        {
            return 'Account ' + accountId + ' not found';
        }

        ETM_AccountsService.updateAccountShadowFields(a);
        update a;

        return 'success';
    }

    @AuraEnabled
    public static String updateAllAccounts()
    {
        Database.executebatch(new ETM_Batch_CopyShadowFields());

        return 'success';
    }

}
