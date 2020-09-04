/*
Name        :        InvoiceAttachmentBatchTest
Date        :        31st May 2019
Description :        It is the test class of InvoiceAttachmentBatch.
*/
@isTest
public class InvoiceAttachmentBatchTest {
    @isTest
    public static void invokeInvoiceAttachmentBatch(){
        Account objCustmr=TestUtil.createAccount('Customer',True,false); 
        objCustmr.personEmail = 'test@tmc.com';
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT objCustmr;
        
        Invoice__c invoiceObj = TestUtil.createInvoice(objCustmr.Id, true);
        Set<String> invoices = new Set<String>();
        invoices.add(invoiceObj.Id);
        InvoiceAttachmentBatch obj = new InvoiceAttachmentBatch(invoices);
        Database.executeBatch(obj,200);
        
    }
    
}