/*
    Name: TerminateRentalSummaryController
    Date: 24-Jan-2020
    Author: JATIN
    Description :  this  controller for show termination enrolment summary  
*/
public  without sharing class TerminateRentalSummaryController {
    public Boolean  isSendToTeminationButton{get;set;}
    public String  terminationRequestEndDate{get;set;}
    public String  pickupRequestEndDate{get;set;}
    public String  terminationReason{get;set;}
    public String  terminationOtherReason{get;set;}
    public Enrolment__c objEnrolment{get;set;}
    public String  enrolmentId{get;set;}
    public Boolean ischeckStage{get;set;}
    public TerminateRentalSummaryController() {
        enrolmentId = ApexPages.currentPage().getParameters().get('enrolmentId');
        ischeckStage = true;
        if(string.isNotBlank(enrolmentId)){
            getAllTerminationFields();  
        }
        
    }
    // get enrolment detials 
    public void getAllTerminationFields(){
        List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {enrolmentId});
        if(listOfenrolment != null && listOfenrolment.size() > 0){
            objEnrolment = listOfenrolment[0];
        }

        terminationRequestEndDate = string.valueOf(objEnrolment.Termination_request_date__c);
        pickupRequestEndDate = string.valueOf(objEnrolment.Piano_Pickup_date__c);
        terminationReason = objEnrolment.Termination_Reason__c;
        terminationOtherReason = objEnrolment.Termination_Reason_others__c;
        ischeckStage = true;
        if(objEnrolment.Stage__c ==ConstantsClass.enrollmentPianoTerminationInProgressStage || objEnrolment.Stage__c ==ConstantsClass.enrollmentPianoRentalTerminatedStage){
            ischeckStage = false;
        }
    }

    // after submit tremination then check who is submit this summary 
    // 1. if salesforce user submit this then send email and update enrolment termination andpickup date 
    // 2. if customer submit this then create 3 task and assign retal or finence queue and enrolment stage is changed
     @RemoteAction      
    public static string submitTerminateRentalSummaryRequest(String enrolmentId, String terminationRequestEndDate, String pickupRequestEndDate,
                                                                String terminationReason, String terminationOtherReason,Boolean isSendToButton){
        try{
             Map<String,Messaging.SingleEmailMessage> sendSingleEmailMessage = new Map<String,Messaging.SingleEmailMessage>();
       
            Date terminationRequestEndDateObj, pickupRequestEndDateObj;
            if(String.isNotBlank(terminationRequestEndDate)){
                terminationRequestEndDateObj = Date.valueOf(terminationRequestEndDate);
            }
            if(String.isNotBlank(pickupRequestEndDate)){
                pickupRequestEndDateObj = Date.valueOf(pickupRequestEndDate);
            }   
            Enrolment__c objEnrolment   = new Enrolment__c(); 
            if(isSendToButton){
                objEnrolment = new  Enrolment__c(id = enrolmentId,Termination_request_date__c = terminationRequestEndDateObj,
                                                Piano_Pickup_date__c = pickupRequestEndDateObj,
                                                Termination_Reason__c =   terminationReason
                                                );
                if(terminationReason.equalsIgnoreCase('Others')){
                    objEnrolment.Termination_Reason_others__c =terminationOtherReason;
                }
                update objEnrolment;
                List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {enrolmentId});
                if(listOfenrolment != null && listOfenrolment.size() > 0){
                    objEnrolment = listOfenrolment[0];
                }
                 map<String,EmailTemplate> mapOfEmailTemplate = New map<String,EmailTemplate>();
                 List<EmailTemplate> listOfEmailTemplate = [SELECT Id, Name ,DeveloperName
                                                    FROM EmailTemplate 
                                                    WHERE DeveloperName =:'Termination_Confirmation'];
                                                    system.debug('listOfEmailTemplate'+listOfEmailTemplate);
                string personContactId,centerId;
                if(objEnrolment.Parent__c != null && string.isNotBlank(objEnrolment.Parent__r.PersonContactId)){
                    personContactId = objEnrolment.Parent__r.PersonContactId;
                }
                if(objEnrolment.Center__c != null && objEnrolment.Center__r != null &&
                    string.isNotBlank(objEnrolment.Center__r.Location__c) ){
                        centerId = objEnrolment.Center__r.Location__c;
                    }
                if(listOfEmailTemplate != null && listOfEmailTemplate.size() > 0 ){
                    sendSingleEmailMessage.put(objEnrolment.Id,AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id,personContactId,objEnrolment.id,centerId));
                } 
              
                if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
                    Messaging.sendEmail(sendSingleEmailMessage.values(), FALSE); 
                }
               
            }
            if(!isSendToButton){
                objEnrolment = new  Enrolment__c(id = enrolmentId,Stage__c ='Piano Termination In-Progress');
                update objEnrolment;
                system.debug('objEnrolment'+objEnrolment);
                List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {enrolmentId});
                if(listOfenrolment != null && listOfenrolment.size() > 0){
                    objEnrolment = listOfenrolment[0];
                }
                Set<string> queueName = new Set<string>{'Finance Queue','Retail Queue'};
                Map<string,QueueSObject > mapOfQueue = new Map<string,QueueSObject >();
                for(QueueSObject objQueueSObject :   [Select Queue.Id, Queue.Name, Queue.Type 
                                                        from QueueSObject 
                                                        WHERE Queue.Type ='Queue' 
                                                        AND Queue.Name In :queueName 
                                                        AND sObjectType='Task']){
                                                            mapOfQueue.put(objQueueSObject.Queue.Name,objQueueSObject);  
                                                        }
                                                        system.debug('mapOfQueue'+mapOfQueue);
                  List<Task> ListOfTask = new List<Task>();
                if(mapOfQueue!= null && mapOfQueue.size() > 0 && mapOfQueue.containsKey('Retail Queue')) {
                    ListOfTask.add(createNewTask('Piano Pickup ',objEnrolment.id,terminationRequestEndDateObj,mapOfQueue.get('Retail Queue').Queue.Id));  
                }     
                if(mapOfQueue!= null && mapOfQueue.size() > 0 && mapOfQueue.containsKey('Retail Queue')) {
                    ListOfTask.add(createNewTask('Piano Inspection',objEnrolment.id,terminationRequestEndDateObj.addDays(1),mapOfQueue.get('Retail Queue').Queue.Id));  
                } 
                if(mapOfQueue!= null && mapOfQueue.size() > 0 && mapOfQueue.containsKey('Finance Queue')) {
                    ListOfTask.add(createNewTask('Deposit Refund',objEnrolment.id,terminationRequestEndDateObj.addDays(30),mapOfQueue.get('Finance Queue').Queue.Id));  
                } 
                insert ListOfTask;
                system.debug('ListOfTask'+ListOfTask);
                 String refundRecType = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();

                List<Payment__c> paymentList = new  List<Payment__c>();
                Decimal refundAmount = AureusCalendarController.getDepositFromFile(objEnrolment.id);
                system.debug('@@@refundAmount'+refundAmount);
                if(refundAmount  != null && refundAmount > 0){
                    Payment__c objPay = new Payment__c();
                    //String chargeId =  AureusCalendarController.fetchCurrentMonthPaymentEntry(objEnrolment,pickupRequestEndDateObj);
                    //System.debug('chargeId'+chargeId);
                    //if(String.isNotBlank(chargeId)){
                        objPay.RecordTypeId =  refundRecType ;
                        objPay.Payment_Date__c = pickupRequestEndDateObj;
                        objPay.Payment_Status__c = ConstantsClass.paymentPendingStatus;
                        objPay.Payment_Amount__c = refundAmount;
                        objPay.Parent_Account__c = objEnrolment.Parent__c;
                       // objPay.Transaction_ID__c = chargeId;
                        objPay.last_lesson_date__c = pickupRequestEndDateObj;
                        paymentList.add(objPay); 
                    /*}else{
                        return 'Charge Id not found';
                    }*/
                }
                system.debug('@@@paymentList'+paymentList);
                if(paymentList.size() > 0){
                    insert paymentList;
                }
                system.debug('@@@paymentList'+paymentList);
            }
        }catch(exception e){
            system.debug('###'+e.getStackTraceString());
            return e.getMessage();
        }
        return 'SUCCESS';
    }

    // create new task and set owner id is queue id
    public static task createNewTask(string subject,string whatId,date activityDate,string queueId){
        task objtask = new task(subject=subject,
                        Description = subject,
                        Priority = 'Medium',
                        WhatId =  whatId,
                        Status='Open',
                        ActivityDate =activityDate,
                        Type= 'Other',
                        ownerId = queueId
                    );
    return objtask;
    }
    //@@jatin: 2-dec-2019: getLastLessonDate method is use for getting last date of lesson on selecting the withdraw end Date.
        
    @RemoteAction      
    public static TerminationSummary getTerminateRentalSummary(String enrolmentId, String terminationRequestEndDate, String pickupRequestEndDate,
                                                                String terminationReason, String terminationOtherReason){
        TerminationSummary objTerminationSummary = new TerminationSummary();
        Date terminationRequestEndDateObj, pickupRequestEndDateObj, nextBillingDate;
        Enrolment__c enrolment;
        Country__c countryObj = new Country__c();
        
        if(String.isNotBlank(terminationRequestEndDate)){
            terminationRequestEndDateObj = Date.valueOf(terminationRequestEndDate);
        }
        if(String.isNotBlank(pickupRequestEndDate)){
            pickupRequestEndDateObj = Date.valueOf(pickupRequestEndDate);
        }
        if(String.isNotBlank(enrolmentId)){
            List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {enrolmentId});
            if(listOfenrolment != null && listOfenrolment.size() > 0){
                enrolment = listOfenrolment[0];
            }
            if(String.isNotBlank(enrolment.Center__r.Country__r.Id)){
                countryObj = enrolment.Center__r.Country__r;    
            }
            
        }
        
        if(String.isNotBlank(enrolment.Id) && terminationRequestEndDateObj != NULL && pickupRequestEndDateObj != NULL && enrolment.Subscription_Line_Items__r != NULL && enrolment.Subscription_Line_Items__r.size() > 0){
                objTerminationSummary.finalInvoices = getFinalInvoiceSummary(enrolment,DateTime.newInstance(terminationRequestEndDateObj, Time.newInstance(0, 0, 0, 0)),enrolment.Subscription_Line_Items__r[0].Amount__c ,enrolment.No_of_Stairs__c);
            }
        if(enrolment != NULL){
            Decimal total = 0, gst = 0;
            DateTime dt = DateTime.newInstance(enrolment.Subscription_Line_Items__r[0].Subscription_Start_Date__c,Time.newInstance(0, 0, 0, 0));
            objTerminationSummary.customerName = enrolment.Parent__r.Name;
            String address = (string.isNotBlank(enrolment.Building_name__c) ? enrolment.Building_name__c : '');
            address+= (string.isNotBlank(enrolment.Block__c) ? ' , ' +enrolment.Block__c : '');
            address+= (string.isNotBlank(enrolment.Unit_and_Level__c) ? ' , ' +enrolment.Unit_and_Level__c : '');
            address+= (string.isNotBlank(enrolment.PIN_code__c) ? ' , ' +enrolment.PIN_code__c : '');
            objTerminationSummary.address = address;
            objTerminationSummary.pianoName = enrolment.Package__r.Name;
            objTerminationSummary.serialNumber = enrolment.Serial_Number__c;
            objTerminationSummary.modalNumber = enrolment.Model__c;
            objTerminationSummary.standardAccessories = enrolment.Standard_Accessories__c;
            objTerminationSummary.rentalStartDate = DateTime.newInstance(enrolment.Subscription_Line_Items__r[0].Subscription_Start_Date__c,Time.newInstance(0, 0, 0, 0)).format('dd MMM, yyyy');
            objTerminationSummary.pianoPickupDate = DateTime.newInstance(pickupRequestEndDateObj,Time.newInstance(0, 0, 0, 0)).format('dd MMM, yyyy');
            objTerminationSummary.rentalTerminationDate = DateTime.newInstance(terminationRequestEndDateObj, Time.newInstance(0, 0, 0, 0)).format('dd MMM, yyyy');
            objTerminationSummary.terminationReason = enrolment.Termination_Reason__c;
            objTerminationSummary.terminationOtherReason = enrolment.Termination_Reason_others__c;
            if(objTerminationSummary.finalInvoices != NULL && objTerminationSummary.finalInvoices.size() != 0){
                for(PianoRentalHelperController.PianoRent currentLesson : objTerminationSummary.finalInvoices){
                    total += currentLesson.total;
                }
                if(total > 0 && countryObj.Tax_Rate__c > 0){
                    gst = total  * (countryObj.Tax_Rate__c / 100);
                }
            }
            objTerminationSummary.total = total + gst;
            objTerminationSummary.gst = gst;
            
           
        }
        return objTerminationSummary;
    }

