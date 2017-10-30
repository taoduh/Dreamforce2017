trigger ETM_Territory2 on Territory2 (after update) {

    Set<Id> territoryLeafNodesWithModifiedParents = new Set<Id>();
    Set<Id> territoryNodesWithModifiedParents = new Set<Id>();

    for (Territory2 record : Trigger.new)
    {
        // we only are concerned with territores that moved in the hierarchy
        if (record.ParentTerritory2Id != Trigger.oldMap.get(record.Id).ParentTerritory2Id)
        {
            if (record.Territory2TypeId == ETM_TerritoryTypesService.pickT2TypeIdFromList(ETM_TerritoryTypesService.TYPE_TERRITORY))
                // leaf means type = territory, bottom of the tree
                territoryLeafNodesWithModifiedParents.add(record.Id);
            else
                // anthing not at the bottom. districts, BUs, etc
                territoryNodesWithModifiedParents.add(record.Id);
        }
    }

    if (territoryLeafNodesWithModifiedParents.size() == 0 && territoryNodesWithModifiedParents.size() == 0)
        return;

    // // adjust sharing for agreements right on the leaf territories
    // adjustTerritorySharing(territoryLeafNodesWithModifiedParents);

    // // the edited territory is higher than the territory level, look
    // // for the territory-level children and deal with agreements there
    // adjustChildrenSharing(territoryNodesWithModifiedParents);

    // private void adjustChildrenSharing(Set<Id> territoriesWithModifiedParents)
    // {
    //     if (territoriesWithModifiedParents.size() == 0) return;

    //     // query for all child territories
    //     TerritoriesSelector territorySelector = new TerritoriesSelector();
    //     List<Territory2> childTerritories = territorySelector.selectChildrenByTerritoryId(territoriesWithModifiedParents);

    //     // filter only the leaf records (type = territory) from the list of children
    //     // ASSUMPTION: accounts are only assigned at the territory level
    //     Set<Id> territoryIds = new Set<Id>();
    //     for (Territory2 t : childTerritories)
    //         if (t.Territory2TypeId == ETM_TerritoryTypesService.pickT2TypeIdFromList(ETM_TerritoryTypesService.TYPE_TERRITORY))
    //             territoryIds.add(t.Id);

    //     adjustTerritorySharing(territoryIds);
    // }

    // private void adjustTerritorySharing(Set<Id> territoryIds)
    // {
    //     if (territoryIds.size() == 0) return;

    //     // query for all account associations
    //     ObjectTerritory2AssociationsSelector accountAssocSelector = new ObjectTerritory2AssociationsSelector();
    //     List<ObjectTerritory2Association> accountAssociations = accountAssocSelector.selectByTerritoryId(territoryIds);

    //     // the service requires a map of AccountId => territoryId
    //     Map<Id, Id> accountIdToTerritoryId = new Map<Id, Id>();
    //     for (ObjectTerritory2Association assoc : accountAssociations)
    //         accountIdToTerritoryId.put(assoc.ObjectId, assoc.Territory2Id);

    //     AgreementsService.recalculateTerritory2Changes(accountIdToTerritoryId.values());
    // }

}