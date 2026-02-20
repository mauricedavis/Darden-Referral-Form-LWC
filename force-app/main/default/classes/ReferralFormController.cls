public without sharing class ReferralFormController {
    
    private static final String EXEC_ED_RECORD_TYPE_ID = '012d0000000XRiCAAW';
    private static final String SYSTEM_ADMIN_USERNAME = 'sysadmin@darden.virginia.edu.salesforce';
    
    @AuraEnabled
    public static String submitReferral(String referrerName, String referrerEmail, 
                                        String referralName, String referralCompany, 
                                        String referralEmail) {
        try {
            // Parse names
            String referrerFirstName = getFirstName(referrerName);
            String referrerLastName = getLastName(referrerName);
            String referralFirstName = getFirstName(referralName);
            String referralLastName = getLastName(referralName);
            
            // Process Referrer
            processReferrer(referrerEmail, referrerFirstName, referrerLastName);
            
            // Process Referral
            String referralNote = 'Referred by: ' + referrerName + ' (' + referrerEmail + ')';
            String company = String.isBlank(referralCompany) ? 'Not Provided' : referralCompany;
            
            processReferral(referralEmail, referralFirstName, referralLastName, 
                          company, referralNote, referralName);
            
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting referral: ' + e.getMessage());
        }
    }
    
    private static void processReferrer(String email, String firstName, String lastName) {
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
        
        // Set owner to System Admin
        Id sysAdminId = getSystemAdminUserId();
        if (sysAdminId != null) {
            newLead.OwnerId = sysAdminId;
        }
        
        insert newLead;
    }
    
    private static void processReferral(String email, String firstName, String lastName, 
                                        String company, String referralNote, String referralName) {
        if (String.isBlank(email)) {
            // No email provided - create Lead without email
            createReferralLead(null, firstName, lastName, company, referralNote);
            return;
        }
        
        // Check if referral exists as Contact
        List<Contact> contacts = [SELECT Id, Description FROM Contact WHERE Email = :email ORDER BY LastModifiedDate DESC LIMIT 1];
        if (!contacts.isEmpty()) {
            // Update existing Contact - match Flow behavior
            Contact c = contacts[0];
            c.Description = referralNote;
            c.Referred__c = referralName;
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
            update l;
            return;
        }
        
        // Create new Lead for referral
        createReferralLead(email, firstName, lastName, company, referralNote);
    }
    
    private static void createReferralLead(String email, String firstName, String lastName, 
                                           String company, String referralNote) {
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
        
        // Set owner to System Admin
        Id sysAdminId = getSystemAdminUserId();
        if (sysAdminId != null) {
            newLead.OwnerId = sysAdminId;
        }
        
        insert newLead;
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
