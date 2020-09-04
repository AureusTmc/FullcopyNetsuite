/*
    Name            :    PackageDowngradeController
    Date            :    28th March 2019
    Author          :    Arpit Vijayvergiya
    Description     :    This Controller is used for create Invoice LineItem for PackageDowngrade.
        
*/

public class PackageDowngradeController implements PackageProcessInterface{
    private Subscription_Line_Item__c objSubLineItem;
    //private Date firstDate;
    //private Date lastDate;
    public PackageDowngradeController  (Subscription_Line_Item__c objSubLineItem){
        this.objSubLineItem = objSubLineItem;
    } 
    public List<Invoice_Line_Item__c> createInvoiceLineItem(Invoice__c objInvoice,Map<String,List<Date>> mapOfDates){
        System.debug('package downgrade test');
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        
        Integer countWithOldPackage = 0;
        Integer countWithNewPackage = 0;
        
        if(String.isNotBlank(objSubLineItem.Enrolment__r.Lesson_Day__c) && mapOfDates.containsKey(objSubLineItem.Enrolment__r.Lesson_Day__c)){
            Date effectiveDate = objSubLineItem.Enrolment__r.Effective_Date__c;
            
            /*
             * Commented by arpit @04th July, now we create a payment record of payment as deposit
             * Decimal depositeFee = (objSubLineItem.Enrolment__r.New_Package_Id__r.Deposit_Fee__c - objSubLineItem.Enrolment__r.Package__r.Deposit_Fee__c);
            */
            List<Date> listOfDates = mapOfDates.get(objSubLineItem.Enrolment__r.Lesson_Day__c);
            if(listOfDates.size() == 5){
                listOfDates.remove(4);
            }
            for(Date objDate : listOfDates){
                if(objDate < effectiveDate ){
                    countWithOldPackage +=1;
                }else if(objDate >= effectiveDate){
                    countWithNewPackage +=1;
                }
            }
            Decimal newPackageUnitPrice = (objSubLineItem.Enrolment__r.New_Package_Id__r.Unit_Fee__c)*countWithNewPackage ;
            Decimal oldPackageUnitPrice = (objSubLineItem.Enrolment__r.Package__r.Unit_Fee__c)*countWithOldPackage;
            
            /*
             * // Commented by arpit @04th July, now we create a payment record of payment as deposit 
             * if(depositeFee != 0){
                listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,depositeFee ,objSubLineItem.Enrolment__r.New_Package_Id__c,true,''));
            }*/
            if(countWithOldPackage >= 1){
                listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,oldPackageUnitPrice ,objSubLineItem.Enrolment__r.Package__c,FALSE,objSubLineItem.Enrolment__r.Teacher__c));
            }
            if(countWithNewPackage >= 1){
                listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,newPackageUnitPrice ,objSubLineItem.Enrolment__r.New_Package_Id__c,FALSE,objSubLineItem.Enrolment__r.Teacher__c));
            }         
        }
        return listOfInvoiceLineItems;
    }
}