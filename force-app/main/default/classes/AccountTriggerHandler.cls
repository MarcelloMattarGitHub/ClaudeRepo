/**
 * @description Handler class for AccountTrigger. Contains all Account trigger
 *              business logic, including Health Rating evaluation and follow-up
 *              Task creation for accounts that transition to "At Risk".
 */
public with sharing class AccountTriggerHandler {

    private static final String RATING_GOOD = 'Good';
    private static final String RATING_AVERAGE = 'Average';
    private static final String RATING_AT_RISK = 'At Risk';

    private static final Decimal GOOD_REVENUE_THRESHOLD = 10000000;
    private static final Integer GOOD_EMPLOYEES_THRESHOLD = 500;
    private static final Decimal AT_RISK_REVENUE_THRESHOLD = 1000000;
    private static final Integer AT_RISK_EMPLOYEES_THRESHOLD = 100;

    /**
     * @description Evaluates Health Rating for every new Account before insert.
     * @param newAccounts Trigger.new list of new Accounts.
     */
    public static void beforeInsert(List<Account> newAccounts) {
        if (newAccounts == null || newAccounts.isEmpty()) {
            return;
        }
        for (Account acc : newAccounts) {
            applyHealthRating(acc);
        }
    }

    /**
     * @description Re-evaluates Health Rating only when AnnualRevenue or
     *              NumberOfEmployees has changed.
     * @param newAccounts Trigger.new list of updated Accounts.
     * @param oldMap Trigger.oldMap of Account state prior to update.
     */
    public static void beforeUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        if (newAccounts == null || newAccounts.isEmpty() || oldMap == null) {
            return;
        }
        for (Account acc : newAccounts) {
            Account oldAcc = oldMap.get(acc.Id);
            if (oldAcc == null) {
                continue;
            }
            if (acc.AnnualRevenue != oldAcc.AnnualRevenue
                || acc.NumberOfEmployees != oldAcc.NumberOfEmployees) {
                applyHealthRating(acc);
            }
        }
    }

    /**
     * @description Post-insert hook. Health Rating was already populated in
     *              beforeInsert, so no further work is required here.
     * @param newAccounts Trigger.new list of inserted Accounts.
     */
    public static void afterInsert(List<Account> newAccounts) {
        // Health Rating is set in beforeInsert; no additional action needed.
    }

    /**
     * @description Creates a follow-up Task for every Account that has just
     *              transitioned into the "At Risk" Health Rating.
     * @param newAccounts Trigger.new list of updated Accounts.
     * @param oldMap Trigger.oldMap of Account state prior to update.
     */
    public static void afterUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        if (newAccounts == null || newAccounts.isEmpty() || oldMap == null) {
            return;
        }

        List<Task> tasksToInsert = new List<Task>();
        Date dueDate = Date.today().addDays(3);

        for (Account acc : newAccounts) {
            Account oldAcc = oldMap.get(acc.Id);
            if (oldAcc == null) {
                continue;
            }
            if (acc.Health_Rating__c == RATING_AT_RISK
                && oldAcc.Health_Rating__c != RATING_AT_RISK) {
                tasksToInsert.add(new Task(
                    Subject = 'Review At Risk Account: ' + acc.Name,
                    WhatId = acc.Id,
                    OwnerId = acc.OwnerId,
                    Priority = 'High',
                    Status = 'Not Started',
                    ActivityDate = dueDate
                ));
            }
        }

        if (!tasksToInsert.isEmpty()) {
            Database.insert(tasksToInsert, AccessLevel.USER_MODE);
        }
    }

    /**
     * @description Computes and applies the Health Rating and evaluation
     *              timestamp on the supplied Account in place. The caller is
     *              responsible for ensuring this runs in a before-context so
     *              no DML is required.
     * @param acc Account record to evaluate.
     */
    private static void applyHealthRating(Account acc) {
        acc.Health_Rating__c = calculateHealthRating(acc.AnnualRevenue, acc.NumberOfEmployees);
        acc.Health_Rating_Last_Evaluated__c = System.now();
    }

    /**
     * @description Pure function that returns the Health Rating value for the
     *              supplied revenue and employee count. Null values fall
     *              through to "Average" by design.
     * @param annualRevenue The Account's AnnualRevenue.
     * @param numberOfEmployees The Account's NumberOfEmployees.
     * @return One of: 'Good', 'Average', 'At Risk'.
     */
    private static String calculateHealthRating(Decimal annualRevenue, Integer numberOfEmployees) {
        if (annualRevenue != null && numberOfEmployees != null
            && annualRevenue > GOOD_REVENUE_THRESHOLD
            && numberOfEmployees > GOOD_EMPLOYEES_THRESHOLD) {
            return RATING_GOOD;
        }
        if (annualRevenue != null && numberOfEmployees != null
            && annualRevenue < AT_RISK_REVENUE_THRESHOLD
            && numberOfEmployees < AT_RISK_EMPLOYEES_THRESHOLD) {
            return RATING_AT_RISK;
        }
        return RATING_AVERAGE;
    }
}
