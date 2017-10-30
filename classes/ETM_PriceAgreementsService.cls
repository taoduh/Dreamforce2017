global with sharing class ETM_PriceAgreementsService {

    public static void recalculateAccountTerrritoryChanges(Set<Id> accountIds)
    {
        List<ETM_Price_Agreement_Account__c> priceAssociations = [SELECT Id, ETM_Price_Agreement__c FROM ETM_Price_Agreement_Account__c WHERE Account__c IN :accountIds];
        Set<Id> agreementIds = ETM_Utils.getSetOfIds(priceAssociations, 'ETM_Price_Agreement__c');
        List<ETM_Price_Agreement__c> affectedAgreements = [SELECT Id FROM ETM_Price_Agreement__c WHERE Id IN :agreementIds];

        recalculateAgreementShares(affectedAgreements);
    }

    public static void recalculateAgreementAccountChanges(List<ETM_Price_Agreement_Account__c> priceAssociations)
    {
        Set<Id> agreementIds = ETM_Utils.getSetOfIds(priceAssociations, 'ETM_Price_Agreement__c');
        List<ETM_Price_Agreement__c> affectedAgreements = [SELECT Id FROM ETM_Price_Agreement__c WHERE Id IN :agreementIds];

        recalculateAgreementShares(affectedAgreements);
    }

    public static void recalculateUserTerritoryChanges(Set<Id> territoryIds)
    {
        // query for associated territories and any territories below those in the hierarchy
        List<Territory2> allTerritories = [SELECT Id, Name FROM Territory2 WHERE ParentTerritory2Id IN :territoryIds OR ParentTerritory2.ParentTerritory2Id IN :territoryIds];
        Set<Id> childTerritoryIds = ETM_Utils.getSetOfIds(allTerritories, 'Id');
        territoryIds.addAll(childTerritoryIds);

        // Retrieve the accounts associated to the above territories
        List<ObjectTerritory2Association> associatedObjectterritories = [SELECT Id, ObjectId FROM ObjectTerritory2Association WHERE Territory2Id IN :territoryIds];
        Set<Id> accountIds = ETM_Utils.getSetOfIds(associatedObjectterritories, 'objectId');

        // Retrieve the agreement account links associated to the above accounts
        List<ETM_Price_Agreement_Account__c> affectedAgreementLinks = [SELECT Id, ETM_Price_Agreement__c FROM ETM_Price_Agreement_Account__c WHERE Account__c IN :accountIds];
        List<ETM_Price_Agreement__c> affectedAgreements = [SELECT Id FROM ETM_Price_Agreement__c WHERE Id IN :ETM_Utils.getSetOfIds(affectedAgreementLinks, 'ETM_Price_Agreement__c')];

        // in the real world, we have to batch user changes to avoid MIXED_DML errors
        // in a test context that is handled with runAs()
        Boolean forceBatch = !Test.isRunningTest();

        recalculateAgreementShares(affectedAgreements, forceBatch);
    }

    public static void recalculateTerritory2Changes(List<Id> territoryIds)
    {
        // Retrieve the account associated to the above territories.
        List<ObjectTerritory2Association> associatedObjectterritories = [SELECT Id FROM ObjectTerritory2Association WHERE Territory2Id IN :new Set<Id>(territoryIds)];
        Set<Id> accountIds = ETM_Utils.getSetOfIds(associatedObjectterritories, 'ObjectId');

        // Retrieve the agreement account links associated to the above accounts.
        List<ETM_Price_Agreement_Account__c> affectedAgreementLinks = [SELECT Id, ETM_Price_Agreement__c FROM ETM_Price_Agreement_Account__c WHERE Account__c IN :accountIds];
        List<ETM_Price_Agreement__c> affectedAgreements = [SELECT Id FROM ETM_Price_Agreement__c WHERE Id IN :ETM_Utils.getSetOfIds(affectedAgreementLinks, 'ETM_Price_Agreement__c')];

        // in the real world, we have to batch user changes to avoid MIXED_DML errors
        // in a test context that is handled with runAs()
        Boolean forceBatch = !Test.isRunningTest();

        recalculateAgreementShares(affectedAgreements, forceBatch);
    }

    @testVisible
    private static void recalculateAgreementShares(List<ETM_Price_Agreement__c> affectedAgreements)
    {
        if (affectedAgreements.size() == 0) return;

        // with this few of records, no need to batch it up
        // just call execute method and do it in real-time
        Boolean forceBatch = (!Test.isRunningTest() && affectedAgreements.size() > getAgreementsBatchSize());

        recalculateAgreementShares(affectedAgreements, forceBatch);
    }

    private static void recalculateAgreementShares(List<ETM_Price_Agreement__c> affectedAgreements, Boolean forceBatch)
    {
        if (affectedAgreements.size() == 0) return;

        Set<Id> agreementIds = ETM_Utils.getSetOfIds(affectedAgreements, 'Id');

        if (forceBatch)
        {
            Database.executeBatch(new ETM_Batch_AgreementShares(agreementIds), getAgreementsBatchSize());
        }
        else
        {
            ETM_Batch_AgreementShares shareRecalculater = new ETM_Batch_AgreementShares(agreementIds);
            shareRecalculater.execute(null, affectedAgreements);
        }
    }

    private static Integer getAgreementsBatchSize()
    {
        Integer batchSize = 100; // default value

        // TODO: retrieve from config if you like

        return batchSize;
    }

}
