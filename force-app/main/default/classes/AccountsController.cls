public with sharing class AccountsController {

    @AuraEnabled(cacheable=true)
    public static AccountsWrapper getAccounts(Integer pageSize, Integer offset) {
        Integer total = [SELECT COUNT() FROM Account];
        List<Account> accounts = [
            SELECT Id, Name, Industry, Phone, AnnualRevenue, Rating
            FROM Account
            ORDER BY Name
            LIMIT :pageSize
            OFFSET :offset
        ];
        return new AccountsWrapper(accounts, total);
    }

    //teste

    public class AccountsWrapper {
        @AuraEnabled public List<Account> accounts;
        @AuraEnabled public Integer totalCount;

        public AccountsWrapper(List<Account> accounts, Integer totalCount) {
            this.accounts = accounts;
            this.totalCount = totalCount;
        }
    }
}