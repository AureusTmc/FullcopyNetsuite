/*
    Name    : CampDayTeacherTrigger 
   date: 04-Mar-2020
   author: jatin
   description : this trigger for  If a teacher is added to the camp / changed, the placeholders should update accordingly. 
                    Same if a teacher is removed from the camp.
    
*/
trigger CampDayTeacherTrigger on Camp_Day_Teachers__c (after insert,after update,Before delete,after undelete){
    Map<string,Camp_Day_Teachers__c> mapOfActiveCampTeachers = new Map<string,Camp_Day_Teachers__c>(); 
    Map<string,Camp_Day_Teachers__c> mapOfUpdateNewCampTeacher = new Map<string,Camp_Day_Teachers__c>();
    Map<string,Camp_Day_Teachers__c> mapOfUpdateOldCampTeacher = new Map<string,Camp_Day_Teachers__c>();
    map<string,Set<String>> mapOfCancelledCampTeacher = new  map<string,Set<String>>();
    set<string> campTeacherIds  = new set<string>();
    if(trigger.isAfter && (Trigger.isInsert ||  Trigger.isUndelete || Trigger.isUpdate)){
        Map<Id,Camp_Day_Teachers__c> oldMap = trigger.oldMap;
        for(Camp_Day_Teachers__c objCampTeacher : Trigger.new){ 
            
            if( (Trigger.isUpdate)){
                Camp_Day_Teachers__c oldCampTeacher = oldMap.get(objCampTeacher.Id);
                // if update camp day teacher then we check if teacher records update and status inactive to Active then we create placeholder bookings
                if(string.isnotBlank(objCampTeacher.status__c) &&  oldCampTeacher.status__c != objCampTeacher.status__c 
                    && objCampTeacher.status__c.equalsIgnoreCase(ConstantsClass.campTeacherActiveStatus)){
                    mapOfActiveCampTeachers.put(objCampTeacher.id,objCampTeacher);
                } // if update camp day teacher then we check if teacher records update and status Active to inactive then we delete all placeholder bookings related to teacher
                else if(string.isnotBlank(objCampTeacher.status__c) &&  oldCampTeacher.status__c != objCampTeacher.status__c 
                            && objCampTeacher.status__c.equalsIgnoreCase(ConstantsClass.campTeacherInActiveStatus)){
                                campTeacherIds  = new set<string>();
                    if(mapOfCancelledCampTeacher.containsKey(objCampTeacher.Camp_Day__c)){
                        campTeacherIds = mapOfCancelledCampTeacher.get(objCampTeacher.Camp_Day__c);
                    }
                    campTeacherIds.add(objCampTeacher.Camp_Teacher__c);
                    mapOfCancelledCampTeacher.put(objCampTeacher.Camp_Day__c,campTeacherIds);
                } // if update camp day teacher then we check if teacher records update and status not change but other date and time is change 
                // then we udpate  all camp placeholder bookings related to teacher               
                else if(((string.isnotBlank(objCampTeacher.Camp_Day__c) &&  oldCampTeacher.Camp_Day__c != objCampTeacher.Camp_Day__c) ||
                    (objCampTeacher.End_Time__c != null &&  oldCampTeacher.End_Time__c != objCampTeacher.End_Time__c) ||
                    (objCampTeacher.Start_time__c != null  &&  oldCampTeacher.Start_time__c != objCampTeacher.Start_time__c) 
                    ) &&  string.isnotBlank(objCampTeacher.status__c) &&  oldCampTeacher.status__c == objCampTeacher.status__c 
                    && objCampTeacher.status__c.equalsIgnoreCase(ConstantsClass.campTeacherActiveStatus) ){
                    mapOfUpdateNewCampTeacher.put(objCampTeacher.id,objCampTeacher);
                    mapOfUpdateOldCampTeacher.put(oldCampTeacher.id,oldCampTeacher);
                }
            }else{
                // insert new records and status is active then we create new placholder bookings 
                if(string.isnotBlank(objCampTeacher.status__c) && objCampTeacher.status__c.equalsIgnoreCase(ConstantsClass.campTeacherActiveStatus)){
                    mapOfActiveCampTeachers.put(objCampTeacher.id,objCampTeacher);
                }
            }
        }
    }
    
    if(Trigger.isDelete ){
        // if camp class teacher deleted or status is Active then we delete camp teacher placholder bookings
        for(Camp_Day_Teachers__c objCampTeacher :Trigger.old){ 
            if(string.isnotBlank(objCampTeacher.status__c) && objCampTeacher.status__c.equalsIgnoreCase(ConstantsClass.campTeacherActiveStatus)){
                campTeacherIds  = new set<string>();
                if(mapOfCancelledCampTeacher.containsKey(objCampTeacher.Camp_Day__c)){
                    campTeacherIds = mapOfCancelledCampTeacher.get(objCampTeacher.Camp_Day__c);
                }
                campTeacherIds.add(objCampTeacher.Camp_Teacher__c);
                mapOfCancelledCampTeacher.put(objCampTeacher.Camp_Day__c,campTeacherIds);
            }
        }
    }

    if(mapOfActiveCampTeachers != null && mapOfActiveCampTeachers.size() > 0){
        CampDayTeacherTriggerHelper.createCampTeachersPlaceholder(mapOfActiveCampTeachers);
    }
    if(mapOfUpdateNewCampTeacher != null && mapOfUpdateNewCampTeacher.size() > 0&& mapOfUpdateOldCampTeacher != null && mapOfUpdateOldCampTeacher.size() > 0){
        CampDayTeacherTriggerHelper.UpdateCampTeachersPlaceholder(mapOfUpdateNewCampTeacher,mapOfUpdateOldCampTeacher);
    }
    system.debug('Cancelled'+mapOfCancelledCampTeacher);
    if(mapOfCancelledCampTeacher != null && mapOfCancelledCampTeacher.size() > 0){
        CampDayTeacherTriggerHelper.deleteCampTeachersPlaceholder(mapOfCancelledCampTeacher);
    }
}