// show invoice summany  last 2 month invoice amount and staire amount
     public  static List<PianoRentalHelperController.PianoRent> getFinalInvoiceSummary(enrolment__c  enrolObj,Datetime pianoPickupDate,decimal rentalPricePerMonth,Decimal noOfStairs){
        List<PianoRentalHelperController.PianoRent> listOfInvoicePianoRent = new List<PianoRentalHelperController.PianoRent>();
       // Integer monthDifference  =system.today();
       PianoRentalHelperController.PianoRent invoicePianoRent = new PianoRentalHelperController.PianoRent();
        Integer remainingDays = 0;
        DateTime currentdatetime = DateTime.newInstance(system.now().year(),system.now().month(),1,system.now().hour(),system.now().minute(),system.now().second());
        string pianoName = 'Piano Rental';
        //10-Feb-2020 :show Piano Rental <<Month>> in the Piano Rental termination Summary. 
       // string pianoName = enrolObj.Package__r.Name;  
        Map<string,Decimal> mapOfTotalcurrentMonthPaidInvoiceAmount = PianoRentalHelperController.getCurrentMonthInvoiceAmount(new Set<String> {enrolObj.id},ConstantsClass.dueStatus);
        Decimal  currentMonthDueInvoiceAmount = 0;
        if(mapOfTotalcurrentMonthPaidInvoiceAmount != null && mapOfTotalcurrentMonthPaidInvoiceAmount.size() > 0 && mapOfTotalcurrentMonthPaidInvoiceAmount.containsKey(enrolObj.id)){
            if(mapOfTotalcurrentMonthPaidInvoiceAmount.get(enrolObj.id) !=  null && mapOfTotalcurrentMonthPaidInvoiceAmount.get(enrolObj.id) > 0){ 
                currentMonthDueInvoiceAmount = mapOfTotalcurrentMonthPaidInvoiceAmount.get(enrolObj.id);
            }
        }
           // 6-Fed:2020: show all remaing  and current month invoice detials 
         if(currentMonthDueInvoiceAmount != null && currentMonthDueInvoiceAmount >0){
             remainingDays = date.daysInMonth(currentdatetime.year(), currentdatetime.month());
             listOfInvoicePianoRent.add(PianoRentalHelperController.createInvoicePianoRent(pianoName + ' - ' +currentdatetime.format('dd MMM, yyyy'),remainingDays,remainingDays,rentalPricePerMonth,currentMonthDueInvoiceAmount));
         }
      
        if(rentalPricePerMonth != null && rentalPricePerMonth > 0){
            system.debug(currentdatetime);
            integer nextMonth = 0;
            while(currentdatetime.addMonths(1) < pianoPickupDate){
                nextMonth++;
                DateTime nextdatetime = DateTime.newInstance(system.now().addMonths(nextMonth).year(),system.now().addMonths(nextMonth).month(),1,system.now().hour(),system.now().minute(),system.now().second());
                remainingDays = date.daysInMonth(nextdatetime.year(), nextdatetime.month());
                listOfInvoicePianoRent.add(PianoRentalHelperController.createInvoicePianoRent(pianoName + ' - ' +nextdatetime.format('dd MMM, yyyy'),remainingDays,remainingDays,rentalPricePerMonth,rentalPricePerMonth));
                currentdatetime = DateTime.newInstance(nextdatetime.year(),nextdatetime.month(),date.daysInMonth(nextdatetime.year(), nextdatetime.month()),system.now().hour(),system.now().minute(),system.now().second());
            }
            remainingDays = date.daysInMonth(pianoPickupDate.year(), pianoPickupDate.month());
            Decimal rentalTotalAmount = 0;
            rentalTotalAmount = pianoPickupDate.day() * (rentalPricePerMonth /  date.daysInMonth(pianoPickupDate.year(), pianoPickupDate.month()));
            datetime pianoPickupDateObj=DateTime.newInstance (pianoPickupDate.year(),pianoPickupDate.month(),1,pianoPickupDate.hour(),pianoPickupDate.minute(),pianoPickupDate.second());
            listOfInvoicePianoRent.add(PianoRentalHelperController.createInvoicePianoRent(pianoName + ' - ' +pianoPickupDateObj.format('dd MMM, yyyy'),remainingDays,pianoPickupDate.day(),rentalPricePerMonth,rentalTotalAmount));
        }
         if(noOfStairs != null && noOfStairs > 0 ){
            Decimal noOfStairsAmount = (noOfStairs != null && noOfStairs > 0 ? noOfStairs * 10 : 0); 
            invoicePianoRent = new PianoRentalHelperController.PianoRent();
            invoicePianoRent.pianoName = 'Additional Stairs Pickup Charges ('+noOfStairs+' Steps - $10/Step)';
            invoicePianoRent.unitPrice = 10;
            invoicePianoRent.invoiceDay = 0;
            invoicePianoRent.total = noOfStairsAmount;
            listOfInvoicePianoRent.add(invoicePianoRent);
        }
        if(listOfInvoicePianoRent != null && listOfInvoicePianoRent.size() > 0){
            return listOfInvoicePianoRent;
        }
        return new List<PianoRentalHelperController.PianoRent>();
    }
    
    public class TerminationSummary{
        public List<PianoRentalHelperController.PianoRent> finalInvoices{get;set;}
        public String customerName{get;set;}
        public String address{get;set;}
        public String pianoName{get;set;}
        public String serialNumber{get;set;}
        public String modalNumber{get;set;}
        public String standardAccessories{get;set;}
        public String rentalStartDate{get;set;}
        public String pianoPickupDate{get;set;}
        public String rentalTerminationDate{get;set;}
         public String terminationReason{get;set;}
        public String terminationOtherReason{get;set;}
        public Decimal gst{get;set;}
        public Decimal total{get;set;}
    }   
    
    
}