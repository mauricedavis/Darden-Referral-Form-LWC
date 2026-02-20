@isTest
private class ReferralFormControllerTest {
    
    @isTest
    static void testSubmitReferralNewLeads() {
        // Test creating new leads when no existing contacts/leads
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'John Referrer',
            'john.referrer@test.com',
            'Jane Referral',
            'Test Company',
            'jane.referral@test.com'
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify referrer lead was created
        List<Lead> referrerLeads = [SELECT Id, FirstName, LastName, Email FROM Lead WHERE Email = 'john.referrer@test.com'];
        System.assertEquals(1, referrerLeads.size(), 'Referrer lead should be created');
        System.assertEquals('John', referrerLeads[0].FirstName);
        System.assertEquals('Referrer', referrerLeads[0].LastName);
        
        // Verify referral lead was created
        List<Lead> referralLeads = [SELECT Id, FirstName, LastName, Email, Company, Description FROM Lead WHERE Email = 'jane.referral@test.com'];
        System.assertEquals(1, referralLeads.size(), 'Referral lead should be created');
        System.assertEquals('Jane', referralLeads[0].FirstName);
        System.assertEquals('Referral', referralLeads[0].LastName);
        System.assertEquals('Test Company', referralLeads[0].Company);
        System.assert(referralLeads[0].Description.contains('Referred by'), 'Description should contain referral note');
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
            ''
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify referral lead was created without email
        List<Lead> referralLeads = [SELECT Id, FirstName, LastName, Company FROM Lead WHERE FirstName = 'Jane' AND LastName = 'NoEmail'];
        System.assertEquals(1, referralLeads.size(), 'Referral lead should be created without email');
        System.assertEquals('Not Provided', referralLeads[0].Company);
    }
    
    @isTest
    static void testSubmitReferralExistingContact() {
        // Create existing contact
        Contact existingContact = new Contact(
            FirstName = 'Existing',
            LastName = 'Contact',
            Email = 'existing.contact@test.com'
        );
        insert existingContact;
        
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'Referrer Name',
            'existing.contact@test.com',
            'New Referral',
            'Company',
            'new.referral@test.com'
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify no new lead was created for referrer (contact exists)
        List<Lead> referrerLeads = [SELECT Id FROM Lead WHERE Email = 'existing.contact@test.com'];
        System.assertEquals(0, referrerLeads.size(), 'No lead should be created for existing contact');
    }
    
    @isTest
    static void testSubmitReferralUpdateExistingContact() {
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
            'referral.person@test.com'
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify existing contact was updated with Referred__c field
        Contact updatedContact = [SELECT Id, Description, Referred__c FROM Contact WHERE Id = :existingContact.Id];
        System.assert(updatedContact.Description.contains('Referred by'), 'Description should contain referral note');
        System.assertEquals('Referral Person Full Name', updatedContact.Referred__c, 'Referred__c should be set to referral name');
    }
    
    @isTest
    static void testSubmitReferralExistingLead() {
        // Create existing lead for referral
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'Lead',
            Email = 'existing.lead@test.com',
            Company = 'Existing Company',
            Status = 'Open - Not Contacted'
        );
        insert existingLead;
        
        Test.startTest();
        String result = ReferralFormController.submitReferral(
            'New Referrer',
            'new.referrer@test.com',
            'Existing Lead',
            'New Company',
            'existing.lead@test.com'
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify existing lead was updated with all fields including Alternate_Email__c
        Lead updatedLead = [SELECT Id, Description, LeadSource, Alternate_Email__c FROM Lead WHERE Id = :existingLead.Id];
        System.assertEquals('Referral', updatedLead.LeadSource);
        System.assert(updatedLead.Description.contains('Referred by'), 'Description should be updated');
        System.assertEquals('existing.lead@test.com', updatedLead.Alternate_Email__c, 'Alternate_Email__c should be set');
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
            'another@test.com'
        );
        Test.stopTest();
        
        System.assertEquals('Success', result, 'Should return Success');
        
        // Verify leads created with correct name parsing
        List<Lead> leads = [SELECT FirstName, LastName FROM Lead WHERE Email = 'single@test.com'];
        System.assertEquals(1, leads.size());
        System.assertEquals('SingleName', leads[0].FirstName);
        System.assertEquals('NotProvided', leads[0].LastName);
    }
}
