trigger LeadTrigger on Lead (
    before insert, before update,
    after insert, after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) LeadTriggerHandler.beforeInsert(Trigger.new);
        if (Trigger.isUpdate) LeadTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) LeadTriggerHandler.afterInsert(Trigger.new);
        if (Trigger.isUpdate) LeadTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
