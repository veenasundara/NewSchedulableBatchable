/* Class:       BatchApexErrorEventCreate
** Created by:  OpFocus (Veena Sundara-Heragu) on 2021-05-05
** Description: This batch class is used to test the BatchApexError trigger and BatchApexErrorTriggerHandler class
*/
public with sharing class BatchApexErrorEventCreate implements Database.Batchable<sObject>, Database.RaisesPlatformEvents
{
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id FROM Task';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope){
        Integer i = 1 / 0; // cause an exception so that the BatchApexErrorEvent platform event is raised
    }

    public void finish(Database.BatchableContext BC){ }
}