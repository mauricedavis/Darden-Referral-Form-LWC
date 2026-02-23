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
    utmSource = '';
    utmMedium = '';
    utmCampaign = '';
    utmTerm = '';
    utmContent = '';
    
    connectedCallback() {
        this.captureTrackingData();
    }
    
    captureTrackingData() {
        try {
            const urlParams = new URLSearchParams(window.location.search);
            
            // Capture UTM parameters
            this.utmSource = urlParams.get('utm_source') || '';
            this.utmMedium = urlParams.get('utm_medium') || '';
            this.utmCampaign = urlParams.get('utm_campaign') || '';
            this.utmTerm = urlParams.get('utm_term') || '';
            this.utmContent = urlParams.get('utm_content') || '';
            
            // Capture page URL
            const paramUrl = urlParams.get('pageUrl') || urlParams.get('ref') || urlParams.get('source');
            
            if (paramUrl) {
                this.pageUrl = decodeURIComponent(paramUrl);
            } else if (document.referrer) {
                this.pageUrl = document.referrer;
            } else {
                this.pageUrl = window.location.href;
            }
        } catch (e) {
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
                pageUrl: this.pageUrl,
                utmSource: this.utmSource,
                utmMedium: this.utmMedium,
                utmCampaign: this.utmCampaign,
                utmTerm: this.utmTerm,
                utmContent: this.utmContent
            });
            
            this.isSubmitted = true;
        } catch (error) {
            this.errorMessage = error.body?.message || 'An error occurred. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }
}
