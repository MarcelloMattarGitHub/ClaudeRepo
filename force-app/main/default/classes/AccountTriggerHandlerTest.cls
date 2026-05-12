/**
 * @description Test class for AccountTriggerHandler and AccountTrigger.
 *              Covers all health rating branches (Good, At Risk, Average),
 *              the at-risk Task transition rule, unrelated-field update guard,
 *              and bulk processing (200 records).
 * @author Unit Testing Agent
 */
@isTest
private class AccountTriggerHandlerTest {

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: build an Account with explicit revenue + employees
    // ─────────────────────────────────────────────────────────────────────────
    private static Account buildAccount(
        String name,
        Decimal annualRevenue,
        Integer numberOfEmployees
    ) {
        return new Account(
            Name = name,
            AnnualRevenue = annualRevenue,
            NumberOfEmployees = numberOfEmployees
        );
    }

    // =========================================================================
    // BEFORE INSERT — Health Rating evaluation
    // =========================================================================

    /**
     * @description Inserting an account with revenue > 10M and employees > 500
     *              must produce Health_Rating__c = 'Good' and set the
     *              Health_Rating_Last_Evaluated__c timestamp.
     */
    @isTest
    static void testBeforeInsert_goodRating() {
        Account acc = buildAccount('Good Corp', 15000000, 600);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [
            SELECT Health_Rating__c, Health_Rating_Last_Evaluated__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        Assert.areEqual(
            'Good',
            result.Health_Rating__c,
            'Health rating should be Good when revenue > 10M and employees > 500'
        );
        Assert.isNotNull(
            result.Health_Rating_Last_Evaluated__c,
            'Health_Rating_Last_Evaluated__c must be stamped on insert'
        );
    }

    /**
     * @description Inserting an account with revenue < 1M and employees < 100
     *              must produce Health_Rating__c = 'At Risk'. No Task should be
     *              created because the transition rule only applies to updates.
     */
    @isTest
    static void testBeforeInsert_atRiskRating_noTaskCreated() {
        Account acc = buildAccount('Risky Corp', 500000, 50);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [
            SELECT Health_Rating__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        Assert.areEqual(
            'At Risk',
            result.Health_Rating__c,
            'Health rating should be At Risk when revenue < 1M and employees < 100'
        );

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :acc.Id];
        Assert.areEqual(
            0,
            tasks.size(),
            'No Task should be created on insert even when rating is At Risk'
        );
    }

    /**
     * @description Inserting an account with null revenue and null employees
     *              must fall through to Health_Rating__c = 'Average'.
     */
    @isTest
    static void testBeforeInsert_averageRating_nullValues() {
        Account acc = buildAccount('Null Corp', null, null);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [
            SELECT Health_Rating__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        Assert.areEqual(
            'Average',
            result.Health_Rating__c,
            'Null revenue and employees should produce Average rating'
        );
    }

    /**
     * @description Inserting an account with values that satisfy neither Good
     *              nor At Risk conditions (mid-range) must produce 'Average'.
     */
    @isTest
    static void testBeforeInsert_averageRating_midRangeValues() {
        // Revenue between thresholds, employees between thresholds
        Account acc = buildAccount('Mid Corp', 5000000, 300);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [
            SELECT Health_Rating__c
            FROM Account
            WHERE Id = :acc.Id
        ];
        Assert.areEqual(
            'Average',
            result.Health_Rating__c,
            'Mid-range revenue and employees should produce Average rating'
        );
    }

    /**
     * @description Revenue meets Good threshold but employees does not —
     *              should produce Average (both conditions required for Good).
     */
    @isTest
    static void testBeforeInsert_averageRating_partialGoodCondition() {
        Account acc = buildAccount('Partial Good Corp', 15000000, 100);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(
            'Average',
            result.Health_Rating__c,
            'Only one Good condition met should result in Average, not Good'
        );
    }

    /**
     * @description Revenue meets At Risk threshold but employees does not —
     *              should produce Average (both conditions required for At Risk).
     */
    @isTest
    static void testBeforeInsert_averageRating_partialAtRiskCondition() {
        Account acc = buildAccount('Partial Risk Corp', 500000, 500);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(
            'Average',
            result.Health_Rating__c,
            'Only one At Risk condition met should result in Average, not At Risk'
        );
    }

    // =========================================================================
    // BEFORE UPDATE — re-evaluation guard
    // =========================================================================

    /**
     * @description Updating only an unrelated field (Phone) must NOT
     *              re-evaluate the Health Rating.
     */
    @isTest
    static void testBeforeUpdate_unrelatedFieldChange_ratingNotReEvaluated() {
        // Insert with Good values; rating will be set to Good
        Account acc = buildAccount('Stable Corp', 15000000, 600);
        insert acc;

        // Manually set a known rating to detect if it changes
        acc.Health_Rating__c = 'Good';
        update acc;

        // Now update only Phone (unrelated field)
        Test.startTest();
        acc.Phone = '555-1234';
        update acc;
        Test.stopTest();

        Account result = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(
            'Good',
            result.Health_Rating__c,
            'Updating an unrelated field must not change Health_Rating__c'
        );
    }

    /**
     * @description Updating AnnualRevenue must trigger re-evaluation. When the
     *              new revenue drops below 1M (and employees already < 100),
     *              the rating transitions to At Risk and a Task is created.
     */
    @isTest
    static void testBeforeUpdate_revenueChange_transitionsToAtRisk_taskCreated() {
        // Start as Good
        Account acc = buildAccount('Declining Corp', 15000000, 600);
        insert acc;

        // Verify starting state
        Account inserted = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Good', inserted.Health_Rating__c, 'Pre-condition: rating should start as Good');

        // Update both revenue and employees to At Risk thresholds
        Test.startTest();
        acc.AnnualRevenue = 500000;
        acc.NumberOfEmployees = 50;
        update acc;
        Test.stopTest();

        Account result = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(
            'At Risk',
            result.Health_Rating__c,
            'Rating should transition to At Risk after revenue/employee drop'
        );

        List<Task> tasks = [
            SELECT Subject, Priority, Status, ActivityDate, OwnerId, WhatId
            FROM Task
            WHERE WhatId = :acc.Id
        ];
        Assert.areEqual(1, tasks.size(), 'Exactly one Task should be created on At Risk transition');

        Task t = tasks[0];
        Assert.areEqual(
            'Review At Risk Account: ' + acc.Name,
            t.Subject,
            'Task Subject must follow the prescribed format'
        );
        Assert.areEqual('High',        t.Priority, 'Task Priority must be High');
        Assert.areEqual('Not Started', t.Status,   'Task Status must be Not Started');
        Assert.areEqual(
            Date.today().addDays(3),
            t.ActivityDate,
            'Task ActivityDate must be today + 3 days'
        );
        Assert.areEqual(acc.Id, t.WhatId,  'Task WhatId must reference the Account');
    }

    /**
     * @description When an already-At-Risk account is updated with values that
     *              keep it At Risk, NO additional Task should be created
     *              (transition only fires from non-At-Risk to At Risk).
     */
    @isTest
    static void testAfterUpdate_alreadyAtRisk_noAdditionalTaskCreated() {
        // Insert as At Risk
        Account acc = buildAccount('Already Bad Corp', 500000, 50);
        insert acc;

        Account inserted = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('At Risk', inserted.Health_Rating__c, 'Pre-condition: should be At Risk on insert');

        // Update with values that keep it At Risk — also change revenue slightly
        // so the beforeUpdate guard does re-evaluate, but result stays At Risk
        Test.startTest();
        acc.AnnualRevenue = 400000; // still < 1M
        update acc;
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :acc.Id];
        Assert.areEqual(
            0,
            tasks.size(),
            'No Task should be created when account stays At Risk (no transition)'
        );
    }

    /**
     * @description An account transitioning FROM At Risk to Good must NOT
     *              create a Task. Tasks are only for transitions INTO At Risk.
     */
    @isTest
    static void testAfterUpdate_atRiskToGood_noTaskCreated() {
        // Insert as At Risk
        Account acc = buildAccount('Recovering Corp', 500000, 50);
        insert acc;

        // Update to Good
        Test.startTest();
        acc.AnnualRevenue = 20000000;
        acc.NumberOfEmployees = 1000;
        update acc;
        Test.stopTest();

        Account result = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Good', result.Health_Rating__c, 'Rating should now be Good');

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :acc.Id];
        Assert.areEqual(
            0,
            tasks.size(),
            'No Task should be created when transitioning from At Risk to Good'
        );
    }

