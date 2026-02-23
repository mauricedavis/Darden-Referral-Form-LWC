public without sharing class ReferralFormController {
    
    private static final String EXEC_ED_RECORD_TYPE_ID = '012d0000000XRiCAAW';
    private static final String SYSTEM_ADMIN_USERNAME = 'sysadmin@darden.virginia.edu.salesforce';
    
    @AuraEnabled
    public static String submitReferral(String referrerName, String referrerEmail, 
                                        String referralName, String referralCompany, 
                                        String referralEmail, String pageUrl,
                                        String utmSource, String utmMedium, String utmCampaign,
                                        String utmTerm, String utmContent) {
        try {
            // Parse names
            String referrerFirstName = getFirstName(referrerName);
            String referrerLastName = getLastName(referrerName);
            String referralFirstName = getFirstName(referralName);
            String referralLastName = getLastName(referralName);
            
            // Process Referrer
            processReferrer(referrerEmail, referrerFirstName, referrerLastName, pageUrl,
                          utmSource, utmMedium, utmCampaign, utmContent);
            
            // Process Referral
            String referralNote = 'Referred by: ' + referrerName + ' (' + referrerEmail + ')';
            String company = String.isBlank(referralCompany) ? 'Not Provided' : referralCompany;
            
            processReferral(referralEmail, referralFirstName, referralLastName, 
                          company, referralNote, referralName, pageUrl,
                          utmSource, utmMedium, utmCampaign, utmContent);
            
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting referral: ' + e.getMessage());
        }
    }
    
    private static void processReferrer(String email, String firstName, String lastName, String pageUrl,
                                        String utmSource, String utmMedium, String utmCampaign, String utmContent) {
        // Check if referrer exists as Contact
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :email ORDER BY LastModifiedDate DESC LIMIT 1];
        if (!contacts.isEmpty()) {
            return; // Referrer already exists as Contact
        }
        
        // Check if referrer exists as Lead
        List<Lead> leads = [SELECT Id FROM Lead WHERE Email = :email AND IsConverted = false ORDER BY LastModifiedDate DESC LIMIT 1];
        if (!leads.isEmpty()) {
            return; // Referrer already exists as Lead
        }
        
        // Create new Lead for referrer
        Lead newLead = new Lead(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            Company = 'Not Provided',
            LeadSource = 'Referral',
            Status = 'Open - Not Contacted',
            RecordTypeId = EXEC_ED_RECORD_TYPE_ID
        );
        
        // Set Page URL if provided
        if (String.isNotBlank(pageUrl)) {
            newLead.Page_URL__c = pageUrl;
        }
        
        // Set UTM fields
        setUtmFieldsOnLead(newLead, utmSource, utmMedium, utmCampaign, utmContent);
        
        // Set owner to System Admin
        Id sysAdminId = getSystemAdminUserId();
        if (sysAdminId != null) {
            newLead.OwnerId = sysAdminId;
        }
        
        insert newLead;
    }
    
    private static void processReferral(String email, String firstName, String lastName, 
                                        String company, String referralNote, String referralName, String pageUrl,
                                        String utmSource, String utmMedium, String utmCampaign, String utmContent) {
        if (String.isBlank(email)) {
            // No email provided - create Lead without email
            createReferralLead(null, firstName, lastName, company, referralNote, pageUrl,
                             utmSource, utmMedium, utmCampaign, utmContent);
            return;
        }
        
        // Check if referral exists as Contact
        List<Contact> contacts = [SELECT Id, Description FROM Contact WHERE Email = :email ORDER BY LastModifiedDate DESC LIMIT 1];
        if (!contacts.isEmpty()) {
            // Update existing Contact - match Flow behavior
            Contact c = contacts[0];
            c.Description = referralNote;
            c.Referred__c = referralName;
            if (String.isNotBlank(pageUrl)) {
                c.Page_URL__c = pageUrl;
            }
            // Set UTM fields on Contact
            setUtmFieldsOnContact(c, utmSource, utmMedium, utmCampaign, utmContent);
            update c;
            return;
        }
        
        // Check if referral exists as Lead
        List<Lead> leads = [SELECT Id, Description FROM Lead WHERE Email = :email AND IsConverted = false ORDER BY LastModifiedDate DESC LIMIT 1];
        if (!leads.isEmpty()) {
            // Update existing Lead - match Flow behavior
            Lead l = leads[0];
            l.Description = referralNote;
            l.LeadSource = 'Referral';
            l.Alternate_Email__c = email;
            if (String.isNotBlank(pageUrl)) {
                l.Page_URL__c = pageUrl;
            }
            // Set UTM fields on Lead
            setUtmFieldsOnLead(l, utmSource, utmMedium, utmCampaign, utmContent);
            update l;
            return;
        }
        
        // Create new Lead for referral
        createReferralLead(email, firstName, lastName, company, referralNote, pageUrl,
                         utmSource, utmMedium, utmCampaign, utmContent);
    }
    
    private static void createReferralLead(String email, String firstName, String lastName, 
                                           String company, String referralNote, String pageUrl,
                                           String utmSource, String utmMedium, String utmCampaign, String utmContent) {
        Lead newLead = new Lead(
            FirstName = firstName,
            LastName = lastName,
            Company = company,
            LeadSource = 'Referral',
            Status = 'Open - Not Contacted',
            Description = referralNote,
            RecordTypeId = EXEC_ED_RECORD_TYPE_ID
        );
        if (String.isNotBlank(email)) {
            newLead.Email = email;
        }
        
        // Set Page URL if provided
        if (String.isNotBlank(pageUrl)) {
            newLead.Page_URL__c = pageUrl;
        }
        
        // Set UTM fields
        setUtmFieldsOnLead(newLead, utmSource, utmMedium, utmCampaign, utmContent);
        
        // Set owner to System Admin
        Id sysAdminId = getSystemAdminUserId();
        if (sysAdminId != null) {
            newLead.OwnerId = sysAdminId;
        }
        
        insert newLead;
    }
    
    private static void setUtmFieldsOnLead(Lead l, String utmSource, String utmMedium, 
                                           String utmCampaign, String utmContent) {
        if (String.isNotBlank(utmSource)) {
            l.utm_source__c = utmSource;
        }
        if (String.isNotBlank(utmMedium)) {
            l.utm_medium__c = utmMedium;
        }
        if (String.isNotBlank(utmCampaign)) {
            l.utm_campaign__c = utmCampaign;
        }
        if (String.isNotBlank(utmContent)) {
            l.utm_content__c = utmContent;
        }
    }
    
    private static void setUtmFieldsOnContact(Contact c, String utmSource, String utmMedium, 
                                              String utmCampaign, String utmContent) {
        if (String.isNotBlank(utmSource)) {
            c.utm_source__c = utmSource;
        }
        if (String.isNotBlank(utmMedium)) {
            c.utm_medium__c = utmMedium;
        }
        if (String.isNotBlank(utmCampaign)) {
            c.utm_campaign__c = utmCampaign;
        }
        if (String.isNotBlank(utmContent)) {
            c.utm_content__c = utmContent;
        }
    }
    
    private static String getFirstName(String fullName) {
        if (String.isBlank(fullName)) return '';
        if (!fullName.contains(' ')) return fullName;
        return fullName.substringBefore(' ');
    }
    
    private static String getLastName(String fullName) {
        if (String.isBlank(fullName)) return 'NotProvided';
        if (!fullName.contains(' ')) return 'NotProvided';
        return fullName.substringAfter(' ');
    }
    
    private static Id getSystemAdminUserId() {
        List<User> users = [SELECT Id FROM User WHERE Username = :SYSTEM_ADMIN_USERNAME AND IsActive = true LIMIT 1];
        if (!users.isEmpty()) {
            return users[0].Id;
        }
        return null;
    }
}
