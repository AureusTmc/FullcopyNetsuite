@isTest
public class testUtility{
    public static Account createAccount(String name, String recType, Boolean isDML) {
        
        Account acc = new Account();
        if(recType != 'Center'){
            acc.LastName = name;
        }else{
            acc.Name = name;
        }
        if(String.isNotBlank(recType)){
            String recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recType).getRecordTypeId();
            acc.recordTypeId = recTypeId;
        }
        
        if(isDML){
            insert acc;
        }
        return acc;
    }
    
    public static Booking__c createBooking(String center, String recType, Boolean isDML) {
        
        Booking__c booking = new Booking__c();
        booking.Center__c = center;
        if(String.isNotBlank(recType)){
            String recTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(recType).getRecordTypeId();
            booking.recordTypeId = recTypeId;
        }
        
        if(isDML){
            insert booking;
        }
        return booking;
    }
    
    public static Enrolment__c createEnrolment(String center, Boolean isDML) {
        
        Enrolment__c enrolment = new Enrolment__c();
        enrolment.Center__c = center;
        
        if(isDML){
            insert enrolment;
        }
        return enrolment;
    }
    
    public static Subscription__c createSubscription(String parent, Boolean isDML) {
        
        Subscription__c subscription = new Subscription__c();
        subscription.Parent__c = parent;
        
        if(isDML){
            insert subscription;
        }
        return subscription;
    }
    
    public static Subscription_Line_Item__c createSubscription_Line_Item(String subscription, Boolean isDML) {
        
        Subscription_Line_Item__c subscriptionLineItem = new Subscription_Line_Item__c();
        subscriptionLineItem.Subscription__c = subscription;
        
        if(isDML){
            insert subscriptionLineItem;
        }
        return subscriptionLineItem;
    }
    
    public static Invoice__c createInvoice(String parent, Boolean isDML) {
        
        Invoice__c invoice = new Invoice__c();
        invoice.Parent_Account__c = parent;
        invoice.due_date__c = System.today();
        invoice.Status__c = 'Due';
        if(isDML){
            insert invoice;
        }
        return invoice;
    }
    
    public static Invoice_Line_Item__c createInvoice_Line_Item(String invoice, Boolean isDML) {
        
        Invoice_Line_Item__c invoiceLineItem = new Invoice_Line_Item__c();
        invoiceLineItem.Invoice__c = invoice;
        
        if(isDML){
            insert invoiceLineItem;
        }
        return invoiceLineItem;
    }
}