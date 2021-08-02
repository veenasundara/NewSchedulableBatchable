/* Class:       BatchApexErrorTriggerHandler
** Created by:  OpFocus (Veena Sundara-Heragu) on 2021-05-04
** Description: Methods for BatchApexError.trigger on BatchApexErrorEvent
*/
public class BatchApexErrorTriggerHandler extends TriggerHandler
{
    private List<BatchApexErrorEvent> triggerNew = (BatchApexErrorEvent[]) Trigger.new;
    private List<BatchApexErrorEvent> triggerOld = (BatchApexErrorEvent[]) Trigger.old;
    private Map<Id, BatchApexErrorEvent> triggerNewmap = (Map<Id, BatchApexErrorEvent>) Trigger.newMap;
    private Map<Id, BatchApexErrorEvent> triggerOldmap = (Map<Id, BatchApexErrorEvent>) Trigger.oldMap;

    // ----------- OVERRIDE METHODS ----------------

    public override void afterInsert()
    {
        UtilsAsynchronousApex.logErrors(triggerNew);
    }


    // ----------- PRIVATE METHODS ----------------

}