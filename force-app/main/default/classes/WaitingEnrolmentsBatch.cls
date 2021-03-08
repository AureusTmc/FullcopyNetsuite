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
        enroledStage = New Set<String>{ConstantsClass.enroledStatus,enrollStageAttended,ConstantsClass.PendingEnrolment,'Requested','Booked'};
        enrolmentEffectiveDate =system.now().addDays(addWaitingdays);//Datetime.newInstance(date.newInstance( 2021,3,6),system.now().time());
    }
    global WaitingEnrolmentsBatch (datetime enrolmentEffectiveDate){
        enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus,ConstantsClass.typeTrial}; 
        enrolStatus = New Set<String>{ConstantsClass.enrolWaitingStatus};
        enroledStage = New Set<String>{ConstantsClass.enroledStatus,ConstantsClass.enrollStageAttended,ConstantsClass.PendingEnrolment,'Requested','Booked'};//
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
        system.debug('weekday'+weekday);
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

        for(Enrolment__c objEnrolment: listOfPrefferedEnrolment){
            preferredTeacherDays.add(objEnrolment.Preferred_Teacher__c);
            //preferredEnrolmentLessonDays.add(objEnrolment.Preferred_Day__c);
            setofCenterIds.add(objEnrolment.Center__c);
            if(string.isNotBlank(objEnrolment.Package__c) && objEnrolment.Package__r.Duration__c != null){
                listOfTeacherWithDuration.add(objEnrolment.Package__r.Duration__c);
            }
        }
        Map<string,MakeupEnrolmentBatchHelper.MakeupAvailMinDetails> mapOfMakeupAvailMinDetails = MakeupEnrolmentBatchHelper.getMultipleTeacherWorkingHourTimeSlotList(setofCenterIds ,preferredTeacherDays,new set<string>{ enrolmentEffectiveDate.format('E')},listOfTeacherWithDuration,enrolmentEffectiveDate,false);
        if(mapOfMakeupAvailMinDetails != null && mapOfMakeupAvailMinDetails.size() > 0){
            system.debug('@mapOfMakeupAvailMinDetails'+mapOfMakeupAvailMinDetails);
            Map<string,MakeupEnrolmentBatchHelper.EnrolmentDetails> mapOfEnrolmentDetails = MakeupEnrolmentBatchHelper.sendPreferredEnrolmentNotification(listOfPrefferedEnrolment,mapOfMakeupAvailMinDetails,listOfTeacherWithDuration,enrolmentEffectiveDate);
            if(mapOfEnrolmentDetails != null && mapOfEnrolmentDetails.size() > 0){
                system.debug('mapOfEnrolmentDetails'+mapOfEnrolmentDetails);
               List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
                // we get templete according to organisation
                Set<string> availabletime =new Set<string>() ;
                Set<string>  availableMakeupTimeSlot =new Set<string>() ;
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
                                    templatename = 'Ossia_Waitlist_Enrolment_Time_Available';
                                }else{
                                    templatename = 'Waitlist_Enrolment_Time_Available';
                                }
                                Messaging.SingleEmailMessage objSingleEmailMessage = MakeupEnrolmentBatchHelper.getEmailInformation(mapOfEmailTemplate,objEnrolmentDetails.objEnrolment,templatename);
                                if(objSingleEmailMessage != null){
                                    sendSingleEmailMessage.add(objSingleEmailMessage);
                                    updateEnrolments.add(new enrolment__c (id= objEnrolmentDetails.objEnrolment.id,Waitlist_Status__c ='Emailed'));
                                }
                            }
                        }
                        system.debug('objEnrolmentDetails'+objEnrolmentDetails.objEnrolment.name);
                        system.debug('objEnrolmentDetails.mapOfavailTimeslots'+objEnrolmentDetails.mapOfavailTimeslots);
                    }
                    system.debug('updateEnrolments'+updateEnrolments);
                    if(updateEnrolments != null && updateEnrolments.size() > 0 ){
                        update updateEnrolments;
                    }
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
        }
       
        /*if(preferredTeacherDays != null && preferredTeacherDays.size() >0 && preferredEnrolmentLessonDays != null && preferredEnrolmentLessonDays.size() > 0){
            List<Enrolment__c> cancelledEnrolmentList = getCanceledEnrolmentList(preferredTeacherDays,preferredEnrolmentLessonDays);
            System.debug('cancelledEnrolmentList'+cancelledEnrolmentList);
            map<string,Set<string>> cancelEnrolmentDayTime = new map<string,Set<string>>();
            set<string> cancelEnrolmentTimeslots = new set<string>();
            set<string> peferredEnrolmentTimeslots = new set<string>();
            Map<string,set<string>> cancelTeacherDays = new Map<string,set<string>>(); 
            Map<string,List<Enrolment__c>> cancelEnrolmentLessonDays = new Map<string,List<Enrolment__c>>(); 
            List<Enrolment__c> listOfCanceledEnrolment = new List<Enrolment__c>();
            set<string> cancelWorkingDays = new set<string>();
            if(cancelledEnrolmentList != null && cancelledEnrolmentList.size() >0 ){
                for(Enrolment__c objEnrolment: cancelledEnrolmentList){
                    cancelWorkingDays = new set<string>();
                    listOfCanceledEnrolment = new List<Enrolment__c>();
                    if(cancelTeacherDays.containsKey(objEnrolment.Teacher__c)){
                        cancelWorkingDays.addAll(cancelTeacherDays.get(objEnrolment.Teacher__c));
                    }
                    if(cancelEnrolmentLessonDays.containsKey(objEnrolment.Lesson_Day__c)){
                        listOfCanceledEnrolment.addAll(cancelEnrolmentLessonDays.get(objEnrolment.Lesson_Day__c));
                    }
                    cancelWorkingDays.add(objEnrolment.Lesson_Day__c);
                    cancelTeacherDays.put(objEnrolment.Teacher__c, cancelWorkingDays);
                    listOfCanceledEnrolment.add(objEnrolment);
                    cancelEnrolmentLessonDays.put(objEnrolment.Lesson_Day__c,listOfCanceledEnrolment);
                }
            }
            System.debug('cancelTeacherDays'+cancelTeacherDays);
            System.debug('cancelEnrolmentLessonDays'+cancelEnrolmentLessonDays);
            System.debug('listOfPrefferedEnrolment'+listOfPrefferedEnrolment);
            if(cancelTeacherDays != null && cancelTeacherDays.size() >0 && cancelEnrolmentLessonDays != null && cancelEnrolmentLessonDays.size() > 0){
                sendSingleEmailMessage = sendEmailToWaitlistEnrolments(listOfPrefferedEnrolment, cancelTeacherDays, cancelEnrolmentLessonDays,mapOfEmailTemplate);
                System.debug('sendSingleEmailMessage'+sendSingleEmailMessage);
                if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
                    System.debug('sendSingleEmailMessage'+sendSingleEmailMessage);
                    Messaging.sendEmail(sendSingleEmailMessage,false); 
                }
            }
        }*/
       
    }

    global void finish(Database.BatchableContext BC){
   
    }
 /*   private static List<Enrolment__c> getCanceledEnrolmentList(Set<string> preferredTeacherDays, set<string> preferredEnrolmentLessonDays){
        return [SELECT Id,Name,Student__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, 
        Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,
        Stage__c,Type__c, Class__c,New_Class__c  FROM Enrolment__c 
        Where Stage__c =: ConstantsClass.enrollmentStageCancelled
        And Teacher__c in: preferredTeacherDays
        and Lesson_Day__c in : preferredEnrolmentLessonDays];
    }

    //If a timeslot is found then an email notification will be send to  Customer to Update enrolment Waitlist_Status__c value 'Waiting' to 'Emailed'. 
    private static List<Messaging.SingleEmailMessage> sendEmailToWaitlistEnrolments(List<Enrolment__c> listOfPrefferedEnrolment,Map<string,set<string>> cancelTeacherDays,
            Map<string,List<Enrolment__c>> cancelEnrolmentLessonDays ,Map<String,EmailTemplate> mapOfEmailTemplate){
        List<Enrolment__c> listOfCanceledEnrolment = new List<Enrolment__c>();
        set<string> peferredEnrolmentTimeslots = new set<string>();
        set<string> cancelWorkingDays = new set<string>();
        set<String> cancelEnrolmentTimeSlots = new set<String>();
        List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();  
        
        for(Enrolment__c objPreferredEnrolment: listOfPrefferedEnrolment){
             System.debug('objPreferredEnrolment'+objPreferredEnrolment); 
             listOfCanceledEnrolment = new List<Enrolment__c>();
             peferredEnrolmentTimeslots = new set<string>();
             cancelWorkingDays = new set<string>();
             cancelEnrolmentTimeSlots = new set<String>();
             System.debug('objPreferredEnrolment.Preferred_Teacher__c'+objPreferredEnrolment.Preferred_Teacher__c); 
             if(cancelTeacherDays.containsKey(objPreferredEnrolment.Preferred_Teacher__c)){
                cancelWorkingDays  = cancelTeacherDays.get(objPreferredEnrolment.Preferred_Teacher__c);
                System.debug('cancelWorkingDays'+cancelWorkingDays); 
                System.debug('objPreferredEnrolment.Preferred_Day__c'+objPreferredEnrolment.Preferred_Day__c); 
                System.debug('cancelEnrolmentLessonDays'+cancelEnrolmentLessonDays); 

                if(string.isnotBlank(objPreferredEnrolment.Preferred_Day__c) && (cancelWorkingDays != null && cancelWorkingDays.size() > 0 
                    && cancelWorkingDays.contains(objPreferredEnrolment.Preferred_Day__c)) 
                    && cancelEnrolmentLessonDays.containsKey(objPreferredEnrolment.Preferred_Day__c) ){
                    listOfCanceledEnrolment = cancelEnrolmentLessonDays.get(objPreferredEnrolment.Preferred_Day__c) ;
                    System.debug('listOfCanceledEnrolment'+listOfCanceledEnrolment); 
                    DateTime peferredEnrolmentstartTime = DateTime.newInstance(system.today(),  objPreferredEnrolment.Preferred_Start_Time__c);
                     DateTime peferredEnrolmentendime = DateTime.newInstance(system.today(),  objPreferredEnrolment.Preferred_End_time__c);
                     System.debug('peferredEnrolmentstartTime'+peferredEnrolmentstartTime); 
                     System.debug('peferredEnrolmentendime'+peferredEnrolmentendime); 
                     if(peferredEnrolmentstartTime != NULL && peferredEnrolmentendime != NULL){
                        peferredEnrolmentTimeslots = MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(peferredEnrolmentstartTime, peferredEnrolmentendime);
                        System.debug('peferredEnrolmentTimeslots'+peferredEnrolmentTimeslots);
                        if(peferredEnrolmentTimeslots != null && peferredEnrolmentTimeslots.size() > 0 && listOfCanceledEnrolment != null && listOfCanceledEnrolment.size() > 0){
                            for( Enrolment__c objCancelEnrolment : listOfCanceledEnrolment){
                                DateTime cancelEnrolmentstartTime = DateTime.newInstance(system.today(),  objCancelEnrolment.Lesson_Start_time__c);
                                DateTime cancelEnrolmentendTime = DateTime.newInstance(system.today(),  objCancelEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objCancelEnrolment.Package__r.Duration__c)));
                                  System.debug('cancelEnrolmentstartTime'+cancelEnrolmentstartTime);
                                  System.debug('cancelEnrolmentendTime'+cancelEnrolmentendTime);
                                if(cancelEnrolmentstartTime != NULL && cancelEnrolmentendTime != NULL){
                                    cancelEnrolmentTimeSlots = MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(cancelEnrolmentstartTime, cancelEnrolmentendTime);
                                      System.debug('cancelEnrolmentTimeSlots'+cancelEnrolmentTimeSlots);
                                      System.debug('peferredEnrolmentTimeslots'+peferredEnrolmentTimeslots);
                                      System.debug('objCancelEnrolment.Package__r.Duration__c'+objCancelEnrolment.Package__r.Duration__c);
                                      System.debug('objPreferredEnrolment.Package__r.Duration__c'+objPreferredEnrolment.Package__r.Duration__c);
                                      System.debug('cancelEnrolmentTimeSlots.containsAll(peferredEnrolmentTimeslots)'+cancelEnrolmentTimeSlots.containsAll(peferredEnrolmentTimeslots));
                                      System.debug('cancelEnrolmentTimeSlots.containsAll(peferredEnrolmentTimeslots)'+peferredEnrolmentTimeslots.containsAll(cancelEnrolmentTimeSlots));
                                    // check canceled enrolment time slots are match to perferred enrolment if we found that time slots so we send a email to customer and update Waitlist_Status__c
                                    if(cancelEnrolmentTimeSlots != null && cancelEnrolmentTimeSlots.size() > 0 && peferredEnrolmentTimeslots.containsAll(cancelEnrolmentTimeSlots)
                                     && objCancelEnrolment.Package__r.Duration__c >=  objPreferredEnrolment.Package__r.Duration__c){
                                        System.debug('objPreferredEnrolment'+objPreferredEnrolment.name); 
                                        System.debug('objCancelEnrolment'+objCancelEnrolment.name); 
                                        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
                                            string templatename='';
                                            if(objPreferredEnrolment.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                                                templatename = 'Ossia_Waitlist_Enrolment_Time_Available';
                                            }else{
                                                templatename = 'Waitlist_Enrolment_Time_Available';
                                            }
                                            Messaging.SingleEmailMessage objSingleEmailMessage = MakeupEnrolmentBatchHelper.getEmailInformation(mapOfEmailTemplate,objPreferredEnrolment,templatename);
                                            if(objSingleEmailMessage != null){
                                                sendSingleEmailMessage.add(objSingleEmailMessage);
                                                objPreferredEnrolment.Waitlist_Status__c ='Emailed';
                                            }
                                        }
                                        Break;
                                    }
                                }
                            }
                        }
                    }
                 }
             }
         }
         System.debug('listOfPrefferedEnrolment'+listOfPrefferedEnrolment); 
         update listOfPrefferedEnrolment;
         return sendSingleEmailMessage;
    }
*/
    
}