public class TeacherWorkingHandler {
    
    public static void createBooking(list<Teacher_Working_Hour__c> workingList){
        list<Booking__c> bkgList = new list<Booking__c>();
        Id bookingRecordType = Schema.SObjectType.booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId(); // Record type of Booking Record
        for(Teacher_Working_Hour__c twh:workingList){
            string startDay = twh.Working_Day__c;  
            date startDate  =system.today();
            Boolean IsDate  = true;
            while(IsDate){
                DateTime myCalDay = (DateTime) startDate;
                if(myCalDay.format('EEE') == startDay){
                    break;
                }
                startDate = startDate.addDays(1);
            }
            date endDate=startDate.addYears(1);    // End date of a year
            while(startDate <= endDate){
                DateTime myDateTime = (DateTime) startDate;
                if(myDateTime.format('EEE') == startDay){  //  Checking and Comparing the selected day 
                    booking__c bkng = new booking__c();
                    bkng.Center__c          = twh.Center_Name__c;
                    bkng.RecordTypeId 		= bookingRecordType;
                    bkng.Booking_Date__c	= startDate;
                    bkng.Teacher_Account__c = twh.Teacher_Name__c;
                    bkng.Start_Time__c 		= twh.Start_Time__c;
                    bkng.End_Time__c		= twh.End_Time__c;
                    bkng.Status__c 			= ConstantsClass.scheduledStatus;
                    bkng.Type__c			= 'Busy';
                    bkng.Category__c 		= 'Lunch';
                    bkng.Remarks__c			= 'Break hours'; 
                    bkgList.add(bkng);  //Added the list of Booking data for all the day in a year 
                }
                startDate=startDate.addDays(7);   
            }
        }
        if(bkgList.size()>0){
           insert bkgList;
        }
            	        
    }

    public static List<Booking__C> getAllEnrolledEnrolmentBookings(Set<string> centerIds,Set<string> resourceIds,map<String,string> teacherWorkingDays){
        Set<string> bookingType = new Set<string>{ConstantsClass.bookTypeRegular,ConstantsClass.typeMakeup,ConstantsClass.typeAdhoc,ConstantsClass.typeTrial};
        date currentDate = system.today();    
        String statusCanceled = ConstantsClass.statusCanceled;
        String enroledStatus = ConstantsClass.enroledStatus;
        String enrolRegularStatus = ConstantsClass.typeRegular;
        String online = ConstantsClass.Online;
         system.debug('centerIds'+centerIds);
        system.debug('resourceIds'+resourceIds);
        string query ='SELECT Id, Booking_Day__c, Resource__c,Start_Time__c ,End_Time__c,Enrolment__c,Teacher_Account__c,Center__c ';
        query += ' FROM Booking__c ';
        query += ' WHERE Enrolment__r.Type__c=:enrolRegularStatus';
        //query += ' And (Enrolment__r.Lesson_Mode__c !=: online Or Lesson_Type__c !=:  online) ';
        query += ' AND Enrolment__r.Stage__c=:enroledStatus';
        query += ' AND Type__c In:bookingType';
        query += ' AND Status__c!=:statusCanceled';
        query += ' AND Booking_date__c>=: currentDate';
        if(centerIds != Null && centerIds.size() > 0){
            query += ' AND Enrolment__r.Center__c In:centerIds';
        }
        if(resourceIds != Null && resourceIds.size() > 0){
            query += ' AND Enrolment__r.Resource__c In:resourceIds';
        }
        if(teacherWorkingDays != Null && teacherWorkingDays.size() > 0){
            List<string> workingDays = teacherWorkingDays.values();
            query += ' AND Booking_Day__c In:workingDays';
            Set<string> teacherIds = teacherWorkingDays.Keyset();
            query += ' AND Teacher_Account__c In:teacherIds';
            system.debug('workingDays'+workingDays);
            system.debug('teacherIds'+teacherIds);
        }
        system.debug('query'+query);
        List<Booking__C> listOfBookings = DataBase.query(query);
        system.debug('listOfBookings'+listOfBookings);
        return listOfBookings;
    }

