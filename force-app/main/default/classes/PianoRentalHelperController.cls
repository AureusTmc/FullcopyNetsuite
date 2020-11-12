/*
    Name: PianoRentalHelperController
    Date: 8-Fed-2020
    Author: JATIN
    Description :  this helper controller for piano rental 
*/
public class PianoRentalHelperController {
    
    //8-feb-2020: Jatin: get enrlment list according to enrol ids
    public static List<Enrolment__c> getRentalEnrolmentList(Set<String> enrolmentIds){
        return [SELECT Id, Name, center__r.country__r.Tax_Rate__c,center__r.country__r.Stripe_Base_Url__c,
                    Extra_Stairs__c,Actual_Delivery_Date_Time__c,Aggrement_Id__c,
                    Package__c,teacher__c,center__c,Stage__c,Parent__r.PersonContactId,Center__r.Location__c,
                    Termination_Reason__c,Termination_Reason_others__c,Termination_request_date__c,Piano_Pickup_date__c,
                    center__r.country__r.Currency_Code__c,center__r.country__r.Stripe_Secret_Key__c,Teacher__r.OwnerId,
                    Parent__c, Parent__r.Name, effective_Date__c, Rental_price_per_month__c,Stair_Charges__c,
                    Final_Delivery_date__c,Rental_Start_date__c,Rental_End_date__c,Minimum_Rental_Commitment_Period__c,
                    Student__r.Name, Package__r.Name, Package__r.Deposit_Fee__c, Package__r.Unit_Fee__c,
                    House_type__c,Building_name__c,Block__c,Unit_and_Level__c,PIN_code__c,Serial_Number__c,Model__c,Standard_Accessories__c,
                    Center__r.Name, Lessons_Start_Date__c, Lesson_Start_time__c, Notice_Period_End_Date__c,  
                    Center__r.country__r.Id, No_of_Stairs__c,Termination_Inspection_Completed__c,Parent__r.Card_Image__c,Parent__r.Card_Number__c,
                    Selling_price__c,Delivery_Charges__c,Parent__r.PersonMobilePhone,Parent__r.PersonEmail,
                    Final_Delivery_Timeslot__c,Parent__r.FirstName, Parent__r.LastName,Parent__r.BillingStreet,
                    Parent__r.BillingCity, Parent__r.BillingCountry,Parent__r.Phone,Parent__r.id,Parent_Email__c,
                    Min_Notice_Inst_Rental_Termination__c,Min_Commit_Dur_Inst_Rental__c,// added by nishi: 12-Nov-2020 : for get piano Terminating months
                    (SELECT Id,Subscription__c,Status__c,Subscription__r.Next_Bill_Date__c,Subscription__r.Subscription_Start_Date__c,Subscription__r.Parent__c,Subscription__r.Center__c,
                    Subscription_Expiry_Date__c,Subscription__r.Parent__r.Stripe_Customer_Id__c, Amount__c,Next_Bill_Date__c,Subscription_Start_Date__c,Subscription__r.Subscription_End_Date__c
                    FROM Subscription_Line_Items__r 
                    WHERE Subscription__c != NULL) 
                    FROM Enrolment__c 
                    WHERE Id =: enrolmentIds];
    }

    // get packed and remover user id 
    public static List<User> getPackerAndRemoverUser(){
        return [SELECT  Id, FirstName, LastName, Name, Email 
                FROM User 
                Where Name=:System.Label.Packers_and_Movers_User_Name];
                //commented by nishi: 18-sep-2020: for admin can set Packers and Movers user name Where Name='Packers and Movers'];
    } 
   	
    // current month invoice according to given status or enrolment id
    public static  Map<String,Decimal> getCurrentMonthInvoiceAmount(Set<String> objEnrolmentIds,string invoiceStatus){
        Date currentMonthdate = date.newInstance(System.today().year(), System.today().Month(), 1);
        decimal totalcurrentMonthPaidInvoiceAmount = 0;
        Map<String,Decimal> mapOfTotalcurrentMonthPaidInvoiceAmount = new Map<String,Decimal>();
        for(AggregateResult result :[SELECT SUM(Amount__c) invoiceTotal, SUM( GST_Amount__c) gstAmount ,Enrolment__c enrol
                                    FROM Invoice_Line_Item__c 
                                    WHERE Enrolment__c In:objEnrolmentIds
                                    AND (Invoice__r.Due_Date__c  = this_month)
                                    AND Invoice__r.Status__c =: invoiceStatus
                                    AND Invoice__r.Invoice_Type__c =:ConstantsClass.recurringInvoiceType
                                    GROUP BY Enrolment__c]){
                                        totalcurrentMonthPaidInvoiceAmount = 0;
            if((Decimal) result.get('invoiceTotal')  != null && (Decimal) result.get('invoiceTotal')> 0){
                totalcurrentMonthPaidInvoiceAmount = (Decimal) result.get('invoiceTotal') ;
            }
            /*
            10-Feb-2020:Rent to purchase need to show Pre-GST Amount
            if((Decimal) result.get('gstAmount')  != null && (Decimal) result.get('gstAmount')> 0){
                totalcurrentMonthPaidInvoiceAmount += (Decimal) result.get('gstAmount') ;
            }
            */
            mapOfTotalcurrentMonthPaidInvoiceAmount.put((string) result.get('enrol'),totalcurrentMonthPaidInvoiceAmount);
        }
        return mapOfTotalcurrentMonthPaidInvoiceAmount;
    }

    public static PianoRent createInvoicePianoRent(string pianoName,Integer remainingDays,Integer invoiceDay,decimal rentalPricePerMonth,Decimal rentalTotalAmount){
        PianoRent invoicePianoRent = new PianoRent();
        invoicePianoRent.pianoName = pianoName;
        invoicePianoRent.invoiceDay = invoiceDay;
        invoicePianoRent.unitPrice = (rentalPricePerMonth != null && rentalPricePerMonth > 0 ?rentalPricePerMonth/remainingDays : 0);
        invoicePianoRent.total = rentalTotalAmount;
        return invoicePianoRent;
    }
    
