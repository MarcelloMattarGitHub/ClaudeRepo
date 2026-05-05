public with sharing class LeadTriggerHandler {

    public static void beforeInsert(List<Lead> newLeads) {
        for (Lead lead : newLeads) {
            // TODO: set default field values on new leads
            // TODO: derive Status_Claude__c from Status (mirrors LeadStatusBatch logic)
        }
    }

    public static void beforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        for (Lead lead : newLeads) {
            Lead old = oldMap.get(lead.Id);
            // TODO: field-change detection and synchronous field updates
            // TODO: re-derive Status_Claude__c when Status changes
        }
    }

    public static void afterInsert(List<Lead> newLeads) {
        // TODO: post-insert actions (e.g., create related records, send notifications)
    }

    public static void afterUpdate(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        // TODO: post-update actions (e.g., cascade updates, external callouts)
    }
}