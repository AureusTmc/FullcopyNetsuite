global with sharing class UpdateLiveEnrolmentInTeacherPortalBatch implements Database.Batchable<sObject>, Database.stateful{
    date currentDate = system.today();
    Date lastWeekDate = currentDate.toStartofWeek(); 
    Date startWeekDate = lastWeekDate.addDays(-6);
    Set<Id> teacherIdSet = new Set<Id>();
    global UpdateLiveEnrolmentInTeacherPortalBatch() {

    }
    global UpdateLiveEnrolmentInTeacherPortalBatch(Date processDate, set<Id>teacherIdSet) {
        currentDate = processDate;
        lastWeekDate = currentDate.toStartofWeek(); 
        startWeekDate = lastWeekDate.addDays(-6);
        this.teacherIdSet = teacherIdSet;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        system.debug('teacherIdSet ** '+teacherIdSet);
        system.debug('currentDate ** '+currentDate);
        system.debug('startWeekDate ** '+startWeekDate);
        system.debug('lastWeekDate ** '+lastWeekDate);
        if(!teacherIdSet.isEmpty()){ 
            return Database.getQueryLocator([Select id,Previous_Week_Downgrades__c, Previous_Week_Trial_Closure__c, Previous_Week_Upgrades__c, Previous_week_withdrawals__c, Current_week_withdrawals__c, Previous_Week_New_Enrolments__c, Current_Week_New_Enrolments__c, Current_Week_Trial_Closure__c, Current_Week_Upgrades__c, Current_Week_Downgrades__c
                                                from Account 
                                                where Employee_Status__c in ('Probation','Confirm')
                                                and  recordType.Name='Teacher'
                                                and (Joining_Date__c=null or Joining_Date__c<=:lastWeekDate) 
                                                and (Last_Working_Date__c=null or Last_Working_Date__c>=:startWeekDate) 
                                                AND Id IN : teacherIdSet]);    
        }else{        
            return Database.getQueryLocator([Select id,Previous_Week_Downgrades__c, Previous_Week_Trial_Closure__c, Previous_Week_Upgrades__c, Previous_week_withdrawals__c, Current_week_withdrawals__c, Previous_Week_New_Enrolments__c, Current_Week_New_Enrolments__c, Current_Week_Trial_Closure__c, Current_Week_Upgrades__c, Current_Week_Downgrades__c
                                             from Account 
                                            where Employee_Status__c in ('Probation','Confirm')
                                            and  recordType.Name='Teacher'
                                            and (Joining_Date__c=null or Joining_Date__c<=:lastWeekDate) 
                                            and (Last_Working_Date__c=null or Last_Working_Date__c>=:startWeekDate)]);    
        }
    }
     global void execute(Database.BatchableContext BC, List<Account> listOfTeachers){
        Set<Id> teacherIds = new Set<Id>();
        
        for(Account objTeacher:listOfTeachers){
            teacherIds.add(objTeacher.Id);
        }
        List<Enrolment__c> listOfEnrolment = getEnrolment(teacherIds);
        Map<string,Integer> mapOfCountNewEnrolments = new  Map<string,Integer>();
        Map<string,Integer> mapOfCountCancelEnrolments = new  Map<string,Integer>();
        Map<string,Integer> mapOfCountUpgradeEnrolments = new  Map<string,Integer>();
        Map<string,Integer> mapOfCountDownEnrolments = new  Map<string,Integer>();
        Map<string,Integer> mapOfCountTrialEnrolments = new  Map<string,Integer>();

        for(Enrolment__c objEnrolment : listOfEnrolment){
            Integer countEnrolment = 0;
            If(objEnrolment.Stage__c ==ConstantsClass.enrollStageAttended &&  (objEnrolment.Type__c ==ConstantsClass.typeTrial)){
                if(objEnrolment.Trial_Date__c != null && objEnrolment.Trial_Date__c >=startWeekDate && objEnrolment.Trial_Date__c <=lastWeekDate){
                    if(mapOfCountTrialEnrolments.containsKey(objEnrolment.Teacher__c)){
                        countEnrolment = mapOfCountTrialEnrolments.get(objEnrolment.Teacher__c);
                    }
                    mapOfCountTrialEnrolments.put(objEnrolment.Teacher__c,countEnrolment++);
                }
            }
            else if(objEnrolment.Stage__c =='Enrolled' &&  (objEnrolment.Type__c =='Regular' ||   objEnrolment.Type__c =='Group Lesson')){
                if(objEnrolment.Enrolment_Created_Date__c != null && objEnrolment.Enrolment_Created_Date__c >=startWeekDate && objEnrolment.Enrolment_Created_Date__c <=lastWeekDate){
                    if(mapOfCountNewEnrolments.containsKey(objEnrolment.Teacher__c)){
                        countEnrolment = mapOfCountNewEnrolments.get(objEnrolment.Teacher__c);
                    }
                    mapOfCountNewEnrolments.put(objEnrolment.Teacher__c,countEnrolment++);
                }
                if(objEnrolment.Effective_Date__c != null && objEnrolment.Effective_Date__c >=startWeekDate && objEnrolment.Effective_Date__c <=lastWeekDate 
                && string.isnotBlank(objEnrolment.Package_Process_Status__c)){
                    if(objEnrolment.Package_Process_Status__c ==ConstantsClass.enrollmentProcessUpgradeType){
                        if(mapOfCountUpgradeEnrolments.containsKey(objEnrolment.New_Teacher__c)){
                            countEnrolment = mapOfCountUpgradeEnrolments.get(objEnrolment.New_Teacher__c);
                        }
                        mapOfCountUpgradeEnrolments.put(objEnrolment.New_Teacher__c,countEnrolment++);
                    }
                    if(objEnrolment.Package_Process_Status__c ==ConstantsClass.enrollmentProcessDowngradeType){
                        if(mapOfCountDownEnrolments.containsKey(objEnrolment.New_Teacher__c)){
                            countEnrolment = mapOfCountDownEnrolments.get(objEnrolment.New_Teacher__c);
                        }
                        mapOfCountDownEnrolments.put(objEnrolment.New_Teacher__c,countEnrolment++);
                    }
                }
            }else if((objEnrolment.Stage__c =='Cancelled' || objEnrolment.Package_Process_Status__c =='Cancellation') &&  (objEnrolment.Type__c =='Regular' ||   objEnrolment.Type__c =='Group Lesson')
            && (objEnrolment.Effective_Date__c != null && objEnrolment.Effective_Date__c >=startWeekDate && objEnrolment.Effective_Date__c <=lastWeekDate)){
               
                if(mapOfCountCancelEnrolments.containsKey(objEnrolment.Teacher__c)){
                    countEnrolment = mapOfCountCancelEnrolments.get(objEnrolment.Teacher__c);
                }
                mapOfCountCancelEnrolments.put(objEnrolment.Teacher__c,countEnrolment++);
            }
        }
        system.debug('mapOfCountTrialEnrolments'+mapOfCountTrialEnrolments);
        system.debug('mapOfCountNewEnrolments'+mapOfCountNewEnrolments);
        system.debug('mapOfCountDownEnrolments'+mapOfCountDownEnrolments);
        system.debug('mapOfCountUpgradeEnrolments'+mapOfCountUpgradeEnrolments);
        system.debug('mapOfCountCancelEnrolments'+mapOfCountCancelEnrolments);
        for(Account objTeacher:listOfTeachers){
            objTeacher.Previous_Week_Trial_Closure__c =objTeacher.Current_Week_Trial_Closure__c;
            objTeacher.Previous_Week_New_Enrolments__c =objTeacher.Current_Week_New_Enrolments__c;
            objTeacher.Previous_Week_Downgrades__c =objTeacher.Current_Week_Downgrades__c;
            objTeacher.Previous_Week_Upgrades__c =objTeacher.Current_Week_Upgrades__c;
            objTeacher.Previous_week_withdrawals__c =objTeacher.Current_week_withdrawals__c;
            if(mapOfCountTrialEnrolments.containsKey(objTeacher.id)){
                objTeacher.Current_Week_Trial_Closure__c = mapOfCountTrialEnrolments.get(objTeacher.id);
            }
            if(mapOfCountNewEnrolments.containsKey(objTeacher.id)){
                objTeacher.Current_Week_New_Enrolments__c = mapOfCountNewEnrolments.get(objTeacher.id);
            }
            if(mapOfCountDownEnrolments.containsKey(objTeacher.id)){
                objTeacher.Current_Week_Downgrades__c = mapOfCountDownEnrolments.get(objTeacher.id);
            }
            if(mapOfCountUpgradeEnrolments.containsKey(objTeacher.id)){
                objTeacher.Current_Week_Upgrades__c = mapOfCountUpgradeEnrolments.get(objTeacher.id);
            }
            if(mapOfCountCancelEnrolments.containsKey(objTeacher.id)){
                objTeacher.Current_week_withdrawals__c = mapOfCountCancelEnrolments.get(objTeacher.id);
            }
        }

        update listOfTeachers;
    }
    global void finish(Database.BatchableContext BC){}
     

     public static List<Enrolment__c> getEnrolment(Set<id> teacherIds){
            return [SELECT Id, Name, Effective_Date__c, Enrolment_Created_Date__c, Lesson_Day__c,Stage__c,Teacher__c,
                    Trial_Completed__c, Trial_Date__c, Trial_Requested_Date__c, Trial_Start_Time__c, 
                    Type__c, New_Teacher__c, New_Lesson_Day__c, Duration__c, Duration_Min__c, 
                    Package_Process_Type__c, Package_Process_Status__c, Start_Date__c, Lesson_Start_time__c, Lessons_Start_Date__c
                    FROM Enrolment__c
                    Where New_Teacher__c in: teacherIds
                    Or Teacher__c In:teacherIds 
            ];
     }
}