    /// 8-Feb-2020: jatin : for insert payment and send email 
    public static void getPaymentForInvoices(Map<String,String> mapOfInvoiceId,string templateName){
        system.debug('mapOfInvoiceId'+mapOfInvoiceId);
        List<Invoice__c> listOfInvoice = [Select Id,Name,Parent_Account__c,Parent_Account__r.PersonContactId,Parent_Account__r.Stripe_Customer_Id__c, 
                                          Total_Amount__c,subscription__c,Balance_Amount__c,Paid_Amount__c,
                                          Parent_Account__r.personEmail,Parent_Account__r.Centre_Name__r.Location__c,
                                          Center__r.Country__c, Center__r.Country__r.Id, Center__r.Country__r.Tax_Rate__c, 
                                          Center__r.Country__r.Currency_Code__c, Center__r.Country__r.Stripe_Base_Url__c, 
                                          Center__r.Country__r.Stripe_Secret_Key__c ,
                                          Center__r.Location__c,status__c
                                          FROM Invoice__c
                                          WHERE Id In:mapOfInvoiceId.keySet()];
                                          system.debug('listOfInvoice'+listOfInvoice);
        Set<String> successinvoiceIdSet = new Set<String>();
        List<Invoice__c> listOfInvoicesTOUpdate = new List<Invoice__c>();
        List<Invoice__c> DeclinedInvoiceList = new List<Invoice__c>();
        //List<Invoice__c> listOfInvoiceToRefund = new List<Invoice__c>();
        Set<Id> fifthBookingIdSet = new Set<Id>();
        List<Payment__c> listOfPayment = new List<Payment__c>();
        Set<String> declinedSet = new Set<String>();
        
        String paymentRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        String payCreditRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsCredit).getRecordTypeId();    
        
        //Map Of Countries of the centre's
        Map<String, Country__c> mapOfCountries = BillingUtility.getCountryMap('');
        
        for(Stripe_Declined_Code__mdt decMdt : [Select Label From Stripe_Declined_Code__mdt]){
            declinedSet.add(decMdt.Label);
        } 
        //26-Nov-2019:jatin Send Email to the Customer if its charge gives error and the payment is not collected from his account
        map<String,EmailTemplate> mapOfEmailTemplate = New map<String,EmailTemplate>();
        List<EmailTemplate> listOfEmailTemplate = New List<EmailTemplate>();
        if(string.isNotBlank(templateName)){
            listOfEmailTemplate = [SELECT Id, Name ,DeveloperName
                                        FROM EmailTemplate 
                                        WHERE DeveloperName =:templateName];
        }

