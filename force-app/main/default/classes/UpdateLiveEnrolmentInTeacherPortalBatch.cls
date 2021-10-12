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
       
        if(!teacherIdSet.isEmpty()){ 
            return Database.getQueryLocator([Select id,Previous_Week_Downgrades__c,Weekly_Actual_Enrolment_Hours__c, Previous_Week_Trial_Closure__c, Previous_Week_Upgrades__c, Previous_week_withdrawals__c, Current_week_withdrawals__c, Previous_Week_New_Enrolments__c, Current_Week_New_Enrolments__c,
                                                 Current_Week_Trial_Closure__c, Current_Week_Upgrades__c, Current_Week_Downgrades__c,
                                                 Previous_Week_Trial_Closure_Rate__c,Current_Week_Trial_Closure_Rate__c
                                                from Account 
                                                where Employee_Status__c in ('Probation','Confirm')
                                                and  recordType.Name='Teacher'
                                                and (Joining_Date__c=null or Joining_Date__c<=:lastWeekDate) 
                                                and (Last_Working_Date__c=null or Last_Working_Date__c>=:startWeekDate) 
                                                AND Id IN : teacherIdSet]);    
        }else{        
            return Database.getQueryLocator([Select id,Previous_Week_Downgrades__c,Weekly_Actual_Enrolment_Hours__c, Previous_Week_Trial_Closure__c, Previous_Week_Upgrades__c, Previous_week_withdrawals__c, Current_week_withdrawals__c, Previous_Week_New_Enrolments__c, Current_Week_New_Enrolments__c,
                                             Current_Week_Trial_Closure__c, Current_Week_Upgrades__c, Current_Week_Downgrades__c,
                                             Previous_Week_Trial_Closure_Rate__c,Current_Week_Trial_Closure_Rate__c
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
        Map<string,Integer> mapOfCountNewEnrolmentWithTrialEnrolments = new  Map<string,Integer>();
        Map<string,Integer> mapOfCountNotEnrolmentTrialEnrolments = new  Map<string,Integer>();
        Map<string,Integer> mapOfCountTrialEnrolments = new  Map<string,Integer>();
        Map<string,decimal> mapOfDuationWithErolments = new  Map<string,decimal>();
        system.debug('teacherIdSet ** '+teacherIdSet);
        system.debug('startWeekDate ** '+startWeekDate);
        system.debug('lastWeekDate ** '+lastWeekDate);
        set<string> enrolmentTrialStages= new set<string>{ConstantsClass.enrollStageAttended,'Requested','Booked','Pending Enrolment'};
        for(Enrolment__c objEnrolment : listOfEnrolment){
            Integer countEnrolment = 0;
            
            If((objEnrolment.Type__c ==ConstantsClass.typeTrial)){
                if(objEnrolment.Stage__c ==ConstantsClass.enrollStageAttended){
                    system.debug('objEnrolment.Trial_Date__c'+objEnrolment.Trial_Date__c);
                    if(objEnrolment.Trial_Date__c != null && objEnrolment.Trial_Date__c >= startWeekDate && objEnrolment.Trial_Date__c <=lastWeekDate && 
                        objEnrolment.bookings__r !=null && objEnrolment.bookings__r.size()> 0 ){
                        if(mapOfCountTrialEnrolments.containsKey(objEnrolment.Teacher__c)){
                            countEnrolment = mapOfCountTrialEnrolments.get(objEnrolment.Teacher__c);
                        }
                        countEnrolment+=1;
                        mapOfCountTrialEnrolments.put(objEnrolment.Teacher__c,countEnrolment);
                        system.debug('---------mapOfCountTrialEnrolments'+mapOfCountTrialEnrolments);
                        system.debug('objEnrolment'+objEnrolment.id);
                    }
                }
                if(enrolmentTrialStages.contains(objEnrolment.Stage__c)){
                    if(mapOfCountNotEnrolmentTrialEnrolments.containsKey(objEnrolment.Teacher__c)){
                        countEnrolment = mapOfCountNotEnrolmentTrialEnrolments.get(objEnrolment.Teacher__c);
                    }
                    countEnrolment+=1;
                    mapOfCountNotEnrolmentTrialEnrolments.put(objEnrolment.Teacher__c,countEnrolment);
                }
            }else if(objEnrolment.Stage__c =='Enrolled' &&  (objEnrolment.Type__c =='Regular')){// ||   objEnrolment.Type__c =='Group Lesson'
                system.debug('objEnrolment.Enrolment_Created_Date__c'+objEnrolment.Enrolment_Created_Date__c);
                system.debug('objEnrolment.Effective_Date__c'+objEnrolment.Effective_Date__c);
                system.debug('objEnrolment.Package_Process_Status__c'+objEnrolment.Package_Process_Status__c);  
                if(objEnrolment.Enrolment_Created_Date__c != null && objEnrolment.Enrolment_Created_Date__c >=startWeekDate && objEnrolment.Enrolment_Created_Date__c <=lastWeekDate){
                    if(mapOfCountNewEnrolments.containsKey(objEnrolment.Teacher__c)){
                        countEnrolment = mapOfCountNewEnrolments.get(objEnrolment.Teacher__c);
                    }
                    countEnrolment+=1;
                    mapOfCountNewEnrolments.put(objEnrolment.Teacher__c,countEnrolment);
                    system.debug('---------mapOfCountNewEnrolments'+mapOfCountNewEnrolments);
                    system.debug('objEnrolment'+objEnrolment.id);
                    if(objEnrolment.Trial_Date__c != null && objEnrolment.Trial_Date__c >= startWeekDate && objEnrolment.Trial_Date__c <=lastWeekDate){
                        if(mapOfCountNewEnrolmentWithTrialEnrolments.containsKey(objEnrolment.Teacher__c)){
                            countEnrolment = mapOfCountNewEnrolmentWithTrialEnrolments.get(objEnrolment.Teacher__c);
                        }
                        countEnrolment+=1;
                        mapOfCountNewEnrolmentWithTrialEnrolments.put(objEnrolment.Teacher__c,countEnrolment);
                    }
                }else if(objEnrolment.Effective_Date__c != null && objEnrolment.Effective_Date__c >=startWeekDate && objEnrolment.Effective_Date__c <=lastWeekDate 
                && string.isnotBlank(objEnrolment.Package_Process_Type__c)){
                    if(objEnrolment.Package_Process_Type__c ==ConstantsClass.enrollmentProcessUpgradeType && objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessCompletedStatus){
                        string teacherId = (objEnrolment.Teacher__c );
                        if(mapOfCountUpgradeEnrolments.containsKey(teacherId)){
                            countEnrolment = mapOfCountUpgradeEnrolments.get(teacherId);
                        }
                        countEnrolment+=1;
                        mapOfCountUpgradeEnrolments.put(teacherId,countEnrolment);
                        system.debug('---------mapOfCountTrialEnrolments'+mapOfCountTrialEnrolments);
                        system.debug('objEnrolment'+objEnrolment.id);
                    }else if(objEnrolment.Package_Process_Type__c ==ConstantsClass.enrollmentProcessDowngradeType && objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessCompletedStatus){
                        string teacherId = (objEnrolment.Teacher__c );
                        if(mapOfCountDownEnrolments.containsKey(teacherId)){
                            countEnrolment = mapOfCountDownEnrolments.get(teacherId);
                        }
                        countEnrolment+=1;
                        mapOfCountDownEnrolments.put(teacherId,countEnrolment);
                        system.debug('---------mapOfCountDownEnrolments'+mapOfCountDownEnrolments);
                        system.debug('objEnrolment'+objEnrolment.id);
                    }/*else if(objEnrolment.Package_Process_Type__c =='Cancellation' && objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessCompletedStatus){
                        string teacherId = objEnrolment.Teacher__c;
                        if(mapOfCountCancelEnrolments.containsKey(teacherId)){
                            countEnrolment = mapOfCountCancelEnrolments.get(teacherId);
                        }
                        mapOfCountCancelEnrolments.put(teacherId,countEnrolment++);
                    }*/
                }    
                decimal durationEnrolment = 0;
                if(objEnrolment.Effective_Date__c != null && objEnrolment.Effective_Date__c.month() == currentDate.month() 
                && string.isnotBlank(objEnrolment.Package_Process_Type__c) && objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessCompletedStatus){
                    if(objEnrolment.Package_Process_Type__c !='Cancellation'){
                        if(mapOfDuationWithErolments.containsKey(objEnrolment.Teacher__c)){
                            durationEnrolment = mapOfDuationWithErolments.get(objEnrolment.Teacher__c);
                        }
                        durationEnrolment += objEnrolment.Duration_Min__c;
                        mapOfDuationWithErolments.put(objEnrolment.Teacher__c,durationEnrolment);
                        system.debug('mapOfDuationWithErolments'+mapOfDuationWithErolments);
                        system.debug('objEnrolment'+objEnrolment.id);
                    }
                }else{
                    if(objEnrolment.Stage__c =='Enrolled' &&  (objEnrolment.Type__c =='Regular')){
                        if(mapOfDuationWithErolments.containsKey(objEnrolment.Teacher__c)){
                            durationEnrolment = mapOfDuationWithErolments.get(objEnrolment.Teacher__c);
                        }
                        durationEnrolment += objEnrolment.Duration_Min__c;
                        mapOfDuationWithErolments.put(objEnrolment.Teacher__c,durationEnrolment);
                        system.debug('mapOfDuationWithErolments'+mapOfDuationWithErolments);
                        system.debug('objEnrolment'+objEnrolment.id);
                    }
                }
                
            }else if(objEnrolment.Stage__c =='Cancelled' &&  objEnrolment.Type__c =='Regular' &&
            objEnrolment.Effective_Date__c != null && objEnrolment.Effective_Date__c >=startWeekDate && objEnrolment.Effective_Date__c <=lastWeekDate 
            && objEnrolment.Package_Process_Type__c =='Cancellation' && objEnrolment.Package_Process_Status__c == ConstantsClass.enrollmentProcessCompletedStatus ){//||   objEnrolment.Type__c =='Group Lesson')
                if(mapOfCountCancelEnrolments.containsKey(objEnrolment.Teacher__c)){
                    countEnrolment = mapOfCountCancelEnrolments.get(objEnrolment.Teacher__c);
                }
                countEnrolment+=1;
                mapOfCountCancelEnrolments.put(objEnrolment.Teacher__c,countEnrolment);
                system.debug('mapOfCountCancelEnrolments'+mapOfCountCancelEnrolments);
                system.debug('objEnrolment'+objEnrolment.id);
            }
        }


        system.debug('mapOfDuationWithErolments'+mapOfDuationWithErolments);
        system.debug('mapOfCountNewEnrolments'+mapOfCountNewEnrolments);
        system.debug('mapOfCountDownEnrolments'+mapOfCountDownEnrolments);
        system.debug('mapOfCountUpgradeEnrolments'+mapOfCountUpgradeEnrolments);
        system.debug('mapOfCountCancelEnrolments'+mapOfCountCancelEnrolments);
        system.debug('mapOfCountTrialEnrolments'+mapOfCountTrialEnrolments);
        for(Account objTeacher:listOfTeachers){
            objTeacher.Previous_Week_Trial_Closure__c =objTeacher.Current_Week_Trial_Closure__c;
            objTeacher.Previous_Week_New_Enrolments__c =objTeacher.Current_Week_New_Enrolments__c;
            objTeacher.Previous_Week_Downgrades__c =objTeacher.Current_Week_Downgrades__c;
            objTeacher.Previous_Week_Upgrades__c =objTeacher.Current_Week_Upgrades__c;
            objTeacher.Previous_week_withdrawals__c =objTeacher.Current_week_withdrawals__c;
            objTeacher.Previous_Week_Trial_Closure_Rate__c =objTeacher.Current_Week_Trial_Closure_Rate__c;
           
            objTeacher.Current_Week_Trial_Closure_Rate__c = ((mapOfCountNewEnrolmentWithTrialEnrolments.containsKey(objTeacher.id) && mapOfCountNewEnrolmentWithTrialEnrolments.get(objTeacher.id) > 0? 
            mapOfCountNewEnrolmentWithTrialEnrolments.get(objTeacher.id):1)/
            (mapOfCountNotEnrolmentTrialEnrolments.containsKey(objTeacher.id) && mapOfCountNotEnrolmentTrialEnrolments.get(objTeacher.id) > 0? 
            mapOfCountNotEnrolmentTrialEnrolments.get(objTeacher.id):1));


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

            if(mapOfDuationWithErolments.containsKey(objTeacher.id)){
                objTeacher.Weekly_Actual_Enrolment_Hours__c = mapOfDuationWithErolments.get(objTeacher.id) != null ? mapOfDuationWithErolments.get(objTeacher.id)/60 : 0;
            }else{
                objTeacher.Weekly_Actual_Enrolment_Hours__c = 0;
            }
        }

        update listOfTeachers;
    }
    global void finish(Database.BatchableContext BC){}
     

     public static List<Enrolment__c> getEnrolment(Set<id> teacherIds){
            return [SELECT Id, Name, Effective_Date__c, Enrolment_Created_Date__c, Lesson_Day__c,Stage__c,Teacher__c,
                    Trial_Completed__c, Trial_Date__c, Trial_Requested_Date__c, Trial_Start_Time__c, 
                    Type__c, New_Teacher__c, New_Lesson_Day__c, Duration__c, Duration_Min__c, New_Package_Id__r.Duration__c,
                    Package_Process_Type__c, Package_Process_Status__c, Start_Date__c, Lesson_Start_time__c, Lessons_Start_Date__c,
                    (select id from bookings__r where type__c ='Trial' and status__c='Completed')
                    FROM Enrolment__c
                    Where// New_Teacher__c in: teacherIds Or 
                     Teacher__c In:teacherIds 
            ];
     }
}