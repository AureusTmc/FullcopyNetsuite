public class PublicHolidayHelper {
    //Added By ....Ravi this trigger create a Holiday Catgory for all teacher in various location as per teacher working hours
    public static void createdPlaceholderPublic(List<Public_Holiday__c> publicHolidayList){
         // defined to store the teacher record types
        string teacherTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
        // defined to stores the Holiday date list
        List<Date> dateList= new List<Date>();
        // defined to store the type of duty if teacher 
        set<string> dutyType = new set<String>();
        // defined to map the Date with Holiday Date
        map<Date,string> mapToHoliday = new map<Date,string>();
        // defined to update the status of Public holiday 
        List<Public_Holiday__c> updatePublicHolidayList = new List<Public_Holiday__c>();
        // defined  to map the PublicHoliday id with COuntry Id
        map<String,string> mapToPublicHoliday = new map<String,String>();
        // new Definde Value
        map<string,List<Account>> mapToTeacherOrganistion= new map<string,List<Account>>();
        set<String> dayStr = new set<String>();
        //  end Defined Value
        // defined to map to working hour
         map<string,string> mapToworkinghour = new map<string,string>();
        set<String> organisationId =  new set<String>();
        list<Booking__c> BookingLeaveList = new list<Booking__c>();
        for(Public_Holiday__c phObj:publicHolidayList){
            Datetime dt = DateTime.newInstance(phObj.Public_Holiday_Date__c, Time.newInstance(0, 0, 0, 0));
            String dayOfWeek=dt.format('E');
            dayStr.add(dayOfWeek);
            if(phObj.Public_Holiday_Date__c <> null && phObj.Organisation_Status__c =='Closed' && phObj.Status__c=='Pending for execution'){
                dateList.add(phObj.Public_Holiday_Date__c);
                dutyType.add('Duty');
                dutyType.add('Non-Duty');
                organisationId.add(phObj.Organisation__c);
                mapToHoliday.put(phObj.Public_Holiday_Date__c,phObj.Name);
            }else if(phObj.Public_Holiday_Date__c <> null && phObj.Status__c=='Pending for execution' && phObj.Organisation_Status__c =='Open') {
                dateList.add(phObj.Public_Holiday_Date__c);
                dutyType.add('Duty');
                mapToHoliday.put(phObj.Public_Holiday_Date__c,phObj.Name);
                 organisationId.add(phObj.Organisation__c);
            }
        }
        for(Public_Holiday__c publicHoliday:[select Id,Organisation__r.Country__c,Country__c from Public_Holiday__c where Id in:publicHolidayList]){
            mapToPublicHoliday.put(publicHoliday.Id,publicHoliday.Organisation__r.Country__c);
        }
        
        // New Code 
        for(Account teacherObj:[select Id,Name,Organisation__c,Employee_Duty_Type__c,(select Working_Day__c,Center_Name__c,Teacher_Name__c,Start_Time__c,End_Time__c from Teacher_Working_Schedules__r  where  Break_Time__c=false and Active__c =true and Working_Day__c in:dayStr) from Account where RecordTypeId=:teacherTypeId and Employee_Duty_Type__c in:dutyType and Organisation__c in:organisationId]){
            if(mapToTeacherOrganistion.containsKey(teacherObj.Organisation__c)){
                list<Account> accList= mapToTeacherOrganistion.get(teacherObj.Organisation__c);
                accList.add(teacherObj); 
                mapToTeacherOrganistion.put(teacherObj.Organisation__c,accList);     
            }else{
                List<Account> accList = new List<Account>(); 
                accList.add(teacherObj);
                mapToTeacherOrganistion.put(teacherObj.Organisation__c,accList);
            }
            for(Teacher_Working_Hour__c workInstance:teacherObj.Teacher_Working_Schedules__r){
                mapToworkinghour.put(workInstance.Teacher_Name__c +'/' + workInstance.Working_Day__c,workInstance.Start_Time__c + '/'+workInstance.End_Time__c + '/' + workInstance.Working_Day__c); 
            }
        }
        Time StartTime =Time.newInstance(08, 00, 00, 00);
        Time EndTime=Time.newInstance(20, 00, 00, 00);
        
        for(Public_Holiday__c publicObj:publicHolidayList){
            if(mapToTeacherOrganistion.containsKey(publicObj.Organisation__c)){
                for(Account accTr:mapToTeacherOrganistion.get(publicObj.Organisation__c)){
                    if(publicObj.Organisation_Status__c=='Closed' || (publicObj.Organisation_Status__c=='Open' && accTr.Employee_Duty_Type__c=='Duty') ){
                        for (Teacher_Working_Hour__c ar : accTr.Teacher_Working_Schedules__r)  {
                            // Date leaveDate=dateList[0];
                            // System.debug('Campaign ID' + ar.get('Center_Name__c'));
                            string CenterId =string.valueOf(ar.Center_Name__c);
                            string teacherId =string.valueOf(ar.Teacher_Name__c);
                            system.debug('teacherId'+teacherId + 'CenterId'+CenterId);
                            
                                Datetime dt = DateTime.newInstance(publicObj.Public_Holiday_Date__c, Time.newInstance(0, 0, 0, 0));
                                String dayOfWeek=dt.format('E');
                                string KeyId=teacherId+'/'+dayOfWeek;
                                // system.debug('mapToworkinghour'+  mapToworkinghour.get(KeyId).split('/')[2] +'teacherId'+teacherId);
                                if(mapToworkinghour.containsKey(KeyId) && mapToworkinghour.get(KeyId).split('/')[2]==dayOfWeek ){
                                    integer hr=integer.valueOf(mapToworkinghour.get(KeyId).split('/')[0].split(':')[0]);
                                    integer min=integer.valueOf(mapToworkinghour.get(KeyId).split('/')[0].split(':')[1]);
                                    StartTime=Time.newInstance(hr,min,00,00);
                                    integer Ehr=integer.valueOf(mapToworkinghour.get(KeyId).split('/')[1].split(':')[0]);
                                    integer Emin=integer.valueOf(mapToworkinghour.get(KeyId).split('/')[1].split(':')[1]);
                                    EndTime=Time.newInstance(Ehr,Emin,00,00);
                                    String RemarkforTeacherLeave='Public Holiday';// Defining the remark for the Teacher Leave reason  
                                    
                                    if(mapToHoliday.containsKey(publicObj.Public_Holiday_Date__c)){
                                        RemarkforTeacherLeave =mapToHoliday.get(publicObj.Public_Holiday_Date__c) +' Public Holiday';
                                    }
                                    
                                    Booking__c bkgLeaveObj = new Booking__c(End_Time__c=EndTime,Start_Time__c=StartTime,Status__c='Scheduled',Type__c='Busy',Category__c='Holiday',Center__c=CenterId,Teacher_Account__c=teacherId,Booking_Date__c=publicObj.Public_Holiday_Date__c,Remarks__c=RemarkforTeacherLeave);
                                    BookingLeaveList.add(bkgLeaveObj);  
                                }
                        }
                    }
                    
                }  
            }
          
            
        }
        system.debug('BookingLeaveList'+BookingLeaveList.size());
        // check for the Leave availability
        if(BookingLeaveList.size()>0){
            insert BookingLeaveList;
        }
         // Updating the Public holiday Country on basis of Orgainistaion 
        for(Public_Holiday__c phObject:publicHolidayList){
            if(mapToPublicHoliday.containsKey(phObject.Id) && (phObject.Status__c =='Draft' || phObject.Status__c =='Pending for execution')){
                Public_Holiday__c phObjct = new Public_Holiday__c(Id=phObject.Id,Country__c=mapToPublicHoliday.get(phObject.Id));
                updatePublicHolidayList.add(phObjct); 
            }
        }
        
        
        if(updatePublicHolidayList.size()>0){
            update updatePublicHolidayList;
        }
    }

}