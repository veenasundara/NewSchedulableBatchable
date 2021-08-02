/* Class:       BatchApexErrorTriggerTest
** Created by:  OpFocus (Veena Sundara-Heragu) on 2021-05-05
** Description: Unit Test for BatchApexError trigger, BatchApexErrorTriggerHandler and BatchApexErrorEventCreate classes
*/
@isTest
public with sharing class BatchApexErrorTriggerTest
{
    static testMethod void testBatchApexErrorEvent() {

        Task t = new Task();
        t.Subject = 'Test';
        insert t;

        try{
            Test.startTest();
            Database.executeBatch(new BatchApexErrorEventCreate());
            Test.stopTest();
        } catch(Exception e){
            system.debug('=========> Exception: ' + e.getMessage() + ' ' +  e.getStackTraceString());
        }
        Test.getEventBus().deliver(); // so that the BatchApexErrorEvent platform event is delivered

        system.assertEquals(1, [Select Id From Asynchronous_Apex_Error__c].size());
    }
}