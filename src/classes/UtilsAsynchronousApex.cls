/* Class:       UtilsAsynchronousApex
** Created by:  OpFocus (Veena Sundara-Heragu) on 2021-05-05
** Description: Methods used by Asynchronous apex (to log errors etc.)
*/
public with sharing class UtilsAsynchronousApex
{
    /**
      * If an apex job exists with the specified name, abort it.
      * @param jobName
      */
    public static void clearJob(String jobName)
    {
        CronTrigger[] lstJob = [
                SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType, State
                FROM CronTrigger
                where CronJobDetail.name = :jobName
        ] ;
        for (CronTrigger cr : lstJob)
        {
            system.abortJob(cr.Id);
        }
    }

    /**
     * Get batch size from custom metadata type. If no record found there, return 200
     * @param jobName
     * @return
     */
    public static Integer getBatchSize(String jobName)
    {
        return(getBatchSize(jobName, 200));
    }
    public static Integer getBatchSize(String jobName, Integer defaultBatchSize)
    {
        defaultBatchSize = defaultBatchSize == null ? 200 : defaultBatchSize;

        // get batch size from custom metadata type if it exists
        Apex_Job_Setting__mdt[] lstCMT = [Select Batch_Size__c from Apex_Job_Setting__mdt Where Label = :jobName];
        Integer batchSize = lstCMT == null || lstCMT.isEmpty() || lstCMT[0].Batch_Size__c == null ? defaultBatchSize : Integer.valueOf(lstCMT[0].Batch_Size__c);
        return batchSize;
    }

    /**
     * formatDatabaseErrors - formats a list of database errors in readable text with line break between each error
     * param - errors > a list of Database.Errors
     */
    public static String formatDatabaseErrors(List<Database.Error> errors) {
        if (errors == null) return null;

        List<String> formattedErrors = new List<String>();

        for (Database.Error error : errors) {
            String formattedError = error.getStatusCode() + ' - ' + error.getMessage();
            formattedErrors.add(formattedError);
        }

        return (formattedErrors.size() > 0 ? String.join(formattedErrors, '\n') : null);
    }


    /**
     * Create an Asynchronous_Apex_Error__c record for an exception from an Apex class. A workflow will cause an email
     * to be sent when this record is created
     * @param ex
     * @param ApexClassName
     */
    public static void logError(Exception ex, String ApexClassName, Id jobId, String recordIds)
    {
        Asynchronous_Apex_Error__c error = new Asynchronous_Apex_Error__c();
        error.Apex_Class__c = ApexClassName;
        error.AsyncApexJobId__c = jobId;
        error.Record_Ids__c = recordIds;
        if(recordIds.contains(','))
        {
            List<String>lstRecordId = recordIds.split(',');
            error.Number_of_Records__c = lstRecordId.size();
        }
        error.Message__c = ex.getMessage();
        error.Stack_Trace__c = ex.getStackTraceString();

        database.insert(new List<Asynchronous_Apex_Error__c>{error}, false); // we don't want any errors with this to interfere with other processing
    }
    public static void logError(Exception ex, String ApexClassName, Id jobId, List<String> lstRecordIds)
    {
        logError(ex, ApexClassName, jobId, String.join(lstRecordIds, ','));
    }
    public static void logError(Exception ex, String ApexClassName, String recordIds)
    {
        logError(ex, ApexClassName, null, recordIds);
    }
    public static void logError(Exception ex, String ApexClassName, List<String> lstRecordIds)
    {
        logError(ex, ApexClassName, null, String.join(lstRecordIds, ','));
    }
    public static void logError(Exception ex, String ApexClassName, Id jobId)
    {
        logError(ex, ApexClassName, jobId, new List<String>());
    }
    public static void logError(Exception ex, String ApexClassName)
    {
        logError(ex, ApexClassName, null, new List<String>());
    }
    /**
     * For errors from database.update methods in batchable jobs, use this method to create an Asynchronous_Apex_Error__c
     * record for the errors from each batch
     * @param ApexClassName
     * @param jobId
     * @param mapErrorByRecordId
     */
    public static void logError(String ApexClassName, Id jobId, Map<Id, String> mapErrorByRecordId)
    {
        List<String> lstRecordId = (List<String>)JSON.deserialize(JSON.serialize(mapErrorByRecordId.keySet()), List<String>.class);
        logError(ApexClassName, jobId, lstRecordId, mapErrorByRecordId.values());
    }

    /**
     * For errors from database.insert methods in batchable jobs, use this method to create an Asynchronous_Apex_Error__c
     * record for the errors from each batch. Record Ids will not be set for inserts
     * @param ApexClassName
     * @param jobId
     * @param mapErrorByRecordId
     */
    public static void logError(String ApexClassName, Id jobId, List<String> lstError)
    {
        logError(ApexClassName, jobId, null, lstError);
    }
    public static void logError(String ApexClassName, Id jobId, List<String>lstRecordId, List<String> lstError)
    {
        Asynchronous_Apex_Error__c error = new Asynchronous_Apex_Error__c();
        error.Apex_Class__c = ApexClassName;
        error.AsyncApexJobId__c = jobId;
        error.Record_Ids__c = lstRecordId == null ? null : String.join(lstRecordId, ',');
        error.Number_of_Records__c = lstRecordId == null ? null : lstRecordId.size();
        error.Message__c = String.join(lstError, '\n\n');

        database.insert(new List<Asynchronous_Apex_Error__c>{error}, false); // we don't want any errors with this to interfere with other processing
    }

    /**
     * When there are Exceptions from batch jobs, the platform event BatchApexErrorEvent is raised and the trigger
     * on that event will call this method to save the error information in the Asynchronous_Apex_Error__c object.
     * A workflow will fire an email when this recordis created
     * @param lstEvent
     */
    public static void logErrors(List<BatchApexErrorEvent>lstEvent)
    {
        // collect AsyncApexJobId from the platform events so that we can get the corresponding Apex Classes
        List<Id>lstJobId = new List<Id>();
        for(BatchApexErrorEvent evt : lstEvent){
            lstJobId.add(evt.AsyncApexJobId);
        }

        // Get Apex Clas bnames for the AsyncApexJobIds
        Map<Id, String>mapApexClassByJobId = new Map<Id, String>();
        for(AsyncApexJob job : [SELECT
                Id, CreatedDate, ApexClass.Name
        FROM
                AsyncApexJob
        WHERE Id IN :lstJobId])
        {
            mapApexClassByJobId.put(job.Id, job.ApexClass.Name);
        }

        // Create Asynchronous_Apex_Error__c records for each platform event
        List<Asynchronous_Apex_Error__c>lstAsynchApexError = new List<Asynchronous_Apex_Error__c>();
        for(BatchApexErrorEvent event : lstEvent){
            Asynchronous_Apex_Error__c error = new Asynchronous_Apex_Error__c();
            error.Apex_Class__c = mapApexClassByJobId.get(event.AsyncApexJobId);
            error.AsyncApexJobId__c = event.AsyncApexJobId;
            error.Record_Ids__c = event.JobScope;
            if(error.Record_Ids__c != null && error.Record_Ids__c.contains(','))
            {
                List<String>lstRecordId = error.Record_Ids__c.split(',');
                error.Number_of_Records__c = lstRecordId.size();
            }
            error.Message__c = event.ExceptionType + ': ' + event.Message;
            error.Stack_Trace__c = event.StackTrace;
            lstAsynchApexError.add(error);
        }
        insert lstAsynchApexError;
    }

}