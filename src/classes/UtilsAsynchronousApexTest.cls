/* Class:       UtilsAsynchronousApexAsynchronousApexTest
** Created by:  OpFocus (Veena Sundara-Heragu) on 2021-05-05
** Description: Unit test for UtilsAsynchronousApexAsynchronousApex
*/
@isTest
public with sharing class UtilsAsynchronousApexTest
{
    static testMethod void myTest1()
    {
        UtilsAsynchronousApex.clearJob('Test');
        system.assertEquals(200, UtilsAsynchronousApex.getBatchSize('Test'));

        List<CaseComment>lstCC = new List<CaseComment>{ new CaseComment()};
        for(Database.SaveResult sr : database.insert(lstCC, false))
        {
            system.assertNotEquals(null, UtilsAsynchronousApex.formatDatabaseErrors(sr.getErrors()));
        }

        Task t = new Task();
        t.Subject = 'Test';
        insert t;
        try
        {
            Integer i = 1/0;
        }
        catch(Exception ex)
        {
            UtilsAsynchronousApex.logError(ex, 'ApexClass');
            UtilsAsynchronousApex.logError(ex, 'ApexClass', t.Id);
            UtilsAsynchronousApex.logError(ex, 'ApexClass', 'RecordId1,RecordId2');
            UtilsAsynchronousApex.logError(ex, 'ApexClass', new List<String>{'RecordId1', 'RecordId2'});
            UtilsAsynchronousApex.logError(ex, 'ApexClass', t.Id, 'RecordId1,RecordId2');
            UtilsAsynchronousApex.logError(ex, 'ApexClass', t.Id, new List<String>{'RecordId1', 'RecordId2'});
            UtilsAsynchronousApex.logError('ApexClass', t.Id, new List<String>{'Error1', 'Error2'});
            UtilsAsynchronousApex.logError('ApexClass', t.Id, new List<String>{'RecordId1', 'RecordId2'},new List<String>{'Error1', 'Error2'});
            UtilsAsynchronousApex.logError('ApexClass', t.Id, new Map<Id, String>{t.Id => 'Error'});
            system.assertEquals(9, [Select Id from Asynchronous_Apex_Error__c].size());
        }

        BatchApexErrorEvent evt = new BatchApexErrorEvent();
        UtilsAsynchronousApex.logErrors(new List<BatchApexErrorEvent>{evt});
        system.assertEquals(10, [Select Id from Asynchronous_Apex_Error__c].size());
    }

}