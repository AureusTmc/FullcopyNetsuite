/*
    Name            :    RegularInvoiceHandler
    Date            :    28th March 2019
    Author          :    Arpit Vijayvergiya
    Description     :    


*/
public class RegularInvoiceHandler implements PackageProcessInterface{
    private Subscription_Line_Item__c objSubLineItem;
    private Date firstDate;
    private Date lastDate;
    public RegularInvoiceHandler(Subscription_Line_Item__c objSubLineItem,Date firstDate,Date lastDate){
        this.objSubLineItem = objSubLineItem;
    	this.firstDate = firstDate;
        this.lastDate = lastDate;
    } 
    
    public List<Invoice_Line_Item__c> createInvoiceLineItem(Invoice__c objInvoice,Map<String,List<Date>> mapOfDates){
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        // Jatin: 28-jan-2020: for manage rental invoice amount
        if(objSubLineItem.Enrolment__r.recordtype.Name == ConstantsClass.enrollmentInstrumentRecTypeName){
            Date effectiveDate = objSubLineItem.Enrolment__r.Termination_request_date__c;  
            if(effectiveDate != NULL && effectiveDate >= firstDate && effectiveDate <= lastDate){
                Decimal rentalTotalAmount = effectiveDate.day() * ( objSubLineItem.Amount__c /  date.daysInMonth(effectiveDate.year(), effectiveDate.month()));
                system.debug(rentalTotalAmount);
                Invoice_Line_Item__c invLineItm = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,rentalTotalAmount,
                                                                objSubLineItem.Enrolment__r.Package__c,False,objSubLineItem.Enrolment__r.Teacher__c);
                invLineItm.Remarks__c = 'Final Piano Rental';
                listOfInvoiceLineItems.add(invLineItm);
            }else{
                Invoice_Line_Item__c invLineItm = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,objSubLineItem.Amount__c,
                                                                objSubLineItem.Enrolment__r.Package__c,False,objSubLineItem.Enrolment__r.Teacher__c);
                invLineItm.Remarks__c = 'Piano Rental';
                listOfInvoiceLineItems.add(invLineItm);
            }
         }else{
            Date effectiveDate = objSubLineItem.Enrolment__r.Promotional_Period_End_Date__c;       
            if(effectiveDate != NULL && effectiveDate >= firstDate && effectiveDate <= lastDate &&
            String.isNotBlank(objSubLineItem.Enrolment__r.Lesson_Day__c) && 
            mapOfDates.containsKey(objSubLineItem.Enrolment__r.Lesson_Day__c)){
                Integer noOfLessonToBeBilled = 0;
                List<Date> listOfDates = mapOfDates.get(objSubLineItem.Enrolment__r.Lesson_Day__c);
                if(listOfDates.size() == 5){
                    listOfDates.remove(4);
                }
                for(Date objDate : listOfDates){
                    if(objDate > effectiveDate){
                        noOfLessonToBeBilled += 1;
                    } 
                }
                if(noOfLessonToBeBilled > 0){
                    Decimal lessonCharge = noOfLessonToBeBilled *  objSubLineItem.Enrolment__r.Package__r.Unit_Fee__c;
                    listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,lessonCharge  ,objSubLineItem.Enrolment__r.Package__c,False,objSubLineItem.Enrolment__r.Teacher__c)); 
                }   
            }else{
                Invoice_Line_Item__c invLineItm = PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,objSubLineItem.Amount__c,
                                                                objSubLineItem.Enrolment__r.Package__c,False,objSubLineItem.Enrolment__r.Teacher__c);
                listOfInvoiceLineItems.add(invLineItm);
            }   
         }
        return listOfInvoiceLineItems;
    }

}