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
        string queryString = 'SELECT Id,Name,Student__c,Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,Parent__c, Parent__r.Available_Make_up_Units__c,Student__r.Name,Parent__r.Name, ';
        queryString+= ' Package_Process_Type__c, Package_Process_Request_Date__c,New_Package_Id__c, Package_Process_Status__c, Effective_Date__c,New_Teacher__c, Next_Lesson_Start_time__c, New_Lesson_Day__c, Stage__c,New_Centre__c,';
        queryString+= ' Type__c, Class__c,New_Class__c  FROM Enrolment__c ';
        queryString+= ' WHERE Type__c In: enrolTypes ';
        queryString+= ' AND Status__c In: enrolStatus ';
        queryString+= ' AND Stage__c =: enroledStage ';
        queryString+= ' AND Preferred_Teacher__c != null ';
        queryString+= ' AND Preferred_End_time__c != null ';
        queryString+= ' AND Preferred_Start_Time__c != null ';
        queryString+= ' AND Preferred_Day__c != null ';
       return Database.getQueryLocator(queryString);                           
    }
    
    global void execute(Database.BatchableContext BC, List<Enrolment__c> listOfEnrolment){
       //System.debug('listOfEnrolment'+listOfEnrolment.size());
        Map<string,set<string>> preferredTeacherDays = new Map<string,set<string>>(); 
        Map<string,List<Enrolment__c>> preferredEnrolmentMap = new Map<string,List<Enrolment__c>>(); 
        List<Enrolment__c> listOfPreferredEnrolment = new List<Enrolment__c>();
        set<string> prefeWorkingDays = new set<string>();
        for(Enrolment__c objEnrolment: listOfEnrolment){
            prefeWorkingDays = new set<string>();
            listOfPreferredEnrolment = new List<Enrolment__c>();
            if(preferredTeacherDays.containsKey(objEnrolment.Preferred_Teacher__c)){
                prefeWorkingDays.addAll(preferredTeacherDays.get(objEnrolment.Preferred_Teacher__c));
            }
            if(preferredEnrolmentMap.containsKey(objEnrolment.Preferred_Day__c)){
                listOfPreferredEnrolment.addAll(preferredEnrolmentMap.get(objEnrolment.Preferred_Day__c));
            }
            prefeWorkingDays.add(objEnrolment.Preferred_Day__c);
            preferredTeacherDays.put(objEnrolment.Preferred_Teacher__c, prefeWorkingDays);
            listOfPreferredEnrolment.add(objEnrolment);
            preferredEnrolmentMap.put(objEnrolment.Preferred_Day__c,listOfPreferredEnrolment);
        }
      //System.debug('preferredEnrolmentMap'+preferredEnrolmentMap.keyset());
      //System.debug('preferredTeacherDays'+preferredTeacherDays.keyset());
        if(preferredTeacherDays != null && preferredTeacherDays.size() >0 && preferredEnrolmentMap != null && preferredEnrolmentMap.size() > 0){
            List<Enrolment__c> cancelledEnrolmentList = [SELECT Id,Name,Student__c,Status__c,Preferred_End_time__c,Preferred_Start_Time__c,Preferred_Day__c,Preferred_Teacher__c ,Center__c, Center__r.Name, 
                                                                Teacher__c, Package__c,Lesson_Start_time__c, Package__r.Duration__c, Lesson_Day__c,
                                                                Stage__c,Type__c, Class__c,New_Class__c  FROM Enrolment__c 
                                                                Where Stage__c =: ConstantsClass.enrollmentStageCancelled
                                                                And Teacher__c in: preferredTeacherDays.keyset()
                                                                and Lesson_Day__c in : preferredEnrolmentMap.keyset()];
                                                               //System.debug('cancelledEnrolmentList'+cancelledEnrolmentList);
            map<string,Set<string>> cancelEnrolmentDayTime = new map<string,Set<string>>();
            set<string> cancelEnrolmentTimeslots = new set<string>();
            set<string> peferredEnrolmentTimeslots = new set<string>();
            if(cancelledEnrolmentList != null && cancelledEnrolmentList.size() >0 ){
                for(Enrolment__c objCancelEnrolment: cancelledEnrolmentList){
                   //System.debug('objCancelEnrolment'+objCancelEnrolment); 
                    listOfPreferredEnrolment = new List<Enrolment__c>();
                    peferredEnrolmentTimeslots = new set<string>();
                    prefeWorkingDays = new set<string>();
                    cancelEnrolmentTimeSlots = new set<String>();
                    if(preferredTeacherDays.containsKey(objCancelEnrolment.Teacher__c)){
                        prefeWorkingDays  = preferredTeacherDays.get(objCancelEnrolment.Teacher__c);
                      //System.debug('prefeWorkingDays'+prefeWorkingDays);
                      //System.debug('objCancelEnrolment.Lesson_Day__c'+objCancelEnrolment.Lesson_Day__c);
                        if(string.isnotBlank(objCancelEnrolment.Lesson_Day__c) && 
                        (prefeWorkingDays != null && prefeWorkingDays.size() > 0 && prefeWorkingDays.contains(objCancelEnrolment.Lesson_Day__c)) 
                        && preferredEnrolmentMap.containsKey(objCancelEnrolment.Lesson_Day__c) ){
                            listOfPreferredEnrolment = preferredEnrolmentMap.get(objCancelEnrolment.Lesson_Day__c);
                           //System.debug('listOfPreferredEnrolment'+listOfPreferredEnrolment);
                            DateTime cancelEnrolmentstartTime = DateTime.newInstance(system.today(),  objCancelEnrolment.Lesson_Start_time__c);
                            DateTime cancelEnrolmentendTime = DateTime.newInstance(system.today(),  objCancelEnrolment.Lesson_Start_time__c.addMinutes(Integer.valueOf(objCancelEnrolment.Package__r.Duration__c)));
                            if(cancelEnrolmentstartTime != NULL && cancelEnrolmentendTime != NULL){
                                cancelEnrolmentTimeSlots = getFormatedTimeSlotList(cancelEnrolmentstartTime, cancelEnrolmentendTime);
                               //System.debug('cancelEnrolmentTimeSlots'+cancelEnrolmentTimeSlots);
                                                      
                                if(cancelEnrolmentTimeSlots != null && cancelEnrolmentTimeSlots.size() > 0){
                                    if(listOfPreferredEnrolment != null && listOfPreferredEnrolment.size() > 0){
                                        for( Enrolment__c objPreferredEnrolment : listOfPreferredEnrolment){
                                           //System.debug('objPreferredEnrolment'+objPreferredEnrolment); 
                                           //System.debug('objCancelEnrolment.Package__r.Duration__c'+objCancelEnrolment.Package__r.Duration__c); 
                                           //System.debug('objPreferredEnrolment.Package__r.Duration__c'+objPreferredEnrolment.Package__r.Duration__c); 
                                            DateTime peferredEnrolmentstartTime = DateTime.newInstance(system.today(),  objPreferredEnrolment.Preferred_Start_Time__c);
                                            DateTime peferredEnrolmentendime = DateTime.newInstance(system.today(),  objPreferredEnrolment.Preferred_End_time__c);
                                            if(peferredEnrolmentstartTime != NULL && peferredEnrolmentendime != NULL){
                                                peferredEnrolmentTimeslots = getFormatedTimeSlotList(peferredEnrolmentstartTime, peferredEnrolmentendime);
                                                if(peferredEnrolmentTimeslots.containsAll(cancelEnrolmentTimeSlots)){
                                                   //System.debug('peferredEnrolmentTimeslots'+peferredEnrolmentTimeslots);
                                                    if(objPreferredEnrolment.Package__r.Duration__c >= objCancelEnrolment.Package__r.Duration__c){
                                                        System.debug('objPreferredEnrolment'+objPreferredEnrolment.name); 
                                                        System.debug('objCancelEnrolment'+objCancelEnrolment.name); 
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
       
    }

    global void finish(Database.BatchableContext BC){
   
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
