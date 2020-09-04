/*
    Name: PianoRentalPurchaseController
    Date: 18-Jan-2020
    Author: JATIN
    Description :  this controller for send email for Piano Rental to purchase request
*/
public class PianoRentalPurchaseController {
    Public Enrolment__c objEnrolment{get;set;}
    Public string  errorMessage{get;set;}
    Public Boolean isErrorOnSave {get;set;}
    public Boolean isAlreadySold {get;set;}
    public string customerRefId{get;set;}
    public String cardImage{get;set;}
    public String sessionId {get;set;}
    public String cardNumber{get;set;}
    public String paymentType{get;set;}
    public Boolean isSignedAgreement{get;set;}
    Public String  aggrementId{get;set;}
    Public String  personEmail{get;set;}
    public Boolean isPaidAmount{get;set;}
    Public String invoiceId;
    Public string pandaDocAttachmentName;
    PandaDocUtility.CreateDocument documentDetails;
    PandaDocUtility.Document document;
    PandaDocUtility.CreateDocument sendDocument;
    PandaDocUtility.SessionDocument sessionDetails; 
    Map<String,Invoice__c> mapOfInvoice = New Map<String,Invoice__c>();
    public PianoRentalPurchaseController(ApexPages.StandardController st) {
        invoiceId= '';
        objEnrolment = (Enrolment__c)st.getRecord();
        documentDetails = new PandaDocUtility.CreateDocument ();
        document = new PandaDocUtility.Document();
        sendDocument = new PandaDocUtility.CreateDocument ();
        sessionDetails = new PandaDocUtility.SessionDocument();
        personEmail ='';
        aggrementId ='';
        isPaidAmount = false;
        errorMessage = '';
        if(string.isNotBlank(objEnrolment.Id)){
            List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {objEnrolment.Id});
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                objEnrolment = listOfenrolment[0];
            }
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                objEnrolment = listOfenrolment[0];
                personEmail=  objEnrolment.Parent__r.PersonEmail;
                pandaDocAttachmentName = objEnrolment.name + '-RentalAgreement';
            }
            cardImage = objEnrolment.Parent__r.Card_Image__c;
            cardNumber = objEnrolment.Parent__r.Card_Number__c;
        }
        if(objEnrolment.Stage__c != ConstantsClass.enrollmentPianoSoldStage){
            isAlreadySold = false;
        }else{
            isAlreadySold = true;
        }
    }
    //19-Feb-2020: get Payment Type picklist for show Payment mode for Offline cards
    public List<SelectOption> getPaymentTypePicklist(){     
        set<string> paymentTypes = new Set<string>{'Card','NETS'};
        List<SelectOption> lstPickvals = new List<SelectOption>();        
        lstPickvals.add(new SelectOption('', '--None--'));
        Map<String, Schema.SObjectField> field_map = Schema.getGlobalDescribe().get('Payment__c').newSObject().getSObjectType().getDescribe().fields.getMap(); //From the Object Api name retrieving the SObject and grab the sobject that was passed
        List<Schema.PicklistEntry> pick_list_values   = field_map.get('Method_of_Payment__c').getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        
        for(Schema.PicklistEntry a : pick_list_values){ //for all values in the picklist list
            if(paymentTypes.contains(a.getValue()))
                lstPickvals.add(new SelectOption(a.getValue(), a.getLabel()));
        }
        
        return lstPickvals;
    }

    // send email to customer for purchase confirmation
    public void sendEmailMessage(){
          List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
           string personContactId,centerId;
             system.debug('@@@objEnrolment.Parent__c'+objEnrolment.Parent__c);
            system.debug('@@@objEnrolment'+objEnrolment);
            if(objEnrolment.Parent__c != null && string.isNotBlank(objEnrolment.Parent__r.PersonContactId)){
                personContactId = objEnrolment.Parent__r.PersonContactId;
            }
            if(objEnrolment.Center__c != null && objEnrolment.Center__r != null &&
                string.isNotBlank(objEnrolment.Center__r.Location__c) ){
                    centerId = objEnrolment.Center__r.Location__c;
             }
               list<EmailTemplate> listOfEmailTemplate = [SELECT Id, Name ,DeveloperName
                                                        FROM EmailTemplate 
                                                        WHERE DeveloperName ='Rental_Purchase_Confirmation'];
            if(listOfEmailTemplate != null && listOfEmailTemplate.size() > 0 ){
                sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id,personContactId,objEnrolment.id,centerId));
            } 
            system.debug('sendSingleEmailMessage'+sendSingleEmailMessage);
            if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
                Messaging.SendEmailResult[] results = Messaging.sendEmail(sendSingleEmailMessage,FALSE );
                if (results[0].success) {
                    isErrorOnSave = false;
                } else {
                    isErrorOnSave = true;
                    errorMessage = results[0].errors[0].message;
                }
            }
            
    }

    // jatin:17-feb-2020: for sign Aggrement 
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
    // jatin:17-feb-2020: for check sign Aggrement 
    public void isSignAgreement(){
        if(string.isBlank(aggrementId) && string.isBlank(sessionId)){
            isSignedAgreement = false;
        }else{
            isSignedAgreement = true;
        }
    }
    // jatin:17-feb-2020: for wait to some mins then check Aggrement 
    Public Void waitAgreement(){
        PandaDocUtility.Document document = new PandaDocUtility.Document();
        if(String.isNotBlank(documentDetails.id)){
            document = PandaDocUtility.viewDocument(documentDetails.id);
        } 
    }
     //jatin:17-feb-2020:for wait to some mins then send Aggrement 
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

     // jatin:17-feb-2020: for create session Id for show aggrement 
    Public void createSession(){
        system.debug('personEmail'+personEmail);
        system.debug('aggrementId'+aggrementId);
        if(String.isNotBlank(aggrementId) && String.isNotBlank(personEmail)){
            sessionId = PianoRentalHelperController.createSession(aggrementId,personEmail);
        }
    }

     // jatin:17-feb-2020: for create sign Aggrement 
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
    
    // 17-Feb-2020: Jatin: if user pay amount with offline card then we create paid status invoice then 
    //we create payment with reference charge id after send email 
    public void createInvoiceViaChargeId(){
        system.debug('customerRefId'+customerRefId);
         mapOfInvoice = ConfirmRentalPurchaseController.createInvoiceWithLineItem(objEnrolment,ConstantsClass.paidStatus);
        if(mapOfInvoice != null && mapOfInvoice.size()>0 && mapOfInvoice.containsKey(objEnrolment.id)) {
            invoiceId = mapOfInvoice.get(objEnrolment.id).id;
            String paymentRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
            Invoice__c objInvoice  = mapOfInvoice.get(objEnrolment.id);
            Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,
                                                                objInvoice.id, 
                                                                objInvoice.Balance_Amount__c,
                                                                ConstantsClass.successStatus); 
            objPayment.Reference_Charge_Id__c = customerRefId;
            objPayment.Method_of_Payment__c = paymentType; // jatin: 19-feb-2020 :add Payment mode for Offline cards
            objPayment.Remarks__c = 'Payment with Offline Card';
            objPayment.recordTypeId = paymentRecType;                
            insert objPayment;  
            errorMessage = 'Success';
            isErrorOnSave = false;
        } else{
            isErrorOnSave = true;
            errorMessage ='Some Error found.';
        }
    }

    // 17-Feb-2020: if user pay amount with online card then we create firstly due invoice then we payment using stripe after then we update invoice with paid status
    public void createInvoiceViaCard(){
        mapOfInvoice = ConfirmRentalPurchaseController.createInvoiceWithLineItem(objEnrolment,ConstantsClass.dueStatus);
        if(mapOfInvoice != null && mapOfInvoice.size()>0 && mapOfInvoice.containsKey(objEnrolment.id)){
            invoiceId = mapOfInvoice.get(objEnrolment.id).id;
            errorMessage = 'Success';
            isErrorOnSave = false;
        } else{
            isErrorOnSave = true;
            errorMessage = 'Some Error found.';
        }
    }

     // 17-Feb-2020: for create payment is user pay with card
     public void getPaymentForInvoices(){
        PianoRentalHelperController.getPaymentForInvoices(new Map<String,string>{invoiceId => invoiceId},'');
    }

    // 17-Feb-2020: jatin:send email with invoice details if user pay purchase amount 
    public void createAttachmentForEmail(){
        if(string.isNotBlank(invoiceId)){
            try{
                List<Invoice__c> listOfInvoice = [Select Id,status__c
                                                    FROM Invoice__c
                                                    WHERE Id =:invoiceId];
                system.debug('listOfInvoice'+listOfInvoice);
                if(listOfInvoice != null && listOfInvoice.size() > 0 && listOfInvoice[0].status__c == ConstantsClass.paidStatus){
                    ConfirmRentalPurchaseController.sendEmailAndUpdateEnrolment(objEnrolment,invoiceId,pandaDocAttachmentName);
                    isErrorOnSave = false;
                    errorMessage = 'Success';
                    isPaidAmount = true;
                }else{
                    errorMessage = 'Some error found. Please contact centre admin for further assistance.';
                    isErrorOnSave = true;
                }
            } catch(exception e){
                isErrorOnSave = true;
                errorMessage = e.getMessage();
            }
        }
           
    }
}