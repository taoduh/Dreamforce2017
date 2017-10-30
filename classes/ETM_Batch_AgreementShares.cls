global class ETM_Batch_AgreementShares implements Database.Batchable<sObject> {

    private Set<Id> agreementIds;

    public ETM_Batch_AgreementShares(Set<Id> agreementIds)
    {
        this.agreementIds = agreementIds;
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return Database.getQueryLocator([SELECT Id FROM ETM_Price_Agreement__c WHERE Id IN :agreementIds]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> affectedAgreements)
    {
        if (affectedAgreements.size() == 0) return;

        Set<Id> batchAgreementIds = ETM_Utils.getSetOfIds(affectedAgreements, 'Id');

        // work our way up from agreements to users that need shares
        Map<Id, Set<Id>> agreementIdToUserIds = mapAgreementsToRelatedUsers(batchAgreementIds);

        // get existing shares on agreements
        List<ETM_Price_Agreement__Share> extantShares = [SELECT Id FROM ETM_Price_Agreement__Share WHERE ParentId IN :batchAgreementIds AND RowCause = 'Manual'];
        // map agreement->user from existing share records
        Map<Id, Set<Id>> existingAgreementIdToUserIds = ETM_Utils.getMapOfIdToIds(extantShares, 'parentId', 'UserorGroupId');

        // compare agreementIdToUserIds with existingAgreementIdToUserIds
        for (Id agreementId : agreementIdToUserIds.keySet())
        {
            if (existingAgreementIdToUserIds.get(agreementId) == null || existingAgreementIdToUserIds.get(agreementId).size() == 0)
                continue;

            Set<Id> usersWhoWillHaveShares = new Set<Id>(agreementIdToUserIds.get(agreementId));

            // Remove the existing users from the to-be users
            // what remains will be added
            agreementIdToUserIds.get(agreementId).removeAll(existingAgreementIdToUserIds.get(agreementId));

            // Remove the to-be users from the old set
            // what remains will be deleted
            existingAgreementIdToUserIds.get(agreementId).removeAll(usersWhoWillHaveShares);
        }

        removeSharingPermissions(existingAgreementIdToUserIds);
        addSharingPermissions(agreementIdToUserIds);
    }

    global void finish(Database.BatchableContext bc) { }

    // using agreement->account assocations, account->territory assignments, and
    // user->territory assignements, figure out which users should get shares with
    // which agreements
    private Map<Id, Set<Id>> mapAgreementsToRelatedUsers(Set<Id> batchAgreementIds)
    {
        // query for agreement->account associations
        List<ETM_Price_Agreement_Account__c> agreementLinks = [SELECT Id, Account__c FROM ETM_Price_Agreement_Account__c WHERE ETM_Price_Agreement__c IN :batchAgreementIds];
        Set<Id> accountIds = ETM_Utils.getSetOfIds(agreementLinks, 'Account__c');
        Map<Id, Set<Id>> agreementIdToAccountIds = ETM_Utils.getMapOfIdToIds(agreementLinks, 'Agreements__c', 'Account__c');
        // query for account->territory associations
        List<ObjectTerritory2Association> territoryLinks = [SELECT Id, Territory2Id FROM ObjectTerritory2Association WHERE ObjectId IN :accountIds];
        Set<Id> leafTerritoryIds = ETM_Utils.getSetOfIds(territoryLinks, 'Territory2Id');
        Map<Id, Set<Id>> accountIdToTerritoryIds = ETM_Utils.getMapOfIdToIds(territoryLinks, 'ObjectId', 'Territory2Id');

        // query for all parent nodes in territory hierarchy
        Map<Id, Set<Id>> territoryLeafIdToParentIds = new Map<Id, Set<Id>>();
        List<Territory2> leafNodes = [SELECT Id, ParentTerritory2Id, ParentTerritory2.ParentTerritory2Id FROM Territory2 WHERE Id IN :leafTerritoryIds AND Territory2Model.State = 'Active'];
        for (Territory2 t : leafNodes)
        {
            territoryLeafIdToParentIds.put(t.Id, new Set<Id>());
            if (t.ParentTerritory2Id != null) territoryLeafIdToParentIds.get(t.Id).add(t.ParentTerritory2Id);
            if (t.ParentTerritory2.ParentTerritory2Id != null) territoryLeafIdToParentIds.get(t.Id).add(t.ParentTerritory2.ParentTerritory2Id);
        }

        // add parent territories to account->territory associations
        for (Id accountId : accountIdToTerritoryIds.keySet())
        {
            if (!accountIdToTerritoryIds.containsKey(accountId)) continue;

            Set<Id> parentTerritoryIds = new Set<Id>();
            for (Id leafId : accountIdToTerritoryIds.get(accountId))
                if (territoryLeafIdToParentIds.containsKey(leafId))
                    parentTerritoryIds.addAll(territoryLeafIdToParentIds.get(leafId));

            accountIdToTerritoryIds.get(accountId).addAll(parentTerritoryIds);
        }

        // map from agreement->territories
        Map<Id, Set<Id>> agreementIdToTerritoryIds = new Map<Id, Set<Id>>();
        for (Id agreementId : agreementIdToAccountIds.keySet())
        {
            agreementIdToTerritoryIds.put(agreementId, new Set<Id>());
            for (Id accountId : agreementIdToAccountIds.get(agreementId))
            {
                if (accountIdToTerritoryIds.get(accountId) == null) continue;
                for (Id territoryId : accountIdToTerritoryIds.get(accountId))
                    agreementIdToTerritoryIds.get(agreementId).add(territoryId);
            }
        }

        // get all users associated with all territories
        Set<Id> allHierarchyIds = flattenT2Map(territoryLeafIdToParentIds);
        List<UserTerritory2Association> userAssociations = [SELECT Id FROM UserTerritory2Association WHERE Territory2Id IN :allHierarchyIds AND User.IsActive = true];
        Map<Id, Set<Id>> territoryIdToUserIds = mapTerritoryToUserFromAssociations(userAssociations);

        // map from agreement->users
        Map<Id, Set<Id>> agreementIdToUserIds = new Map<Id, Set<Id>>();
        for (Id agreementId : agreementIdToTerritoryIds.keySet())
        {
            agreementIdToUserIds.put(agreementId, new Set<Id>());
            for (Id territoryId : agreementIdToTerritoryIds.get(agreementId))
            {
                if (territoryIdToUserIds.get(territoryId) == null) continue;
                for (Id userId : territoryIdToUserIds.get(territoryId))
                    agreementIdToUserIds.get(agreementId).add(userId);
            }
        }

        return agreementIdToUserIds;
    }

    private Map<Id, Set<Id>> mapTerritoryToUserFromAssociations(List<UserTerritory2Association> associatedUsers)
    {
        Map<Id, Set<Id>> territoryIdToUserIds = new Map<Id, Set<Id>>();
        for (UserTerritory2Association a : associatedUsers)
            if (a.UserId != null && a.Territory2Id != null)
            {
                if (!territoryIdToUserIds.containsKey(a.Territory2Id))
                    territoryIdToUserIds.put(a.Territory2Id, new Set<Id>());
                territoryIdToUserIds.get(a.Territory2Id).add(a.UserId);
            }
        return territoryIdToUserIds;
    }

    private void addSharingPermissions(Map<Id, Set<Id>> agreementIdsToUserIds)
    {
        if (agreementIdsToUserIds.size() == 0) return;

        List<ETM_Price_Agreement__Share> agreementShares = new List<ETM_Price_Agreement__Share>();

        for (Id agreementId : agreementIdsToUserIds.keySet())
        {
            if (agreementId == null || agreementIdsToUserIds.get(agreementId) == null || agreementIdsToUserIds.get(agreementId).size() == 0) continue;
            for (Id userId : agreementIdsToUserIds.get(agreementId))
                agreementShares.add(new ETM_Price_Agreement__Share(
                    UserOrGroupId = userId,
                    ParentId = agreementId,
                    AccessLevel = 'Read',
                    RowCause = Schema.ETM_Price_Agreement__Share.RowCause.Manual
                ));
        }
        insert agreementShares;
    }

    private void removeSharingPermissions(Map<Id, Set<Id>> agreementIdsToUserIds)
    {
        if (agreementIdsToUserIds.size() == 0) return;

        //remove the agreement record if it has no values.
        for (Id agreementId : agreementIdsToUserIds.keyset())
            if (agreementIdsToUserIds.get(agreementId).size() == 0)
                agreementIdsToUserIds.remove(agreementId);

        if (agreementIdsToUserIds.keyset().size() == 0) return;

        //retrieve all the existing shares for the agreementIds passed.
        List<ETM_Price_Agreement__Share> shares = [SELECT Id, ParentId, UserOrGroupId FROM ETM_Price_Agreement__Share WHERE ParentId IN :agreementIdsToUserIds.keyset() AND RowCause = 'Manual'];

        List<ETM_Price_Agreement__Share> removeShares = new List<ETM_Price_Agreement__Share>();
        // Find only the shares related to the users in the agreementIdsToUserIds.
        for (ETM_Price_Agreement__Share share : shares)
            if (agreementIdsToUserIds.get(share.ParentId).contains(share.UserOrGroupId))
                removeShares.add(share);

        //remove from the database as they are no longer valid.
        List<Database.DeleteResult> lsr = Database.delete(removeShares, false);
    }

    private Set<Id> flattenT2Map(Map<Id, Set<Id>> territoryLeafIdToParentIds)
    {
        Set<Id> flattened = new Set<Id>();
        for (Id leafId : territoryLeafIdToParentIds.keySet())
        {
            flattened.add(leafId);
            for (Id i : territoryLeafIdToParentIds.get(leafId))
                flattened.add(i);
        }

        return flattened;
    }

}
