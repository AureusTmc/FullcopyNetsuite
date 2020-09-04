trigger TeacherWorkingTrigger on Teacher_Working_Hour__c (after insert,after update) {
    
    if(trigger.isAfter && trigger.isInsert){
        list<Teacher_Working_Hour__c> workingList = new List<Teacher_Working_Hour__c>();
        for(Teacher_Working_Hour__c teachWork:Trigger.new){
            if(teachWork.Active__c && teachWork.Break_Time__c && teachWork.Working_Day__c != null && 
               	teachWork.Teacher_Name__c != null && teachWork.Center_Name__c != null && teachWork.Start_Time__c != null && 
               	teachWork.End_Time__c != null && teachWork.End_Time__c > teachWork.Start_Time__c){
                workingList.add(teachWork); // Adding list of incoming Teacher working list data
            }
        }
        if(workingList.size()>0){
            TeacherWorkingHandler.createBooking(workingList); 
        }
    }
    // Start: Nishi 31-Jul-2020 : for If resource is changed then we update all active enrolment regular and makup bookings
    if(trigger.isAfter && trigger.isupdate){
        Map<Id,Teacher_Working_Hour__c> oldMap = Trigger.oldMap;
        Map<String,map<Id,Teacher_Working_Hour__c>> mapOfOldResourcesWithUpdatedTeachWorkHrs = new Map<String,map<Id,Teacher_Working_Hour__c>>();
        Map<String,map<Id,Teacher_Working_Hour__c>> mapOfCenterWithResUpdatedTeachWorkHrs = new Map<String,map<Id,Teacher_Working_Hour__c>>();
        Map<String,map<Id,Teacher_Working_Hour__c>> mapOfCenterWithoutResUpdatedTeachWorkHrs = new Map<String,map<Id,Teacher_Working_Hour__c>>();
        
        Set<string> centerId = new Set<string>();
        map<String,string> teacherWorkingDays = new map<String,string>();
        map<Id,Teacher_Working_Hour__c> mapOfUpdatedteachWorkHrs = new map<Id,Teacher_Working_Hour__c>();
      
        for(Teacher_Working_Hour__c teachWork:Trigger.new){
            Teacher_Working_Hour__c oldteachWork = oldMap.get(teachWork.Id);
            // already resource id is exist and user update new Resource then we get old resource update active enrolment regular and makup bookings then we udpated with new resource
            if(string.isNotBlank(oldteachWork.Resource__c) && string.isNotBlank(teachWork.Resource__c) &&
                oldteachWork.Resource__c !=  teachWork.Resource__c){
                    mapOfUpdatedteachWorkHrs = new map<Id,Teacher_Working_Hour__c>();
                if(mapOfOldResourcesWithUpdatedTeachWorkHrs.containsKey(oldteachWork.Resource__c)){
                    mapOfUpdatedteachWorkHrs = mapOfOldResourcesWithUpdatedTeachWorkHrs.get(oldteachWork.Resource__c);
                }
                mapOfUpdatedteachWorkHrs.put(teachWork.id,teachWork);
                centerId.add(teachWork.Center_Name__c);
                mapOfOldResourcesWithUpdatedTeachWorkHrs.put(oldteachWork.Resource__c,mapOfUpdatedteachWorkHrs);
                teacherWorkingDays.put(teachWork.Teacher_Name__c,oldteachWork.Working_Day__c);
            }
            //if resource id is not exist and user update new Resource 
            //then we get teacher working hrs related center then get active enrolment regular and makup bookings then we udpated with new resource
            else if(string.isBlank(oldteachWork.Resource__c) && string.isNotBlank(teachWork.Resource__c)){
                    mapOfUpdatedteachWorkHrs = new map<Id,Teacher_Working_Hour__c>();
                if(mapOfCenterWithResUpdatedTeachWorkHrs.containsKey(teachWork.Center_Name__c)){
                    mapOfUpdatedteachWorkHrs = mapOfCenterWithResUpdatedTeachWorkHrs.get(teachWork.Center_Name__c);
                }
                mapOfUpdatedteachWorkHrs.put(teachWork.id,teachWork);
                mapOfCenterWithResUpdatedTeachWorkHrs.put(teachWork.Center_Name__c,mapOfUpdatedteachWorkHrs);
                teacherWorkingDays.put(teachWork.Teacher_Name__c,oldteachWork.Working_Day__c);
            }
            // //if resource id is previously exist and user update and remove resource id
            // //then we get teacher working hrs related center then get active enrolment regular and makup bookings then we udpated with new resource
            // else if(string.isNotBlank(oldteachWork.Resource__c) && string.isBlank(teachWork.Resource__c)){
            //         mapOfUpdatedteachWorkHrs = new map<Id,Teacher_Working_Hour__c>();
            //     if(mapOfCenterWithoutResUpdatedTeachWorkHrs.containsKey(teachWork.Center_Name__c)){
            //         mapOfUpdatedteachWorkHrs = mapOfCenterWithoutResUpdatedTeachWorkHrs.get(teachWork.Center_Name__c);
            //     }
            //     mapOfUpdatedteachWorkHrs.put(teachWork.id,teachWork);
            //     mapOfCenterWithoutResUpdatedTeachWorkHrs.put(teachWork.Center_Name__c,mapOfUpdatedteachWorkHrs);
            //     teacherWorkingDays.put(teachWork.Teacher_Name__c,oldteachWork.Working_Day__c);
            // }
        }
        
        if(mapOfOldResourcesWithUpdatedTeachWorkHrs != null && mapOfOldResourcesWithUpdatedTeachWorkHrs.size() > 0){
            system.debug('mapOfOldResourcesWithUpdatedTeachWorkHrs'+mapOfOldResourcesWithUpdatedTeachWorkHrs);
            teacherWorkingHandler.updateNewResourceAccordingToResource(mapOfOldResourcesWithUpdatedTeachWorkHrs,centerId,teacherWorkingDays);
        }
        if(mapOfCenterWithResUpdatedTeachWorkHrs != null && mapOfCenterWithResUpdatedTeachWorkHrs.size() > 0){
            system.debug('mapOfCenterWithResUpdatedTeachWorkHrs'+mapOfCenterWithResUpdatedTeachWorkHrs);
            teacherWorkingHandler.updateNewResourceAccordingToCenter(mapOfCenterWithResUpdatedTeachWorkHrs,teacherWorkingDays);
        }
        if(mapOfCenterWithoutResUpdatedTeachWorkHrs != null && mapOfCenterWithoutResUpdatedTeachWorkHrs.size() > 0){
            system.debug('mapOfCenterWithoutResUpdatedTeachWorkHrs'+mapOfCenterWithoutResUpdatedTeachWorkHrs);
            teacherWorkingHandler.updateNewResourceAccordingToCenter(mapOfCenterWithoutResUpdatedTeachWorkHrs,teacherWorkingDays);
        }
    }
    // Start: Nishi 31-Jul-2020 : for If resource is changed then we update all active enrolment regular and makup bookings
}