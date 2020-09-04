/*
    Author: Jatin
    Name : ConfirmRentalPurchaseController
    Date: 29-jan-2020
    Description : for show Panda doc then use can sign this than confirm this signature pay piano purchase amount

 */
public  without sharing class ConfirmRentalPurchaseController {
    Public Enrolment__c objEnrolment{get;set;}
    Public String  errorMessage{get;set;}
    Public Boolean isErrorOnSave {get;set;}
    Public String  aggrementId{get;set;}
    Public String  personEmail{get;set;}
    public String cardImage{get;set;}
    public String sessionId {get;set;}
    public String cardNumber{get;set;}
    public String customerRefId{get;set;}
    public String paymentType{get;set;}
    public Boolean isErrOnSave{get;set;}
    public Boolean findEnrolId{get;set;}
    public Boolean isSignedAgreement{get;set;}
    public Boolean isPaidAmount{get;set;}
    Public String invoiceId;
    Public string pandaDocAttachmentName;
    PandaDocUtility.CreateDocument documentDetails;
    PandaDocUtility.Document document;
    PandaDocUtility.CreateDocument sendDocument;
    PandaDocUtility.SessionDocument sessionDetails; 
    Map<String,Invoice__c> mapOfInvoice = New Map<String,Invoice__c>();
    public ConfirmRentalPurchaseController() {
        invoiceId= '';
         system.debug('objEnrolment'+objEnrolment);
        string enrolmentId = ApexPages.currentPage().getParameters().get('Id');
        system.debug('enrolmentId'+enrolmentId);
        objEnrolment= new Enrolment__c();
      //   system.debug('objEnrolment'+st.getRecord());
      //  objEnrolment = (Enrolment__c)st.getRecord();
        //system.debug('objEnrolment'+objEnrolment);
        documentDetails = new PandaDocUtility.CreateDocument ();
        document = new PandaDocUtility.Document();
        sendDocument = new PandaDocUtility.CreateDocument ();
        sessionDetails = new PandaDocUtility.SessionDocument();
        findEnrolId = true;
        personEmail ='';
        aggrementId ='';
        isPaidAmount = false;
        errorMessage = '';
        
        if(string.isNotBlank(enrolmentId)){
            List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {enrolmentId});
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                objEnrolment = listOfenrolment[0];
                personEmail=  objEnrolment.Parent__r.PersonEmail;
                pandaDocAttachmentName = objEnrolment.name + '-RentalAgreement';
            }
            cardImage = objEnrolment.Parent__r.Card_Image__c;
            cardNumber = objEnrolment.Parent__r.Card_Number__c;
            findEnrolId = false;
            if(objEnrolment.Stage__c == ConstantsClass.enrollmentPianoSoldStage){
                errorMessage = ' Piano Already Sold';
                findEnrolId = true;
            }
        }
        
    }
    // jatin:30-Jan-2020: for sign Aggrement 
    public  void signAgreement(){
        system.debug('objEnrolment.id'+objEnrolment.id);
        if(string.isNotBlank(objEnrolment.id)){
            documentDetails = signAgreementRentalPurchase(objEnrolment.id);
            if(String.isNotBlank(documentDetails.id)){
                aggrementId = documentDetails.id;
            }
            system.debug('aggrementId'+aggrementId);
        }
    }
    public void isSignAgreement(){
        if(string.isBlank(aggrementId) && string.isBlank(sessionId)){
            isSignedAgreement = false;
        }else{
            isSignedAgreement = true;
        }
    }
    // jatin:30-Jan-2020: for wait to some mins then check Aggrement 
    Public Void waitAgreement(){
        PandaDocUtility.Document document = new PandaDocUtility.Document();
        if(String.isNotBlank(documentDetails.id)){
            document = PandaDocUtility.viewDocument(documentDetails.id);
        } 
    }
     // jatin:30-Jan-2020: for wait to some mins then send Aggrement 
    Public void sendAgreement(){
        DocumentWrapper.SendDocument sendDocument;
        String body = '';
       
        if(String.isNotBlank(documentDetails.id)){
            sendDocument = new DocumentWrapper.SendDocument('Hello! This document was sent from the PandaDoc API.', true);      
            body = JSON.serialize(sendDocument);
            documentDetails = PandaDocUtility.sendDocument(body, documentDetails.id);
            System.debug('@@@documentDetails'+documentDetails);
        }
    }

     // jatin:30-Jan-2020: for create session Id for show aggrement 
    Public void createSession(){
        system.debug('personEmail'+personEmail);
        system.debug('aggrementId'+aggrementId);
        if(String.isNotBlank(aggrementId) && String.isNotBlank(personEmail)){
            sessionId = PianoRentalHelperController.createSession(aggrementId,personEmail);
        }
    }

     // jatin:30-Jan-2020: for create sign Aggrement 
    Public  PandaDocUtility.CreateDocument signAgreementRentalPurchase(String enrolmentId){
         PandaDocUtility.CreateDocument documentRentalPurchaseDetails = new PandaDocUtility.CreateDocument ();
         if(string.isNotBlank(enrolmentId)){
            map<String,PandaDocUtility.CreateDocument> mapOfdocumentRentalPurchaseDetails= PianoRentalHelperController.signAgreement(new Set<string>{enrolmentId},'Purchase Aggrement');  
            if(mapOfdocumentRentalPurchaseDetails != null && mapOfdocumentRentalPurchaseDetails.size() > 0){
                documentRentalPurchaseDetails = mapOfdocumentRentalPurchaseDetails.get(enrolmentId);
            }
        } 
        return documentRentalPurchaseDetails;
    }

    // 14-Feb-2020: Jatin: if user pay amount with offline card then we create paid status invoice then 
    //we create payment with reference charge id after send email 
    /* 17-feb-2020: commented by jatin: for offline card payment only use  internal user not site guest user 
    public void createInvoiceViaChargeId(){
        system.debug('customerRefId'+customerRefId);
         mapOfInvoice = createInvoiceWithLineItem(objEnrolment,ConstantsClass.paidStatus);
        if(mapOfInvoice != null && mapOfInvoice.size()>0 && mapOfInvoice.containsKey(objEnrolment.id)) {
            invoiceId = mapOfInvoice.get(objEnrolment.id).id;
            String paymentRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
            Invoice__c objInvoice  = mapOfInvoice.get(objEnrolment.id);
            Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,
                                                                objInvoice.id, 
                                                                objInvoice.Balance_Amount__c,
                                                                ConstantsClass.successStatus); 
            objPayment.Reference_Charge_Id__c = customerRefId;
            objPayment.Remarks__c = 'Payment with Offline Card';
            objPayment.recordTypeId = paymentRecType;                
            insert objPayment;  
            errorMessage = 'Success';
            isErrOnSave = false;
        } else{
            isErrOnSave = true;
            errorMessage ='Some Error found.';
        }
    }*/

    // 14-Feb-2020: if user pay amount with online card then we create firstly due invoice then we payment using stripe after then we update invoice with paid status
    public void createInvoiceViaCard(){
        mapOfInvoice = createInvoiceWithLineItem(objEnrolment,ConstantsClass.dueStatus);
        if(mapOfInvoice != null && mapOfInvoice.size()>0 && mapOfInvoice.containsKey(objEnrolment.id)){
            invoiceId = mapOfInvoice.get(objEnrolment.id).id;
            errorMessage = 'Success';
            isErrOnSave = false;
        } else{
            isErrOnSave = true;
            errorMessage = 'Some Error found.';
        }
    }

     /* Jatin:
        create invoice  and invoice line items 
        a. Original piano price (excluding promotion, if any)
        b.  Apply the following deductions
        i.  Maximum 4 month rent paid
        ii. Apply Rental Deposit (as applicable)
        iii.    Apply 1 way paid delivery charges (as applicable)
        
     */
    public static Map<String,Invoice__c> createInvoiceWithLineItem(enrolment__C objEnrolment,string invoiceStatus){
        //commented by jatin: 21-feb-2020: for change requirement now we show all paid inoice amount with detials prevoiusly deduct total 4 mounht paid amount 
        //Map<string,Decimal> mapOfTotalInvoicePaidAmount = PianoRentalHelperController.get4MonthPaidInvoiceAmount(new Set<String>{objEnrolment.id});
        Map<String,List<Invoice__c>> mapOfEnrolmentInvoiceAmount = PianoRentalHelperController.get4MonthPaidInvoiceAmountWithDate(new Set<String>{objEnrolment.id});
        System.debug('!!!mapOfEnrolmentInvoiceAmount'+mapOfEnrolmentInvoiceAmount.size());
        Map<string,Decimal> mapOfTotalcurrentMonthPaidInvoiceAmount = PianoRentalHelperController.getCurrentMonthInvoiceAmount(new Set<String>{objEnrolment.id},ConstantsClass.paidStatus);
        Map<string,Decimal> mapOfTotalRentalDepositAmount  = PianoRentalHelperController.getTotalRentalDepositAmount(new Set<String>{objEnrolment.id});
        Map<String,Invoice__c> mapOfInvoice = New Map<String,Invoice__c>();
        Map<String,Invoice_Line_Item__c> mapOfInvoiceLineItem = New Map<String,Invoice_Line_Item__c>();
         list<Subscription_Line_Item__c> listOfSubsLineItem = new LIst<Subscription_Line_Item__c>();
         map<string,Subscription__c> mapOfSubs = new Map<string,Subscription__c>();
         string invoiceId = '';
            if(string.isNotBlank(objEnrolment.center__r.id) && string.isNotBlank(objEnrolment.center__r.country__r.id) &&
                objEnrolment.Subscription_Line_Items__r != null && objEnrolment.Subscription_Line_Items__r.size() >0){
                Country__c countryObj = objEnrolment.center__r.country__r;
                Subscription_Line_Item__c  objSubLineItem = objEnrolment.Subscription_Line_Items__r[0];
                Invoice__c objInvoice = BillingUtility.fillInvoice(objSubLineItem.Subscription__c,objEnrolment.Parent__c,invoiceStatus);
                objInvoice.Center__c = objEnrolment.Center__c;
                mapOfInvoice.put(objEnrolment.Id,objInvoice);
                system.debug('objEnrolment.Selling_price__c'+objEnrolment.Selling_price__c);
                Invoice_Line_Item__c  inlineItemForChange = new Invoice_Line_Item__c ();
                if( objEnrolment.Selling_price__c != null && objEnrolment.Selling_price__c > 0){
                    inlineItemForChange = PianoRentalHelperController.createInvoicelineItem(objEnrolment,objEnrolment.Selling_price__c,objSubLineItem,countryObj);
                    inlineItemForChange.Remarks__c = 'Original Piano Price';                                             
                    mapOfInvoiceLineItem.put(objEnrolment.Id+'-Selling_price__c',inlineItemForChange);
                }
                inlineItemForChange = new Invoice_Line_Item__c ();
                /*Commented by jatin: 21-Feb-2020:prevoiusly deduct total 4 mounht paid amount
                if(mapOfTotalInvoicePaidAmount != null && mapOfTotalInvoicePaidAmount.size() > 0 && mapOfTotalInvoicePaidAmount.containsKey(objEnrolment.id)){
                    if(mapOfTotalInvoicePaidAmount.get(objEnrolment.id) !=  null && mapOfTotalInvoicePaidAmount.get(objEnrolment.id) > 0){ 
                        decimal totalInvoicePaidAmount = mapOfTotalInvoicePaidAmount.get(objEnrolment.id);
                        totalInvoicePaidAmount =  - totalInvoicePaidAmount;
                        inlineItemForChange = PianoRentalHelperController.createInvoicelineItem(objEnrolment,totalInvoicePaidAmount,objSubLineItem,countryObj);
                        inlineItemForChange.Remarks__c = 'Deduct Maximum 4 month paid rent';                                             
                        mapOfInvoiceLineItem.put(objEnrolment.Id+'-totalInvoicePaidAmount',inlineItemForChange);
                    }
                }*/
               //commented by jatin: 21-feb-2020:start: for change requirement now we show all paid inoice amount with detials 
                if(mapOfEnrolmentInvoiceAmount != null && mapOfEnrolmentInvoiceAmount.size() > 0){
                    List<Invoice__c> listofInvoice = mapOfEnrolmentInvoiceAmount.get(objEnrolment.id);
                    for(Invoice__c objPaidInvoice : listofInvoice){
                        datetime dueDate = datetime.newInstance(objPaidInvoice.Due_Date__c, Time.newInstance(0,0,0,0));
                        inlineItemForChange = PianoRentalHelperController.createInvoicelineItem(objEnrolment,-(objPaidInvoice.Sub_Total__c),objSubLineItem,countryObj);
                        inlineItemForChange.Remarks__c = 'Deduct Paid Rent - '+ dueDate.format('dd MMM, yyyy');                                             
                        mapOfInvoiceLineItem.put(objEnrolment.Id+'-InvoicePaidAmount-'+dueDate.format('dd MMM, yyyy'),inlineItemForChange);
                    }
                }
                 //commented by jatin: 21-feb-2020:end: for change requirement now we show all paid inoice amount with detials 
                inlineItemForChange = new Invoice_Line_Item__c ();
                if(mapOfTotalRentalDepositAmount != null && mapOfTotalRentalDepositAmount.size() > 0 && mapOfTotalRentalDepositAmount.containsKey(objEnrolment.id)){
                    if(mapOfTotalRentalDepositAmount.get(objEnrolment.id) !=  null && mapOfTotalRentalDepositAmount.get(objEnrolment.id) > 0){
                        decimal totalRentalDepositAmount = mapOfTotalRentalDepositAmount.get(objEnrolment.id);
                        totalRentalDepositAmount =  - totalRentalDepositAmount;
                        inlineItemForChange = PianoRentalHelperController.createInvoicelineItem(objEnrolment,totalRentalDepositAmount,objSubLineItem,countryObj);
                        inlineItemForChange.gst_Amount__c = 0;
                        inlineItemForChange.Remarks__c = 'Deduct Rental Deposit';                                             
                        mapOfInvoiceLineItem.put(objEnrolment.Id+'-totalRentalDeposit',inlineItemForChange);
                    }
                }
                inlineItemForChange = new Invoice_Line_Item__c ();
                Decimal totalDeliveryCharges = objEnrolment.Delivery_Charges__c / 2;
                    system.debug('objEnrolment.DeliveryCharges'+totalDeliveryCharges);
                if(totalDeliveryCharges != null && totalDeliveryCharges > 0){
                    totalDeliveryCharges =  - totalDeliveryCharges;
                    inlineItemForChange = PianoRentalHelperController.createInvoicelineItem(objEnrolment,totalDeliveryCharges,objSubLineItem,countryObj);
                    inlineItemForChange.Remarks__c = 'Deduct (One Way) Delivery Charges';                                             
                    mapOfInvoiceLineItem.put(objEnrolment.Id+'-totalDeliveryCharges',inlineItemForChange);
                }
                // 10:feb:2020 for add stairs charges
                Decimal totalStairCharges = objEnrolment.Stair_Charges__c / 2;
                    system.debug('objEnrolment.DeliveryCharges'+totalDeliveryCharges);
                if(totalStairCharges != null && totalStairCharges > 0){
                    totalStairCharges =  - totalStairCharges;
                    inlineItemForChange = PianoRentalHelperController.createInvoicelineItem(objEnrolment,totalStairCharges,objSubLineItem,countryObj);
                    inlineItemForChange.Remarks__c = 'Deduct (One Way) Stair Charges';                                             
                    mapOfInvoiceLineItem.put(objEnrolment.Id+'-totalStairCharges',inlineItemForChange);
                }

                // 5-FEB:2020: for insert Current month rental invoice 
                if(mapOfTotalcurrentMonthPaidInvoiceAmount != null && mapOfTotalcurrentMonthPaidInvoiceAmount.size() > 0 && mapOfTotalcurrentMonthPaidInvoiceAmount.containsKey(objEnrolment.id)){
                    if(mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id) !=  null && mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id) > 0) {
                        decimal totalcurrentMonthPaidInvoiceAmount = mapOfTotalcurrentMonthPaidInvoiceAmount.get(objEnrolment.id);
                        totalcurrentMonthPaidInvoiceAmount =  - totalcurrentMonthPaidInvoiceAmount;
                        inlineItemForChange = PianoRentalHelperController.createInvoicelineItem(objEnrolment,totalcurrentMonthPaidInvoiceAmount,objSubLineItem,countryObj);
                        inlineItemForChange.Remarks__c = 'Deduct Current Month Rental';                                             
                        mapOfInvoiceLineItem.put(objEnrolment.Id+'-Current_Month_Rental',inlineItemForChange);
                    }
                }
                system.debug('mapOfInvoice'+mapOfInvoice); 
                system.debug('mapOfInvoiceLineItem'+mapOfInvoiceLineItem);
                // 5-FEB:2020: for update Subscription end date for subscriptions, subscription line items
                    listOfSubsLineItem.add(new Subscription_Line_Item__c(id=objSubLineItem.id,
                                                                            Subscription_Expiry_Date__c = system.today()));
                    mapOfSubs.put(objSubLineItem.Subscription__r.id,new Subscription__c(id=objSubLineItem.Subscription__r.id,
                                                                            Subscription_End_Date__c = system.today()));
            }
            
            if(mapOfInvoice != null && mapOfInvoice.size() > 0){
                insert mapOfInvoice.values();
                system.debug('mapOfInvoice'+mapOfInvoice);
                if(mapOfInvoiceLineItem != null && mapOfInvoiceLineItem.Size() > 0){
                    for(Invoice_Line_Item__c inlineItemForChange : mapOfInvoiceLineItem.values()){
                        if(mapOfInvoice.containsKey(inlineItemForChange.Enrolment__c)){
                            inlineItemForChange.Invoice__c = mapOfInvoice.get(inlineItemForChange.Enrolment__c).id;
                            invoiceId = mapOfInvoice.get(inlineItemForChange.Enrolment__c).id; 
                        }
                    }
                    Insert  mapOfInvoiceLineItem.values();
                }
                if(mapOfSubs != null && mapOfSubs.size() > 0){
                    update mapOfSubs.values();
                }
                if(listOfSubsLineItem != null && listOfSubsLineItem.size() > 0){
                    update listOfSubsLineItem;
                }
            }
       return mapOfInvoice;
    }

    

   
    // create payment 
    public void getPaymentForInvoices(){
        PianoRentalHelperController.getPaymentForInvoices(new Map<String,string>{invoiceId => invoiceId},'');
    }

    public void createAttachmentForEmail(){
        if(string.isNotBlank(invoiceId)){
            try{
                List<Invoice__c> listOfInvoice = [Select Id,status__c
                                                    FROM Invoice__c
                                                    WHERE Id =:invoiceId];
                system.debug('listOfInvoice'+listOfInvoice);
                if(listOfInvoice != null && listOfInvoice.size() > 0 && listOfInvoice[0].status__c == ConstantsClass.paidStatus){
                    sendEmailAndUpdateEnrolment(objEnrolment,invoiceId,pandaDocAttachmentName);
                    isErrOnSave = false;
                    errorMessage = 'Success';
                    isPaidAmount = true;
                }else{
                    errorMessage = 'Some error found. Please contact centre admin for further assistance.';
                    isErrOnSave = true;
                }
            } catch(exception e){
                isErrOnSave = true;
                errorMessage = e.getMessage();
            }
        }
           
    }

    public static void sendEmailAndUpdateEnrolment(Enrolment__c objEnrolment,string invoiceId,string pandaDocAttachmentName){
         // Email confirmation to the customer with the invoice PDF
         insertPdfAndSendEmail(invoiceId,pandaDocAttachmentName);
         //	Item marked sold in the inventory
         Enrolment__c objEnrolment1 = new Enrolment__c(id= objEnrolment.id, Stage__c ='Piano Sold');
         update objEnrolment1;
         //Turn off the rental subscription
         if(objEnrolment.Subscription_Line_Items__r != null && objEnrolment.Subscription_Line_Items__r.size() > 0){
             List<Subscription_Line_Item__c>  listOfSubLineItem = objEnrolment.Subscription_Line_Items__r;
             // After completed this enrolment then we in Active Subscription_Line_Item__c
             if(listOfSubLineItem != null && listOfSubLineItem.size() > 0){
                 for(Subscription_Line_Item__c objSubLineItem : listOfSubLineItem){
                     objSubLineItem.Status__c = 'In Active';
                     //objSubLineItem.Subscription_Expiry_Date__c = objEnrolment.Termination_request_date__c;
                 }
                 update listOfSubLineItem;
             }
        }
    }
        // insert attachment and Email confirmation to the customer with the invoice PDF
    @future(callout=true)
    public static void insertPdfAndSendEmail(String invoices,string pandaDocAttachmentName){
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
                map<string,Attachment> mapOfInvoiceAttachment  = PianoRentalHelperController.createInvoiceAttachment(invoiceList);
                if(mapOfInvoiceAttachment.containsKey(inv.id)){
                    mapOfAttachment.put(inv.Name+'.pdf',mapOfInvoiceAttachment.get(inv.id).body);
                }
                // 7-Feb:2020: added pandaDoc sign aggrement attachment l 
                system.debug('pandaDocAttachmentName'+pandaDocAttachmentName);
                if(string.isnotBlank(pandaDocAttachmentName)){
                    pandaDocAttachmentName ='%'+pandaDocAttachmentName+'%';
                    List<Attachment> listOfPandaDocAttachment = [SELECT Id,name, Body, createdDate From Attachment
                                                                 WHERE Name Like:pandaDocAttachmentName 
                                                                 AND contentType = 'application/pdf'
                                                                 AND CreatedDate = today
                                                                 ORDER BY createdDate DESC];
                    system.debug('listOfPandaDocAttachment'+listOfPandaDocAttachment);
                    if(listOfPandaDocAttachment != null && listOfPandaDocAttachment.size() > 0){
                        mapOfAttachment.put(listOfPandaDocAttachment[0].name,listOfPandaDocAttachment[0].Body);
                    }
                }
                if(mapOfAttachment != null && mapOfAttachment.size() > 0){
                   PianoRentalHelperController.sendEmailWithInvoiceAttachment(new Map<string,map<String ,Blob>>{inv.id =>mapOfAttachment}, invoiceList,'Rental Purchase Invoice');
                }
            }
        }
    }
    
}