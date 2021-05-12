/*
    Name            :    PackageUpgradeController
    Date            :    28th March 2019
    Author          :    Arpit Vijayvergiya
    Description     :    This Controller is used for create Invoice LineItem for PackageUpgrade.
        
*/

public class PackageUpgradeController implements PackageProcessInterface{
    private Subscription_Line_Item__c objSubLineItem;
    public PackageUpgradeController (Subscription_Line_Item__c objSubLineItem){
        this.objSubLineItem = objSubLineItem;
    } 
    public List<Invoice_Line_Item__c> createInvoiceLineItem(Invoice__c objInvoice,Map<String,List<Date>> mapOfDates){
        System.debug('objSubLineItem '+objSubLineItem );
        List<Invoice_Line_Item__c> listOfInvoiceLineItems = new List<Invoice_Line_Item__c>();
        Integer countWithOldPackage = 0;
        Integer countWithNewPackage = 0;
        if(String.isNotBlank(objSubLineItem.Enrolment__r.Lesson_Day__c) && mapOfDates.containsKey(objSubLineItem.Enrolment__r.Lesson_Day__c)){
            Date effectiveDate = objSubLineItem.Enrolment__r.Effective_Date__c;
            
            //Decimal depositeFee = (objSubLineItem.Enrolment__r.New_Package_Id__r.Deposit_Fee__c - objSubLineItem.Enrolment__r.Package__r.Deposit_Fee__c);
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
            
            //commented by arpit as change in process in jun, now we create intrim invoice for deposit 
            /*if(depositeFee > 0){
                listOfInvoiceLineItems.add(createInvoiceLineItem(objInvoice.id,objSubLineItem,depositeFee ,objSubLineItem.Enrolment__r.New_Package_Id__c,true,''));
            }*/
            if(countWithOldPackage >= 1){
                if(objSubLineItem.Enrolment__r.Type_of_Package__c != ConstantsClass.PromoTypePayment){
                    listOfInvoiceLineItems.add(createInvoiceLineItem(objInvoice.id,objSubLineItem,oldPackageUnitPrice ,objSubLineItem.Enrolment__r.Package__c,FALSE,objSubLineItem.Enrolment__r.Teacher__c));
                }else{
                     // added by nishi: 10-May-2021:start: If the next billing date is less than the effective date and the package is the promo package then we will check that the invoice line item month matches the month of the next billing date, 
                    //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record. the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
           
                    Date effectivePromotionalDate = objSubLineItem.Enrolment__r.Promotional_Period_End_Date__c;       
                    if(effectivePromotionalDate != NULL && (effectivePromotionalDate > effectiveDate  &&
                        String.isNotBlank(objSubLineItem.Enrolment__r.Lesson_Day__c) && 
                        mapOfDates.containsKey(objSubLineItem.Enrolment__r.Lesson_Day__c))){
                            countWithOldPackage =0;
                        for(Date objDate : listOfDates){
                            if( objDate<=objSubLineItem.Enrolment__r.Promotional_Period_End_Date__c && objSubLineItem.Enrolment__r.Promotional_Period_End_Date__c > effectiveDate){
                                if(objDate < effectiveDate){
                                    countWithOldPackage+=1;
                                }
                            }
                        }   
                        oldPackageUnitPrice = (objSubLineItem.Enrolment__r.Package_To_Be_Change__r.Unit_Fee__c)*countWithOldPackage;
                        listOfInvoiceLineItems.add(PackageUpgradeController.createInvoiceLineItem(objInvoice.id,objSubLineItem,oldPackageUnitPrice ,objSubLineItem.Enrolment__r.Package_To_Be_Change__c,FALSE,objSubLineItem.Enrolment__r.Teacher__c));
                          // added by nishi: 10-May-2021:end: If the next billing date is less than the effective date and the package is the promo package then we will check that the invoice line item month matches the month of the next billing date, 
                        //if it exists then we will create promo period credit memo and remove promotional package end date on enrolment record. the next month invoice generation we create invoice with new teacher or package and adjust this credit memo.
           
                   
                    }
                }
                    //added by nishi: 21-Aug-2020: for manage Facility Fee if its ossia organistion 
                //  if(string.isNotBlank(objSubLineItem.Enrolment__r.Center__c) && string.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Organisation__c) &&
                //  string.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Organisation__r.Name)&& 
                //  objSubLineItem.Enrolment__r.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                //      if(objSubLineItem.Enrolment__r.Package__r.Facility_Fee__c != null){
                //          Decimal facilityCharge = (objSubLineItem.Enrolment__r.Package__r.Facility_Fee__c/4)*countWithOldPackage ; 
                //          Invoice_Line_Item__c objinvLineItm =  createInvoiceLineItem(objInvoice.id,objSubLineItem,facilityCharge ,objSubLineItem.Enrolment__r.Package__c,FALSE,objSubLineItem.Enrolment__r.Teacher__c); 
                //          objinvLineItm.remarks__c = objSubLineItem.Enrolment__r.Package__r.Name+' (Facility Fee)';
                //          listOfInvoiceLineItems.add(objinvLineItm);
                //      }
                //  }
                //added by nishi: 21-Aug-2020: for manage Facility Fee if its ossia organistion 
             
            }
            if(countWithNewPackage >= 1){
                  //added by nishi: 21-Aug-2020: for manage Facility Fee 
                  if(string.isNotBlank(objSubLineItem.Enrolment__r.Center__c) && string.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Organisation__c) &&
                  string.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Organisation__r.Name)&& 
                  objSubLineItem.Enrolment__r.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                    //   if(objSubLineItem.Enrolment__r.New_Package_Id__r.Facility_Fee__c != null){
                    //       Decimal facilityCharge = (objSubLineItem.Enrolment__r.New_Package_Id__r.Facility_Fee__c/4)*countWithNewPackage ; 
                    //       Invoice_Line_Item__c objinvLineItm =  createInvoiceLineItem(objInvoice.id,objSubLineItem,facilityCharge ,objSubLineItem.Enrolment__r.New_Package_Id__c,FALSE,objSubLineItem.Enrolment__r.New_Teacher__c); 
                    //       objinvLineItm.remarks__c = objSubLineItem.Enrolment__r.New_Package_Id__r.Name+' (Facility Fee)';
                    //       listOfInvoiceLineItems.add(objinvLineItm);
                    //   }
                    //if its ossia organistion upgrade condition in ossia teacher is also change so we added new teacher also
                    listOfInvoiceLineItems.add(createInvoiceLineItem(objInvoice.id,objSubLineItem,newPackageUnitPrice ,objSubLineItem.Enrolment__r.New_Package_Id__c,FALSE,objSubLineItem.Enrolment__r.New_Teacher__c));
                  }else{
                    listOfInvoiceLineItems.add(createInvoiceLineItem(objInvoice.id,objSubLineItem,newPackageUnitPrice ,objSubLineItem.Enrolment__r.New_Package_Id__c,FALSE,objSubLineItem.Enrolment__r.Teacher__c));
                  }
                 //added by nishi: 21-Aug-2020: for manage Facility Fee if its ossia organistion 
            } 
        }
        return listOfInvoiceLineItems;
    }
    
    public static Invoice_Line_Item__c createInvoiceLineItem(Id invoiceId,Subscription_Line_Item__c objSubLineItem,Decimal amount,
                                                               Id packageId,Boolean isDeposit,String teacherId){
        Invoice_Line_Item__c invLineItm = new Invoice_Line_Item__c();
        invLineItm.Enrolment__c = objSubLineItem.Enrolment__c;
        invLineItm.Subscription_Line_Item__c = objSubLineItem.Id;
        if(amount != null){
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
            if(String.isNotBlank(objSubLineItem.Enrolment__r.Center__c) && String.isNotBlank(objSubLineItem.Enrolment__r.Center__r.Country__c) && 
                objSubLineItem.Enrolment__r.Center__r.Country__r.Tax_Rate__c > 0 && amount != null){
                    system.debug('amount'+amount);
                    Double gstAmount = BillingUtility.roundOffAmount(amount * (objSubLineItem.Enrolment__r.Center__r.Country__r.Tax_Rate__c / 100));
                    system.debug('gstAmount'+gstAmount);
                    invLineItm.gst_Amount__c = gstAmount;
            }
        }
        return invLineItm;
    }
}