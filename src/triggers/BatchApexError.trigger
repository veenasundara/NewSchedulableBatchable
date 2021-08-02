/*
** Trigger:  BatchApexError
** SObject:  BatchApexErrorEvent
** Created by OpFocus (Veena Sundara-Heragu) on 2021-05-04
** Description: Trigger for BatchApexErrorEvent.  Details in BatchApexErrorTriggerHandler
**              
*/
trigger BatchApexError on BatchApexErrorEvent (after insert)
{
    new BatchApexErrorTriggerHandler().run();
}