        system.debug('@@listOfEmailTemplate'+listOfEmailTemplate);
        Map<String,Messaging.SingleEmailMessage> sendSingleEmailMessage = new Map<String,Messaging.SingleEmailMessage>();
        for(Invoice__c objInvoice : listOfInvoice){
            try{
                //Country Object to store the country object for the perticular Invoice...
                Country__c countryObj = new Country__c();
                if(mapOfCountries.containsKey(objInvoice.Center__r.Country__c)){
                    countryObj = mapOfCountries.get(objInvoice.Center__r.Country__c);
                }
                string personContactId,centerId;
                
                if(objInvoice.Balance_Amount__c >= 0.30 && String.isNotBlank(countryObj.Id) 
                   && String.isNotBlank(countryObj.Currency_Code__c) 
                   && String.isNotBlank(countryObj.Stripe_Base_Url__c) 
                   && String.isNotBlank(countryObj.Stripe_Secret_Key__c)){
                       BillingUtility.StripeCharge objStripeCharge = BillingUtility.createChargeForCustomerWithInvoice(
                           objInvoice.Parent_Account__r.Stripe_Customer_Id__c,
                           objInvoice.Balance_Amount__c, countryObj.Currency_Code__c,
                           objInvoice.Name, countryObj.Stripe_Base_Url__c, 
                           countryObj.Stripe_Secret_Key__c);
                       System.debug('@@@objStripeCharge'+objStripeCharge);
                       if(objStripeCharge.statusCode == 200 && objStripeCharge.paid != null && objStripeCharge.paid){
                           objInvoice.status__c = ConstantsClass.paidStatus;
                           listOfInvoicesTOUpdate.add(objInvoice);
                           Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,
                                                                              objInvoice.Id, 
                                                                              objInvoice.Balance_Amount__c,
                                                                              ConstantsClass.successStatus); 
                           objPayment.Transaction_ID__c = objStripeCharge.Id;
                           objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;               
                           objPayment.recordTypeId = paymentRecType;                
                           listOfPayment.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                           if(objInvoice.Parent_Account__r != null && string.isNotBlank(objInvoice.Parent_Account__r.PersonContactId)){
                               personContactId = objInvoice.Parent_Account__r.PersonContactId;
                           }
                           if(objInvoice.Parent_Account__r != null && objInvoice.Parent_Account__r.Centre_Name__r != null &&
                              string.isNotBlank(objInvoice.Parent_Account__r.Centre_Name__r.Location__c) ){
                                  centerId = objInvoice.Parent_Account__r.Centre_Name__r.Location__c;
                              }
                           if(listOfEmailTemplate != null && listOfEmailTemplate.size() > 0&& mapOfInvoiceId.containsKey(objInvoice.Id)){
                               sendSingleEmailMessage.put(objInvoice.Id,AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id,personContactId,mapOfInvoiceId.get(objInvoice.Id),centerId));
                           }   
                           
                       }else{
                        system.debug('objStripeCharge.error.message'+objStripeCharge.error.message);   
                        system.debug('objStripeCharge.error.stripeType'+objStripeCharge.error.stripeType);
                       }
                   }else if(objInvoice.Balance_Amount__c <= 0.30 && objInvoice.Balance_Amount__c > 0){
                       objInvoice.status__c = ConstantsClass.paidStatus;
                       listOfInvoicesTOUpdate.add(objInvoice);
                       Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,
                                                                          objInvoice.Id, 
                                                                          objInvoice.Balance_Amount__c,
                                                                          ConstantsClass.successStatus); 
                       objPayment.recordTypeId = payCreditRecType;
                       objPayment.remarks__c = 'Rounding Down';
                       listOfPayment.add(objPayment); //String parId, String invId, Decimal payAmt, String status
                       if(objInvoice.Parent_Account__r != null && string.isNotBlank(objInvoice.Parent_Account__r.PersonContactId)){
                           personContactId = objInvoice.Parent_Account__r.PersonContactId;
                       }
                       if(objInvoice.Parent_Account__r != null && objInvoice.Parent_Account__r.Centre_Name__r != null &&
                          string.isNotBlank(objInvoice.Parent_Account__r.Centre_Name__r.Location__c) ){
                              centerId = objInvoice.Parent_Account__r.Centre_Name__r.Location__c;
                          }
                       if(listOfEmailTemplate != null && listOfEmailTemplate.size() > 0 && mapOfInvoiceId.containsKey(objInvoice.Id)){
                           sendSingleEmailMessage.put(objInvoice.Id,AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id,personContactId,mapOfInvoiceId.get(objInvoice.Id),centerId));
                       } 
                   }
            }catch(Exception ex){
                System.debug('@@@@Exception '+ex.getMessage());
                System.debug('@@@@Exception '+ex.getLineNumber());
            }
            
        }
        if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
            Messaging.sendEmail(sendSingleEmailMessage.values(), FALSE); 
        }
        system.debug('@@@listOfInvoicesTOUpdate'+listOfInvoicesTOUpdate);
        system.debug('@@@sendSingleEmailMessage'+sendSingleEmailMessage);
        if(listOfInvoicesTOUpdate.size()>0){
            Database.Update(listOfInvoicesTOUpdate,false);
            system.debug('@@@listOfInvoicesTOUpdate'+listOfInvoicesTOUpdate);
            system.debug('@@@mapOfInvoiceId'+mapOfInvoiceId);
            //insertPdfAndSendEmail(listOfInvoicesTOUpdate,sendSingleEmailMessage);
            if(listOfPayment.size() > 0){
                Database.insert(listOfPayment,false);
            }
        }  
    }


    // create invoice line Items 
    public static Invoice_Line_Item__c createInvoicelineItem(Enrolment__c objEnrolment,Decimal invoiceAmount,Subscription_Line_Item__c  objSubLineItem,Country__c countryObj){
        Invoice_Line_Item__c inlineItemForChange = new Invoice_Line_Item__c();
        inlineItemForChange.Enrolment__c = objEnrolment.id;
        inlineItemForChange.Subscription_Line_Item__c = objSubLineItem.Id;
        if(invoiceAmount != null && invoiceAmount != 0){
            inlineItemForChange.Amount__c = BillingUtility.roundOffAmount(invoiceAmount);                                                               
        } 
        if(String.isNotBlank(objEnrolment.Package__c)){
            inlineItemForChange.Package__c = objEnrolment.Package__c;
        }
        inlineItemForChange.Is_Deposit__c = false;        
        if(countryObj.Tax_Rate__c >  0 && invoiceAmount != 0 ){
            Double gstAmount = BillingUtility.roundOffAmount(Double.valueOf(invoiceAmount) * (countryObj.Tax_Rate__c / 100));
            inlineItemForChange.gst_Amount__c = gstAmount;
        }
        inlineItemForChange.month__c = objEnrolment.Final_Delivery_date__c;
        return inlineItemForChange;
    }

    //Email confirmation to the customer with the invoice PDF
    public static void sendEmailWithInvoiceAttachment(Map<string,map<String ,Blob>> mapOfInvoiceAttachment,List<Invoice__c> ListOfInvoice ,string templateName){
            
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>(); 
        for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
            mapOfOrgWide.put(objAddress.DisplayName,objAddress);
        }
        map<String ,Blob> mapOfAttachment = new  map<String ,Blob> ();
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE name =:templateName LIMIT 1];
        for(Invoice__c inv :ListOfInvoice){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(inv.Parent_Account__r.personContactId);
            mail.setWhatId(inv.Id);
            mail.setTemplateId(template.id);
            mail.saveAsActivity = true;
            String location = inv.Center__r.Location__c;
            if(String.isNotBlank(location) && mapOfOrgWide.containsKey(location)){
                mail.setOrgWideEmailAddressId(mapOfOrgWide.get(location).Id);
            }
            List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
            mapOfAttachment = mapOfInvoiceAttachment.get(inv.id); 
            for(string attachmentName : mapOfAttachment.keySet()){
                Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                efa.setFileName(attachmentName);
                efa.setBody(mapOfAttachment.get(attachmentName));
                fileAttachments.add(efa);
            }
            mail.setFileAttachments(fileAttachments);
            emailList.add(mail);
        }
            system.debug('emailList'+emailList);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList,FALSE);
        if (results[0].success) {
            system.debug('sucess');
        } else {
            system.debug(results[0].errors[0].message);
        }
    }

    public static map<string,Attachment> createInvoiceAttachment(List<Invoice__c> listOfInvoice){
        map<string,Attachment> mapOfInvoiceAttachment = new  map<string,Attachment>();
        for(Invoice__c inv: listOfInvoice){    
            String pdfName =  inv.Name+'.pdf';
            Attachment attach = new Attachment();
            Blob body = Blob.valueOf('Some Text');
            try {
                String siteUrl = System.Label.Aureus_Site;
                PageReference pdf = new PageReference(siteUrl+'/apex/SubscriptionInvoicePdfClone?Id='+inv.Id);
                body =  pdf.getContentAsPdf();
            } catch (Exception e) {
                body = Blob.valueOf('Some Text');
            }
            attach.Body = body;
            attach.Name = pdfName;
            attach.ParentId = inv.id;
            mapOfInvoiceAttachment.put(inv.id,attach);
        }
        if(mapOfInvoiceAttachment != null && mapOfInvoiceAttachment.size() > 0 ){
            insert mapOfInvoiceAttachment.values();
        }
        return mapOfInvoiceAttachment;
    }

    // sign panda doc Aggrement
    Public static map<String,PandaDocUtility.CreateDocument> signAgreement(Set<String> enrolmentIds,string aggrementName){
        map<String,PandaDocUtility.CreateDocument> MapOfDocumentDetails = new map<String,PandaDocUtility.CreateDocument>();
      
        List<Enrolment__c> listOfEnrolment =  new List<Enrolment__c>();
        if(enrolmentIds != null && enrolmentIds.size() > 0 ){
            if(string.isNotBlank(aggrementName)){
                Map<String,String> mapOfcreateDocWrapperBody = new Map<String,String>();
                if(aggrementName=='Rental Aggrement'){
                    mapOfcreateDocWrapperBody = fillRentalDocumentWrapper(enrolmentIds);
                }else if(aggrementName=='Purchase Aggrement'){
                    mapOfcreateDocWrapperBody = fillPurchaseDocumentWrapper(enrolmentIds);
                }
                system.debug('mapOfcreateDocWrapperBody'+mapOfcreateDocWrapperBody);  
                for(string enrolmentId: mapOfcreateDocWrapperBody.keySet()){
                    PandaDocUtility.CreateDocument documentDetails = PandaDocUtility.createDocument(mapOfcreateDocWrapperBody.get(enrolmentId)); 
                    /*Get response in  json format 
                        {
                            "id": "msFYActMfJHqNTKH8YSvF1",
                            "status": "document.uploaded",
                            "name": "API Sample Document from PandaDoc Template",
                            "date_created": "2018-08-02T08:42:13.836022Z",
                            "date_modified": "2018-08-02T08:42:13.836022Z",
                            "expiration_date": null,
                            "uuid": "msFYActMfJHqNTKH8YSvF1"
                        }
                    */
                    system.debug('@@@documentDetails'+documentDetails);
                    if(String.isNotBlank(documentDetails.id)){
                        system.debug(documentDetails.id);
                        MapOfDocumentDetails.put(enrolmentId,documentDetails);  
                    }
                } 
                system.debug('@@@listOfEnrolment'+listOfEnrolment);
            }
        } 
        return MapOfDocumentDetails;
    }

      //jatin: 12-Jan:2020 for Return detailed data about a document and return only input field value 
    Public static PandaDocUtility.Fields  getDocumentStairs(string aggrementId){
        PandaDocUtility.Fields objNewFields;
        list<PandaDocUtility.Fields> listOfFieldsDetails; 
        if(String.isNotBlank(aggrementId)){
            PandaDocUtility.Fields objFields = PandaDocUtility.viewDocumentDetails(aggrementId,'Stairs');
                if(string.isNotBlank(objFields.name) && objFields.name =='Stairs'){
                    objNewFields =  objFields;
                }
        }
         return objNewFields;
    }
    
    // Get basic data about a document such as name, status, and dates
    Public static map<String,PandaDocUtility.Document> waitAgreement(map<String,string> MapOfDocumentDetails ){
        map<String,PandaDocUtility.Document> MapOfDocument = new map<String,PandaDocUtility.Document>();
        PandaDocUtility.Document document = new PandaDocUtility.Document();
        system.debug('@@@waitAgreement'+MapOfDocumentDetails);
        if(MapOfDocumentDetails != null && MapOfDocumentDetails.size() > 0){
            for(string enrolmentId: MapOfDocumentDetails.keySet()){
                if( String.isNotBlank(MapOfDocumentDetails.get(enrolmentId))){
                    document = PandaDocUtility.viewDocument(MapOfDocumentDetails.get(enrolmentId));
                    system.debug('@@@document'+document);
                    if(String.isNotBlank(document.id)){
                        system.debug(document.id);
                        MapOfDocument.put(enrolmentId,document); 
                    } 
                    MapOfDocument.put(enrolmentId,document);
                } 
            }
        }
        system.debug('@@@MapOfDocument'+MapOfDocument);
        return MapOfDocument;
    }

    //Move a document to sent status and send an optional email.
    Public static map<string,PandaDocUtility.CreateDocument> sendAgreement(Map<String,string> MapOfDocumentDetails){
        DocumentWrapperForPianoRental.SendDocument sendDocument;
        map<string,PandaDocUtility.CreateDocument> mapOfsendDocument = new map<string,PandaDocUtility.CreateDocument>();
        String body = '';
        if(MapOfDocumentDetails != null && MapOfDocumentDetails.size() > 0){
            for(string enrolmentId: MapOfDocumentDetails.keySet()){
                PandaDocUtility.CreateDocument documentDetails;
                if( String.isNotBlank(MapOfDocumentDetails.get(enrolmentId))){
                    sendDocument = new DocumentWrapperForPianoRental.SendDocument('Hello! This document was sent from the PandaDoc API.', true);      
                    body = JSON.serialize(sendDocument);
                     System.debug('@@@body'+body);
                   /*Get response in  json format 
                    {
                        "id": "msFYActMfJHqNTKH8YSvF1",
                        "name": "API Sample Document from PandaDoc Template",
                        "status": "document.sent",
                        "date_created": "2018-02-06T08:42:13.836022Z",
                        "date_modified": "2018-02-06T08:42:13.836022Z",
                        "expiration_date": "2018-02-06T08:42:13.836022Z",
                        "version": "1",
                        "uuid": "msFYActMfJHqNTKH8YSvF1"
                    }
                    */
                    documentDetails = PandaDocUtility.sendDocument(body, MapOfDocumentDetails.get(enrolmentId));
                    System.debug('@@@documentDetails'+documentDetails);
                    if(documentDetails.status == 'document.sent'){
                        mapOfsendDocument.put(enrolmentId,documentDetails);
                    }
                }
            }
        }
        return mapOfsendDocument;
    }

    
    // create document session for sign aggrement
    Public static string  createSession(string aggrementId,string personEmail){
        string sessionId='';
        PandaDocUtility.SessionDocument sessionDetails = new PandaDocUtility.SessionDocument(); 
        if(String.isNotBlank(aggrementId) && String.isNotBlank(personEmail)){
             String body = '{ "recipient": "'+personEmail+'", "lifetime": 3600}';   
             sessionDetails = PandaDocUtility.createSession(aggrementId, body);
             System.debug('@@@sessionDetails'+sessionDetails);
             if(String.isNotBlank(sessionDetails.id)){
                 sessionId = sessionDetails.id;     
             }
         }
         return sessionId;
     }

     // create Rental Doumnent body according to enrolment details 
     private static Map<String,String> fillRentalDocumentWrapper(Set<String> EnrolmentIds){        
        String jsonBody = '';       
        DocumentWrapperForPianoRental.Fields field;       
        List<DocumentWrapperForPianoRental.Tokens> tokens;
        DocumentWrapperForPianoRental.recipients recipientTransporter = new DocumentWrapperForPianoRental.recipients();     
        DocumentWrapperForPianoRental.recipients recipientClient = new DocumentWrapperForPianoRental.recipients();     
        List<DocumentWrapperForPianoRental.recipients> listOfRecipient = new List<DocumentWrapperForPianoRental.recipients>();    
        List<User> listOfPackerAndRemoverUser =  getPackerAndRemoverUser();
        Map<String,String> mapOfcreateDocWrapper = new Map<string,String>();
        if(EnrolmentIds.size() > 0){      
            for(Enrolment__c enrolmentObj:getRentalEnrolmentList(EnrolmentIds)){
                jsonBody = '';
                DateTime enrolmentDateTime;     
               // DocumentWrapperForPianoRental.Rows row;  
                listOfRecipient = new List<DocumentWrapperForPianoRental.recipients>();
                recipientTransporter = new DocumentWrapperForPianoRental.recipients();
                recipientClient = new DocumentWrapperForPianoRental.recipients(); 
                DocumentWrapperForPianoRental.CreateDocument createDocWrapper = new DocumentWrapperForPianoRental.CreateDocument();     
                 createDocWrapper.recipients = new List<DocumentWrapperForPianoRental.Recipients>();       
               
                createDocWrapper.name = '';    
                //add templete and folder Id
                createDocWrapper.template_uuid =  Label.Piano_Rental_Template_Id;//'5jfk4yvnNWaqsjmg4tdnbm';   
                createDocWrapper.folder_uuid = Label.Piano_Rental_Folder_Id;//'r7Fhbe9cvV6MCnD59adALG';
                //createDocWrapper.metadata.salesforceAccount_id = enrolDetail.transorterDetails.Id;     
                // add first signature of Delivery_Person detials
                if(listOfPackerAndRemoverUser != null && listOfPackerAndRemoverUser.size() >0){
                    recipientTransporter.first_name = listOfPackerAndRemoverUser[0].FirstName;       
                    recipientTransporter.last_name =listOfPackerAndRemoverUser[0].LastName;      
                    recipientTransporter.email =listOfPackerAndRemoverUser[0].Email;       
                    recipientTransporter.role = 'Delivery_Person';      
                    recipientTransporter.recipient_type = 'signer';  
                    recipientTransporter.has_completed = true;  
                    createDocWrapper.recipients.add(recipientTransporter);    
                }
                tokens = new List<DocumentWrapperForPianoRental.Tokens>();
                // pass a list of tokens/values to pre-fill tokens used in a template
                if(enrolmentObj.Parent__r != null){
                    tokens.add(new DocumentWrapperForPianoRental.Tokens('Parent_First_Name__c', enrolmentObj.Parent__r.FirstName));
                    tokens.add(new DocumentWrapperForPianoRental.Tokens('Parent_Last_Name__c', enrolmentObj.Parent__r.LastName));
                    tokens.add(new DocumentWrapperForPianoRental.Tokens('Parent__r.BillingStreet', enrolmentObj.Parent__r.BillingStreet));
                    tokens.add(new DocumentWrapperForPianoRental.Tokens('Parent__r.BillingCity', enrolmentObj.Parent__r.BillingCity));
                    tokens.add(new DocumentWrapperForPianoRental.Tokens('Parent__r.BillingCountry', enrolmentObj.Parent__r.BillingCountry));
                    tokens.add(new DocumentWrapperForPianoRental.Tokens('Parent_Phone__c', enrolmentObj.Parent__r.Phone));
                }
                tokens.add(new DocumentWrapperForPianoRental.Tokens('Model__c', enrolmentObj.Model__c));
                tokens.add(new DocumentWrapperForPianoRental.Tokens('Serial_Number__c', enrolmentObj.Serial_Number__c));
                
                if(enrolmentObj.Final_Delivery_date__c != null && enrolmentObj.Final_Delivery_Timeslot__c != null){
                    Datetime finalDeliveryDate = Datetime.newInstance(enrolmentObj.Final_Delivery_date__c, enrolmentObj.Final_Delivery_Timeslot__c);
                    String slotTime = finalDeliveryDate.format('dd-MMM-YYYY h:mm a');   
                    tokens.add(new DocumentWrapperForPianoRental.Tokens('FinalDeliveryTimeslot', slotTime));
                }
                tokens.add(new DocumentWrapperForPianoRental.Tokens('Standard_Accessories__c', enrolmentObj.Standard_Accessories__c));
                
                // add user details who is sign this documtents
                if(String.isNotBlank(enrolmentObj.Parent__r.Id)){       
                    createDocWrapper.metadata.salesforceAccount_id = enrolmentObj.Parent__r.id;     
                    recipientClient.first_name = enrolmentObj.Parent__r.FirstName;        
                    recipientClient.last_name = enrolmentObj.Parent__r.LastName;      
                    recipientClient.email = enrolmentObj.Parent__r.PersonEmail; 
                    recipientClient.recipient_type = 'signer';  
                    recipientClient.has_completed = true;  
                    recipientClient.role = 'Client';      
                    createDocWrapper.recipients.add(recipientClient);     
                } 
                //commented by jaitn: 10-feb-2020: default show 0 stairs user added only extra stirs. 
                //String stairs =  enrolmentObj.No_of_Stairs__c != null ? string.valueOf(enrolmentObj.No_of_Stairs__c) : '0';
                // 
                field = new DocumentWrapperForPianoRental.Fields('0', 'Stairs');       
                createDocWrapper.fields = new DocumentWrapperForPianoRental.CustomField(field);  
                
                enrolmentDateTime = system.now();  
                createDocWrapper.name += enrolmentObj.name + '-';    
                createDocWrapper.tokens = tokens;
                // 10-Feb:2020:jatin:In the name of the attachment -- rental policy should be changed to "Delivery Note"
                //createDocWrapper.name += 'rental policy';       
                
                createDocWrapper.name += 'Delivery Note';       
                if(String.isNotBlank(createDocWrapper.name)){       
                    jsonBody = JSON.Serialize(createDocWrapper).replaceAll('pandadoc_Default_Section_XYZ','default');   
                    jsonBody = jsonBody.replaceAll('pandadoc_Currency_Code_XYZ','currency');     
                    System.debug('createDocWrapper '+createDocWrapper);     
                    System.debug('createDocWrapper '+createDocWrapper.metadata);        
                    jsonBody = jsonBody.replaceAll('salesforceAccount_id','salesforce.account_id');     
                    jsonBody = jsonBody;  
                    system.debug('jsonBody'+jsonBody);      
                }
                mapOfcreateDocWrapper.put(enrolmentObj.Id,jsonBody); 
            }   
            
        }       
        system.debug('mapOfcreateDocWrapper'+mapOfcreateDocWrapper);
        return mapOfcreateDocWrapper;        
    }

      // jatin:30-Jan-2020: for fill purchase document required fields
      private  static Map<String,String> fillPurchaseDocumentWrapper(Set<String> EnrolmentIds){        
        String jsonBody = '';       
        DocumentWrapperForPianoPurchase.Fields field;       
        List<DocumentWrapperForPianoPurchase.Tokens> tokens;
        DocumentWrapperForPianoPurchase.recipients recipientClient = new DocumentWrapperForPianoPurchase.recipients();     
        Map<String,String> mapOfcreateDocWrapper = new Map<string,String>();
        Map<String,Decimal> mapOfTotalInvoicePaidAmount = get4MonthPaidInvoiceAmount(EnrolmentIds);
                 
        Map<String,Decimal> mapOfTotalRentalDepositAmount  = getTotalRentalDepositAmount(EnrolmentIds);
        if(EnrolmentIds.size() > 0){      
            for(Enrolment__c enrolmentObj:getRentalEnrolmentList(EnrolmentIds)){
                jsonBody = '';
                DateTime enrolmentDateTime;     
                //DocumentWrapperForPianoPurchase.Rows row;  
                recipientClient = new DocumentWrapperForPianoPurchase.recipients(); 
                DocumentWrapperForPianoPurchase.CreateDocument createDocWrapper = new DocumentWrapperForPianoPurchase.CreateDocument();     
                 createDocWrapper.recipients = new List<DocumentWrapperForPianoPurchase.Recipients>();       
               
                createDocWrapper.name = '';    
                //add templete and folder Id
               
                createDocWrapper.template_uuid =  Label.Piano_Purchase_Template_Id;//'q6ScM9GBwi7UAzutYCfS8m';   
                createDocWrapper.folder_uuid = Label.Piano_Purchase_Folder_Id;//'LQ66xcYvjjSZebir2cCUW8';
                tokens = new List<DocumentWrapperForPianoPurchase.Tokens>();
                // pass a list of tokens/values to pre-fill tokens used in a template
                if(enrolmentObj.Parent__r != null){
                    tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Parent_First_Name__c', enrolmentObj.Parent__r.FirstName));
                    tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Parent_Last_Name__c', enrolmentObj.Parent__r.LastName));
                }
                
                tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Selling__c', string.valueOf(enrolmentObj.Selling_price__c != null ?enrolmentObj.Selling_price__c : 0)));
                if(mapOfTotalInvoicePaidAmount.containsKey(enrolmentObj.id))
                    tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Rental_price_per_month__c', string.valueOf(mapOfTotalInvoicePaidAmount.get(enrolmentObj.id) != null ? mapOfTotalInvoicePaidAmount.get(enrolmentObj.id) : 0)));
                else
                    tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Rental_price_per_month__c', '0'));
                
                tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Delivery__c', string.valueOf(enrolmentObj.Delivery_Charges__c != null && enrolmentObj.Delivery_Charges__c > 0 ? (enrolmentObj.Delivery_Charges__c/2):0)));
                if(mapOfTotalRentalDepositAmount.containsKey(enrolmentObj.id))
                    tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Deposit__c', string.valueOf(mapOfTotalRentalDepositAmount.get(enrolmentObj.id) != null ?mapOfTotalRentalDepositAmount.get(enrolmentObj.id) : 0 )));
                else{
                    tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Deposit__c', '0'));
                }
                tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Model__c', enrolmentObj.Model__c));
                tokens.add(new DocumentWrapperForPianoPurchase.Tokens('Serial_Number__c', enrolmentObj.Serial_Number__c));
                // add user details who is sign this documtents
                system.debug('enrolmentObj.Parent__r.PersonEmail'+enrolmentObj.Parent__r.PersonEmail);
                if(String.isNotBlank(enrolmentObj.Parent__r.Id)){       
                    createDocWrapper.metadata.salesforceAccount_id = enrolmentObj.Parent__c;     
                    recipientClient.first_name = enrolmentObj.Parent__r.FirstName;        
                    recipientClient.last_name = enrolmentObj.Parent__r.LastName;      
                    recipientClient.email = enrolmentObj.Parent__r.PersonEmail; 
                    recipientClient.recipient_type = 'signer';  
                    recipientClient.has_completed = true;  
                    recipientClient.role = 'Client';      
                    createDocWrapper.recipients.add(recipientClient);  
                   
                     //field = new DocumentWrapperForPianoPurchase.Fields(enrolmentObj.Parent__r.firstName +' '+enrolmentObj.Parent__r.lastName, 'Parent Name');       
                    //createDocWrapper.fields = new DocumentWrapperForPianoPurchase.CustomField(field); 
                } 
                enrolmentDateTime = system.now();  
                createDocWrapper.name += enrolmentObj.name + '-';    
                createDocWrapper.tokens = tokens;
                createDocWrapper.name += 'Purchase Agreement';  
                if(String.isNotBlank(createDocWrapper.name)){       
                    jsonBody = JSON.Serialize(createDocWrapper).replaceAll('pandadoc_Default_Section_XYZ','default');   
                    jsonBody = jsonBody.replaceAll('pandadoc_Currency_Code_XYZ','currency');     
                    System.debug('createDocWrapper '+createDocWrapper);     
                    System.debug('createDocWrapper '+createDocWrapper.metadata);        
                    jsonBody = jsonBody.replaceAll('salesforceAccount_id','salesforce.account_id');     
                    jsonBody = jsonBody;  
                    system.debug('jsonBody'+jsonBody);      
                }
                mapOfcreateDocWrapper.put(enrolmentObj.Id,jsonBody); 
            }   
            
        }       
        
        return mapOfcreateDocWrapper;        
    }
    

    // get last 4 month paid invoice amount with gst
    public static  map<string,Decimal> get4MonthPaidInvoiceAmount(set<string> enrolmentIds){
        Date last4thMonthStartdate = date.newInstance(System.today().addMonths(-4).year(), System.today().addMonths(-4).Month(), 1);
        Date last4thMonthEnddate = date.newInstance(System.today().year(), System.today().Month(), 1);
        last4thMonthEnddate =last4thMonthEnddate.addDays(-1);
        decimal total4monthPaidInvoiceAmount = 0;
        system.debug(' last4thMonthdate'+last4thMonthStartdate);
        system.debug(' last4thMonthEnddate'+last4thMonthEnddate);
        map<string,Decimal> mapOf4MonthPaidInvoiceAmount = new map<string,Decimal>();
        for(AggregateResult result :[SELECT SUM(Amount__c) invoiceTotal, SUM( GST_Amount__c) gstAmount ,Enrolment__c enrol
                                    FROM Invoice_Line_Item__c 
                                    WHERE Enrolment__c In:enrolmentIds
                                    AND (Invoice__r.Due_Date__c  >=: last4thMonthStartdate And Invoice__r.Due_Date__c <=: last4thMonthEnddate)
                                    AND Invoice__r.Status__c = 'Paid'
                                    AND Invoice__r.Invoice_Type__c =:ConstantsClass.recurringInvoiceType
                                    GROUP BY Enrolment__c]){
            total4monthPaidInvoiceAmount = 0;
            if((Decimal) result.get('invoiceTotal')  != null && (Decimal) result.get('invoiceTotal')> 0){
                total4monthPaidInvoiceAmount = (Decimal) result.get('invoiceTotal');
            }/*
            10-Feb-2020:Rent to purchase need to show Pre-GST Amount    
            if((Decimal) result.get('gstAmount')  != null && (Decimal) result.get('gstAmount')> 0){
                total4monthPaidInvoiceAmount += (Decimal) result.get('gstAmount');
            }*/
            mapOf4MonthPaidInvoiceAmount.put(string.valueOf(result.get('enrol')),  total4monthPaidInvoiceAmount);
        }
        system.debug('mapOf4MonthPaidInvoiceAmount'+mapOf4MonthPaidInvoiceAmount);
        return mapOf4MonthPaidInvoiceAmount;
    }

    // 13-Feb-2020: Jatin: this function get enrolement and parent id then get related 4 month paid invoice amount with due date for show summary in termination page
    public static  Map<String,List<Invoice__c>> get4MonthPaidInvoiceAmountWithDate(Set<string> enrolmentIds){
        Date last4thMonthStartdate = date.newInstance(System.today().addMonths(-4).year(), System.today().addMonths(-4).Month(), 1);
        Date last4thMonthEnddate = date.newInstance(System.today().year(), System.today().Month(), 1);
        last4thMonthEnddate =last4thMonthEnddate.addDays(-1);
        decimal total4monthPaidInvoiceAmount = 0;
        system.debug(' last4thMonthdate'+last4thMonthStartdate);
        system.debug(' last4thMonthEnddate'+last4thMonthEnddate);
        Map<String,List<Invoice__c>> mapOfEnrolmentInvoiceAmount = new Map<string,List<Invoice__c>>();
        Map<String,String> mapOfInvoiceEnrolmentIds = new Map<String,String>();
        List<Invoice__c> listofInvoice = new List<Invoice__c>();
        // get invoice line item for get enrolmentIds related to invoiceid
        for(Invoice_Line_Item__c objlineItem : [SELECT Id,Amount__c,Enrolment__c,Invoice__c,Invoice__r.Parent_Account__c from Invoice_Line_Item__c
                                    Where Enrolment__c In:enrolmentIds
                                    AND (Invoice__r.Due_Date__c  >=: last4thMonthStartdate And Invoice__r.Due_Date__c <=: last4thMonthEnddate)
                                    AND Invoice__r.Status__c = 'Paid'
                                    AND Invoice__r.Invoice_Type__c =:ConstantsClass.recurringInvoiceType]){
           if(!mapOfInvoiceEnrolmentIds.containsKey(objlineItem.Invoice__c)){
               mapOfInvoiceEnrolmentIds.put(objlineItem.Invoice__c,objlineItem.Enrolment__c);      
            }         
        }
        system.debug('mapOfInvoiceEnrolmentIds'+mapOfInvoiceEnrolmentIds);
        // get invoice for get  last 4 month recurring type  paid invoices
        if(mapOfInvoiceEnrolmentIds != null && mapOfInvoiceEnrolmentIds.size() > 0){
            for(Invoice__c objInvoice :[SELECT Due_Date__c, Id ,Sub_Total__c FROM Invoice__c 
                                                where Id In: mapOfInvoiceEnrolmentIds.keySet()]){
                List<String> paidInvoiceDateAndAmount = new List<String>();
                string enrolmentId ='';
                string parentId ='';
                if(mapOfInvoiceEnrolmentIds.containsKey(objInvoice.id)){
                    listofInvoice = new List<Invoice__c>();
                    if(mapOfEnrolmentInvoiceAmount.containsKey(mapOfInvoiceEnrolmentIds.get(objInvoice.id))){
                        listofInvoice = mapOfEnrolmentInvoiceAmount.get(mapOfInvoiceEnrolmentIds.get(objInvoice.id));
                    }
                    listofInvoice.add(objInvoice);
                    mapOfEnrolmentInvoiceAmount.put(mapOfInvoiceEnrolmentIds.get(objInvoice.id),listofInvoice);
                }
            }
        }
        system.debug('mapOfEnrolmentInvoiceAmount'+mapOfEnrolmentInvoiceAmount);
        return mapOfEnrolmentInvoiceAmount;
    }

    // get depoist  invoice amount with gst
    public static  Map<string,Decimal>  getTotalRentalDepositAmount(Set<string> objEnrolmentIds){
        Date last4thMonthdate = date.newInstance(System.today().addMonths(-4).year(), System.today().addMonths(-4).Month(), 1);
        Decimal totalRentalDeposit = 0;
        Set<String> packageNames = New Set<String>{'Deposit'} ;
        Map<string,Decimal> mapOfTotalRentalDeposit = new Map<string,Decimal>();
        for(AggregateResult result : [SELECT SUM(Amount__c) invoiceTotal, SUM( GST_Amount__c) gstAmount ,Enrolment__c enrol
                                                        FROM Invoice_Line_Item__c 
                                                        WHERE Enrolment__c IN: objEnrolmentIds
                                                        AND Is_Deposit__c = true
                                                        AND Invoice__r.Due_Date__c <= Today
                                                        GROUP BY Enrolment__c]){
                                                            totalRentalDeposit = 0;
            if((Decimal) result.get('invoiceTotal')  != null && (Decimal) result.get('invoiceTotal')> 0){
                totalRentalDeposit = (Decimal) result.get('invoiceTotal');
            }/*
            10-Feb-2020:Rent to purchase need to show Pre-GST Amount
            if((Decimal) result.get('gstAmount')  != null && (Decimal) result.get('gstAmount')> 0){
                totalRentalDeposit += (Decimal) result.get('gstAmount');
            }*/
            mapOfTotalRentalDeposit.put(string.valueOf(result.get('enrol')),totalRentalDeposit);
        }
        return mapOfTotalRentalDeposit;
    }
    /* 8-Feb-2020: inset email with invoie Pdf  attachment
    public static void insertPdfAndSendEmail(List<Invoice__c> invoiceList,Map<String,Messaging.SingleEmailMessage> sendSingleEmailMessage){
        DateTime now = DateTime.now();
        system.debug('invoiceList'+invoiceList);
         if(invoiceList.size() > 0){
            map<Id,Blob> mapOfAttachment = new map<Id,Blob>();
            List<Attachment> listOfAttachment = new List<Attachment>();
            for(Invoice__c inv:invoiceList){
                String pdfName =  inv.Name+'.pdf';
                Attachment attach = new Attachment();
                Blob body = Blob.valueOf('Some Text');
                try {
                    String siteUrl = System.Label.Aureus_Site;
                    PageReference pdf = new PageReference(siteUrl+'/apex/SubscriptionInvoicePdfClone?Id='+inv.Id);
                    body =  pdf.getContentAsPdf();
                } catch (Exception e) {
                    body = Blob.valueOf('Some Text');
                    system.debug('####error '+e.getMessage());
                }
                system.debug('@@@body'+string.valueOf(body));    
                attach.Body = body;
                attach.Name = pdfName;
                attach.ParentId = inv.id;
                mapOfAttachment.put(inv.id,body);
                listOfAttachment.add(attach);
            }
            if(listOfAttachment.size() > 0){
                insert listOfAttachment;
                system.debug('mapOfAttachment'+mapOfAttachment);
                system.debug('listOfAttachment'+listOfAttachment);
                system.debug('invoiceList'+invoiceList);
                system.debug('sendSingleEmailMessage'+sendSingleEmailMessage);
                sendEmail(mapOfAttachment,invoiceList,sendSingleEmailMessage);
            }
        }
    }
    //Email confirmation to the customer with the invoice PDF
    private static void sendEmail(map<Id,Blob> mapOfAttachment,List<Invoice__c> invoiceList,Map<String,Messaging.SingleEmailMessage> sendSingleEmailMessage){
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>(); 
        for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
            mapOfOrgWide.put(objAddress.DisplayName,objAddress);
        }
        system.debug('mapOfAttachment'+mapOfAttachment);
        //EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName ='Instrument_Delivery_Confirmation' LIMIT 1];
         for(Invoice__c inv:invoiceList){
            if(sendSingleEmailMessage.containsKey(inv.id)){
                Messaging.SingleEmailMessage mail = sendSingleEmailMessage.get(inv.id);
                if(mapOfAttachment.containsKey(inv.id)){
                    List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                    efa.setFileName('Instrument_Delivery_Confirmation.pdf');
                    efa.setBody(mapOfAttachment.get(inv.id));
                    fileAttachments.add(efa);
                    mail.setFileAttachments(fileAttachments);
                }
                emailList.add(mail);
            }
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList);
        system.debug('results'+results);
        if (results[0].success) {
            system.debug('sucess');
        } else {
            system.debug(results[0].errors[0].message);
        }
    }*/


    public class PianoRent{
        public String pianoName{get;set;}
        public Integer invoiceDay{get;set;}
        public Decimal unitPrice{get;set;}
        public Decimal total{get;set;}
    } 
     
}