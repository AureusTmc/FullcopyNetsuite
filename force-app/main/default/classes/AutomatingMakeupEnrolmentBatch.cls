/*
    Name : AutomatingMakeupEnrolmentBatch
    Desription :  a.	Identify all those parents whose makeup credit is more than > 200 minutes (configurable)
                    b.	Check if 15 or 30 minutes timeslot is available immediately before or after their scheduled regular booking scheduled after 3 days (configurable). 
                    c.	In case any such opportunity is available then send out an email notification to Parent for booking the timeslot. Push notification to mobile app as well.*

    Author : Nishi Jain
    Date : 5-Feb-2021
*/
global with sharing class AutomatingMakeupEnrolmentBatch implements Database.Batchable<sObject>,database.stateful{
    global Set<String> enrolTypes;
    global String enroledStage;
    global Date startdate;
    
    global AutomatingMakeupEnrolmentBatch (date startdate){
        enrolTypes = New Set<String>{ConstantsClass.enrolRegularStatus}; 
        enroledStage = ConstantsClass.enroledStatus;
        this.startdate =startdate.addDays(Integer.valueOf( System.Label.Make_up_Credit_Days));
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        decimal makeupcreditdays  =  decimal.valueOf(System.Label.Total_Make_up_Credits);
        string  organisation =System.Label.Ossia_Organisation_Name;
        string queryString = 'SELECT Id,Name,Student__c,Waitlist_Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
            queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
            queryString+= ' Type__c, Class__c,New_Class__c,Center__r.Organisation__r.name,Parent__r.Centre_Name__r.Location__c,Parent__r.PersonContactId,Parent__r.FCM_Token__c,instrument__c  FROM Enrolment__c ';
            queryString+= ' WHERE Type__c In: enrolTypes ';
            queryString+= ' AND Stage__c =: enroledStage ';
            queryString+= ' And (( Center__r.Organisation__r.Name =: organisation And Available_Make_up_mins__c  > makeupcreditdays ) ';
            queryString+= ' Or ( Center__r.Organisation__r.Name !=: organisation And Parent__r.Available_Make_up_Units__c  > makeupcreditdays ) ) ';
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
        map<string,set<String>> mapofCenterIds = new map<string,set<String>>();
        set<String> teacherIds = new set<String>();
        map<string,set<String>> mapofTeacherLessondays = new map<string,set<String>>();
        set<String> weekdays = new set<String>();
        set<string> listOfTeacherWithDuration = new set<string>();
        for(Enrolment__c objEnrolment: listOfPrefferedEnrolment){
            DateTime enrolmentstartTime = DateTime.newInstance(system.today(),  objEnrolment.Lesson_Start_time__c);
            DateTime enrolmentendTime = DateTime.newInstance(system.today(),  objEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objEnrolment.Package__r.Duration__c)));
            if(enrolmentstartTime != NULL && enrolmentendTime != NULL){
                // collect all teachers list  according to enrolment's center
                teacherIds = new set<String>();
                if(mapofCenterIds.containsKey(objEnrolment.Center__c)){
                    teacherIds = mapofCenterIds.get(objEnrolment.Center__c);
                }
                teacherIds.add(objEnrolment.Teacher__c);
                mapofCenterIds.put(objEnrolment.Center__c,teacherIds);

                 // collect all Weekdays list  according to enrolment's teacher
                 weekdays = new set<String>();
                if(mapofTeacherLessondays.containsKey(objEnrolment.Teacher__c)){
                    teacherIds = mapofTeacherLessondays.get(objEnrolment.Teacher__c);
                }
                weekdays.add(objEnrolment.Lesson_Day__c);
                mapofTeacherLessondays.put(objEnrolment.Teacher__c,weekdays);
                listOfTeacherWithDuration.add(objEnrolment.Teacher__c +'@'+ objEnrolment.Package__r.Duration__c);
            }
        }
        Map<String,set<String>> availTeacherTimeSlots = MakeupEnrolmentBatchHelper.getMultipleTeacherWorkingHourTimeSlotList(mapofCenterIds ,mapofTeacherLessondays,listOfTeacherWithDuration,startdate);
        //Check if 15 or 30 minutes timeslot is available immediately before or after their scheduled regular booking scheduled after 3 days 
        //if any slot is blank then we send out an email notification to Parent for booking the timeslot
        if(availTeacherTimeSlots != null && availTeacherTimeSlots.size() > 0){
            List<Mobile_Notification__c> listOfMobileNotification = new List<Mobile_Notification__c>();
            set<String> enrolmentRequiredTimeSlots = new set<String>();
            set<String> teacherAvailTimeSlots = new set<String>();
            for(Enrolment__c objEnrolment: listOfPrefferedEnrolment){
                teacherAvailTimeSlots = new set<String>();
                if(availTeacherTimeSlots.containsKey(objEnrolment.Center__c +'@'+objEnrolment.Teacher__c+'@'+ objEnrolment.Package__r.Duration__c)){
                    teacherAvailTimeSlots = availTeacherTimeSlots.get(objEnrolment.Center__c +'@'+objEnrolment.Teacher__c+'@'+ objEnrolment.Package__r.Duration__c);
                    DateTime enrolmentstartTime = DateTime.newInstance(system.today(),  objEnrolment.Lesson_Start_time__c).addMinutes(30);
                    DateTime enrolmentendTime = DateTime.newInstance(system.today(),  objEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objEnrolment.Package__r.Duration__c))).addMinutes(30);
                    if(enrolmentstartTime != NULL && enrolmentendTime != NULL){
                        enrolmentRequiredTimeSlots = MakeupEnrolmentBatchHelper.getFormatedTimeSlotList(enrolmentstartTime, enrolmentendTime);
                        if(enrolmentRequiredTimeSlots != null && enrolmentRequiredTimeSlots.size() > 0){
                            if(teacherAvailTimeSlots.containsAll(enrolmentRequiredTimeSlots)){
                                Set<string> availabletime =new Set<string>() ;
                                for(string enroltime : enrolmentRequiredTimeSlots){
                                    if(teacherAvailTimeSlots.contains(enroltime)){
                                        availabletime.add(enroltime);
                                    }
                                }
                                Messaging.SingleEmailMessage objSingleEmailMessage = MakeupEnrolmentBatchHelper.getEmailInformation(mapOfEmailTemplate,objEnrolment);
                                if(objSingleEmailMessage != null)
                                    sendSingleEmailMessage.add(objSingleEmailMessage);
                                Mobile_Notification__c log = MakeupEnrolmentBatchHelper.getMobileNotificationMsg(objEnrolment,String.join(new List<String>(availabletime),','),enrolmentstartTime.format('dd, MMM'));
                                if(log != null)
                                    listOfMobileNotification.add(log); 
                            }
                        }
                    }
                }
            }
            if(listOfMobileNotification.size() > 0 && listOfMobileNotification!= Null){
                insert listOfMobileNotification;
            }
        }
        if(sendSingleEmailMessage != null && sendSingleEmailMessage.size() > 0 ){
            Messaging.sendEmail(sendSingleEmailMessage, FALSE); 
        }
       
    }

    global void finish(Database.BatchableContext BC){
   
    }
}