    Public static void updateNewResourceAccordingToResource(Map<String,map<Id,Teacher_Working_Hour__c>> mapOfOldResourcesWithUpdatedTeachWorkHrs,Set<string> centerIds,map<String,string> teacherWorkingDays){
        if(mapOfOldResourcesWithUpdatedTeachWorkHrs != null && mapOfOldResourcesWithUpdatedTeachWorkHrs.size() > 0){
            List<Booking__C> listOfBookings = getAllEnrolledEnrolmentBookings(centerIds,mapOfOldResourcesWithUpdatedTeachWorkHrs.keySet(),teacherWorkingDays);
            map<id,Enrolment__c> mapOfEnrolment = new  map<id,Enrolment__c>();
            if(listOfBookings != null && listOfBookings.size() >0){
                for(Booking__C objBooking : listOfBookings){
                    if(mapOfOldResourcesWithUpdatedTeachWorkHrs.containsKey(objBooking.Resource__c)){
                        map<Id,Teacher_Working_Hour__c> mapOfUpdatedteachWorkHrs = mapOfOldResourcesWithUpdatedTeachWorkHrs.get(objBooking.Resource__c);
                        if(mapOfUpdatedteachWorkHrs != Null && mapOfUpdatedteachWorkHrs.size() > 0 ){
                            for(Teacher_Working_Hour__c objUpdatedteachWorkHrs : mapOfUpdatedteachWorkHrs.values()){
                                if(objBooking.Teacher_Account__c == objUpdatedteachWorkHrs.Teacher_Name__c &&
                                    objBooking.Booking_Day__c == objUpdatedteachWorkHrs.Working_Day__c &&
                                    objBooking.Start_Time__c >= objUpdatedteachWorkHrs.Start_Time__c
                                    && objBooking.End_Time__c <= objUpdatedteachWorkHrs.End_Time__c){
                                    objBooking.Resource__c = objUpdatedteachWorkHrs.Resource__c;
                                    mapOfEnrolment.put(objBooking.enrolment__C,new Enrolment__c (id= objBooking.enrolment__C,Resource__c = objUpdatedteachWorkHrs.Resource__c));
                                    system.debug('objBooking'+objBooking);
                                }
                            }
                        }   
                    }
                }
                update listOfBookings;
                system.debug('listOfBookings'+listOfBookings.size());
                system.debug('mapOfEnrolment'+mapOfEnrolment.size());
                if(mapOfEnrolment != null && mapOfEnrolment.size() > 0){
                    update mapOfEnrolment.values();
                    system.debug('mapOfEnrolment'+mapOfEnrolment);
                }
            }
        }
    }

    Public static void updateNewResourceAccordingToCenter(Map<String,map<Id,Teacher_Working_Hour__c>> mapOfCenterWithUpdatedTeachWorkHrs,map<String,string> teacherWorkingDays){
        if(mapOfCenterWithUpdatedTeachWorkHrs != null && mapOfCenterWithUpdatedTeachWorkHrs.size() >0){
            List<Booking__C> listOfBookings = getAllEnrolledEnrolmentBookings(mapOfCenterWithUpdatedTeachWorkHrs.keySet(),new Set<string>(),teacherWorkingDays);
            system.debug('listOfBookings'+listOfBookings);
            if(listOfBookings != null && listOfBookings.size() > 0){
                map<id,Enrolment__c> mapOfEnrolment = new  map<id,Enrolment__c>();
                for(Booking__C objBooking : listOfBookings){
                    if(mapOfCenterWithUpdatedTeachWorkHrs.containsKey(objBooking.Center__c)){
                        map<Id,Teacher_Working_Hour__c> mapOfUpdatedteachWorkHrs = mapOfCenterWithUpdatedTeachWorkHrs.get(objBooking.Center__c);
                         if(mapOfUpdatedteachWorkHrs != null && mapOfUpdatedteachWorkHrs.size() > 0){
                            for(Teacher_Working_Hour__c objUpdatedteachWorkHrs : mapOfUpdatedteachWorkHrs.values()){
                                if(objBooking.Teacher_Account__c == objUpdatedteachWorkHrs.Teacher_Name__c &&
                                    objBooking.Booking_Day__c == objUpdatedteachWorkHrs.Working_Day__c &&
                                    objBooking.Start_Time__c >= objUpdatedteachWorkHrs.Start_Time__c
                                    && objBooking.End_Time__c <= objUpdatedteachWorkHrs.End_Time__c){
                                    objBooking.Resource__c = objUpdatedteachWorkHrs.Resource__c;
                                    //system.debug('objBooking'+objBooking);
                                    mapOfEnrolment.put(objBooking.enrolment__C,new Enrolment__c (id= objBooking.enrolment__C,Resource__c = objUpdatedteachWorkHrs.Resource__c));
                                }
                            }
                            
                        }   
                    }
                }
                update listOfBookings;
                system.debug('listOfBookings'+listOfBookings.size());
                system.debug('mapOfEnrolment'+mapOfEnrolment.size());
                if(mapOfEnrolment != null && mapOfEnrolment.size() > 0){
                    system.debug('listOfEnrolment'+mapOfEnrolment);
                    update mapOfEnrolment.values();
                }
            }
        }
    }

    
}