import { LightningElement, api, wire, track } from 'lwc';
import getQuoteBundleTree from '@salesforce/apex/OpportunityBundleService.getQuoteBundleTree';

export default class OpportunityBundleView extends LightningElement {
    @api recordId; // Opportunity Id
    @track bundles = [];
    @track standalone = [];
    @track error;
    @track loading = true;

    @wire(getQuoteBundleTree, { opportunityId: '$recordId' })
    wiredData({ data, error }) {
        if (data) {
            this.bundles = Array.isArray(data.bundles) ? data.bundles : [];
            this.standalone = Array.isArray(data.standalone) ? data.standalone : [];
            this.error = undefined;
        } else if (error) {
            this.error = this.normalizeError(error);
            this.bundles = [];
            this.standalone = [];
        }
        this.loading = false;
    }

    get hasData() {
        return (this.bundles && this.bundles.length) || (this.standalone && this.standalone.length);
    }

    // Format amount with Intl using locale only; no currency code passed from server.
    formatAmount(value) {
        try {
            if (value === null || value === undefined) return '';
            return new Intl.NumberFormat(undefined, { style: 'decimal', minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(value);
        } catch (e) {
            return value;
        }
    }

    normalizeError(err) {
        if (Array.isArray(err?.body)) {
            return err.body.map(e => e.message).join(', ');
        }
        return err?.body?.message || err?.message || 'Unknown error';
    }

    // Expand/collapse toggles for bundles
    handleToggle(event) {
        const id = event.currentTarget?.dataset?.id;
        if (!id) return;
        const section = this.template.querySelector(`section[data-id="${id}"]`);
        if (section) {
            section.classList.toggle('expanded');
        }
    }

    renderedCallback() {
        // Ensure all bundles start as collapsed
        if (this.bundles && this.bundles.length > 0) {
            const sections = this.template.querySelectorAll('section.bundle');
            sections.forEach(section => {
                section.classList.remove('expanded');
            });
        }
    }
    
    connectedCallback() {
        // Initialize the component state
        this.loading = true;
        this.error = undefined;
    }
}
