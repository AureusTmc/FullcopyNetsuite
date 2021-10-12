/*
        Name        : SendInvoiceInMailBatch
        Date        : 2019/07/30
        Description : This batch class is used to send mail with invoice as pdf attachment to accounts.
*/

global class SendInvoiceInMailBatch implements Database.Batchable<Invoice__c>{
    private Set<String> invoiceIds ;
    public SendInvoiceInMailBatch(Set<String> invoiceIds){
        this.invoiceIds = invoiceIds;
    }
    
    global List<Invoice__c> start(Database.BatchableContext context){
        String query;
        if(invoiceIds != null && !invoiceIds.isEmpty()){
            query = 'SELECT Id, Center__r.Location__c, Parent_Account__r.PersonEmail, Parent_Account__r.PersonContactId, Email_Sent__c,Center__r.Organisation__r.Name FROM Invoice__c WHERE Id IN : invoiceIds AND Email_Sent__c = FALSE AND Parent_Account__r.Want_Invoice_As_Email__c = TRUE';
        }
        return Database.query(query);
    }
    
    global void execute(Database.BatchableContext context, List<Invoice__c> listOfInvoices){
        
        List<Messaging.SingleEmailMessage> mailsToSendList = new List<Messaging.SingleEmailMessage>();
        String templateId = AureusUtility.getEmailTemplateId('Invoice_Receipt');
        String ossiaTemplateId = AureusUtility.getEmailTemplateId('Ossia_Invoice_Receipt');
        if(String.isNotBlank(templateId) && String.isNotBlank(ossiaTemplateId)){
            for(Invoice__c invoiceObj: listOfInvoices){
                if(String.isNotBlank(invoiceObj.Parent_Account__r.PersonContactId) && String.isNotBlank(invoiceObj.Center__r.Location__c)){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    //nishi:12-Oct-2020: for sending a email according to organisation
                    if(string.isNotBlank(invoiceObj.Center__r.Organisation__r.Name) && invoiceObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                        mail = AureusUtility.getSingleEmailMessage(ossiaTemplateId,invoiceObj.Parent_Account__r.PersonContactId,invoiceObj.Id,invoiceObj.Center__r.Location__c);
                    }else{
                        mail = AureusUtility.getSingleEmailMessage(templateId,invoiceObj.Parent_Account__r.PersonContactId,invoiceObj.Id,invoiceObj.Center__r.Location__c);
                    }
                    //nishi:12-Oct-2020: for sending a email according to organisation
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName('Invoice.pdf');
                    efa.setBody(AureusUtility.getInvoicePDF(invoiceObj.Id));
                    mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                    mailsToSendList.add(mail);
                }
            }
            if(!mailsToSendList.isEmpty()){
                Messaging.SendEmailResult[] result = Messaging.sendEmail(mailsToSendList,false);
                Set<Id> targetIdsFailed = new Set<Id>();
                for(Messaging.SendEmailResult resObj: result){
                    if(!resObj.isSuccess()){
                        targetIdsFailed.add(resObj.getErrors()[0].getTargetObjectId());
                    }
                }
                for(Invoice__c invoiceObj: listOfInvoices){
                    if(!targetIdsFailed.contains(invoiceObj.Parent_Account__r.PersonContactId)){
                        invoiceObj.Email_Sent__c = true;
                    }
                }
            }
            
            if(!listOfInvoices.isEmpty()){
                update listOfInvoices;
            }
        }
    }
    
    global void finish(Database.BatchableContext context){
        
    }
}