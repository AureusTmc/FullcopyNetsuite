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
    global String enroledStage;
    global WaitingEnrolmentsBatch (){
        enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus}; 
        enrolStatus =New Set<String>{ConstantsClass.enrolWaitingStatus};
        enroledStage = ConstantsClass.enroledStatus;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        string queryString = 'SELECT Id,Name,Student__c,Waitlist_Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
        queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
        queryString+= ' Type__c, Class__c,New_Class__c,Center__r.Organisation__r.name,Parent__r.Centre_Name__r.Location__c,Parent__r.PersonContactId  FROM Enrolment__c ';
        queryString+= ' WHERE Type__c In: enrolTypes ';
        queryString+= ' AND Waitlist_Status__c In: enrolStatus ';
        queryString+= ' AND Stage__c =: enroledStage ';
        queryString+= ' AND Preferred_Teacher__c != null ';
        queryString+= ' AND Preferred_End_time__c != null ';
        queryString+= ' AND Preferred_Start_Time__c != null ';
        queryString+= ' AND Preferred_Day__c != null ';
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
        set<string> preferredEnrolmentLessonDays = new set<string> (); 
        for(Enrolment__c objEnrolment: listOfPrefferedEnrolment){
            preferredTeacherDays.add(objEnrolment.Preferred_Teacher__c);
            preferredEnrolmentLessonDays.add(objEnrolment.Preferred_Day__c);
        }
        if(preferredTeacherDays != null && preferredTeacherDays.size() >0 && preferredEnrolmentLessonDays != null && preferredEnrolmentLessonDays.size() > 0){
            List<Enrolment__c> cancelledEnrolmentList = getCanceledEnrolmentList(preferredTeacherDays,preferredEnrolmentLessonDays);
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

            if(cancelTeacherDays != null && cancelTeacherDays.size() >0 && cancelEnrolmentLessonDays != null && cancelEnrolmentLessonDays.size() > 0){
                sendSingleEmailMessage = sendEmailToWaitlistEnrolments(listOfPrefferedEnrolment, cancelTeacherDays, cancelEnrolmentLessonDays,mapOfEmailTemplate);
                system.debug('sendSingleEmailMessage'+sendSingleEmailMessage);
                if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
                    Messaging.sendEmail(sendSingleEmailMessage, FALSE); 
                }
            }
        }
       
    }

    global void finish(Database.BatchableContext BC){
   
    }
    private static List<Enrolment__c> getCanceledEnrolmentList(Set<string> preferredTeacherDays, set<string> preferredEnrolmentLessonDays){
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
            //System.debug('objCancelEnrolment'+objCancelEnrolment); 
             listOfCanceledEnrolment = new List<Enrolment__c>();
             peferredEnrolmentTimeslots = new set<string>();
             cancelWorkingDays = new set<string>();
             cancelEnrolmentTimeSlots = new set<String>();
             if(cancelTeacherDays.containsKey(objPreferredEnrolment.Preferred_Teacher__c)){
                cancelWorkingDays  = cancelTeacherDays.get(objPreferredEnrolment.Preferred_Teacher__c);
                if(string.isnotBlank(objPreferredEnrolment.Preferred_Day__c) && (cancelWorkingDays != null && cancelWorkingDays.size() > 0 && cancelWorkingDays.contains(objPreferredEnrolment.Preferred_Day__c)) 
                    && cancelEnrolmentLessonDays.containsKey(objPreferredEnrolment.Preferred_Day__c) ){
                    listOfCanceledEnrolment = cancelEnrolmentLessonDays.get(objPreferredEnrolment.Preferred_Day__c) ;
                    DateTime peferredEnrolmentstartTime = DateTime.newInstance(system.today(),  objPreferredEnrolment.Preferred_Start_Time__c);
                     DateTime peferredEnrolmentendime = DateTime.newInstance(system.today(),  objPreferredEnrolment.Preferred_End_time__c);
                     if(peferredEnrolmentstartTime != NULL && peferredEnrolmentendime != NULL){
                        peferredEnrolmentTimeslots = getFormatedTimeSlotList(peferredEnrolmentstartTime, peferredEnrolmentendime);
                        if(peferredEnrolmentTimeslots != null && peferredEnrolmentTimeslots.size() > 0 && listOfCanceledEnrolment != null && listOfCanceledEnrolment.size() > 0){
                            for( Enrolment__c objCancelEnrolment : listOfCanceledEnrolment){
                                DateTime cancelEnrolmentstartTime = DateTime.newInstance(system.today(),  objCancelEnrolment.Lesson_Start_time__c);
                                DateTime cancelEnrolmentendTime = DateTime.newInstance(system.today(),  objCancelEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objCancelEnrolment.Package__r.Duration__c)));
                                if(cancelEnrolmentstartTime != NULL && cancelEnrolmentendTime != NULL){
                                    cancelEnrolmentTimeSlots = getFormatedTimeSlotList(cancelEnrolmentstartTime, cancelEnrolmentendTime);
                                    // check canceled enrolment time slots are match to perferred enrolment if we found that time slots so we send a email to customer and update Waitlist_Status__c
                                    if(cancelEnrolmentTimeSlots != null && cancelEnrolmentTimeSlots.size() > 0 && cancelEnrolmentTimeSlots.containsAll(peferredEnrolmentTimeslots)
                                     && objCancelEnrolment.Package__r.Duration__c >=  objPreferredEnrolment.Package__r.Duration__c){
                                        System.debug('objPreferredEnrolment'+objPreferredEnrolment.name); 
                                        System.debug('objCancelEnrolment'+objCancelEnrolment.name); 
                                        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
                                            sendSingleEmailMessage.add(getEmailInformation(mapOfEmailTemplate,objPreferredEnrolment));
                                            objPreferredEnrolment.Waitlist_Status__c ='Emailed';
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
         update listOfPrefferedEnrolment;
         return sendSingleEmailMessage;
    }

     // we get templete according to Enrolment organisation
    private static Messaging.SingleEmailMessage getEmailInformation(Map<String,EmailTemplate> mapOfEmailTemplate,Enrolment__c objPreferredEnrolment){
        Messaging.SingleEmailMessage objsendSingleEmailMessage = new Messaging.SingleEmailMessage();
        if(mapOfEmailTemplate != null && mapOfEmailTemplate.size() > 0 ){
            string centerId,personContactId;
            if(objPreferredEnrolment.Parent__c != null && objPreferredEnrolment.Parent__r.Centre_Name__r != null &&
                string.isNotBlank(objPreferredEnrolment.Parent__r.Centre_Name__r.Location__c) ){
                centerId = objPreferredEnrolment.Parent__r.Centre_Name__r.Location__c;
            }
            if(objPreferredEnrolment.Parent__c != null && string.isNotBlank(objPreferredEnrolment.Parent__r.PersonContactId)){
                personContactId = objPreferredEnrolment.Parent__r.PersonContactId;
            }
            if(objPreferredEnrolment.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                if(mapOfEmailTemplate.containsKey('Ossia_Waitlist_Enrolment_Time_Available')){
                    objsendSingleEmailMessage = AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get('Ossia_Waitlist_Enrolment_Time_Available').Id,personContactId,objPreferredEnrolment.id,centerId);
                }
            }else{
                if(mapOfEmailTemplate.containsKey('Waitlist_Enrolment_Time_Available')){
                    objsendSingleEmailMessage = AureusUtility.getSingleEmailMessage(mapOfEmailTemplate.get('Waitlist_Enrolment_Time_Available').Id,personContactId,objPreferredEnrolment.id,centerId);
                }   
            }
        }
        return objsendSingleEmailMessage;
    }
    private static set<String> getFormatedTimeSlotList(DateTime startTime, DateTime endTime){
        set<String> timeSlots = new set<String>();
        if(startTime < endTime){
            while(startTime <= endTime){
                timeSlots.add(startTime.format('h:mm a'));
                startTime = startTime.addMinutes(15);
            }
        }
        return timeSlots;
    }
}
