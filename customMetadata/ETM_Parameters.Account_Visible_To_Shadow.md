<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Account Visible To Shadow</label>
    <protected>false</protected>
    <values>
        <field>Description__c</field>
        <value xsi:type="xsd:string">Map of fields visible on the UI to corresponding fields used by ETM rules</value>
    </values>
    <values>
        <field>Value__c</field>
        <value xsi:type="xsd:string">BillingStreet:ETM_Street__c
BillingCity:ETM_City__c
BillingPostalCode:ETM_Postal_Code__c
BillingState:ETM_State__c
BillingCountry:ETM_Country__c
Account_Tier__c:ETM_Account_Tier__c</value>
    </values>
</CustomMetadata>
