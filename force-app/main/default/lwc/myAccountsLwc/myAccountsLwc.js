import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAccounts from '@salesforce/apex/AccountsController.getAccounts';

const AVATAR_COLORS = ['#1589EE', '#9050E9', '#FF538A', '#E8A201', '#3BA755', '#C86E3F'];

const RATING_CONFIG = {
    Hot:  { cssClass: 'rating-hot',  emoji: '🔥' },
    Warm: { cssClass: 'rating-warm', emoji: '' },
    Cold: { cssClass: 'rating-cold', emoji: '' }
};

const currencyFormatter = new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0
});

const PAGE_SIZE = 10;

export default class MyAccountsLwc extends NavigationMixin(LightningElement) {
    @api displayLimit; // kept for meta.xml compatibility — pagination uses PAGE_SIZE constant

    accounts = [];
    totalCount = 0;
    isLoading = false;
    isLoadingMore = false;
    error;

    get displayCount() {
        return this.accounts.length;
    }

    get hasMore() {
        return this.accounts.length < this.totalCount;
    }

    connectedCallback() {
        this.isLoading = true;
        this._loadPage(0);
    }

    handleScroll(event) {
        if (this.isLoadingMore || !this.hasMore) return;
        const el = event.target;
        if (el.scrollTop + el.clientHeight >= el.scrollHeight - 60) {
            this.isLoadingMore = true;
            this._loadPage(this.accounts.length);
        }
    }

    _loadPage(offset) {
        getAccounts({ pageSize: PAGE_SIZE, offset })
            .then(result => {
                this.totalCount = result.totalCount;
                const newAccounts = result.accounts.map(acc => this._processAccount(acc));
                this.accounts = [...this.accounts, ...newAccounts];
                this.isLoading = false;
                this.isLoadingMore = false;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                this.isLoadingMore = false;
            });
    }

    handleNameClick(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    _processAccount(acc) {
        const initial = acc.Name ? acc.Name.charAt(0).toUpperCase() : '?';
        const colorIndex = acc.Name ? acc.Name.charCodeAt(0) % AVATAR_COLORS.length : 0;
        const ratingConfig = RATING_CONFIG[acc.Rating] || { cssClass: 'rating-default', emoji: '' };

        return {
            ...acc,
            initial,
            avatarStyle: `background-color: ${AVATAR_COLORS[colorIndex]};`,
            formattedRevenue: acc.AnnualRevenue ? currencyFormatter.format(acc.AnnualRevenue) : '--',
            ratingClass: ratingConfig.cssClass,
            ratingEmoji: ratingConfig.emoji
        };
    }
}
