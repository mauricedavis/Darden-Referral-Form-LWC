@isTest
private class ReferralFormControllerTest {
    
    private static final String TEST_PAGE_URL = 'https://cloud.learn.darden.virginia.edu/ee-darden-alum-tep-referral';
    
    @isTest
    static void testSubmitReferralNewLeads() {
        // Test creating new leads when no existing contacts/leads
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'John Referrer',
            'john.referrer@test.com',
            'Jane Referral',
            'Test Company',
            'jane.referral@test.com',
            TEST_PAGE_URL,
            'linkedin', 'social', 'tep-referral', null, 'banner-ad'
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify referrer lead was created with Page URL and UTM fields
        List<Lead> referrerLeads = [SELECT Id, FirstName, LastName, Email, Page_URL__c, 
                                    utm_source__c, utm_medium__c, utm_campaign__c, utm_content__c 
                                    FROM Lead WHERE Email = 'john.referrer@test.com'];
        System.assertEquals(1, referrerLeads.size(), 'Referrer lead should be created');
        System.assertEquals('John', referrerLeads[0].FirstName);
        System.assertEquals('Referrer', referrerLeads[0].LastName);
        System.assertEquals(TEST_PAGE_URL, referrerLeads[0].Page_URL__c, 'Page URL should be set');
        System.assertEquals('linkedin', referrerLeads[0].utm_source__c, 'UTM Source should be set');
        
        // Verify referral lead was created with Page URL and UTM fields
        List<Lead> referralLeads = [SELECT Id, FirstName, LastName, Email, Company, Description, Page_URL__c,
                                    utm_source__c, LeadSource 
                                    FROM Lead WHERE Email = 'jane.referral@test.com'];
        System.assertEquals(1, referralLeads.size(), 'Referral lead should be created');
        System.assertEquals('Jane', referralLeads[0].FirstName);
        System.assertEquals('Referral', referralLeads[0].LastName);
        System.assertEquals('Test Company', referralLeads[0].Company);
        System.assert(referralLeads[0].Description.contains('Referred by'), 'Description should contain referral note');
        System.assertEquals('Referral', referralLeads[0].LeadSource, 'LeadSource should be Referral for new leads');
    }
    
    @isTest
    static void testSubmitReferralExistingReferrerContact() {
        // Create existing contact for referrer
        Contact existingContact = new Contact(
            FirstName = 'Existing',
            LastName = 'Referrer',
            Email = 'existing.referrer@test.com'
        );
        insert existingContact;
        
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'Existing Referrer',
            'existing.referrer@test.com',
            'New Referral Person',
            'Company',
            'new.referral@test.com',
            TEST_PAGE_URL,
            null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify existing contact was updated with only Description
        Contact updatedContact = [SELECT Id, Description FROM Contact WHERE Id = :existingContact.Id];
        System.assert(updatedContact.Description.contains('Referred: New Referral Person'), 
                     'Description should say Referred: [referral name]');
        
        // Verify no new lead was created for referrer
        List<Lead> referrerLeads = [SELECT Id FROM Lead WHERE Email = 'existing.referrer@test.com'];
        System.assertEquals(0, referrerLeads.size(), 'No lead should be created for existing contact referrer');
    }
    
