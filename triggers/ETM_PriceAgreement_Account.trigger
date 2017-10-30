trigger ETM_PriceAgreement_Account on ETM_Price_Agreement_Account__c (after insert, after update, after delete) {

    // public override void onAfterInsert()
    // {
    //     Map<Id, Id> agreementIdToAccountId = new Map<Id, Id>();

    //     for (AgreementAccount__c aa : allJunctionRecords)
    //         if (aa.Account__c != null && aa.Agreements__c != null)
    //             agreementIdToAccountId.put(aa.Agreements__c, aa.Account__c);

    //     updateRelatedAgreements(agreementIdToAccountId, new Set<Id>());

    //     AgreementsService.recalculateAgreementAccountChanges(allJunctionRecords);
    // }

    // public override void onAfterUpdate(Map<Id, SObject> existingRecords)
    // {
    //     Map<Id, Id> agreementIdToAccountId = new Map<Id, Id>();
    //     Set<Id> agreementsToClearAccount = new Set<Id>();

    //     List<AgreementAccount__c> changedAgreementAccounts = new List<AgreementAccount__c>();
    //     for (AgreementAccount__c aa : allJunctionRecords)
    //     {
    //         AgreementAccount__c oldRec = (AgreementAccount__c)existingRecords.get(aa.Id);

    //         if (aa.Account__c == oldRec.Account__c && aa.Agreements__c == oldRec.Agreements__c)
    //             continue;
    //         else if (aa.Account__c != oldRec.Account__c || aa.Agreements__c != oldRec.Agreements__c)
    //             changedAgreementAccounts.add(aa);

    //         if (aa.Agreements__c == oldRec.Agreements__c)
    //         {
    //             if (oldRec.Agreements__c != null)
    //                 agreementIdToAccountId.put(aa.Agreements__c, aa.Account__c);
    //         }
    //         else
    //         {
    //             if (oldRec.Agreements__c != null)
    //                 agreementsToClearAccount.add(oldRec.Agreements__c);
    //             if (aa.Agreements__c != null)
    //                 agreementIdToAccountId.put(aa.Agreements__c, aa.Account__c);
    //         }
    //     }

    //     updateRelatedAgreements(agreementIdToAccountId, agreementsToClearAccount);

    //     // update agreement share records if Agreements__c or Account__c was changed
    //     AgreementsService.recalculateAgreementAccountChanges(changedAgreementAccounts);
    // }

    // public override void onAfterDelete()
    // {
    //     Set<Id> agreementsToClearAccount = new Set<Id>();

    //     for (AgreementAccount__c aa : allJunctionRecords)
    //         if (aa.Agreements__c != null)
    //             agreementsToClearAccount.add(aa.Agreements__c);

    //     updateRelatedAgreements(new Map<Id, Id>(), agreementsToClearAccount);

    //     AgreementsService.recalculateAgreementAccountChanges(allJunctionRecords);
    // }


    // private void updateRelatedAgreements(Map<Id, Id> agreementIdToAccountId, Set<Id> agreementsToClearAccount)
    // {
    //     AgreementsSelector agreementsSelector = new AgreementsSelector();
    //     ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(new List<Schema.SObjectType> {Agreements__c.SObjectType});

    //     // update agreements where the account needs to be cleared
    //     if (agreementsToClearAccount.size() > 0)
    //     {
    //         List<Agreements__c> agreementsLosingAccounts = agreementsSelector.selectById(agreementsToClearAccount);
    //         for (Agreements__c a : agreementsLosingAccounts)
    //             a.Account__c = null;

    //         uow.registerDirty(agreementsLosingAccounts);
    //     }

    //     // update agreements where the account needs to be set
    //     if (agreementIdToAccountId.size() > 0)
    //     {
    //         List<Agreements__c> agreementsGettingAccounts = agreementsSelector.selectById(agreementIdToAccountId.keySet());
    //         for (Agreements__c a : agreementsGettingAccounts)
    //             a.Account__c = agreementIdToAccountId.get(a.Id);

    //         uow.registerDirty(agreementsGettingAccounts);
    //     }

    //     try
    //     {
    //         uow.commitWork();
    //     }
    //     catch (Exception e)
    //     {
    //         for (AgreementAccount__c a : allJunctionRecords)
    //             a.addError('Unable to propagate account to agreement record -- ' + e);
    //     }
    // }

}