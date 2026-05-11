public with sharing class OverdueLeadsController {

    @AuraEnabled(cacheable=true)
    public static List<LeadWrapper> getOverdueLeads() {
        List<Lead> overdueLeads = [
            SELECT Id, Name, Company, Days_Since_Last_Contact__c
            FROM Lead
            WHERE OwnerId = :UserInfo.getUserId()
              AND Overdue_Follow_Up__c = true
              AND IsConverted = false
            WITH USER_MODE
            ORDER BY Days_Since_Last_Contact__c DESC
        ];

        List<LeadWrapper> wrappers = new List<LeadWrapper>();
        for (Lead l : overdueLeads) {
            LeadWrapper w = new LeadWrapper();
            w.id = l.Id;
            w.name = l.Name;
            w.company = l.Company;
            w.daysSince = l.Days_Since_Last_Contact__c != null
                ? Integer.valueOf(l.Days_Since_Last_Contact__c)
                : null;
            wrappers.add(w);
        }
        return wrappers;
    }

    public class LeadWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String company;
        @AuraEnabled public Integer daysSince;
    }
}