    @isTest
    static void testSubmitReferralExistingReferrerLead() {
        // Create existing lead for referrer
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'ReferrerLead',
            Email = 'existing.referrer.lead@test.com',
            Company = 'Test Co',
            Status = 'Open - Not Contacted',
            LeadSource = 'Web'
        );
        insert existingLead;
        
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'Existing ReferrerLead',
            'existing.referrer.lead@test.com',
            'Another Referral',
            'Company',
            'another.referral@test.com',
            TEST_PAGE_URL,
            null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify existing lead was updated with only Description
        Lead updatedLead = [SELECT Id, Description, LeadSource FROM Lead WHERE Id = :existingLead.Id];
        System.assert(updatedLead.Description.contains('Referred: Another Referral'), 
                     'Description should say Referred: [referral name]');
        System.assertEquals('Web', updatedLead.LeadSource, 'LeadSource should NOT change for existing referrer');
    }
    
    @isTest
    static void testSubmitReferralUpdateExistingReferralContact() {
        // Create existing contact that will be found as the referral
        Contact existingContact = new Contact(
            FirstName = 'Referral',
            LastName = 'Person',
            Email = 'referral.person@test.com'
        );
        insert existingContact;
        
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'John Doe',
            'john.doe@test.com',
            'Referral Person Full Name',
            'Company',
            'referral.person@test.com',
            TEST_PAGE_URL,
            'google', 'cpc', 'summer-campaign', 'executive education', 'text-link'
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify existing contact was updated per client requirements
        Contact updatedContact = [SELECT Id, Description, Referred__c, Page_URL__c,
                                  hed__AlternateEmail__c, Secondary_Lead_Source__c,
                                  utm_source__c, utm_medium__c, utm_campaign__c, utm_content__c 
                                  FROM Contact WHERE Id = :existingContact.Id];
        System.assert(updatedContact.Description.contains('Referred by'), 'Description should contain referral note');
        System.assertEquals('Referral Person Full Name', updatedContact.Referred__c, 'Referred__c should be set');
        System.assertEquals(TEST_PAGE_URL, updatedContact.Page_URL__c, 'Page URL should be set');
        System.assertEquals('referral.person@test.com', updatedContact.hed__AlternateEmail__c, 'hed__AlternateEmail__c should be set');
        System.assertEquals('Referral', updatedContact.Secondary_Lead_Source__c, 'Secondary_Lead_Source__c should be Referral');
        System.assertEquals('google', updatedContact.utm_source__c, 'UTM Source should be set');
    }
    
    @isTest
    static void testSubmitReferralExistingReferralLead() {
        // Create existing lead for referral
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'Lead',
            Email = 'existing.lead@test.com',
            Company = 'Existing Company',
            Status = 'Open - Not Contacted',
            LeadSource = 'Web'
        );
        insert existingLead;
        
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'New Referrer',
            'new.referrer@test.com',
            'Existing Lead',
            'New Company',
            'existing.lead@test.com',
            TEST_PAGE_URL,
            'email', 'newsletter', 'monthly-update', null, null
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify existing lead was updated per client requirements
        Lead updatedLead = [SELECT Id, Description, LeadSource, Secondary_Lead_Source__c, 
                           Alternate_Email__c, Page_URL__c, utm_source__c, utm_medium__c, utm_campaign__c 
                           FROM Lead WHERE Id = :existingLead.Id];
        System.assert(updatedLead.Description.contains('Referred by'), 'Description should be updated');
        System.assertEquals('existing.lead@test.com', updatedLead.Alternate_Email__c, 'Alternate_Email__c should be set');
        System.assertEquals('Referral', updatedLead.Secondary_Lead_Source__c, 'Secondary_Lead_Source__c should be Referral');
        System.assertEquals('Web', updatedLead.LeadSource, 'LeadSource should NOT change for existing leads');
        System.assertEquals(TEST_PAGE_URL, updatedLead.Page_URL__c, 'Page URL should be set');
        System.assertEquals('email', updatedLead.utm_source__c, 'UTM Source should be set');
    }
    
    @isTest
    static void testSubmitReferralNoEmail() {
        // Test with no referral email
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'John Referrer',
            'john2.referrer@test.com',
            'Jane NoEmail',
            '',
            '',
            TEST_PAGE_URL,
            null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify referral lead was created without email but with Page URL
        List<Lead> referralLeads = [SELECT Id, FirstName, LastName, Company, Page_URL__c FROM Lead WHERE FirstName = 'Jane' AND LastName = 'NoEmail'];
        System.assertEquals(1, referralLeads.size(), 'Referral lead should be created without email');
        System.assertEquals('Not Provided', referralLeads[0].Company);
        System.assertEquals(TEST_PAGE_URL, referralLeads[0].Page_URL__c, 'Page URL should be set');
    }
    
    @isTest
    static void testSubmitReferralSingleName() {
        // Test with single name (no space)
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'SingleName',
            'single@test.com',
            'AnotherSingle',
            'Company',
            'another@test.com',
            TEST_PAGE_URL,
            null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify leads created with correct name parsing
        List<Lead> leads = [SELECT FirstName, LastName FROM Lead WHERE Email = 'single@test.com'];
        System.assertEquals(1, leads.size());
        System.assertEquals('SingleName', leads[0].FirstName);
        System.assertEquals('NotProvided', leads[0].LastName);
    }
    
    @isTest
    static void testSubmitReferralNoPageUrl() {
        // Test with null page URL (should still work)
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'Test User',
            'testuser@test.com',
            'Test Referral',
            'Test Co',
            'testreferral@test.com',
            null,
            null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success even without page URL');
        
        // Verify lead was created without Page URL
        List<Lead> leads = [SELECT Id, Page_URL__c FROM Lead WHERE Email = 'testreferral@test.com'];
        System.assertEquals(1, leads.size(), 'Lead should be created');
        System.assertEquals(null, leads[0].Page_URL__c, 'Page URL should be null');
    }
    
    @isTest
    static void testSubmitReferralWithAllUtmParams() {
        // Test with all UTM parameters
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'UTM Referrer',
            'utm.referrer@test.com',
            'UTM Referral',
            'UTM Company',
            'utm.referral@test.com',
            TEST_PAGE_URL,
            'linkedin', 'social', 'tep-2026', 'executive', 'banner-ad'
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify referral lead has all UTM fields populated
        List<Lead> leads = [SELECT Id, utm_source__c, utm_medium__c, utm_campaign__c, utm_content__c 
                           FROM Lead WHERE Email = 'utm.referral@test.com'];
        System.assertEquals(1, leads.size(), 'Lead should be created');
        System.assertEquals('linkedin', leads[0].utm_source__c, 'UTM Source should be set');
        System.assertEquals('social', leads[0].utm_medium__c, 'UTM Medium should be set');
        System.assertEquals('tep-2026', leads[0].utm_campaign__c, 'UTM Campaign should be set');
        System.assertEquals('banner-ad', leads[0].utm_content__c, 'UTM Content should be set');
    }
}
