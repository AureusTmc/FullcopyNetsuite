/*
    Name            :     EnrolmentChangeHandler
    Date            :     28th may 2019
    Author          :
    Description     :    This class handle billing of enrolment change request to distribute revenue on teacher basis.

*/
public class EnrolmentChangeHandler implements PackageProcessInterface{
    private Subscription_Line_Item__c objSubLineItem;
    public EnrolmentChangeHandler(Subscription_Line_Item__c objSubLineItem){
        this.objSubLineItem = objSubLineItem;
    }
    public List<Invoice_Line_Item__c> createInvoiceLineItem(Invoice__c objInvoice,Map<String,List<Date>> mapOfDates){
        System.debug('change handler');
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        Integer countWithOldTeacher = 0;
        Integer countWithNewTeacher = 0;
        
        if(String.isNotBlank(objSubLineItem.Enrolment__r.Lesson_Day__c) && mapOfDates.containsKey(objSubLineItem.Enrolment__r.Lesson_Day__c)){
            Date effectiveDate = objSubLineItem.Enrolment__r.Effective_Date__c;
            
            List<Date> listOfDates = mapOfDates.get(objSubLineItem.Enrolment__r.Lesson_Day__c);
            if(listOfDates.size() == 5){
                listOfDates.remove(4);
            }
            for(Date objDate : listOfDates){
                if(objDate < effectiveDate ){
                    countWithOldTeacher +=1;
                }else if(objDate >= effectiveDate){
                    countWithNewTeacher +=1;
                }
            }
            Decimal newTeacherUnitPrice = (objSubLineItem.Enrolment__r.New_Package_Id__r.Unit_Fee__c)*countWithNewTeacher ;
            Decimal oldTeacherUnitPrice = (objSubLineItem.Enrolment__r.Package__r.Unit_Fee__c)*countWithOldTeacher;
            System.debug('countWithOldTeacher '+countWithOldTeacher);
            System.debug('countWithNewTeacher '+countWithNewTeacher);
            
            if(countWithOldTeacher >= 1){
                listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,oldTeacherUnitPrice ,objSubLineItem.Enrolment__r.Package__c,FALSE,objSubLineItem.Enrolment__r.Teacher__c));
            }
            if(countWithNewTeacher >= 1){
                listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,newTeacherUnitPrice ,objSubLineItem.Enrolment__r.New_Package_Id__c,FALSE,objSubLineItem.Enrolment__r.New_Teacher__c));
            }         
        }
       System.debug('listOfInvoiceLineItems '+listOfInvoiceLineItems.size());
        return listOfInvoiceLineItems;
    }
        
}