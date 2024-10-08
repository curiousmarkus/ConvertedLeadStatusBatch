public class LeadStatusBatch implements Database.Batchable<SObject>, Schedulable {
    
    // Start method for Batchable interface
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all Leads converted with Status 'Converted', ensure they meet the minimum data quality requirements
        return Database.getQueryLocator([
            SELECT Id, 
                   ConvertedDate, 
                   ConvertedAccount.CreatedDate, 
                   ConvertedContact.CreatedDate, 
                   ConvertedOpportunity.CreatedDate, 
                   Status
            FROM Lead
            WHERE Status = 'Converted'
                AND IsConverted = true
                AND ConvertedDate != null
                AND ConvertedAccountId != null
                AND ConvertedContactId != null
        ]);
    }
    
    // Execute method for Batchable interface
    public void execute(Database.BatchableContext BC, List<Lead> scope) {
        List<Lead> leadsToUpdate = new List<Lead>();
        // List<ErrorLog__c> errorLogs = new List<ErrorLog__c>();
        
        for (Lead ld : scope) {
            try {
                String newStatus = determineNewStatus(ld);
                
                if (newStatus.startsWith('Error')) {
                    // Log the error using existing ErrorLog__c object
                    /*
                    ErrorLog__c errorLog = new ErrorLog__c(
                        ClassName__c = 'LeadStatusBatch',
                        FunctionName__c = 'execute',
                        ErrorMessage__c = newStatus,
                        ErrorMessageLong__c = 'Lead ID: ' + ld.Id,
                        // StackTrace__c can be populated if available
                    );
                    errorLogs.add(errorLog);
                    */
                    
                    // TODO: Implement your own error handling mechanism here.
                    // For example, you could send an email notification, log to a different custom object, or use Platform Events.
                    System.debug('Error in LeadStatusBatch.execute: ' + newStatus + ' for Lead ID: ' + ld.Id);
                    
                } else {
                    // Update the Lead status
                    ld.Status = newStatus;
                    leadsToUpdate.add(ld);
                }
            } catch (Exception e) {
                // Handle unexpected exceptions and log them
                /*
                ErrorLog__c errorLog = new ErrorLog__c(
                    ClassName__c = 'LeadStatusBatch',
                    FunctionName__c = 'execute',
                    ErrorMessage__c = e.getMessage(),
                    ErrorMessageLong__c = 'Lead ID: ' + ld.Id + '\n' + e.getStackTraceString(),
                    StackTrace__c = e.getStackTraceString()
                );
                errorLogs.add(errorLog);
                */
                
                // TODO: Implement your own exception handling mechanism here.
                System.debug('Exception in LeadStatusBatch.execute: ' + e.getMessage() + ' for Lead ID: ' + ld.Id);
            }
        }
        
        // Perform DML operations outside the loop
        if (!leadsToUpdate.isEmpty()) {
            try {
                update leadsToUpdate;
            } catch (DmlException d) {
                // Log DML exceptions
                for (Lead failedLead : leadsToUpdate) {
                    /*
                    ErrorLog__c errorLog = new ErrorLog__c(
                        ClassName__c = 'LeadStatusBatch',
                        FunctionName__c = 'execute',
                        ErrorMessage__c = 'DML Exception',
                        ErrorMessageLong__c = 'Failed to update Lead ID: ' + failedLead.Id + '\n' + d.getMessage(),
                        StackTrace__c = d.getStackTraceString()
                    );
                    errorLogs.add(errorLog);
                    */
                    
                    // TODO: Implement your own DML exception handling mechanism here.
                    System.debug('DML Exception in LeadStatusBatch.execute: Failed to update Lead ID: ' + failedLead.Id + ' - ' + d.getMessage());
                }
            }
        }
        
        /*
        if (!errorLogs.isEmpty()) {
            try {
                insert errorLogs;
            } catch (DmlException d) {
                System.debug('Failed to insert error logs: ' + d.getMessage());
            }
        }
        */
        
        // Note: Since ErrorLog__c is commented out, ensure you have your own error handling implemented.
    }
    
    // Finish method for Batchable interface
    public void finish(Database.BatchableContext BC) {
        // Optionally, implement post-processing like sending notifications
    }
    
    // Helper method to determine the new status based on the provided logic
    private String determineNewStatus(Lead ld) {
        DateTime convertedDate = ld.ConvertedDate;
        DateTime accountCreatedDate = ld.ConvertedAccount.CreatedDate.date();
        DateTime contactCreatedDate = ld.ConvertedContact.CreatedDate.date();
        DateTime oppCreatedDate = ld.ConvertedOpportunity != null ? ld.ConvertedOpportunity.CreatedDate.date() : null;
        
        Boolean isExAcc = accountCreatedDate != null && accountCreatedDate != convertedDate;
        Boolean isNewAcc = accountCreatedDate == convertedDate;
        Boolean isExCon = contactCreatedDate != null && contactCreatedDate != convertedDate;
        Boolean isNewCon = contactCreatedDate == convertedDate;
        
        if (isNewAcc) {
            if (isNewCon) {
                if (oppCreatedDate == null) {
                    return 'Converted - New Acc, New Con, No Opp';
                } else if (oppCreatedDate == convertedDate) {
                    return 'Converted - New Acc, New Con, New Opp';
                } else {
                    return 'Error - not converting into existing Opps';
                }
            } else if (isExCon) {
                if (oppCreatedDate == null) {
                    return 'Converted - New Acc, Ex Con, No Opp';
                } else if (oppCreatedDate == convertedDate) {
                    return 'Converted - New Acc, Ex Con, New Opp';
                } else {
                    return 'Error - not converting into existing Opps';
                }
            }
        } else if (isExAcc) {
            if (isNewCon) {
                if (oppCreatedDate == null) {
                    return 'Converted - Ex Acc, New Con, No Opp';
                } else if (oppCreatedDate == convertedDate) {
                    return 'Converted - Ex Acc, New Con, New Opp';
                } else {
                    return 'Converted - Ex Acc, New Con, Ex Opp';
                }
            } else if (isExCon) {
                if (oppCreatedDate == null) {
                    return 'Converted - Ex Acc, Ex Con, No Opp';
                } else if (oppCreatedDate == convertedDate) {
                    return 'Converted - Ex Acc, Ex Con, New Opp';
                } else {
                    return 'Converted - Ex Acc, Ex Con, Ex Opp';
                }
            }
        }
        
        // Default case if none of the conditions match
        return 'Error - Undefined status criteria';
    }
    
    // Schedulable interface method
    public void execute(SchedulableContext sc) {
        // Define the batch size (optional, default is 200)
        Integer batchSize = 200;
        Database.executeBatch(this, batchSize);
    }
}
