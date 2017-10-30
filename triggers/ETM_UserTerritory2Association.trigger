trigger ETM_UserTerritory2Association on UserTerritory2Association (before insert, before delete, after insert, after delete) {

    ETM_PriceAgreementsService.recalculateUserTerritoryChanges(ETM_Utils.getSetOfIds(Trigger.new, 'Territory2Id'));

}