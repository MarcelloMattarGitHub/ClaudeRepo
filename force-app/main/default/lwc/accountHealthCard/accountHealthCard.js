import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import ACCOUNT_HEALTH_RATING_FIELD from '@salesforce/schema/Account.Health_Rating__c';
import ACCOUNT_HEALTH_LAST_EVALUATED_FIELD from '@salesforce/schema/Account.Health_Rating_Last_Evaluated__c';

const RATING_GOOD = 'Good';
const RATING_AVERAGE = 'Average';
const RATING_AT_RISK = 'At Risk';

export default class AccountHealthCard extends LightningElement {
    @api recordId;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [ACCOUNT_HEALTH_RATING_FIELD, ACCOUNT_HEALTH_LAST_EVALUATED_FIELD]
    })
    account;

    get healthRating() {
        if (!this.account || !this.account.data) {
            return null;
        }
        return getFieldValue(this.account.data, ACCOUNT_HEALTH_RATING_FIELD);
    }

    get lastEvaluated() {
        if (!this.account || !this.account.data) {
            return null;
        }
        return getFieldValue(this.account.data, ACCOUNT_HEALTH_LAST_EVALUATED_FIELD);
    }

    get hasRating() {
        return this.healthRating != null && this.healthRating !== '';
    }

    get hasError() {
        return this.account && !!this.account.error;
    }

    get hasLastEvaluated() {
        return this.hasRating && this.lastEvaluated != null;
    }

    get badgeLabel() {
        return this.hasRating ? this.healthRating : 'Not evaluated';
    }

    get badgeClass() {
        switch (this.healthRating) {
            case RATING_GOOD:
                return 'badge badge-good';
            case RATING_AVERAGE:
                return 'badge badge-average';
            case RATING_AT_RISK:
                return 'badge badge-at-risk';
            default:
                return 'badge badge-unknown';
        }
    }
}
