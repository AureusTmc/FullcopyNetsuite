/*
    Name : AutomatingMakeupEnrolmentBatch
    Desription :  a.	Identify all those parents whose makeup credit is more than > 200 minutes (configurable)
                    b.	Check if 15 or 30 minutes timeslot is available immediately before or after their scheduled regular booking scheduled after 3 days (configurable). 
                    c.	In case any such opportunity is available then send out an email notification to Parent for booking the timeslot. Push notification to mobile app as well.*

    Author : Nishi Jain
    Date : 5-Feb-2021
*/
global with sharing class AutomatingMakeupEnrolmentBatch implements Database.Batchable<sObject>,database.stateful,Database.AllowsCallouts{
    global Set<String> enrolTypes;
    global String enroledStage;
    global Datetime enrolmentEffectiveDate;
    global String weekday;
    global AutomatingMakeupEnrolmentBatch (date startdate){
        enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus}; 
        enroledStage = ConstantsClass.enroledStatus;
        enrolmentEffectiveDate =  Datetime.newInstance(startdate.addDays(Integer.valueOf( System.Label.Make_up_Credit_Days)), time.newInstance(0,0,0,0));
        weekday = enrolmentEffectiveDate.format('EEEE');
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        decimal makeupcreditdays  =  decimal.valueOf(System.Label.Total_Make_up_Credits);
        string  organisation =System.Label.Ossia_Organisation_Name;
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled};
        Set<String> bookTypeSet = new Set<String>{ ConstantsClass.typeRegular};
        Set<Date> dates = new  Set<Date>{enrolmentEffectiveDate.date()};
        string queryString = 'SELECT Id,Name,Student__c,Waitlist_Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
            queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
            queryString+= ' Type__c, Class__c,New_Class__c,Center__r.Organisation__r.name,Parent__r.Centre_Name__r.Location__c,Parent__r.PersonContactId,Parent__r.FCM_Token__c,';
            queryString+= ' (Select id from Bookings__r WHERE RecordType.Name =: recordTypeLesson AND Start_Time__c != NULL AND End_Time__c != NULL';
            queryString += ' AND Booking_Date__c IN: dates AND status__c IN: bookingStatus AND Type__c IN: bookTypeSet ), ';
            queryString += ' instrument__c,Automation_make_up_booking_Date__c  FROM Enrolment__c ';
            queryString+= ' WHERE Type__c In: enrolTypes ';
            queryString+= ' AND Stage__c =: enroledStage ';
            queryString+= ' AND Lesson_Day__c =: weekday ';
            queryString+= ' And (( Center__r.Organisation__r.Name =: organisation And Available_Make_up_mins__c  >: makeupcreditdays ) ';
            queryString+= ' Or ( Center__r.Organisation__r.Name !=: organisation And Parent__r.Available_Make_up_Units__c  >: makeupcreditdays ) )  ';
            string enrolmentid ='a066F00001VZgNP';
            queryString+= ' And id=: enrolmentid';
            //queryString+= ' LIMIT 5';

        return Database.getQueryLocator(queryString);                           
    }
    
    global void execute(Database.BatchableContext BC, List<Enrolment__c> listOfEnrolment){
        try {
            Map<string,MakeupEnrolmentBatchHelper.EnrolmentDetails> mapOfEnrolmentDetails = MakeupEnrolmentBatchHelper.newMakeupBookingNotification(listOfEnrolment, enrolmentEffectiveDate);
            
        //Check if 15 or 30 minutes timeslot is available immediately before or after their scheduled regular booking scheduled after 3 days 
            //if any slot is blank then we send out an email notification to Parent for booking the timeslot
            if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
                system.debug('mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
                Set<String> paymentFailedEmails=new Set<string>{'Makeup_Booking_Alert_Template','Ossia_Makeup_Booking_Alert_Template'};
                Map<String,EmailTemplate> mapOfEmailTemplate = new Map<String,EmailTemplate>();
                List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
                // we get templete according to organisation
                Set<string> availabletime =new Set<string>() ;
                Set<string>  availableMakeupTimeSlot =new Set<string>() ;
                for(EmailTemplate objEmailTemplate: [SELECT Id, Name,DeveloperName 
                                                    FROM EmailTemplate 
                                                    WHERE DeveloperName In:paymentFailedEmails]){
                                                        mapOfEmailTemplate.put(objEmailTemplate.DeveloperName,objEmailTemplate);
                                                    }
                List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();  
                if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
                    List<Enrolment__c> updateEnrolments= new  List<Enrolment__c>();
                    for(MakeupEnrolmentBatchHelper.EnrolmentDetails objEnrolmentDetails: mapOfEnrolmentDetails.values()){
                        if(objEnrolmentDetails.mapOfavailTimeslots != null && objEnrolmentDetails.mapOfavailTimeslots.size() > 0){
                            availabletime =new Set<string>();
                            availableMakeupTimeSlot =new Set<string>() ;
                            for(string duration : objEnrolmentDetails.mapOfavailTimeslots.keyset()){
                                availabletime =objEnrolmentDetails.mapOfavailTimeslots.get(duration);
                                if(availabletime != null && availabletime.size() > 0){
                                    for(string slot:availabletime){
                                        availableMakeupTimeSlot.add(slot + ' (' + duration+ ' mins)');
                                    }
                                }
                                
                            }
                            if(availableMakeupTimeSlot != null && availableMakeupTimeSlot.size() > 0){
                                string templatename='';
                                if(objEnrolmentDetails.objEnrolment.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                                    templatename = 'Ossia_Makeup_Booking_Alert_Template';
                                }else{
                                    templatename = 'Makeup_Booking_Alert_Template';
                                }
                                Messaging.SingleEmailMessage objSingleEmailMessage = MakeupEnrolmentBatchHelper.getEmailInformation(mapOfEmailTemplate,objEnrolmentDetails.objEnrolment,templatename);
                                if(objSingleEmailMessage != null)
                                    sendSingleEmailMessage.add(objSingleEmailMessage);
                                Mobile_Notification__c log = MakeupEnrolmentBatchHelper.getMobileNotificationMsg(objEnrolmentDetails.objEnrolment,String.join(new List<String>(availableMakeupTimeSlot),','),objEnrolmentDetails.enrolmentDate);
                                if(log != null)
                                    listOfMobileNotification.add(log); 
                                updateEnrolments.add(new Enrolment__c(id= objEnrolmentDetails.objEnrolment.id, Automation_make_up_booking_Date__c = enrolmentEffectiveDate.date()));    
                            }
                        }
                        system.debug('objEnrolmentDetails'+objEnrolmentDetails.objEnrolment.name);
                        system.debug('objEnrolmentDetails.mapOfavailTimeslots'+objEnrolmentDetails.mapOfavailTimeslots);
                        
                    }
                    if(updateEnrolments != null && updateEnrolments.size() > 0 ){
                        update updateEnrolments;
                    }
                }
            
                if(listOfMobileNotification!= Null && listOfMobileNotification.size() > 0){
                        insert listOfMobileNotification;
                }
                system.debug('listOfMobileNotification'+listOfMobileNotification);
                system.debug('sendSingleEmailMessage'+sendSingleEmailMessage);
                if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
                    Messaging.SendEmailResult[] result = Messaging.sendEmail(sendSingleEmailMessage,false);
                    Set<Id> targetIdsFailed = new Set<Id>();
                    for(Messaging.SendEmailResult resObj: result){
                        if(!resObj.isSuccess()){
                            targetIdsFailed.add(resObj.getErrors()[0].getTargetObjectId());
                        }
                    }
                    system.debug('targetIdsFailed'+targetIdsFailed);
                }
            
            }
        }catch(Exception e) {
            System.debug(e);
        }
    }

    global void finish(Database.BatchableContext BC){
   
    }
}