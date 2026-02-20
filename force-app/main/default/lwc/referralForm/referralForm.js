import { LightningElement, track } from 'lwc';
import submitReferral from '@salesforce/apex/ReferralFormController.submitReferral';

export default class ReferralForm extends LightningElement {
    @track referrerName = '';
    @track referrerEmail = '';
    @track referralName = '';
    @track referralCompany = '';
    @track referralEmail = '';
    @track isLoading = false;
    @track isSubmitted = false;
    @track errorMessage = '';
    
    pageUrl = '';
    
    connectedCallback() {
        this.capturePageUrl();
    }
    
    capturePageUrl() {
        try {
            // Try to get the parent page URL (for iframe embeds)
            if (document.referrer) {
                this.pageUrl = document.referrer;
            } else {
                // Fallback to current page URL
                this.pageUrl = window.location.href;
            }
        } catch (e) {
            // If access is blocked due to cross-origin, use current URL
            this.pageUrl = window.location.href;
        }
    }

    handleReferrerNameChange(event) {
        this.referrerName = event.target.value;
        this.clearError();
    }

    handleReferrerEmailChange(event) {
        this.referrerEmail = event.target.value;
        this.clearError();
    }

    handleReferralNameChange(event) {
        this.referralName = event.target.value;
        this.clearError();
    }

    handleReferralCompanyChange(event) {
        this.referralCompany = event.target.value;
    }

    handleReferralEmailChange(event) {
        this.referralEmail = event.target.value;
        this.clearError();
    }

    clearError() {
        this.errorMessage = '';
    }

    validateForm() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        return allValid;
    }

    async handleSubmit() {
        if (!this.validateForm()) {
            this.errorMessage = 'Please fill in all required fields correctly.';
            return;
        }

        this.isLoading = true;
        this.errorMessage = '';

        try {
            await submitReferral({
                referrerName: this.referrerName,
                referrerEmail: this.referrerEmail,
                referralName: this.referralName,
                referralCompany: this.referralCompany,
                referralEmail: this.referralEmail,
                pageUrl: this.pageUrl
            });
            
            this.isSubmitted = true;
        } catch (error) {
            this.errorMessage = error.body?.message || 'An error occurred. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }
}
