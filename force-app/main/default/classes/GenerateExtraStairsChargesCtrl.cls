/**
* Name :GenerateExtraStairsChargesCtrl
* Date: 14-Feb-2020
* Author : jatin
* Description : this controller calculate extra stairs charge than create invoice and payment records then update 
*              piano rental enrolment stair_charges and stairs field 
* 
*/
public with sharing class GenerateExtraStairsChargesCtrl {
    Public Enrolment__c objEnrolment{get;set;}
    public Boolean isGenerateExtraStairsCharges{get;set;}
    Public string  errorString {get;set;}
    public Boolean isPaidAmount{get;set;}
    public string invoiceId;
    public Decimal extraStairsAmount{get;set;}
    public GenerateExtraStairsChargesCtrl(ApexPages.StandardController st) {
        objEnrolment = (Enrolment__c)st.getRecord();
        if(string.isNotBlank(objEnrolment.Id)){
            List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {objEnrolment.Id});
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                objEnrolment = listOfenrolment[0];
            }
        }
        isGenerateExtraStairsCharges =  checkExtraStairsChargeOrNot();
        if(isGenerateExtraStairsCharges){
            extraStairsAmount =  objEnrolment.Extra_Stairs__c * Decimal.valueOf(System.Label.Per_Stair_Charges) *2;
        }
    }
    
    public boolean checkExtraStairsChargeOrNot(){
        Boolean isExtraStairsCharge = true;
        if(objEnrolment.Stage__c != ConstantsClass.enrollmentPianoRentalActiveStage){
            isExtraStairsCharge = false;
            errorString = 'Enrolment Stage is not \'Piano Rental Active\''; 
        }else if(objEnrolment.Actual_Delivery_Date_Time__c == null){
            isExtraStairsCharge = false;
            errorString = 'Delivery completion is Pending Now...'; 
        }else if(objEnrolment.Extra_Stairs__c == null || objEnrolment.Extra_Stairs__c == 0){
            isExtraStairsCharge = false;
            errorString = 'Delivery completed But Packer Not Found Any Extra Stairs.'; 
        }
        return isExtraStairsCharge;
    }
    
    public void generateExtraStairsCharges(){
        isGenerateExtraStairsCharges = checkExtraStairsChargeOrNot();
        Invoice__c objInvoice = New Invoice__c();
        Invoice_Line_Item__c objInvoiceLineItem = New Invoice_Line_Item__c();
        if(isGenerateExtraStairsCharges){
            try{
                if(string.isNotBlank(objEnrolment.center__r.id) && string.isNotBlank(objEnrolment.center__r.country__r.id) &&
                   objEnrolment.Subscription_Line_Items__r != null && objEnrolment.Subscription_Line_Items__r.size() >0){
                       Country__c countryObj = objEnrolment.center__r.country__r;
                       if(objEnrolment.Extra_Stairs__c != null && objEnrolment.Actual_Delivery_Date_Time__c != null){
                           //Decimal extraStairsAmount =  objEnrolment.Extra_Stairs__c * Decimal.valueOf(System.Label.Per_Stair_Charges);
                           //system.debug(extraStairsAmount);
                           
                           Subscription_Line_Item__c  objSubLineItem = objEnrolment.Subscription_Line_Items__r[0];
                           
                           objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c,objEnrolment.Parent__c,ConstantsClass.dueStatus);
                           objInvoice.Center__c = objEnrolment.Center__c;
                           objInvoiceLineItem = PianoRentalHelperController.createInvoicelineItem(objEnrolment,extraStairsAmount,objSubLineItem,countryObj);
                           objInvoiceLineItem.Remarks__C = 'Extra Staircase moving charges for '+objEnrolment.Extra_Stairs__c+' steps (2-way)';                                             
                           objInvoiceLineItem.month__c = System.today();
                           //objInvoiceLineItem.gst_Amount__c = 0;
                       }           
                   }
                
                if(objInvoice != null ){
                    insert objInvoice;
                    invoiceId = objInvoice.id;
                    if(objInvoiceLineItem != null){
                        objInvoiceLineItem.Invoice__c = objInvoice.id;
                        insert  objInvoiceLineItem;
                    }
                    
                }
                errorString ='getPaymentForInvoices';
            }catch(Exception e){
                isGenerateExtraStairsCharges = false;
                errorString = e.getMessage();
            }
        } 
    }
    
    
    // create payment 
    public void getPaymentForInvoices(){
        PianoRentalHelperController.getPaymentForInvoices(new Map<String,string>{invoiceId => invoiceId},'');
        errorString ='createAttachmentForEmail';
    }
    
    public void createAttachmentForEmail(){
        if(string.isNotBlank(invoiceId)){
            try{
                List<Invoice__c> listOfInvoice = [Select Id,status__c
                                                  FROM Invoice__c
                                                  WHERE Id =:invoiceId];
                system.debug('listOfInvoice'+listOfInvoice);
                if(listOfInvoice != null && listOfInvoice.size() > 0 && listOfInvoice[0].status__c == ConstantsClass.paidStatus){
                    System.debug('listOfInvoice'+listOfInvoice);
                    // Email confirmation to the customer with the invoice PDF
                    insertPdfAndSendEmail(invoiceId);
                    //	Item marked sold in the inventory
                    decimal extrastairs = objEnrolment.Extra_Stairs__c;
                    Enrolment__c updateEnrolment = new Enrolment__c(id= objEnrolment.id,
                                                                    No_of_Stairs__c = objEnrolment.No_of_Stairs__c + extrastairs,
                                                                    Stair_Charges__c = objEnrolment.Stair_Charges__c + extraStairsAmount,
                                                                    Extra_Stairs__c = 0);
                    System.debug('@@@updateEnrolment'+updateEnrolment);
                    update updateEnrolment;
                    errorString = 'Success';
                    isGenerateExtraStairsCharges = true;
                    isPaidAmount = true;
                }else{
                    errorString = 'Some error found. Please contact centre admin for further assistance.';
                    isGenerateExtraStairsCharges = false;
                }
            } catch(exception e){
                isGenerateExtraStairsCharges = false;
                errorString = e.getMessage();
            }
        }
        
    }
    // insert attachment and Email confirmation to the customer with the invoice PDF
    @future(callout=true)
    public static void insertPdfAndSendEmail(String invoices){
        DateTime now = DateTime.now();
        if(string.isNotBlank(invoices)){
            List<Invoice__c> invoiceList = [SELECT Id,Name,Total_Amount__c,
                                            Center__r.Location__c,Parent_Account__r.personContactId,
                                            status__c FROM Invoice__c 
                                            WHERE Id =:invoices];
            map<String ,Blob> mapOfAttachment = new map<String,Blob>();
            List<Attachment> listOfAttachment = new List<Attachment>();
            if(invoiceList != null && invoiceList.size() > 0){
                Invoice__c inv = invoiceList[0];
                String pdfName =  inv.Name+'.pdf';
                map<string,Attachment> mapOfInvoiceAttachment  = PianoRentalHelperController.createInvoiceAttachment(invoiceList);
                if(mapOfInvoiceAttachment.containsKey(inv.id)){
                    mapOfAttachment.put(inv.Name+'.pdf',mapOfInvoiceAttachment.get(inv.id).body);
                }
                if(mapOfAttachment != null && mapOfAttachment.size() > 0){
                    PianoRentalHelperController.sendEmailWithInvoiceAttachment(new Map<string,map<String ,Blob>>{inv.id =>mapOfAttachment}, invoiceList,'Extra Stairs Invoice');
                }
            }
        }
    }
    
}