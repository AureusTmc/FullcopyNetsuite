/*
        Name            :    PackageProcessInterface
        Date            :    28th March 2019
        Author          :    Arpit Vijayvergiya
        Description     :    This is parent interface to handle package Upgrade,Downgrade and Cancellation Process.
*/

public interface PackageProcessInterface{
     List<Invoice_Line_Item__c> createInvoiceLineItem(Invoice__c objInvoice,Map<String,List<Date>> mapOfDates);
}