import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOverdueLeads from '@salesforce/apex/OverdueLeadsController.getOverdueLeads';

export default class OverdueLeadsLwc extends NavigationMixin(LightningElement) {
    leads = [];
    isLoading = false;
    error;

    connectedCallback() {
        this.isLoading = true;
        getOverdueLeads()
            .then(result => {
                this.leads = result;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error && error.body && error.body.message
                    ? error.body.message
                    : 'Unable to load overdue leads.';
                this.isLoading = false;
            });
    }

    navigateToLead(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }
}