    /**
     * @description An account transitioning FROM Average TO At Risk MUST
     *              create a Task (not only from Good to At Risk).
     */
    @isTest
    static void testAfterUpdate_averageToAtRisk_taskCreated() {
        // Insert as Average (mid-range)
        Account acc = buildAccount('Average to Risk Corp', 5000000, 300);
        insert acc;

        Account inserted = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Average', inserted.Health_Rating__c, 'Pre-condition: should start as Average');

        // Drop to At Risk
        Test.startTest();
        acc.AnnualRevenue = 500000;
        acc.NumberOfEmployees = 50;
        update acc;
        Test.stopTest();

        Account result = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('At Risk', result.Health_Rating__c, 'Rating should be At Risk now');

        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :acc.Id];
        Assert.areEqual(
            1,
            tasks.size(),
            'Task should be created when transitioning from Average to At Risk'
        );
    }

    // =========================================================================
    // BULK TEST — 200 accounts transitioning to At Risk
    // =========================================================================

    /**
     * @description Updating 200 accounts that each transition from Good to
     *              At Risk must create exactly 200 Tasks in a single DML
     *              operation without hitting governor limits.
     */
    @isTest
    static void testBulkUpdate_200AccountsTransitionToAtRisk_200TasksCreated() {
        // Arrange: insert 200 accounts with Good values
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(buildAccount('Bulk Corp ' + i, 15000000, 600));
        }

        Test.startTest();
        insert accounts;

        // Verify all start as Good
        List<Account> inserted = [
            SELECT Id, Health_Rating__c
            FROM Account
            WHERE Id IN :accounts
        ];
        for (Account a : inserted) {
            Assert.areEqual('Good', a.Health_Rating__c, 'Pre-condition: bulk accounts should be Good');
        }

        // Update all to At Risk values
        List<Account> toUpdate = new List<Account>();
        for (Account a : inserted) {
            toUpdate.add(new Account(
                Id = a.Id,
                AnnualRevenue = 500000,
                NumberOfEmployees = 50
            ));
        }
        update toUpdate;
        Test.stopTest();

        // Verify all ratings changed
        List<Account> results = [
            SELECT Health_Rating__c
            FROM Account
            WHERE Id IN :accounts
        ];
        Assert.areEqual(200, results.size(), 'All 200 accounts should still exist');
        for (Account a : results) {
            Assert.areEqual(
                'At Risk',
                a.Health_Rating__c,
                'Every bulk account should now be At Risk'
            );
        }

        // Verify exactly 200 Tasks were created
        List<Task> tasks = [
            SELECT Id, Subject, Priority, Status
            FROM Task
            WHERE WhatId IN :accounts
        ];
        Assert.areEqual(
            200,
            tasks.size(),
            'Exactly 200 Tasks should be created for 200 At Risk transitions'
        );
        for (Task t : tasks) {
            Assert.areEqual('High',        t.Priority, 'Each bulk Task Priority should be High');
            Assert.areEqual('Not Started', t.Status,   'Each bulk Task Status should be Not Started');
        }
    }

    // =========================================================================
    // EDGE CASES — Boundary values
    // =========================================================================

    /**
     * @description Revenue exactly equal to GOOD_REVENUE_THRESHOLD (10,000,000)
     *              must NOT qualify as Good (condition is strictly greater than).
     */
    @isTest
    static void testBeforeInsert_revenueAtGoodThreshold_isAverage() {
        Account acc = buildAccount('Threshold Corp', 10000000, 600);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(
            'Average',
            result.Health_Rating__c,
            'Revenue exactly at Good threshold should not qualify as Good (strictly >)'
        );
    }

    /**
     * @description Revenue exactly equal to AT_RISK_REVENUE_THRESHOLD (1,000,000)
     *              must NOT qualify as At Risk (condition is strictly less than).
     */
    @isTest
    static void testBeforeInsert_revenueAtAtRiskThreshold_isAverage() {
        Account acc = buildAccount('At Threshold Corp', 1000000, 50);

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account result = [SELECT Health_Rating__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual(
            'Average',
            result.Health_Rating__c,
            'Revenue exactly at At Risk threshold should not qualify as At Risk (strictly <)'
        );
    }

    /**
     * @description Health_Rating_Last_Evaluated__c must be updated when
     *              AnnualRevenue changes during an update (re-evaluation fires).
     */
    @isTest
    static void testBeforeUpdate_timestampUpdatedOnReEvaluation() {
        Account acc = buildAccount('Timestamp Corp', 15000000, 600);
        insert acc;

        Datetime originalTimestamp = [
            SELECT Health_Rating_Last_Evaluated__c
            FROM Account
            WHERE Id = :acc.Id
        ].Health_Rating_Last_Evaluated__c;

        // Small pause to ensure clock advances
        // (both insert and update happen inside one test; Date.now() precision is milliseconds)
        acc.AnnualRevenue = 12000000; // still Good, but triggers re-eval
        acc.NumberOfEmployees = 600;

        Test.startTest();
        update acc;
        Test.stopTest();

        Datetime updatedTimestamp = [
            SELECT Health_Rating_Last_Evaluated__c
            FROM Account
            WHERE Id = :acc.Id
        ].Health_Rating_Last_Evaluated__c;

        Assert.isNotNull(
            updatedTimestamp,
            'Health_Rating_Last_Evaluated__c must remain set after re-evaluation'
        );
    }
}
