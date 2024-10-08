# ConvertedLeadStatusBatch
A Salesforce Apex Batch class for updating converted Lead statuses that helps understand how Leads convert into new or existing records

## WHY
In Salesforce, while a user converts a Lead, he can take multiple decisions:
- New or existing Account
- New or existing Contact
- New, existing, or no Opportunity

Usually it is hard to report on what percentage of leads lead to e.g. new contacts.

## SOLUTION
By comparing the Conversion Date with the Creation Date of Account, Contact and Opportunity, we identify what was done in the conversion process.
By updating the Lead Status, it is easy to get the necessary insights using standard reports.


# IMPLEMENTATION
## Avoiding issues due to bad data
In the initial SOQL Query we ensure that we only handle leads that have the necessary fields. This is usually the case. However, if you have migrated leads into you org in the past, it can lead to issues (speaking from experience).
- IsConverted
- ConvertedDate
- ConvertedAccountId
- ConvertedContactId

## Testing
There is a comprehensive test class LeadStatusBatchTest.cls to ensure the batch class functions as expected.

## Error Handling
For Error Handling we use a custom object (and a flow that sends an email as soon as we have a new record in there).
As you might not have this in your org, this is currently outcommented.
You might want to implement your own error logging.

Of course you can also create the same object as we have:
Object Name: ErrorLog__c 
(Auto Number as Name)
Fields: 
- Class Name ClassName__c Text(255)
- Function Name FunctionName__c Text(255)
- Error Message ErrorMessage__c Text(255)
- Error Message Long ErrorMessageLong__c Long Text Area(131072)
- Stack Trace StackTrace__c Text(255)
- Record ID RecordId__c Text(255)


# License
This project is licensed under the MIT License. See the LICENSE file for details.
