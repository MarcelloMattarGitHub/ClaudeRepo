trigger AccountTrigger on Account (
    before insert, before update,
    after insert, after update
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) AccountTriggerHandler.beforeInsert(Trigger.new);
        if (Trigger.isUpdate) AccountTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) AccountTriggerHandler.afterInsert(Trigger.new);
        if (Trigger.isUpdate) AccountTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
}
