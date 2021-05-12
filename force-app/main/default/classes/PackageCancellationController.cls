/*
    Name            :    PackageCancellationController
    Date            :    4 April 2019
    Author          :    
    Description     :    This controller is used for the creating invoice line item for the package cancellation process.
*/

public class PackageCancellationController implements PackageProcessInterface{
    private Subscription_Line_Item__c objSubLineItem;
    public PackageCancellationController(Subscription_Line_Item__c objSubLineItem){
        this.objSubLineItem = objSubLineItem;
    }
    public List<Invoice_Line_Item__c> createInvoiceLineItem(Invoice__c objInvoice,Map<String,List<Date>> mapOfDates){
        System.debug('Cancellation Controller');
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        if(String.isNotBlank(objSubLineItem.Enrolment__r.Lesson_Day__c) && mapOfDates.containsKey(objSubLineItem.Enrolment__r.Lesson_Day__c)){
            Integer noOfLessonToBeBilled = 0;
            Date effectiveDate = objSubLineItem.Enrolment__r.Effective_Date__c;
            List<Date> listOfDates = mapOfDates.get(objSubLineItem.Enrolment__r.Lesson_Day__c);
            if(listOfDates.size() == 5){
                listOfDates.remove(4);
            }
            for(Date objDate : listOfDates){
                if(objDate <= effectiveDate){
                    noOfLessonToBeBilled += 1;
                } 
            }
            /*Decimal depositeFee = objSubLineItem.Enrolment__r.Package__r.Deposit_Fee__c;
            
            if(depositeFee != 0){
            // deposite fee
                listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,-1*depositeFee ,objSubLineItem.Enrolment__r.Package__c,True,'')); 
            }*/
            if(noOfLessonToBeBilled > 0){
                if(objSubLineItem.Enrolment__r.Type_of_Package__c != ConstantsClass.PromoTypePayment){
                    Decimal lessonCharge = noOfLessonToBeBilled *  objSubLineItem.Enrolment__r.Package__r.Unit_Fee__c;
                    //lesson charge without GST
                    listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,lessonCharge  ,objSubLineItem.Enrolment__r.Package__c,False,objSubLineItem.Enrolment__r.Teacher__c)); 
                }else{
                      // added by nishi: 10-May-2021:start: If the next billing date is less than the effective date and the package is the promo package then we will check that the invoice line item month matches the month of the next billing date, 
                    //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record. the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
           
                  
                    Date effectivePromotionalDate = objSubLineItem.Enrolment__r.Promotional_Period_End_Date__c;   
                     
                    if(effectivePromotionalDate != NULL && (effectivePromotionalDate > effectiveDate   &&
                        String.isNotBlank(objSubLineItem.Enrolment__r.Lesson_Day__c) && 
                        mapOfDates.containsKey(objSubLineItem.Enrolment__r.Lesson_Day__c))){
                        noOfLessonToBeBilled =0;
                        for(Date objDate : listOfDates){
                            if( objDate<=objSubLineItem.Enrolment__r.Promotional_Period_End_Date__c && objSubLineItem.Enrolment__r.Promotional_Period_End_Date__c > effectiveDate){
                                if(objDate < effectiveDate){
                                    noOfLessonToBeBilled+=1;
                                }
                            }
                        }   
                        Decimal lessonCharge = noOfLessonToBeBilled *  objSubLineItem.Enrolment__r.Package_To_Be_Change__r.Unit_Fee__c;
                        //lesson charge without GST
                        listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,lessonCharge  ,objSubLineItem.Enrolment__r.Package_To_Be_Change__c,False,objSubLineItem.Enrolment__r.Teacher__c)); 
                    }
                      // added by nishi: 10-May-2021:start: If the next billing date is less than the effective date and the package is the promo package then we will check that the invoice line item month matches the month of the next billing date, 
                    //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record. the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
           
                  
                }
            }
            //Decimal gstCharge = lessonCharge * ((Decimal.valueOf(Label.GST_Tax_Rate)/100));  
            //System.debug('gstCharge '+gstCharge );
            //Decimal finalAmount = (lessoncharge+gstCharge)- depositeFee;
            //System.debug('finalAmount '+finalAmount );
            //listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,finalAmount ,objSubLineItem.Enrolment__r.Package__c,FALSE)); 
        }
        return listOfInvoiceLineItems;
    } 
}