global with sharing class ETM_Batch_UpdateTerritoryValues implements Database.Batchable<sObject>, Database.Stateful {

    // TODO: move to metadata
    private static Map<String, String> territoryFieldToAccountField = new Map<String, String>{
        'Name' => 'ETM_Territory__c',
        'Parent.Name' => 'ETM_District__c',
        'Parent.Parent.Name' => 'ETM_Region__c'
    };

    global Set<Id> updatedAccountIds;

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        String queryFields = String.join(territoryFieldToAccountField.values(), ', ');
        String soql = 'SELECT Id, ' + queryFields + ' FROM Account';
        return Database.getQueryLocator(soql);
    }

    global void execute(Database.BatchableContext bc, List<sObject> accounts)
    {
        List<Territory2Model> activeModels = [SELECT Id from Territory2Model where State = 'Active'];
        if (activeModels.size() == 0) return;
        Id activeModelId = activeModels.get(0).Id;

        // retrieve territory associations related to accounts
        Set<Id> accountIds = ETM_Utils.getSetOfIds(accounts, 'Id');
        String associationSoql = buildAssociationSoql(activeModelId, accountIds);
        List<ObjectTerritory2Association> associationList = (List<ObjectTerritory2Association>)Database.query(associationSoql);

        // NOTE: if you have more than one territory associated with an account, filter here for the one you want
        Map<Id, ObjectTerritory2Association> accountIdToTerritoryAssociation = new Map<Id, ObjectTerritory2Association>();
        for (ObjectTerritory2Association assoc : associationList)
        {
            accountIdToTerritoryAssociation.put(assoc.ObjectId, assoc);
        }

        List<Account> accountsWithNewTerritory = new List<Account>();
        Map<Id, Id> accountIdToUpdatedTerritoryId = new Map<Id, Id>();

        for (Account a : (List<Account>)accounts)
        {
            // determine if territory association has changed
            // if it has, update the account values
            Boolean associationUpdated = false;
            ObjectTerritory2Association association = accountIdToTerritoryAssociation.get(a.Id);
            Territory2 associatedTerritory = (association == null ? null : association.Territory2);
            associationUpdated = updateIfChanged(a, associatedTerritory);

            // add updated rows to collections
            if (associationUpdated)
            {
                accountsWithNewTerritory.add(a);
                accountIdToUpdatedTerritoryId.put(a.Id, (association == null ? null : association.Territory2Id));
            }
        }

        if (accountsWithNewTerritory.size() > 0)
        {
            Database.update(accountsWithNewTerritory, false);
        }

        // NOTE: this is here so that unit tests which call execute directly work
        if (updatedAccountIds == null) updatedAccountIds = new Set<Id>();

        if (accountIdToUpdatedTerritoryId.size() > 0)
            updatedAccountIds.addAll(accountIdToUpdatedTerritoryId.keyset());
    }

    global void finish(Database.BatchableContext bc) {
        if (updatedAccountIds != null && updatedAccountIds.size() > 0)
            ETM_PriceAgreementsService.recalculateAccountTerrritoryChanges(updatedAccountIds);
    }


    private Boolean updateIfChanged(Account account, Territory2 territory)
    {
        Boolean associationUpdated = false;

        for (String territoryField : territoryFieldToAccountField.keySet())
        {
            String territoryFieldValue = ETM_Utils.getDeepValueFromObject(territory, territoryField.split('\\.'));
            // NOTE: thought about null vs '' but decided the first time the record will
            // be updated to '' and that's fine
            if (account.get(territoryFieldToAccountField.get(territoryField)) != territoryFieldValue)
            {
                associationUpdated = true;
            }
        }

        if (associationUpdated)
        {
            for (String territoryField : territoryFieldToAccountField.keySet())
            {
                String territoryFieldValue = ETM_Utils.getDeepValueFromObject(territory, territoryField.split('\\.'));
                account.put(territoryFieldToAccountField.get(territoryField), territoryFieldValue);
            }
        }

        return associationUpdated;
    }

    private String buildAssociationSoql(Id activeModelId, Set<Id> accountIds)
    {
        // list of fields to query
        List<String> t2Fields = new List<String>();
        for (String s : territoryFieldToAccountField.keySet())
        {
            t2Fields.add('Territory2.' + s);
        }
        String queryFields = String.join(t2Fields, ', ');

        return 'SELECT Id, AssociationCause, ObjectId, Territory2Id, ' +
                queryFields +
             'FROM ObjectTerritory2Association ' +
             'WHERE Territory2.Territory2ModelID = :activeModelId ' +
             'AND Territory2Id != null ' +
             'AND ObjectId IN :accountIds';
    }

}
