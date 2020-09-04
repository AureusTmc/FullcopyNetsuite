/*
    Name            :   VoidInvoiceController
    Date            :   20 May 2019
    Author          :
    Description     :   This class is used for void and delete process of invoice.
*/
public class VoidInvoiceController {
    @AuraEnabled
    public static String processInvoice(String invId, String processType,String remark){
        String parentId = '';
        if(String.isNotBlank(invId) && String.isNotBlank(processType)){
            if(processType == 'void'){
                Invoice__c objInv = new Invoice__c(Id=invId, Status__c ='void',Remarks__c = remark);
                update objInv;
                if(string.isNotBlank(objInv.id)){
                    /* Jatin:6-mar-2020:Start: check that if the invoice type is prepayment and promo 
                                    then we will not send the info to sage 
                                    instead of that we will send the email to the customer
                                    other wise we call sage function and update invoice */
                    Map<string,Boolean> mapOfInvoiceIsPromoPrepayemnt = checkInvoiceIsPromoPrepayemnt(new Set<Id>{objInv.id});
                    system.debug('mapOfInvoiceIsPromoPrepayemnt'+mapOfInvoiceIsPromoPrepayemnt);
                    if(mapOfInvoiceIsPromoPrepayemnt != null && mapOfInvoiceIsPromoPrepayemnt.size() > 0){
                        if(mapOfInvoiceIsPromoPrepayemnt.containsKey(objInv.id) && mapOfInvoiceIsPromoPrepayemnt.get(objInv.id)){
                            EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:'Void_Invoice_PrePayment' LIMIT 1];
                            system.debug('template'+template);
                            objInv =  [SELECT Id, Parent_Account__r.personContactId ,Center__r.Location__c FROM Invoice__c WHERE Id=: objInv.id];
                            system.debug('objInv'+objInv);
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(template.id,objInv.Parent_Account__r.personContactId,objInv.Id,objInv.Center__r.Location__c);
                            mail.setTreatTargetObjectAsRecipient(false);
                            mail.setToAddresses(new list<string>{Label.Financial_User_Email});
                            system.debug('mail'+mail);
                            Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {mail},FALSE);

                        }else{
                            SageIntacctIntegrationUtility.voidInvoice(invId);
                        }
                    }
                }
                
            }else if(processType == 'delete'){
                Invoice_Archive__c invoiceArchive = new Invoice_Archive__c();
                List<Payment__c> payments = new List<Payment__c>();
                List<Invoice__c> objInv = [SELECT Id, Name, Parent_Account__c, (SELECT Id FROM Payments__r) FROM Invoice__c WHERE Id=: invId]; 
                if(objInv.size() > 0){ 
                    
                    invoiceArchive.Parent__c = objInv[0].Parent_Account__c;
                    invoiceArchive.Deleted_By__c = UserInfo.getUserId();
                    invoiceArchive.Name = objInv[0].Name;
                    
                    INSERT invoiceArchive;
                    for(Payment__c payment : objInv[0].Payments__r){
                        payments.add(payment);
                    } 
                    parentId = objInv[0].Parent_Account__c;
                }
                
                if(payments.size() > 0){
                    DELETE payments;                   
                }
                DELETE objInv;
                
            }
        }
        return parentId;
    }

/* Jatin:6-mar-2020:Start: check that invoice id  if the invoice type is prepayment and promo  or not
 if Prepayement or promo then return true otherwise false  */
    public static Map<string,Boolean> checkInvoiceIsPromoPrepayemnt(Set<Id> InvoiceIds){
        Map<string,Boolean> mapOfInvoiceIsPromoPrepayemnt = new  Map<string,Boolean>();
        if(InvoiceIds != null && InvoiceIds.size() > 0){
            Set<string> packageType = new Set<string>{ConstantsClass.PromoTypePayment,ConstantsClass.prePaymentType};

            For(invoice__c objInvoice: [Select Id,
                                        (select id, package__c 
                                            from invoice_line_items__r 
                                            where Package__r.Type_of_package__c in: packageType)
                                        from invoice__c 
                                        where id IN: InvoiceIds]) {
                if(objInvoice.invoice_line_items__r != null && objInvoice.invoice_line_items__r.size() > 0){
                    mapOfInvoiceIsPromoPrepayemnt.put(objInvoice.id,True);
                }else{
                    mapOfInvoiceIsPromoPrepayemnt.put(objInvoice.id,False);
                }
            } 
        }  
        return mapOfInvoiceIsPromoPrepayemnt;
    }
}