/*
    Name : WaitingEnrolmentsBatch
    date: 3-Feb-2021
    Author :  Nishi Jain
    Description:
    1.	 A scheduled process will run for all Waiting enrolments and check for the availability of the preferred time slot for the enrolment duration.
    2.	If a timeslot is found then an email notification will be send to Centre Admin and Customer to perform the necessary action. 

*/
global with sharing class WaitingEnrolmentsBatch implements Database.Batchable<sObject>,database.stateful {
    global Set<String> enrolTypes;
    global Set<String> enrolStatus;
    global set<String> enroledStage;
    Global datetime enrolmentEffectiveDate;
    global WaitingEnrolmentsBatch (integer addWaitingdays){
        enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.typeTrial}; 
        enrolStatus = New Set<String>{ConstantsClass.enrolWaitingStatus};
        enroledStage = New Set<String>{ConstantsClass.enroledStatus,ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment,'Requested','Booked'};
        enrolmentEffectiveDate =system.now().addDays(addWaitingdays);//Datetime.newInstance(date.newInstance( 2021,3,6),system.now().time());
    }
    global WaitingEnrolmentsBatch (datetime enrolmentEffectiveDate){
        enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.typeTrial}; 
        enrolStatus = New Set<String>{ConstantsClass.enrolWaitingStatus};
        enroledStage = New Set<String>{ConstantsClass.enroledStatus,ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment,'Requested','Booked'};
        this.enrolmentEffectiveDate =enrolmentEffectiveDate;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        String weekday = enrolmentEffectiveDate.format('EEEE');
        string queryString = 'SELECT Id,Name,Student__c,Waitlist_Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
        queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
        queryString+= ' Type__c, Class__c,New_Class__c,Center__r.Organisation__r.name,Parent__r.Centre_Name__r.Location__c,Parent__r.PersonContactId ,Trial_Start_Time__c FROM Enrolment__c ';
        queryString+= ' WHERE Type__c In: enrolTypes ';
        queryString+= ' AND Waitlist_Status__c In: enrolStatus ';
        queryString+= ' AND Stage__c In: enroledStage ';
        queryString+= ' AND Preferred_Teacher__c != null ';
        queryString+= ' AND Preferred_End_time__c != null ';
        queryString+= ' AND Preferred_Start_Time__c != null ';
        queryString+= ' AND Preferred_Day__c != null ';
        queryString+= ' AND Preferred_Day__c =: weekday ';
       //system.debug('weekday'+weekday);
        // string enrolmentId='a066F00001SthwMQAR';
        // queryString+= ' AND Id =:enrolmentId ';
        
       return Database.getQueryLocator(queryString);                           
    }
    
    global void execute(Database.BatchableContext BC, List<Enrolment__c> listOfPrefferedEnrolment){
        Set<String> paymentFailedEmails=new Set<string>{'Ossia_Waitlist_Enrolment_Time_Available','Waitlist_Enrolment_Time_Available'};
        Map<String,EmailTemplate> mapOfEmailTemplate = new Map<String,EmailTemplate>();
         // we get templete according to organisation
        
        for(EmailTemplate objEmailTemplate: [SELECT Id, Name,DeveloperName 
                                            FROM EmailTemplate 
                                            WHERE DeveloperName In:paymentFailedEmails]){
                                                mapOfEmailTemplate.put(objEmailTemplate.DeveloperName,objEmailTemplate);
                                            }
         List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();                                            
        set<string> preferredTeacherDays = new set<string>(); 
        //set<string> preferredEnrolmentLessonDays = new set<string> (); 
        set<string> setofCenterIds = new set<string>();
        list<string> listOfTeacherWithDuration = new list<string>();
        List<Enrolment__c> listOfPrefferedRegularEnrolment = new List<Enrolment__c>();
        List<Enrolment__c> listOfPrefferedTrailEnrolment = new List<Enrolment__c>();
        for(Enrolment__c objEnrolment: listOfPrefferedEnrolment){
            preferredTeacherDays.add(objEnrolment.Preferred_Teacher__c);
            //preferredEnrolmentLessonDays.add(objEnrolment.Preferred_Day__c);
            setofCenterIds.add(objEnrolment.Center__c);
            if(string.isNotBlank(objEnrolment.Package__c) && objEnrolment.Package__r.Duration__c != null){
                listOfTeacherWithDuration.add(objEnrolment.Package__r.Duration__c);
            }
            if(objEnrolment.Type__c == ConstantsClass.typeTrial && (objEnrolment.Stage__c =='Requested' && objEnrolment.Stage__c == 'Booked')){
                listOfPrefferedTrailEnrolment.add(objEnrolment);
            }else{
                listOfPrefferedRegularEnrolment.add(objEnrolment);
            }
        }
        Map<string,MakeupEnrolmentBatchHelper.MakeupAvailMinDetails> mapOfMakeupAvailMinRegularDetails = MakeupEnrolmentBatchHelper.getMultipleTeacherWorkingHourTimeSlotList(setofCenterIds ,preferredTeacherDays,new set<string>{ enrolmentEffectiveDate.format('E')},listOfTeacherWithDuration,enrolmentEffectiveDate,false);
        Map<string,MakeupEnrolmentBatchHelper.MakeupAvailMinDetails> mapOfMakeupAvailMinTrailDetails = MakeupEnrolmentBatchHelper.getMultipleTeacherWorkingHourTimeSlotList(setofCenterIds ,preferredTeacherDays,new set<string>{ enrolmentEffectiveDate.format('E')},listOfTeacherWithDuration,enrolmentEffectiveDate,true);
        
        if((mapOfMakeupAvailMinRegularDetails != null && mapOfMakeupAvailMinRegularDetails.size() > 0) || (mapOfMakeupAvailMinTrailDetails != null && mapOfMakeupAvailMinTrailDetails.size() > 0)){
           //system.debug('@mapOfMakeupAvailMinDetails'+mapOfMakeupAvailMinDetails);
            Map<string,MakeupEnrolmentBatchHelper.EnrolmentDetails> mapOfEnrolmentDetails = new Map<string,MakeupEnrolmentBatchHelper.EnrolmentDetails>();
            if(mapOfMakeupAvailMinRegularDetails != null && mapOfMakeupAvailMinRegularDetails.size() > 0 && listOfPrefferedRegularEnrolment != null && listOfPrefferedRegularEnrolment.size() > 0 ){
                mapOfEnrolmentDetails.putAll(MakeupEnrolmentBatchHelper.sendPreferredEnrolmentNotification(listOfPrefferedRegularEnrolment,mapOfMakeupAvailMinRegularDetails,listOfTeacherWithDuration,enrolmentEffectiveDate));
            }
            if(mapOfMakeupAvailMinTrailDetails != null && mapOfMakeupAvailMinTrailDetails.size() > 0 && listOfPrefferedTrailEnrolment != null && listOfPrefferedTrailEnrolment.size() > 0){
                mapOfEnrolmentDetails.putAll(MakeupEnrolmentBatchHelper.sendPreferredEnrolmentNotification(listOfPrefferedTrailEnrolment,mapOfMakeupAvailMinTrailDetails,listOfTeacherWithDuration,enrolmentEffectiveDate));
            }
            if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
               //system.debug('mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
               List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
                // we get templete according to organisation
                Set<string> availabletime =new Set<string>() ;
                Set<string>  availableMakeupTimeSlot =new Set<string>() ;
                map<string,string> centerIds = new  map<string,string>();
                if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
                    List<Enrolment__c> updateEnrolments= new  List<Enrolment__c>();
                    Map<string,Account> updateCenterEmailDate= new  Map<string,Account>();
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
                               /* string templatename='';
                                if(objEnrolmentDetails.objEnrolment.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                                    templatename = 'Ossia_Waitlist_Enrolment_Time_Available';
                                }else{
                                    templatename = 'Waitlist_Enrolment_Time_Available';
                                }
                                Messaging.SingleEmailMessage objSingleEmailMessage = MakeupEnrolmentBatchHelper.getEmailInformation(mapOfEmailTemplate,objEnrolmentDetails.objEnrolment,templatename);
                                if(objSingleEmailMessage != null){
                                    sendSingleEmailMessage.add(objSingleEmailMessage);
                                */
                                if(objEnrolmentDetails.objEnrolment.Parent__c != null && string.isNotBlank(objEnrolmentDetails.objEnrolment.Parent__r.PersonContactId)){
                                    string personContactId = objEnrolmentDetails.objEnrolment.Parent__r.PersonContactId;
                                    centerIds.put(objEnrolmentDetails.objEnrolment.Center__c,personContactId);
                                }
                            
                                updateEnrolments.add(new enrolment__c (id= objEnrolmentDetails.objEnrolment.id,Waitlist_Status__c ='Emailed'));
                                updateCenterEmailDate.put(objEnrolmentDetails.objEnrolment.Center__c,new Account(Id = objEnrolmentDetails.objEnrolment.Center__c,Waitlisting_Date__c = enrolmentEffectiveDate.date()));
                                //}
                            }
                        }
                       //system.debug('objEnrolmentDetails'+objEnrolmentDetails.objEnrolment.name);
                       //system.debug('objEnrolmentDetails.mapOfavailTimeslots'+objEnrolmentDetails.mapOfavailTimeslots);
                    }
                   //system.debug('updateEnrolments'+updateEnrolments);
                    if(updateEnrolments != null && updateEnrolments.size() > 0 ){
                        update updateEnrolments;
                    }
                    if(updateCenterEmailDate != null && updateCenterEmailDate.size() > 0 ){
                        update updateCenterEmailDate.values();
                    }
                }

                if(centerIds != null && centerIds.size() > 0){
                    MakeupEnrolmentBatchHelper.sendEmailToCenterQueueMember(centerIds);
                }
            
                /*system.debug('listOfMobileNotification'+listOfMobileNotification);
               //system.debug('sendSingleEmailMessage'+sendSingleEmailMessage);
                if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
                    Messaging.SendEmailResult[] result = Messaging.sendEmail(sendSingleEmailMessage,false);
                    Set<Id> targetIdsFailed = new Set<Id>();
                    for(Messaging.SendEmailResult resObj: result){
                        if(!resObj.isSuccess()){
                            targetIdsFailed.add(resObj.getErrors()[0].getTargetObjectId());
                        }
                    }
                   //system.debug('targetIdsFailed'+targetIdsFailed);
                }*/
            
            }
        }
    }

    global void finish(Database.BatchableContext BC){
   
    }
     
   
}