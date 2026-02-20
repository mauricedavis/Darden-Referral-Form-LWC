# Darden Executive Education - Referral Form LWC

A custom Lightning Web Component (LWC) solution for the Darden School of Business Executive Education referral form, designed to replace the standard Salesforce Flow component on Experience Sites.

## Project Overview

### The Problem

The Darden Executive Education team needed to embed a referral form on an external website via a Salesforce Experience Site. The original implementation used a standard Salesforce Screen Flow (`Website_Referral_Form`), which presented two critical styling issues:

1. **Unwanted gray bars/borders** around the embedded form
2. **Right-aligned Submit button** that needed to be centered

### Why Standard Approaches Failed

Multiple approaches were attempted before arriving at the final solution:

| Approach | Result | Reason for Failure |
|----------|--------|-------------------|
| CSS in Experience Site Head Markup | Failed | Shadow DOM encapsulation prevents external CSS from penetrating Flow components |
| JavaScript Static Resource injection | Failed | Flow components use **closed** Shadow DOM, blocking `shadowRoot` access |
| LWC Wrapper around Flow | Partial | Resolved permission issues but could not style internal Flow elements |

### Root Cause Discovery

The original Experience Site ("Referrals") was built using the **Lightning Web Runtime (LWR)** framework, which has stricter security restrictions for guest users compared to Aura-based sites. This prevented LWCs with Apex dependencies from rendering for unauthenticated users.

### The Solution

Created a completely custom LWC (`referralForm`) with:
- Full control over styling (centered button, no gray bars)
- Dedicated Apex controller (`ReferralFormController`) replicating all Flow logic
- Compatible with Aura-based Experience Sites for guest user access

## Components

### Lightning Web Component

**`referralForm`** - Custom form component with:
- 5 input fields matching the original Flow
- Centered Submit button
- Loading spinner during submission
- Success/Thank you message
- Full validation

### Apex Controller

**`ReferralFormController.cls`** - Backend logic that:
- Processes referrer information (creates Lead if not exists)
- Processes referral information (creates/updates Lead or Contact)
- Runs in `without sharing` mode for guest user access
- Uses the Executive Education Record Type

### Logic Flow

```
1. User submits form
   │
2. Process Referrer
   ├── Check if Contact exists (by email) → Skip if found
   ├── Check if Lead exists (by email, not converted) → Skip if found
   └── Create new Lead if not found
   │
3. Process Referral
   ├── If no email provided → Create Lead without email
   ├── If Contact exists → Update Description + Referred__c field
   ├── If Lead exists → Update Description, LeadSource, Alternate_Email__c
   └── If not found → Create new Lead
   │
4. Display Thank You message
```

### Field Mappings

| Form Field | Lead Field | Contact Field |
|------------|------------|---------------|
| Your Name | FirstName, LastName | - |
| Your Email | Email | - |
| Referral Name | FirstName, LastName | - |
| Referral Company | Company | - |
| Referral Email | Email | - |
| (Auto) | Description, LeadSource="Referral" | Description, Referred__c |
| (Auto) | RecordTypeId (Exec Ed) | - |
| (Auto) | Status="Open - Not Contacted" | - |

## Deployment

### Prerequisites

- Salesforce CLI (`sf`) installed
- Authenticated to target org: `sf org login web -a darden-prod`

### Deploy to Org

```bash
# Deploy Apex classes with tests
sf project deploy start \
  --source-dir force-app/main/default/classes \
  --test-level RunSpecifiedTests \
  --tests ReferralFormControllerTest \
  --target-org darden-prod

# Deploy LWC
sf project deploy start \
  --source-dir force-app/main/default/lwc/referralForm \
  --target-org darden-prod

# Deploy Permission Set
sf project deploy start \
  --source-dir force-app/main/default/permissionsets \
  --target-org darden-prod
```

### Experience Site Configuration

1. **Important**: Use an **Aura-based** Experience Site (not LWR)
2. In Experience Builder, drag the "Referral Form" component onto the page
3. Publish the site
4. Assign the `Referral_Flow_Access` permission set to the Guest User profile

### Guest User Permissions Required

The following permissions must be granted to the Experience Site Guest User:

- **Apex Class Access**: `ReferralFormController`
- **Object Permissions**:
  - Lead: Read, Create, Edit
  - Contact: Read, Edit
- **Permission Set**: `Referral_Flow_Access`

## File Structure

```
force-app/
└── main/
    └── default/
        ├── classes/
        │   ├── ReferralFormController.cls
        │   ├── ReferralFormController.cls-meta.xml
        │   ├── ReferralFormControllerTest.cls
        │   └── ReferralFormControllerTest.cls-meta.xml
        ├── lwc/
        │   └── referralForm/
        │       ├── referralForm.html
        │       ├── referralForm.js
        │       ├── referralForm.css
        │       └── referralForm.js-meta.xml
        ├── permissionsets/
        │   └── Referral_Flow_Access.permissionset-meta.xml
        ├── flows/
        │   └── Website_Referral_Form.flow-meta.xml (original Flow for reference)
        └── profiles/
            └── Referrals Profile.profile-meta.xml
```

## Testing

The `ReferralFormControllerTest` class provides 100% code coverage with the following test scenarios:

1. **New Leads Creation** - Both referrer and referral are new
2. **No Email Provided** - Referral submitted without email
3. **Existing Contact (Referrer)** - Referrer already exists as Contact
4. **Existing Lead (Referral)** - Referral already exists as unconverted Lead
5. **Single Name Handling** - Names without spaces default LastName to "NotProvided"
6. **Existing Contact (Referral)** - Updates Contact with `Referred__c` field

Run tests:
```bash
sf apex run test -n ReferralFormControllerTest --target-org darden-prod --result-format human
```

## Known Limitations

1. **LWR Sites**: This LWC will **not** render for guest users on Lightning Web Runtime (LWR) Experience Sites. Use Aura-based sites only.

2. **Record Type**: The Executive Education Record Type ID (`012d0000000XRiCAAW`) is hardcoded. Update in `ReferralFormController.cls` if deploying to a different org.

3. **Custom Fields**: Requires these custom fields to exist:
   - `Contact.Referred__c` (Text)
   - `Lead.Alternate_Email__c` (Email)

## Related JIRA Ticket

**DARDENEXED-3** - Referral Form Styling Issues

## Authors

- Attain Partners
- Darden School of Business IT Team

## License

This project is proprietary to the University of Virginia Darden School of Business.
