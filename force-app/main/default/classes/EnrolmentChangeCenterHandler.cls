/*
    Name            :     EnrolmentChangeCenterHandler
    Date            :     07th Sep 2020
    Author          :
    Description     :    This class handle billing of enrolment change center request to distribute revenue on teacher basis.

*/
public class EnrolmentChangeCenterHandler implements PackageProcessInterface{
    private Subscription_Line_Item__c objSubLineItem;
    public EnrolmentChangeCenterHandler(Subscription_Line_Item__c objSubLineItem){
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
                    //countWithOldTeacher +=1; // commented by nishi: 11-Sep-2020: for billing to  effective month  
                    countWithNewTeacher +=1;
                }else if(objDate >= effectiveDate){
                    countWithNewTeacher +=1;
                }
            }
            Decimal newTeacherUnitPrice = (objSubLineItem.Enrolment__r.New_Package_Id__r.Unit_Fee__c)*countWithNewTeacher ;
            Decimal oldTeacherUnitPrice = (objSubLineItem.Enrolment__r.Package__r.Unit_Fee__c)*countWithOldTeacher;
            System.debug('countWithOldTeacher '+countWithOldTeacher);
            System.debug('countWithNewTeacher '+countWithNewTeacher);
            
            if(countWithOldTeacher >= 1){
                listOfInvoiceLineItems.add(createInvoiceLineItem(objInvoice.id,objSubLineItem,oldTeacherUnitPrice ,objSubLineItem.Enrolment__r.Package__c,FALSE,objSubLineItem.Enrolment__r.Teacher__c));
            }
            if(countWithNewTeacher >= 1){
                listOfInvoiceLineItems.add(createInvoiceLineItem(objInvoice.id,objSubLineItem,newTeacherUnitPrice ,objSubLineItem.Enrolment__r.New_Package_Id__c,FALSE,objSubLineItem.Enrolment__r.New_Teacher__c));
            }         
        }
       System.debug('listOfInvoiceLineItems '+listOfInvoiceLineItems.size());
        return listOfInvoiceLineItems;
    }

    public static Invoice_Line_Item__c createInvoiceLineItem(Id invoiceId,Subscription_Line_Item__c objSubLineItem,Decimal amount,
                                                               Id packageId,Boolean isDeposit,String teacherId){
        Invoice_Line_Item__c invLineItm = new Invoice_Line_Item__c();
        invLineItm.Enrolment__c = objSubLineItem.Enrolment__c;
        invLineItm.Subscription_Line_Item__c = objSubLineItem.Id;
        if(amount > 0){
        	invLineItm.Amount__c = BillingUtility.roundOffAmount(amount);                                                               
        }                                                           
         //objSubLineItem.Amount__c;
        invLineItm.Package__c = packageId;  //objSubLineItem.Plan_Package__c;
        invLineItm.Invoice__c = invoiceId;//objInvoice.id;
        invLineItm.Is_Deposit__c = isDeposit;
        if(String.isNotBlank(teacherId)){
            invLineItm.teacher_id__c = teacherId;
        }
        if(!isDeposit){
            if(String.isNotBlank(objSubLineItem.Enrolment__r.New_Centre__c) && String.isNotBlank(objSubLineItem.Enrolment__r.New_Centre__r.Country__c) && 
                objSubLineItem.Enrolment__r.New_Centre__r.Country__r.Tax_Rate__c > 0 && amount > 0){
                    Double gstAmount = BillingUtility.roundOffAmount(Double.valueOf(amount) * (objSubLineItem.Enrolment__r.New_Centre__r.Country__r.Tax_Rate__c / 100));
                    invLineItm.gst_Amount__c = gstAmount;
            }
        }
        return invLineItm;
    }
}