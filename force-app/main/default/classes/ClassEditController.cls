/*
	Class Name	:	ClassEditController
	Date        :   2019/08/20      
	Description :   This is a Controller for Class Edit Functionality.
*/
public class ClassEditController {
	/*
		This Method will return the Edit Screen Group lesson details 
	 */
    @RemoteAction
    Public static BookDetails fetchBookDetailsForScreen(String bookingId){
    	BookDetails bookDetails;
       // List<AureusCalendarController.GroupPackage> groupPackages;
        List<Booking__c> bookingList = new List<Booking__c>();
        Boolean isOssia = false; //added by nishi:2-sep-2020;
                 
        if(String.isNotBlank(bookingId)){
            // selected Group lesson details
            Booking__c bookObj = fetchSelectedBookingDetails(bookingId);
            /* 27-Feb-2020: commented by jatin for this pacakge list is not using in calendar
            if(String.isNotBlank(bookObj.Center__c)){
            	groupPackages = AureusCalendarController.fetchGroupPackages(bookObj.Center__c,bookObj.Teacher_Account__c); 
                //groupPackages = AureusCalendarController.fetchGroupPackages(bookObj.Center__c,bookObj.Package__r.Package_Fee__c);    
            }*/
            // selected Group lesson Booking details
            if(String.isNotBlank(bookObj.Id)){
                bookingList = fetchAllBookingsForClass(bookObj.Id);
                //start:added by nishi: 2-Sep-2020: for get selected class center is related to Ossia organization group class 
                if(String.isNotBlank(bookObj.Class__r.Centre_Name__c) && String.isNotBlank(bookObj.Class__r.Centre_Name__r.Organisation__c) && String.isNotBlank(bookObj.Class__r.Centre_Name__r.Organisation__r.Name) &&
                bookObj.Class__r.Centre_Name__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                    isOssia = true; 
                }
                //end:added by nishi: 2-Sep-2020: for get selected class center is related to Ossia organization group class 
            }
            
            
            // selected Group lesson history details
            bookDetails = new BookDetails(bookObj, /*groupPackages, */bookingList,isOssia);
            bookDetails.bookingHistoryList = AureusCalendarController.getBookingHistory(bookingId);
        }
        return bookDetails;
    }

    // added by nishi: 10-Sep-2020: for show new Reschadule group class details
    @RemoteAction
    public static RescheduledBookDetails showRescheduledGroupClassBookings(Map<String, Object> bookingReschedule){
        RescheduledBookDetails objRescheduledBookDetails = new RescheduledBookDetails();
        String teacherProfileName = ConstantsClass.teacherProfileName;
        List<Account> accList = new List<Account>();
        List<Resource__c> resourceList = new List<Resource__c>();
        List<Booking__c> bookObjList = new List<Booking__c>();
        List<Attachment> attachList = new List<Attachment>();
        if(bookingReschedule.containsKey('Id')){
            string bookingId = string.valueOf( bookingReschedule.get('Id'));
            Booking__c bookingObj = fetchSelectedBookingDetails(bookingId);
            objRescheduledBookDetails.bookObj =bookingObj;
            objRescheduledBookDetails.isOssia = false; 
            if(String.isNotBlank(bookingObj.Id)){
                if(String.isNotBlank(bookingObj.Class__r.Centre_Name__c) && String.isNotBlank(bookingObj.Class__r.Centre_Name__r.Organisation__c) 
                && String.isNotBlank(bookingObj.Class__r.Centre_Name__r.Organisation__r.Name) &&
                bookingObj.Class__r.Centre_Name__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                    objRescheduledBookDetails.isOssia = true; 
                }
            }
            objRescheduledBookDetails.resourceName =  bookingObj.Resource__r.Name;
            objRescheduledBookDetails.resourceId = bookingObj.Resource__c;
            if(bookingReschedule.containsKey('resource')){
                if(bookingReschedule.get('resource') != bookingObj.Teacher_Account__c){
                    accList = AureusCalendarControllerHelper.getListOfTeacher(bookingObj.Center__c, String.valueOf(bookingReschedule.get('resource')));
                    if(accList.size() > 0){
                        objRescheduledBookDetails.staffMember = accList[0].Name;
                        objRescheduledBookDetails.staffMemberId = accList[0].id;
                        attachList = [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
                                      WHERE parentid=:accList[0].Id AND Name Like :teacherProfileName AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
                                      ORDER BY LastModifiedDate DESC LIMIT 1];
                        if(attachList.size() > 0){
                            objRescheduledBookDetails.teacherAttachmentId = attachList[0].Id;
                        }
                    }else{
                    //start: nish: 31-Jul-2020: If resource Calendar exist then teacher records not found then we check existing booking Teacher_Account__c details    
                        accList = AureusCalendarControllerHelper.getListOfTeacher(bookingObj.Center__c, bookingObj.Teacher_Account__c);
                        if(accList.size() > 0){
                            objRescheduledBookDetails.staffMember = accList[0].Name;
                            objRescheduledBookDetails.staffMemberId = accList[0].id;
                            attachList = [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
                                          WHERE parentid=:accList[0].Id AND Name Like :teacherProfileName AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
                                          ORDER BY LastModifiedDate DESC LIMIT 1];
                            if(attachList.size() > 0){
                                objRescheduledBookDetails.teacherAttachmentId = attachList[0].Id;
                            }
                        }
                        // get Resource Detail if change resource then we get resource 
                        if(bookingReschedule.get('resource') != bookingObj.Resource__c){
                            resourceList = AureusCalendarControllerHelper.getListOfResource(bookingObj.Center__c, String.valueOf(bookingReschedule.get('resource')));
                            if(resourceList.size() > 0){
                                objRescheduledBookDetails.resourceName = resourceList[0].Name;
                                objRescheduledBookDetails.resourceId = resourceList[0].id;
                            }
                        }

                    //start: nish: 31-Jul-2020: If resource Calendar exist then teacher records not found then we check existing booking Teacher_Account__c details    
                    
                    }
                }else{
                    objRescheduledBookDetails.staffMember = bookingObj.Teacher_Account__r.Name;
                    objRescheduledBookDetails.staffMemberId = bookingObj.Teacher_Account__c;
                    attachList = [SELECT Id, Name, LastModifiedDate, ContentType FROM Attachment 
                                  WHERE parentid=:bookingObj.Teacher_Account__c AND Name Like :teacherProfileName AND ContentType IN ('image/png', 'image/jpeg', 'image/gif')
                                  ORDER BY LastModifiedDate DESC LIMIT 1];
                    if(attachList.size() > 0){
                        objRescheduledBookDetails.teacherAttachmentId = attachList[0].Id;
                    }
                }
                
            }
            if(bookingReschedule.containsKey('date')){
                objRescheduledBookDetails.timeOfBooking = String.valueOf(bookingReschedule.get('date')).split('T')[1];
                objRescheduledBookDetails.dateAndTime = String.valueOf(bookingReschedule.get('date'));
                DateTime dateChange = DateTime.newInstance(Date.valueOf(String.valueOf(bookingReschedule.get('date')).split('T')[0]), Time.newInstance(0, 0, 0, 0));
                objRescheduledBookDetails.isDayChange = false;
                if(bookingObj.Booking_Date__c != dateChange.date()){
                    objRescheduledBookDetails.isDayChange = true;
                }
            }
        }
        return objRescheduledBookDetails ;

    }
     //Json For reschadule Class Popup
     Public Class RescheduledBookDetails{
        public Booking__c bookObj;
        public Boolean isOssia;
        public String service;
        public String resourceId;
        public String resourceName;
        public String staffMember;
        public String staffMemberId;
        public String dateAndTime;
        public String timeOfBooking;
        public String teacherAttachmentId;     
        public Boolean isDayChange;   
     }
// added by nishi: 10-Sep-2020: for  Reschadule group class future and current with related group lessons
     @RemoteAction 
    public static AureusCalendarController.ProcessResult updateGroupClassBooking(String bookingId, String startDate, String endDate,
     String teacherId, String placeholder, String isFuture/*, String redirectCase, String caseId,
     String isResourceId*/){
        
        AureusCalendarController.ProcessResult objResult = new AureusCalendarController.ProcessResult();
        Booking__c bookingObj = new Booking__c();
        List<Booking__c> bookingObjList = new List<Booking__c>(); 
        List<Booking__c> bookingList = new List<Booking__c>(); 
        List<Booking__c> bookList = new List<Booking__c>();
        List<Booking__c> oldBookList = new List<Booking__c>();
        Booking__c oldBooking = new Booking__c();
        List<Booking__c> placeholderList = new List<Booking__c>();
        Map<Id ,Enrolment__c> enrollMap = new Map<Id, Enrolment__c>();
        DateTime startDateTime, endDateTime;
        Integer duration = 0;
        Boolean isError = false;
        String lessonRecordType = ConstantsClass.groupBookingRecordType;
        String busyType = ConstantsClass.typeBusy;
        if(String.isNotBlank(bookingId)){
            bookingObjList = [SELECT Id, Name, Enrolment__c,Package__c , Student__c, Student__r.Name, Resource__c,Prev_Start_Time__c,
                              Enrolment__r.Teacher__c, Individual_Booking__c, Type__c, Enrolment__r.Lesson_Day__c, Prev_Booking_Date__c,
                              Enrolment__r.Lesson_Start_time__c, Booking_Date__c, Start_Time__c, End_Time__c, Group_Class__c,Class__c,
                              Status__c, Center__c, Teacher_Account__c, Teacher_Account__r.Name, Lesson_Type__c,
                              Duration__c, RecordType.Name, Category__c, Appointment_Day__c,Enrolment__r.Resource__c,Prev_Teacher__c, 
                              (SELECT Id, Name, Enrolment__c,Package__c , Student__c, Student__r.Name, Resource__c,Prev_Teacher__c,
                                Enrolment__r.Teacher__c, Individual_Booking__c, Type__c, Enrolment__r.Lesson_Day__c, Prev_Start_Time__c,
                                Enrolment__r.Lesson_Start_time__c, Booking_Date__c, Start_Time__c, End_Time__c, Prev_Booking_Date__c,
                                Status__c, Center__c, Teacher_Account__c, Teacher_Account__r.Name, Lesson_Type__c,
                                Duration__c, RecordType.Name, Category__c, Appointment_Day__c,Enrolment__r.Resource__c
                                FROM Bookings1__r)
                              FROM Booking__c WHERE Id =: bookingId];
        }
        if(bookingObjList.size() > 0 && isFuture == 'false'){
            bookingObj = bookingObjList[0];
            startDateTime = DateTime.newInstance(bookingObj.Booking_Date__c, bookingObj.Start_Time__c);
            endDateTime = DateTime.newInstance(bookingObj.Booking_Date__c, bookingObj.End_Time__c);
            duration = (Integer)(((endDateTime.getTime() - startDateTime.getTime()) / 1000) / 60);
            oldBooking = bookingObjList[0].clone(false, false, false, false);
            
            if(String.isNotBlank(startDate)){
                bookingObj.Prev_Start_Time__c = bookingObj.Start_Time__c;
                bookingObj.Start_Time__c = Time.newInstance(Integer.valueOf(startDate.split('T')[1].split(':')[0]), Integer.valueOf(startDate.split('T')[1].split(':')[1]), Integer.valueOf(startDate.split('T')[1].split(':')[2]), 0); 
                
                bookingObj.Prev_Booking_Date__c = bookingObj.Booking_Date__c;
                bookingObj.Booking_Date__c = Date.valueOf(startDate.split('T')[0]);
            }
            if(String.isNotBlank(endDate)){
                bookingObj.End_Time__c = Time.newInstance(Integer.valueOf(endDate.split('T')[1].split(':')[0]), Integer.valueOf(endDate.split('T')[1].split(':')[1]), Integer.valueOf(endDate.split('T')[1].split(':')[2]), 0);    
            }else if(String.isBlank(endDate)){
                if(bookingObj.Duration__c != NULL){
                    bookingObj.End_Time__c = bookingObj.Start_Time__c.addMinutes(Integer.valueOf(bookingObj.Duration__c));
                }else if(duration > 0){
                    
                    bookingObj.End_Time__c = bookingObj.Start_Time__c.addMinutes(duration);
                }
                
            }
            if(String.isNotBlank(teacherId)){
                //if teacher is change then related teacher working hrs resource Id we are update in Booking Resource field 
                if(bookingObj.RecordType.Name == lessonRecordType){
                    bookingObj.Prev_Teacher__c = bookingObj.Teacher_Account__r.Name;
                    bookingObj.Teacher_Account__c = teacherId;
                }
            }
            if(bookingObj.Bookings1__r != null && bookingObj.Bookings1__r.size() > 0){
                for(Booking__c objBooking : bookingObj.Bookings1__r){
                    objBooking.Prev_Start_Time__c = bookingObj.Prev_Start_Time__c;
                    objBooking.Start_Time__c = bookingObj.Start_Time__c;
                    objBooking.Prev_Booking_Date__c = bookingObj.Prev_Booking_Date__c ;
                    objBooking.Booking_Date__c = bookingObj.Booking_Date__c;
                    objBooking.End_Time__c =   bookingObj.End_Time__c;
                    objBooking.Prev_Teacher__c =bookingObj.Prev_Teacher__c;
                    objBooking.Teacher_Account__c =  bookingObj.Teacher_Account__c;
                    if(objBooking.Type__c == ConstantsClass.typeRegular){
                        objBooking.Individual_Booking__c = true;
                    }
                    bookingList.add(objBooking);
                }
            }
            
        }else if(bookingObjList.size() > 0 && isFuture == 'true'){
             bookingObj = bookingObjList[0];
             if(bookingObj.Type__c == ConstantsClass.groupTypeBooking){
                String  oldTeacherId;
                Integer oldDuration;
                Time startTime;
                DateTime dateChange = DateTime.newInstance(Date.valueOf(startDate.split('T')[0]), Time.newInstance(0, 0, 0, 0));
                Boolean isDayChange = false;
                if(bookingObj.Booking_Date__c != dateChange.date()){
                    isDayChange = true;
                }
                Class__c classObj = new Class__c();
               //system.debug('bookingObj.Group_Class__c'+bookingObj.Class__c);
                if(String.isNotBlank(bookingObj.Class__c)){
                    List<Class__c> classlist= fetchGroupClass(bookingObj.Class__c);
                   //system.debug('classlist'+classlist);
                    if(classlist != null && classlist.size() > 0){
                        classObj = classlist[0];
                        oldTeacherId = classObj.teacher__c;
                        oldDuration = Integer.valueOf(classObj.Duration__c);  
                        startTime = classObj.Start_Time__c; 
                        //if teacher is change then related teacher working hrs resource Id we are update in Booking Resource field 
                        if(String.isNotBlank(teacherId)){
                            classObj.Teacher__c  = teacherId;
                        }
                        if(isDayChange){
                            classObj.Class_Date__c =  dateChange.date();
                        }
                        if(String.isNotBlank(startDate)){
                            classObj.Start_Time__c = Time.newInstance(Integer.valueOf(startDate.split('T')[1].split(':')[0]), Integer.valueOf(startDate.split('T')[1].split(':')[1]), Integer.valueOf(startDate.split('T')[1].split(':')[2]), 0); 
                        } 
                        if(String.isNotBlank(startDate)){
                            classObj.End_Time__c = classObj.Start_Time__c.addMinutes(Integer.valueOf(classObj.Duration__c));
                        } 
                        if(String.isNotBlank(classObj.Id)){
                            UPDATE classObj;
                           //system.debug('classObj'+classObj);
                           //commented by nishi:29-Sep-2020
                           RescheduleForAllFutureGroupClassBookings allReschedule = new RescheduleForAllFutureGroupClassBookings(isDayChange, classObj, dateChange.date(), bookingObj.Booking_Date__c);
                        }
                    }
                }
            }else if(bookingObj.Type__c == busyType){
                Date rescheduledDate =  Date.valueOf(startDate.split('T')[0]);
                Date bookingDate = bookingObj.Booking_Date__c;
                Integer daysdeff = bookingDate.daysBetween(rescheduledDate);
                
                for(Booking__c busyBookObj : AureusCalendarController.getFutureBusyBookings(BookingObj)){
                    duration =AureusCalendarController.getTimeStampBetween(busyBookObj.Start_Time__c, busyBookObj.End_Time__c);
                    if(String.isNotBlank(startDate)){
                        busyBookObj.Start_Time__c = Time.newInstance(Integer.valueOf(startDate.split('T')[1].split(':')[0]), Integer.valueOf(startDate.split('T')[1].split(':')[1]), Integer.valueOf(startDate.split('T')[1].split(':')[2]), 0);
                        busyBookObj.Booking_Date__c = busyBookObj.Booking_Date__c.addDays(daysdeff);
                    }
                    
                    if(String.isNotBlank(endDate)){
                        busyBookObj.End_Time__c = Time.newInstance(Integer.valueOf(endDate.split('T')[1].split(':')[0]), Integer.valueOf(endDate.split('T')[1].split(':')[1]), Integer.valueOf(endDate.split('T')[1].split(':')[2]), 0);
                    }else if(String.isBlank(endDate)){
                        busyBookObj.End_Time__c = busyBookObj.Start_Time__c.addMinutes(duration);
                    }
                        if(String.isNotBlank(teacherId) && teacherId != bookingObj.Teacher_Account__c && bookingObj.RecordType.Name == lessonRecordType){
                            busyBookObj.Teacher_Account__c = teacherId;
                        }
                    bookingList.add(busyBookObj); 
                }
            }
            
        }
        
        if(bookingObj != NULL && isFuture == 'false'){
            bookingList.add(bookingObj);
            oldBookList.add(oldBooking);
        }
        Booking__c placeholderObj = new Booking__c();
        if(bookingList.size() > 0 && placeholder == 'true'){
            placeholderList.addAll(AureusCalendarController.createPlaceholderForGroupClass(oldBookList, 'reschedule', startDate));
        }
        if(bookingList.size() > 0){
            Database.SaveResult[] saveResults = Database.update(bookingList, false);
            for(Database.SaveResult sr : saveResults){
               
                if(!sr.isSuccess()){
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                      //system.Debug('@@The following error has occurred.');                    
                      //system.Debug('@@@@'+err.getStatusCode() + ': ' + err.getMessage());
                      //system.Debug('@@@@Account fields that affected this error: ' + err.getFields());
                    }
                    isError = true;
                }
            }
        }
        
        if(placeholderList.size() > 0){
            insert placeholderList;
        }
        if(isError){
            objResult.msg = 'Some Error Occured';
        }else{
            // if(/*isFuture == 'false' && */bookingList.size() > 0 && bookingList[0].Type__c != ConstantsClass.typeBusy && redirectCase == 'true'){
            //     Case objCase =  AureusCalendarControllerHelper.createCase(caseId, bookingList[0].id,'Reschedule');
            //     objResult.caseId = objCase.Id;
            // }
            objResult.msg = 'Success';
        }
        
        return objResult;
    }
    public static List<Class__c> fetchGroupClass(string classId){
        return [SELECT Centre_Name__c, Package_Fee__c, Program__c, Unit_Fee__c, of_Units__c, Active__c, Class_Date__c, Class_Day__c, Class_End_Date__c,
                    Class_Start_Date__c, Class_Type__c, End_Time__c, Maximum_age__c, Minimum_age__c, Package__c, Start_Time__c, Teacher__c, Total_Capacity__c, 
                    Total_Enrolment__c, Duration__c,  Grade__c, Is_Makeup_Class__c, Name, Id ,Centre_Name__r.Organisation__r.Name
                    FROM Class__c
                    Where Id=:classId];

    }
    //@@jatin:17-Dec-2019:get All Group type students for manage available group lesson min.
    @RemoteAction
    public static String getGroupStudents(String studentName,string centerId,string groupAppointmentType,Boolean isOssia){
        string recordTypeCustomer = ConstantsClass.recordTypeCustomer;
        Map<Id, Integer> parentMakeupHours = new Map<Id, Integer>();
        List<Account> accList = new List<Account>();
        List<AureusCalendarController.Students> sObjList = new List<AureusCalendarController.Students>();
        AureusCalendarController.Students sObj = new AureusCalendarController.Students();
        List<String> listOfEnrolmentStudents = new List<String>(); 
         system.debug('!!!groupAppointmentType'+groupAppointmentType);
        system.debug('!!!studentName'+studentName);
        system.debug('!!!centerId'+centerId);
        if(groupAppointmentType.equalsIgnoreCase('MakeUp') || isOssia){
            For(Enrolment__c objEnrolment :[Select Id,Student__c 
                                                    From Enrolment__c
                                                    Where Class__C != Null
                                                    And type__c =: ConstantsClass.enrolGroupType]){
                listOfEnrolmentStudents.add(objEnrolment.Student__c);
            }
      
            if(listOfEnrolmentStudents!= null && listOfEnrolmentStudents.size() > 0){
                accList = [SELECT Id, Name, RecordType.Name, available_Make_up_mins_For_Group__c, Also_a_Student__c, Parent__c, 
                            Parent__r.available_Make_up_mins_For_Group__c, Parent__r.Name, PersonEmail, Parent__r.PersonEmail, PersonMobilePhone ,
                            Parent__r.PersonMobilePhone FROM
                            Account 
                            WHERE RecordType.Name =:recordTypeCustomer 
                            AND ((Also_a_Student__c = true AND Parent__c = NULL)
                            OR (Parent__c != NULL AND Also_a_Student__c = false)) 
                            AND Id IN :listOfEnrolmentStudents
                            AND (Name LIKE :'%'+studentName+'%')
                            /*AND Centre_Name__c=:centerId*/ LIMIT 10];
            //system.debug('!!!accList'+accList);
                if(accList != null && accList.size() >0 ){
                    for(Account acc : accList){
                        sObj = new AureusCalendarController.Students();
                        sObj.id = acc.Id;
                        sObj.label = acc.Name;
                        
                        if(acc.Also_a_Student__c && String.isBlank(acc.Parent__c)){
                            sObj.parentId = '';
                            sObj.parentName = '';
                            sObj.email = acc.PersonEmail;
                            sObj.phone = acc.PersonMobilePhone;
                            sObj.makeupHours = Integer.valueOf(acc.available_Make_up_mins_For_Group__c);
                        }else if(acc.Also_a_Student__c == false && String.isNotBlank(acc.Parent__c)){
                            sObj.parentId = acc.Parent__c;
                            sObj.parentName = acc.Parent__r.Name;
                            sObj.email = acc.Parent__r.PersonEmail;
                            sObj.phone = acc.Parent__r.PersonMobilePhone;
                            sObj.makeupHours = Integer.valueOf(acc.Parent__r.available_Make_up_mins_For_Group__c);
                        }
                        if(sObj.makeupHours == NULL){
                            sObj.makeupHours = 0;
                        }
                        sObjList.add(sObj);
                    }
                }
            }
            return JSON.serialize(sObjList);
        }else{
        return AureusCalendarController.getStudents(studentName);
        }
        
    }

    // nishi: 3-Nov-2020: for get Adhoc Group class Packages list If aureus organisation then we get package according to duration and center
    // If ossia organisation then we get pacakges according to instrument, grade and duration 
    @RemoteAction
    public static String getGroupAdhocPackagesList(string centerId,string groupClassid,Boolean isOssia){
        List<AdhocPackages> listOfAdhocPackages = new List<AdhocPackages>();
        AdhocPackages objAdhocPackages = new AdhocPackages();
        Map<String, Package__c> adhocPackageMap = new Map<String, Package__c>();
        if(string.isnotBlank(groupClassid)){
            Map<string,string> mapOfgradeInstruments = new Map<string,string>();
            if(isOssia){
                Set<string> gradeList = new Set<string>();
                Set<string> classInstrumentList= new Set<String>();
                List<Ossia_Group_Grade_Package__c> listOfclass =  [SELECT Class_Name__c, Package__c,Package__r.Duration__c,Package__r.name,  Name, Id ,
                                                                    Package__r.Program__r.Instrument__c,Class_Name__r.Grade__c
                                                                    FROM Ossia_Group_Grade_Package__c
                                                                    Where Class_Name__c =:groupClassId];
                if(listOfclass != null && listOfclass.size() > 0){
                    for(Ossia_Group_Grade_Package__c classObj : listOfclass ){
                        objAdhocPackages = new AdhocPackages();
                        objAdhocPackages.packageid = classObj.Package__c;
                        objAdhocPackages.packageName = classObj.Package__r.Name;
                        objAdhocPackages.packageDuration = classObj.Package__r.Duration__c;
                        objAdhocPackages.gradeList= classObj.Name;
                        objAdhocPackages.instrument= classObj.Package__r.Program__r.Instrument__c;
                        listOfAdhocPackages.add(objAdhocPackages);
                        /*commented by nishi: 5-Nov-2020:Packages defined in group class can be used instead of adhoc packages
                        if(string.isnotBlank(classObj.Class_Name__r.Grade__c) && classObj.Class_Name__r.Grade__c.split(';') != null && classObj.Class_Name__r.Grade__c.split(';').size() > 0){
                            gradeList.addAll(classObj.Class_Name__r.Grade__c.split(';'));
                        }
                        Set<string> grades = new Set<string>();
                        if(mapOfgradeInstruments.containsKey(classObj.Package__r.Program__r.Instrument__c)){
                            string gradeValue = mapOfgradeInstruments.get(classObj.Package__r.Program__r.Instrument__c);
                            grades.addAll(gradeValue.split('-'));
                        }
                        grades.addAll(classObj.Class_Name__r.Grade__c.split(';'));
                        mapOfgradeInstruments.put(classObj.Package__r.Program__r.Instrument__c,String.join(new list<string>(grades), '-'));*/
                    }
                }  
                /*commented by nishi: 5-Nov-2020:Packages defined in group class can be used instead of adhoc packages
                system.debug('mapOfgradeInstruments'+mapOfgradeInstruments);
                system.debug('gradeList'+gradeList);
                if(listOfclass != null && listOfclass.size() > 0){
                	adhocPackageMap = OssiaCenterCalendarController.fetchOssiaAdhocLessons(centerId,listOfclass[0].Package__r.Duration__c,mapOfgradeInstruments.keySet(),gradeList);
                }*/
            }else{
                List<class__c> classList = [select id,Package__c,Package__r.Duration__c,Package__r.name,Package__r.Program__r.Instrument__c from class__C where id=:groupClassId];
                if(classList != null && classList.size() > 0){
                    for(class__C classObj : classList ){
                        objAdhocPackages = new AdhocPackages();
                        objAdhocPackages.packageid = classObj.Package__c;
                        objAdhocPackages.packageName = classObj.Package__r.Name;
                        objAdhocPackages.packageDuration = classObj.Package__r.Duration__c;
                        objAdhocPackages.gradeList= '';
                        objAdhocPackages.instrument= classObj.Package__r.Program__r.Instrument__c;
                        listOfAdhocPackages.add(objAdhocPackages);
                    }
                    //commented by nishi: 5-Nov-2020:Packages defined in group class can be used instead of adhoc packages
                	//adhocPackageMap = OssiaCenterCalendarController.fetchAdhocLessons(centerId,classList[0].Package__r.Duration__c);
                }
            }
            /*commented by nishi: 5-Nov-2020:Packages defined in group class can be used instead of adhoc packages
            system.debug('adhocPackageMap'+adhocPackageMap);
            if(adhocPackageMap != null && adhocPackageMap.size() > 0){
                Set<string> packageIds = new Set<string>();
                for(Package__c objPackage  : adhocPackageMap.values()){
                    if(!packageIds.contains(objPackage.id)){
                        objAdhocPackages = new AdhocPackages();
                        objAdhocPackages.packageid = objPackage.id;
                        objAdhocPackages.packageName = objPackage.Name;
                        objAdhocPackages.packageDuration = objPackage.Duration__c;
                        objAdhocPackages.gradeList= mapOfgradeInstruments != null && mapOfgradeInstruments.size() > 0 && mapOfgradeInstruments.containsKey(objPackage.Program__r.Instrument__c) ? mapOfgradeInstruments.get(objPackage.Program__r.Instrument__c) :'' ;
                        objAdhocPackages.instrument= objPackage.Program__r.Instrument__c;
                        listOfAdhocPackages.add(objAdhocPackages);
                        packageIds.add(objPackage.id);
                    }
                }
            }*/
        }
        system.debug('listOfAdhocPackages'+listOfAdhocPackages);
         return JSON.serialize(listOfAdhocPackages);
    }

   
    public class AdhocPackages{
        Public string packageid;
        Public string packageName;
        Public string packageDuration;
        Public string gradeList;
        Public string instrument;
    }

    //@@jatin: 2-dec-2019: getLastLessonDate method is use for getting last date of lesson on selecting the withdraw end Date.
        
    @RemoteAction      
    public static AureusCalendarController.WithdrawalSummary getWithdrawGroupClassSummary(String bookingId, String withdrawEndDate, String lastLessonDate){
        AureusCalendarController.WithdrawalSummary withdrawSummary = new AureusCalendarController.WithdrawalSummary();
        Date withdrawEndDateObj, lastLessonDateObj, nextBillingDate;
        List<AureusCalendarController.Lessons> lastLessonsList = new List<AureusCalendarController.Lessons>();
        List<AureusCalendarController.Lessons> makeupPendingList = new List<AureusCalendarController.Lessons>();
        Enrolment__c enrolment;
        Country__c countryObj = new Country__c();
        
        if(String.isNotBlank(withdrawEndDate)){
            withdrawEndDateObj = Date.valueOf(lastLessonDate);
        }
        if(String.isNotBlank(lastLessonDate)){
            lastLessonDateObj = Date.valueOf(lastLessonDate);
        }
        if(String.isNotBlank(bookingId)){
            
            enrolment = AureusCalendarController.getEnrolDetails(bookingId);
            if(String.isNotBlank(enrolment.Center__r.Country__r.Id)){
                countryObj = enrolment.Center__r.Country__r;    
            }
            
        }
        
        if(String.isNotBlank(enrolment.Id)){
            nextBillingDate = AureusCalendarController.getNextBillingDate(enrolment.Id);
            if(String.isNotBlank(enrolment.Id) && lastLessonDateObj != NULL && nextBillingDate != NULL){
                withdrawSummary.lastLessons = getLast4Lessons(enrolment.Id, lastLessonDateObj, nextBillingDate);
                withdrawSummary.finalDeposits = AureusCalendarController.getFinalDepositSummary(withdrawSummary.lastLessons);
                withdrawSummary.makeupLessons = getPendingMakeupBookings(enrolment.Id, lastLessonDateObj);
            }
        }
        if(enrolment != NULL){
            Decimal total = 0, gst = 0;
            DateTime dt = DateTime.newInstance(enrolment.Lessons_Start_Date__c, enrolment.Lesson_Start_time__c);
            withdrawSummary.student = enrolment.student__r.Name;
            withdrawSummary.packageName = enrolment.Package__r.Name;
            withdrawSummary.centre = enrolment.Center__r.Name;
            withdrawSummary.LessonDay = dt.format('dd MMM, yyyy hh:mma');
            dt = DateTime.newInstance(withdrawEndDateObj, enrolment.Lesson_Start_time__c);
            withdrawSummary.noticeDate = dt.format('dd MMM, yyyy');
            dt = DateTime.newInstance(lastLessonDateObj, enrolment.Lesson_Start_time__c);
            withdrawSummary.lastDate = dt.format('dd MMM, yyyy');
            withdrawSummary.deposit =   AureusCalendarController.getDepositFromFile(enrolment.id);     //enrolment.Package__r.Deposit_Fee__c;
            if(withdrawSummary.finalDeposits != NULL && withdrawSummary.finalDeposits.size() != 0){
                for(AureusCalendarController.Lessons currentLesson : withdrawSummary.finalDeposits){
                    total += currentLesson.unitPrice;
                }
                if(total > 0 && countryObj.Tax_Rate__c > 0){
                    gst = total  * (countryObj.Tax_Rate__c / 100);
                }
            }
            withdrawSummary.refund = 0;
            withdrawSummary.total = total + gst;
            withdrawSummary.gst = gst;
            if(withdrawSummary.deposit > 0){
                withdrawSummary.refund = withdrawSummary.deposit - withdrawSummary.total;
            }
            //System.debug('lastLessonDateObj'+lastLessonDateObj);
            String chargeId = AureusCalendarController.fetchCurrentMonthPaymentEntry(enrolment,lastLessonDateObj);
            if(String.isNotBlank(chargeId) && (lastLessonDateObj < nextBillingDate)){
                withdrawSummary.refund += getLessonRefundAmount(enrolment,lastLessonDateObj);   
                  //start:  added by nishi: 21-sep-2020: if next Billing date is greated then next month
                  date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1); // 1-10-2020
                  if(nextBillingDate >= nextMonthDate && lastLessonDateObj.Month() < nextMonthDate.addMonths(-1).Month()){ 
                      withdrawSummary.refund += getLessonRefundAmount(enrolment,nextMonthDate.addMonths(-1));  
                  }
                  //start:  added by nishi: 21-sep-2020: if next Billing date is greated then next month     
            }
        }
        return withdrawSummary;
    }

    // @@jatin:26-dec-2019 for withdrawal group lesson get Lesson Refund Amount according to group lesson bookings
    public static Decimal getLessonRefundAmount(Enrolment__c objEnrol,Date lastLessonDate){
        Decimal amount = 0;
        List<Booking__c> bookings = getCurrentBilledBooking(objEnrol.id,lastLessonDate);
        Integer count= 0;
        for(Booking__c objBook : bookings){
            if(objBook.booking_date__c > lastLessonDate){
                count+=1;
            }
        }
        if(count >0){
            amount = count * objEnrol.package__r.unit_fee__c;
            if(objEnrol.Center__r != null 
            && objEnrol.Center__r.Country__r != null 
            && objEnrol.Center__r.Country__r.Tax_Rate__c != null
            && objEnrol.Center__r.Country__r.Tax_Rate__c > 0){
                amount+= (amount  * objEnrol.Center__r.Country__r.Tax_Rate__c)  / 100;
            }
            
        }
        return amount;
    }
      // @@jatin:26-dec-2019 : return currentBilledBookings
    private static List<Booking__c> getCurrentBilledBooking(String enrolId,Date lastLessonDate){
        Date firstDate = Date.newInstance(lastLessonDate.year(),lastLessonDate.month(),01);
        Date lastDate = firstDate.addMonths(1).addDays(-1);
        return [SELECT Booking_Date__c 
                FROM Booking__c
                WHERE Enrolment__c=: enrolId 
                AND Booking_Date__c >=: firstDate 
                AND Booking_Date__c <=: lastDate
                AND (Type__c =: ConstantsClass.groupLessonTypeBooking) 
                //commented by :jatin: 7-Jan-2020: for show all type of bookings
                //AND (Status__c = :ConstantsClass.statusScheduled OR Status__c = :ConstantsClass.statusPending)
                ];
    }   
    // @@jatin:26-dec-2019 for withdrawal group lesson get last 4 lesson 
    public static List<AureusCalendarController.Lessons> getLast4Lessons(String enrolId, Date lastLessonDateObj, Date nextBillingDate){
            Map<String, String> mapOfInvoiceName = new Map<String, String>();
            mapOfInvoiceName = AureusCalendarController.getInvoiceFromEnrolment(enrolId);
            List<AureusCalendarController.Lessons> lessonsList = new List<AureusCalendarController.Lessons>();
            AureusCalendarController.Lessons lesson = new AureusCalendarController.Lessons();
            Set<String> bookingIdSet = new Set<String>();
            List<AureusCalendarController.Lessons> reverselessonList = new List<AureusCalendarController.Lessons>();
            Set<String> bookingStatus = new Set<String>();
            
            bookingStatus.add(ConstantsClass.statusScheduled); 
            bookingStatus.add(ConstantsClass.statusPending);
            bookingStatus.add(ConstantsClass.statusCompleted);
            bookingStatus.add(ConstantsClass.statusNoshow);
            
            Datetime formatedDate;
            
            for(Booking__c bookObj : [SELECT Id, Name, type__c, Status__c, Booking_Date__c, Start_Time__c, Duration__c, Package__c,
                                    Package__r.Name, Package__r.Unit_Fee__c, Student__r.Name 
                                    FROM Booking__c 
                                    WHERE Enrolment__c =: enrolId 
                                    AND Type__c =: ConstantsClass.groupLessonTypeBooking 
                                    AND Booking_Date__c <= :lastLessonDateObj 
                                    ORDER BY Booking_Date__c DESC LIMIT 4]){
                                        lesson = new AureusCalendarController.Lessons();
                                        bookingIdSet.add(bookObj.Id);                          
                                        formatedDate = DateTime.newInstance(bookObj.Booking_Date__c, bookObj.Start_Time__c);
                                        lesson.bookingId = bookObj.Id;
                                        lesson.Lesson = bookObj.Package__r.Name;
                                        lesson.bookingDate = formatedDate.format('dd MMM, yyyy');
                                        lesson.bookingTime = formatedDate.format('hh:mma');
                                        lesson.duration = bookObj.Duration__c;
                                        lesson.unitPrice = bookObj.Package__r.Unit_Fee__c;
                                        lesson.student = bookObj.Student__r.Name;
                                        lesson.qty = 1;
                                        if(bookObj.Booking_Date__c < nextBillingDate){
                                            if(mapOfInvoiceName.keyset().size() > 0){
                                                lesson.status = mapOfInvoiceName.get('Id')+':'+ mapOfInvoiceName.get('Name');
                                            }else{
                                                lesson.status = 'Billed';
                                            }
                                            
                                        }else if(bookObj.Booking_Date__c >= nextBillingDate){
                                            lesson.status = 'Deposit';
                                        }
                                        reverselessonList.add(lesson); 
                                    }
            if(reverselessonList.size() > 0){
                for(integer i = reverselessonList.size() - 1; i >= 0; i--){
                    lessonsList.add(reverselessonList[i]);
                }
            }
            
            return lessonsList;
        }  


    // @@jatin: 26-dec-2019: for withdrawal group lesson  get Pending Makeup Bookings
    public static List<AureusCalendarController.Lessons> getPendingMakeupBookings(String enrolId, Date lastLessonDateObj){
        List<AureusCalendarController.Lessons> lessonsList = new List<AureusCalendarController.Lessons>();
        AureusCalendarController.Lessons lesson = new AureusCalendarController.Lessons();
        Set<String> bookingTypes = new Set<String>();
        bookingTypes.add(ConstantsClass.groupLessonTypeBooking);
        String statusCanceled = ConstantsClass.statusCanceled;
        Datetime formatedDate, lastDateObj;
        lastDateObj = DateTime.newInstance(lastLessonDateObj, Time.newInstance(0, 0, 0, 0));
        for(Booking__c bookObj : [SELECT Id, Student__r.Name, Booking_Date__c, Canceled_Date__c, Start_Time__c, 
                                    Available_Make_up_Units__c, Make_up_Expiry_Date__c 
                                    FROM Booking__c
                                    WHERE enrolment__c =: enrolId 
                                    AND Type__c IN: bookingTypes 
                                    AND Status__c =: statusCanceled 
                                    AND Available_Make_up_Units__c > 0 
                                    AND Make_up_Expiry_Date__c >= TODAY 
                                    ORDER BY Canceled_Date__c]){
            lesson = new AureusCalendarController.Lessons();
            formatedDate = DateTime.newInstance(bookObj.Booking_Date__c, bookObj.Start_Time__c);
            lesson.bookingId = bookObj.Id;
            lesson.duration = bookObj.Available_Make_up_Units__c;
            lesson.bookingTime = formatedDate.format('hh:mma');
            lesson.student = bookObj.student__r.Name;
            
            if(bookObj.Canceled_Date__c != NULL){
                
                DateTime bookingDate = DateTime.newInstance(bookObj.Booking_Date__c, Time.newInstance(0, 0, 0, 0));
                lesson.cancelDate = bookingDate.format('dd MMM, yyyy'); 
            }else{
                lesson.cancelDate = '';
            }
            
            formatedDate = DateTime.newInstance(bookObj.Make_up_Expiry_Date__c, bookObj.Start_Time__c);
            lesson.expiryDate = formatedDate.format('dd MMM, yyyy');
            lesson.nextExpiryDate = lastDateObj.format('dd MMM, yyyy');
            lessonsList.add(lesson);
        }
        return lessonsList;
    }  
    // @@jatin: 26-dec-2019: for withdrawal group lesson  type booking 
     @RemoteAction
    public static String cancelGroupLessonSubscriptionRequest(String bookingId, String endDate, String lastLessonDate, String myCase, String redirectCase){
        String caseIdToReturn;
        if(String.isNotBlank(bookingId)){
                IAdvanceAction withdrawlPackageObj;
                withdrawlPackageObj = new WithDrawlEnrolmentClassProcessController(bookingId, endDate, lastLessonDate, 
                                                                         myCase,redirectCase);
                caseIdToReturn = WithdrawlPackageObj.initProcess();
        }
        return caseIdToReturn;
    }
    //@jatin:03-Dec-2019 : for manage upgrade group class bookings  
    @RemoteAction
    public static String upgradePackageClassOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                 Map<String, String> caseValues,string oldClassId,String newClassId,string newTeacherId){
                                                     String caseIdToReturn;
                                                     if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                        String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)&& String.isNotBlank(oldClassId) && String.isNotBlank(newClassId)
                                                        && String.isNotBlank(newTeacherId)  ){
                                                            IAdvanceAction upgradePackageObj;
                                                            upgradePackageObj = new UpgradeEnrolmentClassProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                                                                                oldPackageId,newTeacherId, timeSlot, myCaseId, caseRedirect, 
                                                                                                                                caseValues,oldClassId, newClassId);
                                                            caseIdToReturn = upgradePackageObj.initProcess();
                                                     }
                                                     return caseIdToReturn;
    }

    //@jatin:04-Jan-2019 : for manage update group class to same other class bookings  
    @RemoteAction
    public static String updateGroupClassToSamePackageOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                 string oldClassId,String newClassId,string newTeacherId){
                                                     String caseIdToReturn;
                                                     if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                        String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)&& String.isNotBlank(oldClassId) && String.isNotBlank(newClassId)
                                                        && String.isNotBlank(newTeacherId)  ){
                                                            IAdvanceAction upgradePackageObj;
                                                            upgradePackageObj = new UpdateEnrolmentClassProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                                                                                oldPackageId,newTeacherId, timeSlot, myCaseId, caseRedirect, 
                                                                                                                                oldClassId, newClassId);
                                                            caseIdToReturn = upgradePackageObj.initProcess();
                                                     }
                                                     return caseIdToReturn;
    }

      //@jatin:12-Nov-2020 : for manage Change center group class to same other class bookings  
      @RemoteAction
      public static String ChangeCenterGroupToSamePackageOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                   String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                   string oldClassId,String newClassId,string newTeacherId,String oldCenterId,string newCenterId){
                                                       String caseIdToReturn;
                                                      /* commmented by nishi:23-Nov-2020: for deployment of the Ossia enhancements not include anything from Enhancements part -2 
                                                      if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                          String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)&& String.isNotBlank(oldClassId) && String.isNotBlank(newClassId)
                                                          && String.isNotBlank(newTeacherId) && String.isNotBlank(oldCenterId) && String.isNotBlank(newCenterId)  ){
                                                              IAdvanceAction upgradePackageObj;
                                                              upgradePackageObj = new ChangeCenterClassProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                                                                                  oldPackageId,newTeacherId, timeSlot, myCaseId, caseRedirect, 
                                                                                                                                  oldClassId, newClassId,oldCenterId,newCenterId);
                                                              caseIdToReturn = upgradePackageObj.initProcess();
                                                       }commmented by nishi:23-Nov-2020: for deployment of the Ossia enhancements not include anything from Enhancements part -2 */
                                                       return caseIdToReturn;
      }

    //@jatin:24-Dec-2019 : for manage upgrade To Individual Class Of Customer bookings  
    @RemoteAction
    public static String upgradeToIndividualClassOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                 Map<String, String> caseValues,string oldTeacherId,String newTeacherId){
                                                     String caseIdToReturn;
                                                     if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                                                        String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)&& String.isNotBlank(oldTeacherId) && String.isNotBlank(newTeacherId)  ){
                                                            IAdvanceAction upgradePackageObj;
                                                            upgradePackageObj = new UpgradeToIndividualProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                                                                                oldPackageId, timeSlot, myCaseId, caseRedirect, 
                                                                                                                                caseValues, newTeacherId);
                                                            caseIdToReturn = upgradePackageObj.initProcess();
                                                     }
                                                     return caseIdToReturn;
    }

// @jatin 28-Nov-2019 : get summary with new and old class details
    @RemoteAction
    public static AureusCalendarController.UpgradeDowngradePackageSummary  getUpgradeGroupClassPackageSummary(String oldPackageId, String newPackageId, 
                                                                                    String currentEffectiveDateObj,String newEffectiveDate,
                                                                                     String availTimeSlots, String oldavailableTimeSlots,
                                                                                    String enrolmentId, String typeOfSummary,
                                                                                    string newTeacher,string oldTeacher,
                                                                                    String oldClassId,string newClassId,
                                                                                    String newcenter,string oldCenter){
        Map<String, String> enrolSummary = new Map<String, String>();
        DateTime newDateTime;
        DateTime currentDateTime;
        Date nextBillDate;
        Package__c newPackg, oldPackg = new Package__c();
        Integer minutesOfFifthBooking = 0;
        Integer countWithNewPackage = 0;
        List<Enrolment__c> enrolmentList = new List<Enrolment__c>(); 
        AureusCalendarController.UpgradeDowngradePackageSummary summary = new AureusCalendarController.UpgradeDowngradePackageSummary();
        Set<id> setOfClassIds = new Set<Id>();
                                                                                       //system.debug('!!oldClassId'+oldClassId);
                                                                                       //system.debug('!!newClassId'+newClassId);
        if(String.isNotBlank(oldClassId) && String.isNotBlank(newClassId) &&   (typeOfSummary == 'GroupToHigherPackage' || typeOfSummary == 'GroupToSameClass' || typeOfSummary == 'GroupToChangeCenter' )){
            setOfClassIds.add(oldClassId);
            setOfClassIds.add(newClassId);
        }
        
        if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
            summary = AureusCalendarController.getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
            newPackg = summary.newPackage;
            oldPackg = summary.oldPackage;            
        }
         /*jatin:24-dec-2019: for upgrade to individual booking add teachers  */
        if(string.isNotBlank(newTeacher) && string.isNotBlank(oldTeacher) ){
            set<String> teacherIds = new Set<String>{newTeacher,oldTeacher};
            if(string.isNotBlank(newcenter) && typeOfSummary == 'GroupToChangeCenter'){
                teacherIds.add(newcenter);
            }
            Map<String,Account> mapOfAccount = New Map<String,Account>([Select id,Name from Account where Id in :teacherIds]);
            if(mapOfAccount.containsKey(newTeacher)){
                summary.newTeacherName = mapOfAccount.get(newTeacher).Name;
                summary.newTeacherId = mapOfAccount.get(newTeacher).Id;
            }
            if(mapOfAccount.containsKey(oldTeacher)){
                summary.oldTeacherName = mapOfAccount.get(oldTeacher).Name;
                summary.oldTeacherId = mapOfAccount.get(oldTeacher).Id;
            }
            if(mapOfAccount.containsKey(newcenter) && typeOfSummary == 'GroupToChangeCenter'){
                summary.newCenterName = mapOfAccount.get(newcenter).Name;
                summary.newCenterId = mapOfAccount.get(newcenter).Id;
            }
            
        }
        // @jatin 28-Nov-2019 : added new and old class details
        if(setOfClassIds != null && setOfClassIds.size() >0 &&  (typeOfSummary == 'GroupToHigherPackage' || typeOfSummary == 'GroupToSameClass'|| typeOfSummary == 'GroupToChangeCenter' )){
            map<id,Class__c> mapOfClasses = new Map<Id,class__c>([Select id, name from Class__c where id in:setOfClassIds]);
            if(mapOfClasses != null && mapOfClasses.size() >0 ){
                if(mapOfClasses.containsKey(newClassId)){
                    summary.newClassName = mapOfClasses.get(newClassId).Name;
                    summary.newClassId = mapOfClasses.get(newClassId).id;
                }
                if(mapOfClasses.containsKey(oldClassId)){
                    summary.oldClassName = mapOfClasses.get(oldClassId).Name;
                    summary.oldClassId = mapOfClasses.get(oldClassId).id;
                }
            }
        }
        if(String.isNotBlank(enrolmentId)){
            summary.currentPackageDeposit = AureusCalendarController.getDepositFromFile(enrolmentId);
            enrolSummary = AureusCalendarController.getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
            if(enrolSummary.containsKey('currentCenterName')){
                summary.oldCenterName = enrolSummary.get('currentCenterName');
            }
            if(enrolSummary.containsKey('currentCenter')){
                summary.oldCenterId = enrolSummary.get('currentCenter');
            }
           if(enrolSummary.containsKey('currentTeacher')){
                summary.oldTeacherName = enrolSummary.get('currentTeacher');
            }
            if(enrolSummary.containsKey('currentClass')){
                summary.oldClassId = enrolSummary.get('currentClass');
            } // @jatin: 4:Jan:2020 : for show Class name in upgrade group class
            if(enrolSummary.containsKey('currentClassName')){
                summary.oldClassName = enrolSummary.get('currentClassName');
            }
            if(enrolSummary.containsKey('currentTeacherId')){
                summary.oldTeacherId = enrolSummary.get('currentTeacherId');
            }
            if(enrolSummary.containsKey('currentMonthInvoice')){
                summary.invoiceForCurrentMonth = Decimal.valueOf(enrolSummary.get('currentMonthInvoice'));
            }
            if(enrolSummary.containsKey('studentName')){
                summary.studentName = enrolSummary.get('studentName');
            }
            if(enrolSummary.containsKey('parentName')){
                summary.parentName = enrolSummary.get('parentName');
            }
            enrolmentList = AureusCalendarController.getNextBillingDateSubscription(enrolmentId);
            if(enrolmentList.size() > 0){
                nextBillDate = AureusCalendarController.getNextBillingSubscriptionLineItemDate(enrolmentList);
            } 
        }
        
        
        if(String.isNotBlank(newEffectiveDate) && String.isNotBlank(availTimeSlots)){
            newDateTime = AureusCalendarController.getDateTimeFromString(availTimeSlots);
            newDateTime = DateTime.newInstance(Date.valueOf(newEffectiveDate), newDateTime.time());
            //summary.newDayAndTime = newDateTime.format('EEE, MMM dd YYYY h:mm a');
            summary.newDayAndTime = newDateTime.format('EEE @ h:mm a');
            summary.effectiveDate = newDateTime.format('EEE, MMM dd YYYY');
        }
        if(String.isNotBlank(currentEffectiveDateObj)  && String.isNotBlank(oldavailableTimeSlots) ){
            currentDateTime = AureusCalendarController.getDateTimeFromString(oldavailableTimeSlots.trim());
            currentDateTime = DateTime.newInstance(Date.valueOf(currentEffectiveDateObj), currentDateTime.time());
            summary.currentDayAndTime = currentDateTime.format('EEE @ h:mm a');
            summary.currentEffectiveDate = currentDateTime.format('EEE, MMM dd YYYY');
        }
        if((typeOfSummary == 'upgrade class' || typeOfSummary == 'GroupToIndividual' || typeOfSummary == 'GroupToHigherPackage' ) && newDateTime != NULL && String.isNotBlank(enrolmentId)){
            List<Date> dates = AureusCalendarController.getMonthDates(newDateTime);
            List<Booking__c> listOfBookings = fetchBookingsForUpgrade(enrolmentId, dates);
            for(Booking__c objBooking : listOfBookings){
                if(objBooking.Booking_Date__c >= newDateTime.date()){
                    if(objBooking.Type__c == ConstantsClass.groupLessonBookingRecordType){
                        countWithNewPackage +=1;
                    }
                }
            }
            
            Decimal totalAmount = 0;
            Decimal depositeFee = (newPackg.Deposit_Fee__c - summary.currentPackageDeposit);
            summary.invoiceDepositTopup = depositeFee;
            Decimal newPackageUnitPrice = (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c)*countWithNewPackage ;
            
            
            if(typeOfSummary =='upgrade class' || typeOfSummary =='GroupToIndividual' || typeOfSummary == 'GroupToHigherPackage' ){
                if(summary.taxRate>0){
                    newPackageUnitPrice += newPackageUnitPrice * Decimal.valueOf(summary.taxRate)/100;
                }
                //summary.invoiceDepositLessonTopup = BillingUtility.roundOffAmount(newPackageUnitPrice);
                totalAmount = BillingUtility.roundOffAmount(newPackageUnitPrice);
                totalAmount +=   BillingUtility.roundOffAmount(depositeFee) ;
                if(newDateTime <= nextBillDate){
                   
                     // added by Nishi: 21-Sep-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
                        //  ex: 12-Aug-2020 effective date and next Billing date 01-Oct-2020 
                        date nextMonthDate = Date.newInstance(system.today().addMonths(2).year(),system.today().addMonths(2).Month(),1);
                        Integer countWithNextPackage = 0;
                        Decimal nextPackageUnitPrice =0;
                        if(nextBillDate >= nextMonthDate && newDateTime.month() < nextMonthDate.addMonths(-1).month()){
                            if(String.isNotBlank(enrolmentId)){
                                List<Booking__c> nextMonthlistOfBookings =UpgradeDowngradeController.fetchListOfNextMonthBookings(enrolmentId);
                                //system.debug('nextMonthlistOfBookings'+nextMonthlistOfBookings);
                                for(Booking__c objBooking : nextMonthlistOfBookings){
                                    if(objBooking.Booking_Date__c <= nextMonthDate){
                                        if(objBooking.Type__c == ConstantsClass.groupLessonTypeBooking ){
                                            countWithNextPackage += 1;
                                        }
                                    }
                                }
                            }
                            nextPackageUnitPrice = (newPackg.Unit_Fee__c - oldPackg.Unit_Fee__c)*countWithNextPackage ;
                            Decimal nextPackageFacilityPrice = 0;
                            if(summary.taxRate > 0 && nextPackageUnitPrice > 0){
                                nextPackageUnitPrice += nextPackageUnitPrice * (Decimal.valueOf(summary.taxRate)/100);
                            }
                            totalAmount +=   nextPackageUnitPrice ;
                        }
                        // added by Nishi: 21-Sep-2020: if next billing date is greater then next month then we create new invoice for adjuct new upgraded package unitfee 
                        summary.invoiceTopup = BillingUtility.roundOffAmount(totalAmount);
                        summary.invoiceDepositLessonTopup = BillingUtility.roundOffAmount(newPackageUnitPrice+nextPackageUnitPrice);
                }else{
                    summary.invoiceTopup = BillingUtility.roundOffAmount(depositeFee);
                    summary.invoiceDepositLessonTopup = 0;
                }
            }
            
        }
        system.debug('@@summary'+summary);
        return summary;
    }
    public  static List<Booking__c> fetchBookingsForUpgrade(String enrolmentId, List<Date> dates){
        return [SELECT Id,Booking_Date__c,Is_Fifth_Booking__c,Type__c 
                FROM Booking__c 
                WHERE Enrolment__c=:enrolmentId AND 
                Booking_Date__c IN: dates 
                //jatin:7-jan-2020 : for now we calculate all booking 
                //AND Status__c !=: ConstantsClass.statusCanceled 
                AND Type__c =: ConstantsClass.groupLessonBookingRecordType];
    }
    
    //@@jatin:20-dec-2019: for get enrollment for group lesson convert regular booking
    @RemoteAction
    public static AureusCalendarController.EnrolmentEdit getGroupLessonEnrolmentUpdateDetails(String enrolmentId,string grade){
        AureusCalendarController.EnrolmentEdit enrolEdit = new AureusCalendarController.EnrolmentEdit();
        Map<String, String> enrolDetails = new Map<String, String>();
        if(String.isNotBlank(enrolmentId)){
            enrolDetails = AureusCalendarController.getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
            if(enrolDetails.containsKey('currentTeacher')){
                enrolEdit.currentTeacher = enrolDetails.get('currentTeacher');
            } 
            if(enrolDetails.containsKey('currentPackage')){
                enrolEdit.currentPackage = enrolDetails.get('currentPackage');
            } 
            if(enrolDetails.containsKey('currentDay')){
                enrolEdit.currentDayTimeSlot = enrolDetails.get('currentDay');
            }   
            if(enrolDetails.containsKey('currentPackageDuration')){
                enrolEdit.duration = Integer.valueOf(enrolDetails.get('currentPackageDuration'));
            }
            if(enrolDetails.containsKey('currentLessonDay')){
                enrolEdit.currentWeekDay = enrolDetails.get('currentLessonDay');
            }
             if(enrolDetails.containsKey('currentWeekDay')){
                enrolEdit.currentWeekDay = enrolDetails.get('currentWeekDay');
            }
            // @jatin:19-dec-2019: added instument for group class upgrade to regular user get packages list according to instruments
       
            if(enrolDetails.containsKey('instrument')){
                enrolEdit.currentInstrument = enrolDetails.get('instrument');
            }
           
            enrolEdit.currentTeacherId = enrolDetails.containsKey('currentTeacherId') ? enrolDetails.get('currentTeacherId') : '';
            enrolEdit.currentPackageId = enrolDetails.containsKey('currentPackageId') ? enrolDetails.get('currentPackageId') : '';
            
            if(enrolDetails.containsKey('currentCenter')){
                enrolEdit.center = enrolDetails.get('currentCenter');
                  //start: added by nishi: 12-Nov-2020: for get All center accoding to organisation
                  enrolEdit.centerName = enrolDetails.get('currentCenterName');
                  enrolEdit.centers = new List<AureusCalendarController.Data>();
                 List<AureusCalendarController.Data> multipleCentersData = new List<AureusCalendarController.Data>();
                 AureusCalendarController.Data centerdata = new AureusCalendarController.Data();
                 List<Account> centers = AureusCalendarController.getOrganisationRelatedCenters(enrolDetails.get('currentOrganisation'));
                 for(Account center : centers){
                     centerdata = new AureusCalendarController.Data();
                     centerdata.Id = center.Id;
                     centerdata.name = center.Name;
                     multipleCentersData.add(centerdata); 
                 }    
                 if(multipleCentersData.size() > 0){
                     enrolEdit.centers = multipleCentersData;
                 }
                  //end added by nishi: 12-Nov-2020: for get All center accoding to organisation
                enrolEdit.teachers = new List<AureusCalendarController.Data>();
                List<AureusCalendarController.Data> multipleData = new List<AureusCalendarController.Data>();
                AureusCalendarController.Data data = new AureusCalendarController.Data();
                // @@jatin: 3-JAN-2020: for show different teacher according to grade condintion
                //GroupToIndividual = show all teachers according to current center
                //'GroupToSameClass' = show teacher accrording to group class teachers
                //GroupToHigherPackage = same as GroupToSameClass teachers
                List<Account> teachers = new List<Account>();
                if(grade.equalsIgnoreCase('GroupToIndividual')){
                    teachers = AureusCalendarControllerHelper.getListOfTeacher(enrolDetails.get('currentCenter'));
                }else if(grade.equalsIgnoreCase('GroupToSameClass') || grade.equalsIgnoreCase('GroupToHigherPackage')){
                    //21-Sep-2020:nishi:start: show check enrolment is related to ossia group class then we get teacher accoding to Ossia_Group_Grade_Package__c child records
                    Boolean isOssia = enrolDetails.containsKey('isOssia')  ? Boolean.valueOf( enrolDetails.get('isOssia')) : false;
                    if(isOssia){
                        teachers = OssiaCenterCalendarController.getListOfOssiaClassTeacher(enrolDetails.get('currentCenter'), enrolEdit.currentPackageId,grade);
                    }else{
                        teachers = getListOfClassTeacher(enrolDetails.get('currentCenter'), enrolEdit.currentPackageId,grade);
                    }
                     //21-Sep-2020:nishi:end: show check enrolment is related to ossia group class then we get teacher accoding to Ossia_Group_Grade_Package__c child records
                }
                //commented by jatin: for now w get all teachers 
                //List<Account> teachers = AureusCalendarControllerHelper.getListOfTeachersByInstrument(enrolDetails.get('currentCenter'),enrolDetails.get('instrument'));
                if(teachers != null && teachers.size() > 0){
                    for(Account teacher : teachers){
                        data = new AureusCalendarController.Data();
                        data.Id = teacher.Id;
                        data.name = teacher.Name;
                        multipleData.add(data); 
                    }    
                }
                if(multipleData.size() > 0){
                    enrolEdit.teachers = multipleData;
                }
            }       
        }
        return enrolEdit; 
    }
    
    // show teachers list according to selected Advance action button if click GroupToSameClass then show same package fee reocrds
    // and GroupToHigherPackage show higher package fee records
    private static List<Account> getListOfClassTeacher(string centerId,string packageId,string changeEnrolType){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        Set<String> teachersIdSet = new Set<String>();
         Map<Id,Account> mapOfGroupClassTeachers = New  Map<Id,Account>();
        if(String.isNotBlank(centerId)){
            List<Teacher_Working_Hour__c> teacherWorkingHourList = new List<Teacher_Working_Hour__c>();
            teacherWorkingHourList = [SELECT id, Center_Name__c, Teacher_Name__c, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__c =: centerId ];
            for(Teacher_Working_Hour__c twh : teacherWorkingHourList){
                teachersIdSet.add(twh.Teacher_Name__c);
            }
        }
        
        String query = '';             
        if(teachersIdSet.size() > 0){
            query = 'SELECT Id, Name,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c FROM Account WHERE RecordType.Name =: teacherRecType AND Status__c =: teacherWorkingStatus';
            query+= ' AND id IN : teachersIdSet';
            query+= ' ORDER BY Name';
        }
        if(String.isNotBlank(query) && String.isNotBlank(centerId) && String.isNotBlank(packageId)){
            Map<Id,Account> mapOfTeachers = New  Map<Id,Account>();
            set<string>instruments = new set<string>();
            map<string,set<string>> mapOfInstruments = new map<string,set<string>> ();
            for(account objTeacher : Database.query(query)){
                mapOfTeachers.put(objTeacher.id,objTeacher);
                instruments = new set<string>();
                if(mapOfInstruments.containsKey(objTeacher.id)){
                    instruments.addAll(mapOfInstruments.get(objTeacher.id));
                }
                if(objTeacher.Major_Instruments_Disciplines__c != null){       
                        for(String strIns : objTeacher.Major_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                    if(objTeacher.Minor_Instruments_Disciplines__c != null){       
                        for(String strIns : objTeacher.Minor_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }
                mapOfInstruments.put(objTeacher.id,instruments);     
            }
            // 7-jan:2020: show teacher according to active classes
            if(mapOfTeachers != null && mapOfTeachers.size() >0){
                Package__c objpackage = [SELECT id,Package_Fee__c 
                                        From Package__c
                                        WHERE Id=: packageId];
                string queryClass= 'Select Id,Teacher__c,Package__r.Program__r.Instrument__c From Class__c Where Available_Capacity__c > 0 ';
                If(string.isNotBlank(centerId)){
                    queryClass += ' And Centre_Name__c =:centerId ';
                }
                If(mapOfTeachers != null && mapOfTeachers.size() > 0){
                    set<Id> teacherIds = mapOfTeachers.keySet();
                    queryClass += ' AND Teacher__c In:teacherIds ';
                }
                If(string.isNotBlank(objpackage.Id) && objpackage.Package_Fee__c != null && objpackage.Package_Fee__c > 0 ){
                    decimal packageFee = objpackage.Package_Fee__c;
                    if(changeEnrolType.equalsIgnoreCase('GroupToSameClass') ){
                        queryClass += ' AND package__r.Package_Fee__c =: packageFee ';
                    }else if(changeEnrolType.equalsIgnoreCase('GroupToHigherPackage')){
                        queryClass += ' AND package__r.Package_Fee__c >: packageFee ';
                    }
                }
                List<CLass__c> listOfCLass = DataBase.Query(queryClass);
                if(listOfCLass != null && listOfCLass.size() > 0){
                    for(CLass__C objClass :listOfCLass){
                        if(mapOfTeachers.containsKey(objClass.Teacher__c) && mapOfInstruments.containsKey(objClass.Teacher__c)){
                            if(mapOfInstruments.get(objClass.Teacher__c).contains(objClass.Package__r.Program__r.Instrument__c)){
                                mapOfGroupClassTeachers.put(objClass.Teacher__c,mapOfTeachers.get(objClass.Teacher__c));
                            }
                        }
                    }
                }
            }
        }
        if(mapOfGroupClassTeachers != null && mapOfGroupClassTeachers.size() > 0){
            return mapOfGroupClassTeachers.values();
        }
        return new List<Account>();
    }
   //@@jatin-19-dec-2019: for get packages according to teacher or previous instrument
   @RemoteAction
    public static List<AureusCalendarController.Data> getPackageAccordingToTeacherOrInstrument(String centerId,Integer duration,
                                                                                                string instrument){
        List<AureusCalendarController.Data> packageList = new List<AureusCalendarController.Data>();
        AureusCalendarController.Data dt = new AureusCalendarController.Data();
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
        if(String.isNotBlank(instrument)&& String.isNotBlank(centerId)){        
            for(Package__c pkg : [SELECT Id, Name FROM Package__c
                                    WHERE Location__c =: centerId 
                                    AND Program__r.Status__c =: ConstantsClass.activeStatus  
                                    AND Program__r.Instrument__c =: instrument       
                                    AND Program__r.Billing__c != null 
                                    AND Program__r.Scheduling__c != null 
                                    AND Active__c = True
                                    AND (Type__c = 'Individual' OR Type__c = 'Home') AND 
                                    RecordtypeId =: pkgLessRecId 
                                    AND Duration__c >=: string.valueOf(duration)
                                    AND Type_of_package__c = 'Normal'
                                    ORDER BY Program__r.Name]){
                                        dt = new AureusCalendarController.Data();
                                        dt.Id = pkg.Id;
                                        dt.name = pkg.Name;
                                        packageList.add(dt);
                                    }    
            
        }
        
        return packageList;
    }

    // 3-Jan-2020: package accorging to teacher, center duration and upgrade condition  
    @RemoteAction
    public static List<AureusCalendarController.Data> getUpgradePackageAccordingToTeacher(String centerId, String teacherId, 
                                                                                          string bookingId,  string grade){
         List<AureusCalendarController.Data> packageList = new List<AureusCalendarController.Data>();
        AureusCalendarController.Data dt = new AureusCalendarController.Data();
        Set<String> instruments =  new Set<String>();    
        List<Booking__c> bookingList = new List<Booking__c>();   
        String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
        if(String.isNotBlank(teacherId)){
            List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c 
                                    FROM Account WHERE Id =:teacherId];
            if(tchrList.size() > 0){        
                for(Account acc: tchrList){        
                    if(acc.Major_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Major_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                    if(acc.Minor_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Minor_Instruments_Disciplines__c.split(';'))        
                            instruments.add(strIns);        
                    }       
                }
            }
           //system.debug('instruments'+instruments);
            if(String.isNotBlank(bookingId)){
                bookingList = [SELECT Id, Name, Package__c,Type__c, Package__r.Name, Package__r.Active__c, enrolment__r.Package__c,
                                enrolment__r.Package__r.Package_Fee__c, enrolment__c,Center__r.Organisation__r.Name,
                                enrolment__r.Package__r.Duration__c, enrolment__r.Lesson_Day__c, enrolment__r.Package__r.Type__c, 
                                enrolment__r.Package__r.Location__c, enrolment__r.Package__r.Program__r.Instrument__c
                                FROM Booking__c 
                                WHERE Id =: bookingId];
            }
            //system.debug('bookingId'+bookingList);
            if(instruments != null && instruments.size() > 0 && String.isNotBlank(centerId)){   
                List<Package__c> listOfPackage = new List<Package__c>();
                set<string> packageType =  new Set<String>();
                string query ='';
                 String activeStatus =  ConstantsClass.activeStatus;
                query  += 'SELECT Id, Name FROM Package__c ';  
                query  += ' WHERE  Program__r.Status__c =: activeStatus '; 
                query  += ' AND Program__r.Instrument__c IN: instruments ';       
                query  += ' AND Program__r.Billing__c != null ';
                query  += ' AND Program__r.Scheduling__c != null ';
                query  += ' AND Active__c = True ';
                query  += ' AND RecordtypeId =: pkgLessRecId ';
                query  += ' AND Type_of_package__c = \'Normal\'';
                query += ' AND Location__c =: centerId';
                if(grade.equalsIgnoreCase('GroupToIndividual') && bookingList != null && bookingList.size() > 0){
                   decimal packageFee = bookingList[0].enrolment__r.Package__r.Package_Fee__c;
                   packageType =  new Set<String>{'Individual','Home'};
                   query  += ' AND Type__c In: packageType ';
                   query  += ' AND Package_Fee__c > :packageFee ';
                   query  += ' ORDER BY Program__r.Name';
                  //system.debug('@@query'+Database.query(query));
                    listOfPackage = Database.query(query);
                }else if((grade.equalsIgnoreCase('GroupToChangeCenter') || grade.equalsIgnoreCase('GroupToSameClass')) && bookingList != null && bookingList.size() > 0 ){
                   decimal packageFee = bookingList[0].enrolment__r.Package__r.Package_Fee__c;
                   packageType =  new Set<String>{ConstantsClass.packageTypeGroup};
                   query  += ' AND Type__c In: packageType ';
                   query  += ' AND Package_Fee__c = :packageFee ';
                   //system.debug('@@query'+Database.query(query));
                    query  += ' ORDER BY Program__r.Name';
                    listOfPackage = Database.query(query);
                }else if(grade.equalsIgnoreCase('GroupToHigherPackage') && bookingList != null && bookingList.size() > 0){
                    decimal packageFee = bookingList[0].enrolment__r.Package__r.Package_Fee__c;
                    packageType =  new Set<String>{ConstantsClass.packageTypeGroup};
                    query  += ' AND Type__c In: packageType ';
                    query  += ' AND Package_Fee__c > :packageFee ';
                    query  += ' ORDER BY Program__r.Name';
                   //system.debug('@@query'+Database.query(query));
                    listOfPackage = Database.query(query);
                    
                }
                // jatin:7-jan-2020 : show package according to active classes  
                if(grade.equalsIgnoreCase('GroupToHigherPackage') || grade.equalsIgnoreCase('GroupToSameClass') || grade.equalsIgnoreCase('GroupToChangeCenter') ){
                    map<id,Package__c> mapOfpackages = New map<id,Package__c>();
                    map<id,Package__c> mapOfGroupClassPackage = New map<id,Package__c>();
                    for(Package__c pkg :  listOfPackage){
                        mapOfpackages.put(pkg.id ,pkg);
                    }
                    if(bookingList != null && bookingList.size() > 0 && String.isNotBlank(bookingList[0].Center__c) && 
                    String.isNotBlank(bookingList[0].Center__r.Organisation__c) && 
                    String.isNotBlank(bookingList[0].Center__r.Organisation__r.Name) && 
                    bookingList[0].Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                        for(Ossia_Group_Grade_Package__c objClass : [SELECT Class_Name__c, Package__c,Package__r.name,  Name, Id ,Package__r.Program__r.Instrument__c
                                                    FROM Ossia_Group_Grade_Package__c
                                                    WHERE Class_Name__r.Active__c = true  
                                                    AND Class_Name__r.Centre_Name__c =:centerId 
                                                    AND Class_Name__r.Teacher__c =: teacherId
                                                    AND Package__r.Program__r.Instrument__c IN: instruments 
                                                    And Class_Name__r.Available_Capacity__c > 0]){
                                if(mapOfpackages.containsKey(objClass.Package__c)){
                                    mapOfGroupClassPackage.put(objClass.Package__c,mapOfpackages.get(objClass.Package__c));
                                }
                            }  
                        for(Package__c pkg :  mapOfGroupClassPackage.values()){
                            dt = new AureusCalendarController.Data();
                            dt.Id = pkg.Id;
                            dt.name = pkg.Name;
                            packageList.add(dt);
                        }  
                    }else{
                        for(CLass__C objClass : [Select Id,Package__c From Class__c 
                                                    WHERE Active__c = true  
                                                    AND Centre_Name__c =:centerId 
                                                    AND Teacher__c =: teacherId
                                                    AND Package__r.Program__r.Instrument__c IN: instruments 
                                                    And Available_Capacity__c > 0]){
                                if(mapOfpackages.containsKey(objClass.Package__c)){
                                    mapOfGroupClassPackage.put(objClass.Package__c,mapOfpackages.get(objClass.Package__c));
                                }
                            }  
                        for(Package__c pkg :  mapOfGroupClassPackage.values()){
                            dt = new AureusCalendarController.Data();
                            dt.Id = pkg.Id;
                            dt.name = pkg.Name;
                            packageList.add(dt);
                        }    
                    }
                }else{// is grade condition is group to regular than show all package records 
                    for(Package__c pkg :  listOfPackage){
                        dt = new AureusCalendarController.Data();
                        dt.Id = pkg.Id;
                        dt.name = pkg.Name;
                        packageList.add(dt);
                    }  
                }

            }
        }
        return packageList;
    }
   
    Private static Booking__c fetchSelectedBookingDetails(string bookingId){
        Booking__c bookingObjToReturn;
        for(Booking__c bookObj : [SELECT Id, Name, Center__r.Name, Teacher_Account__r.Name, Duration__c, Start_Time__c, 
                                    Booking_Date__c, Package__r.Name, Package__r.Duration__C,Class__r.Instrument__c,
                                    Class__r.Class_Type__c,Class__r.Maximum_age__c,Class__r.Minimum_age__c,
                                    Class__r.Class_Start_Date__c,Resource__r.Name, Class__r.Active__c,
                                   Class__c,Package__r.Package_Fee__c, Class__r.Start_Time__c,Class__r.Total_Capacity__c,
                                   Class__r.Name, Class__r.Available_Capacity__c ,
                                   Class__r.Centre_Name__r.Organisation__r.Name,Class__r.grade__c,Class__r.Duration__c // added by nishi: 2-sep-2020 : for get class grade and organisation 
                                   FROM Booking__c WHERE Id =: bookingId LIMIT 1]){
            bookingObjToReturn = bookObj;
        }
        return bookingObjToReturn;
    }
	
    // jatin: 19-dec-2019: for create group lesson for give makeup mins.
@RemoteAction
    public static AureusCalendarController.ProcessResult  createGroupbooking(String bookingJson, String redirectCase, String caseId){
        AureusCalendarController.ProcessResult  objResult = new AureusCalendarController.ProcessResult();
        //String errorMsg = 'false';
        objResult.msg = 'false';
        Boolean isError = false;
        Map<String, Object> bookingMap = new Map<String, Object>();
        Booking__c bookingObj = new Booking__c();
        List<Booking__c> bookingList = new List<Booking__c>();
        DateTime bookingDateTime;
        String parentId;
        Date bookDate;
        if(String.isNotBlank(bookingJson)){
           system.debug('@@bookingJson'+bookingJson);
            bookingMap = (Map<String, Object>)JSON.deserializeUntyped(bookingJson);
           system.debug('@@bookingMap'+bookingMap);
           system.debug('@@redirectCase'+redirectCase);
           system.debug('@@caseId'+caseId);
            if(bookingMap.containsKey('date')){
                String bd = String.valueOf(bookingMap.get('date'));
                if(String.isNotBlank(bd)){                   
                    bookingDateTime = DateTime.newInstance(Integer.valueOf(bd.split('T')[0].split('-')[0]), Integer.valueOf(bd.split('T')[0].split('-')[1]), Integer.valueOf(bd.split('T')[0].split('-')[2]), Integer.valueOf(bd.split('T')[1].split(':')[0]), Integer.valueOf(bd.split('T')[1].split(':')[1]), 0);
                    bookDate = Date.newInstance(Integer.valueOf(bd.split('T')[0].split('-')[0]), Integer.valueOf(bd.split('T')[0].split('-')[1]), Integer.valueOf(bd.split('T')[0].split('-')[2]));
                }
               system.debug('bookingDateTime'+bookDate);
                
            }
            if(bookingMap.containsKey('isRecurring')){
                if(String.valueOf(bookingMap.get('isRecurring')) == 'false'){
                    if(bookingMap.containsKey('centerId')){
                        bookingObj.Center__c = String.valueOf(bookingMap.get('centerId'));
                    }
                     if(bookingMap.containsKey('groupClassId')){
                        bookingObj.Group_Class__c = String.valueOf(bookingMap.get('groupClassId'));
                    }
                    if(bookingMap.containsKey('teacherId')){
                        bookingObj.Teacher_Account__c = String.valueOf(bookingMap.get('teacherId'));
                    }
                    if(bookingMap.containsKey('studentId')){
                        bookingObj.Student__c = String.valueOf(bookingMap.get('studentId'));
                    }
                    if(bookingMap.containsKey('packageId')){
                        bookingObj.Package__c = String.valueOf(bookingMap.get('packageId'));
                    }
                    //added by nishi: in ossia orgnisation case we added enrolment Id with makeup bookings
                    if(bookingMap.containsKey('enrolementId')){
                        bookingObj.enrolment__c = String.valueOf(bookingMap.get('enrolementId'));
                    }
                    //added by nishi: in ossia orgnisation case we added enrolment Id with makeup bookings
                    if(bookingMap.containsKey('type')){
                        if(String.valueOf(bookingMap.get('type')) == ConstantsClass.groupLessonTypeBooking){
                            bookingObj.Type__c = ConstantsClass.typeMakeup;
                        }
                    }
                    bookingObj.status__c = ConstantsClass.statusScheduled;
                    bookingObj.recordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();

                    if(bookingMap.containsKey('date')){
                        String bookingDate = String.valueOf(bookingMap.get('date'));
                        if(String.isNotBlank(bookingDate)){
                            bookingObj.Booking_Date__c = Date.valueOf(bookingDate.split('T')[0]);
                            bookingObj.Start_Time__c = Time.newInstance(Integer.valueOf(bookingDate.split('T')[1].split(':')[0]), Integer.valueOf(bookingDate.split('T')[1].split(':')[1]), Integer.valueOf(bookingDate.split('T')[1].split(':')[2]), 0);
                            if(bookingMap.containsKey('duration')){
                                bookingObj.End_Time__c =  Time.newInstance(Integer.valueOf(bookingDate.split('T')[1].split(':')[0]), Integer.valueOf(bookingDate.split('T')[1].split(':')[1]) + Integer.valueOf(bookingMap.get('duration')), Integer.valueOf(bookingDate.split('T')[1].split(':')[2]), 0);
                            }
                        }
                    }
                    Account objAcc = [SELECT Id,Parent__c FROM Account WHERE ID =:bookingObj.Student__c ];
                    parentId = String.isBlank(objAcc.Parent__c) ? objAcc.Id : objAcc.Parent__c;
                    //add ParentId in Booking parent
                    bookingObj.Parent__c = parentId;
                    
                    Boolean isChecked = AureusCalendarController.validateBookingTime(bookingObj.Teacher_Account__c,bookDate,bookingObj.End_Time__c);
                    string selgroupClassId = bookingMap.containsKey('selgroupClassId') ? String.valueOf(bookingMap.get('selgroupClassId')) : '';
                    if(string.isNotBlank(selgroupClassId) && isChecked ){
                       // isChecked = validateBookingIsAvailable(selgroupClassId);
                    }
                   system.debug('@@@isChecked'+isChecked);
                   system.debug('@@@bookingObj'+bookingObj);
                    Database.SaveResult saveResult;
                    if(isChecked){
                        saveResult = Database.insert(bookingObj, false);
                    }
                    system.debug('saveResult'+saveResult);
                    if(isChecked == False && saveResult == null){
                        isError = true;
                        objResult.msg = 'error';
                    }else{
                            if(bookingObj.Type__c == ConstantsClass.typeMakeup){
                                bookingList.add(bookingObj);
                                AureusCalendarController.deductMakeupHours(bookingList, parentId);
                            }
                            
                            //create case Here
                            if((bookingObj.Type__c == ConstantsClass.typeMakeup) && redirectCase == 'true'){
                                Case objCase = AureusCalendarControllerHelper.createCase(caseId, bookingObj.Id, bookingObj.Type__c);
                                objResult.caseId = objCase.Id;
                            }
                            
                        }
                        
                    }
                }
            }
            //system.debug('@@objResult'+objResult);
             return objResult;
            
        }
    
    
    // @jatin: 13-dec-2019 : for show time slots according to selected class 
    @RemoteAction
    public static List<String> getGroupLessonTimeSlotsAccordingly(String effectiveDateStr,string newClassId){
        List<String> availTimeSlots = new List<String>();
        DateTime effectiveDate;
        if(String.isNotBlank(effectiveDateStr)){
            effectiveDate = DateTime.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2]));
        }
       //system.debug('@@newClassId'+newClassId);
        List<class__c> listofClass = [select id,Class_Start_Date__c ,Class_End_Date__c ,Class__c.Start_Time__c
                                    from Class__c
                                    where id=:newClassId];
       //system.debug('@@@listofClass'+listofClass);
        if(listofClass != null && listofClass.size() > 0 ){
            DateTime startTime = DateTime.newInstance(effectiveDate.date(),listofClass[0].Start_Time__c);
            availTimeSlots.add(startTime.format('h:mm a'));
        }system.debug('@@@availTimeSlots'+availTimeSlots);
        
        return availTimeSlots;
    }
    
    

    private static List<Booking__c> fetchAllBookingsForClass(String bookingId){
        String groupLessonBookingRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
        //Set<String> statusSet = new Set<String>{ConstantsClass.pendingStatus, ConstantsClass.scheduledStatus};
        Set<String> bookingTypeSet = new Set<String>{ConstantsClass.groupLessonTypeBooking, ConstantsClass.busyBookingType,ConstantsClass.typeAdhoc,ConstantsClass.typeMakeup,ConstantsClass.trialStatus};
        return [SELECT Id, Name, Student__r.Name, Parent__r.Name, Status__c ,Booking_Date__c,start_Time__c ,
                Class__r.Instrument__c,Class__r.Class_Type__c,Type__c
                FROM Booking__c WHERE RecordTypeId =:groupLessonBookingRecordType 
                AND Group_Class__c =: bookingId
                AND Status__c !=: ConstantsClass.statusCanceled
                AND Type__c In:bookingTypeSet /*AND Status__c IN: statusSet*/];
    }
    
     //@3-jan-2020:  Jatin : for get Teacher or package accorging to class days for update enrollment new Effective dates
    @RemoteAction 
    public static  Set<string> getNewEffectiveGroupDateSlots(String packageId, String teacherId){
        Set<string> weekdays = new Set<String>();
        boolean isOssia = true;
        for(class__c objclass : [SELECT id,Class_Day__c,Start_Time__c ,Class_Start_Date__c,End_Time__c,Centre_Name__r.Organisation__r.Name
                                FROM Class__C
                                WHERE Teacher__c =:teacherId
                                AND Package__c =: packageId
                                AND Active__c = true]){
            if(String.isNotBlank(objclass.Centre_Name__c) && 
            String.isNotBlank(objclass.Centre_Name__r.Organisation__c) && 
            String.isNotBlank(objclass.Centre_Name__r.Organisation__r.Name) && 
            objclass.Centre_Name__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                isOssia= true;
            }else{          
                isOssia= false;          
                weekdays.add(objclass.Class_Day__c);
            }
        }
       //system.debug('weekdays'+weekdays);
       //system.debug('isOssia'+isOssia);
       //system.debug('packageId'+packageId);
       //system.debug('teacherId'+teacherId);
        if(isOssia){
            for(Ossia_Group_Grade_Package__c objclass:  [SELECT Class_Name__c, Class_Name__r.Class_Day__c,Package__c,Package__r.name,  Name, Id ,Package__r.Program__r.Instrument__c
                                                                FROM Ossia_Group_Grade_Package__c
                                                                WHERE Class_Name__r.Teacher__c =:teacherId
                                                                AND Package__c =: packageId
                                                                AND Class_Name__r.Active__c = true]){
                weekdays.add(objclass.Class_Name__r.Class_Day__c); 
            }
        }
       //system.debug('weekdays'+weekdays);
        return weekdays;
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

    @RemoteAction
    public static Boolean markCompleteOrNoShow(String bookingIds, String actionStr){
        Boolean isSucess = FALSE;
       //system.debug('@@@mapOfAppointments'+bookingIds);
        List<Booking__c> bookingList = new List<Booking__c>();
        String action = (actionStr == 'noShow') ? ConstantsClass.statusNoshow : ConstantsClass.statusCompleted;
        if(String.isNotBlank(bookingIds)){
        	for(String bookingId : bookingIds.split(';')){
                bookingList.add(new Booking__c(Id = bookingId, Status__c = action));
            }    
        }
         
        if(bookingList.size() > 0){
            update bookingList;     
            isSucess = TRUE;
        }
        return isSucess;
    }
   	    
    //Json For Edit Class Popup
    Public Class BookDetails{
        Booking__c bookObj;
        //List<AureusCalendarController.GroupPackage> groupPackages;
        List<BookingDetais> bookingList;
        public List<AureusCalendarController.BookingHistory> bookingHistoryList;
        Boolean isOssia;
        public BookDetails(Booking__c bookObj, /*List<AureusCalendarController.GroupPackage> groupPackages,*/ List<Booking__c> bookList,Boolean isOssiaOrg ){
            this.bookObj = bookObj;
            this.isOssia =isOssiaOrg;
           // this.groupPackages = groupPackages;
            bookingList = new List<BookingDetais>();
            bookingHistoryList = new List<AureusCalendarController.BookingHistory>();
            for(Booking__c objBooking : bookList){
                bookingList.add(new BookingDetais(objBooking.student__r.name,objBooking.Parent__r.name,objBooking.status__c,objBooking.name,
                                objBooking.id,
                                String.valueOf(objBooking.Booking_Date__c)+'T'+String.valueOf(objBooking.start_Time__c).split('\\.')[0],objBooking.type__c));
            }
            //this.bookList = bookList;
            
        }
    }


    // @jatin: 4-Jan-2019 : for show time slots according to  date ,teacher,center,
    @RemoteAction
    public static Set<String> getTimeSlotsGroupClassAccordingly(String centerId, String teacherId, String selectedPackage,String effectiveDateStr){
        List<String> availTimeSlots = new List<String>();
        DateTime effectiveDate;
        if(String.isNotBlank(effectiveDateStr)){
            effectiveDate = DateTime.newInstance(Integer.valueOf(effectiveDateStr.split('-')[0]), Integer.valueOf(effectiveDateStr.split('-')[1]), Integer.valueOf(effectiveDateStr.split('-')[2]));
        }
        Set<Date> dt = new Set<Date>();
        dt.add(effectiveDate.date());
        List<Booking__c> bookingList = getGroupClassBookingsOnSelectedDates(centerId, teacherId,selectedPackage, dt);
        Set<String> bookingSlots = new Set<String>();
        if(bookingList.size() > 0){
            for(Booking__c currentBook : bookingList){
                dateTime startTime =DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c);
                bookingSlots.add(currentBook.Class__C +'-'+startTime.format('h:mm a'));
            }
        }else{
            bookingList = OssiaCenterCalendarController.getGroupClassOssiaBookingsOnSelectedDates(centerId, teacherId,selectedPackage, dt);
            bookingSlots = new Set<String>();
            if(bookingList.size() > 0){
                for(Booking__c currentBook : bookingList){
                    dateTime startTime =DateTime.newInstance(currentBook.Booking_Date__c, currentBook.Start_Time__c);
                    bookingSlots.add(currentBook.Class__C +'-'+startTime.format('h:mm a'));
                }
            }
        }
        return bookingSlots;
    }

   private static List<Booking__c> getGroupClassBookingsOnSelectedDates(String centerId, String teacherId,string selectedPackage, Set<Date> dates){
        String groupBookingRecordType = ConstantsClass.groupBookingRecordType;
        Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted, ConstantsClass.blockStatus};
        Set<String> bookTypeSet = new Set<String>{ConstantsClass.groupTypeBooking};
        Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory};     
        Date dt, endDt;
        String busyType = ConstantsClass.typeBusy;
       
        String weekDay;
        String queryStr = 'SELECT Id, Name,Class__C, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c';
        queryStr += ' WHERE RecordType.Name =: groupBookingRecordType AND Start_Time__c != NULL AND End_Time__c != NULL AND Class__C != null and Class__r.Is_Makeup_Class__c = false';
        if(String.isNotBlank(centerId)){
            queryStr += ' AND Center__c =: centerId';
        }
        if(String.isNotBlank(teacherId)){
            queryStr += ' AND Teacher_Account__c =: teacherId';
        }
         if(String.isNotBlank(selectedPackage)){
            queryStr += ' AND Package__c =: selectedPackage';
        }
        if(dates.size() > 0){
            DateTime dTime = DateTime.now();
            for(Date d : dates){
                dt = d;
                break;
            }
            if(dt != null){
                endDt = dt.addMonths(1);
                dTime = DateTime.newInstance(dt, dTime.time());
            }
            weekDay = dTime.format('EEEE');
            
            queryStr += ' AND Booking_Date__c >=: dt AND Booking_Date__c <= :endDt';
            if(String.isNotBlank(weekDay)){
                queryStr += ' AND Appointment_Day__c =: weekDay';
            }
            queryStr += ' AND status__c IN: bookingStatus AND ((Type__c IN: bookTypeSet) OR (Type__c =: busyType AND Category__c NOT IN: busyStatusSet))';
            
        }

        //System.debug('@@@@queryStr'+queryStr);
        
        return Database.query(queryStr);
    }
    public class ClassDateTimeSlot{
        public set<string> weekDays;
        public Map<String,Set<String>> dateTimeSlots;
    }
    public class BookingDetais{
        string studentName;
        string parentName;
        string status;
        string bookingName;
        string bookingId;
        string start;
         string bookingType;
        public BookingDetais(string studentName,string parentName,string status,string bookingName,string  bookingId,string start,string bookingType){
            this.studentName = studentName;
            this.parentName = parentName;
            this.status =status;
            this.bookingName =bookingName;
            this.bookingId =bookingId;
            this.start =start;
            this.bookingType = bookingType;
        }
    }

    // nishi: 2-Nov-2020: get group adhoc package list
    @RemoteAction 
    public static AureusCalendarController.AdhocLessonDetails  getGroupAdhocPackageDetail(String student, String packageId, String teacherId){
        String recordTypeLesson = ConstantsClass.recordTypeLesson;
        AureusCalendarController.AdhocLessonDetails adhocDetails = new AureusCalendarController.AdhocLessonDetails();
        if(String.isNotBlank(packageId)){
            for(Package__c packageObj : [SELECT Id, Name, RecordType.Name, Location__r.Name, Location__r.Country__r.Tax_Rate__c, Location__r.Organisation__r.Tax_Rate__c, 
                                        of_Units__c, Package_Fee__c, Unit_Fee__c, Duration__c ,/*facility_Fee__c,*/Location__r.Organisation__r.Name
                                        FROM Package__c WHERE RecordType.Name =: recordTypeLesson AND Id =: packageId]){
                
                adhocDetails.packageName = packageObj.Name; 
                adhocDetails.packageId = packageObj.Id;
                adhocDetails.packageFee = BillingUtility.roundOffAmount(packageObj.Unit_Fee__c);//packageObj.Package_Fee__c;
                adhocDetails.unitFee = packageObj.Unit_Fee__c ;
                adhocDetails.units = Integer.valueOf(packageObj.of_Units__c);
                adhocDetails.duration = packageObj.Duration__c;
                //Start: added by nishi: 17-Aug-2020: for manage facility fee is ossia related centers 
                if(String.isNotBlank(packageObj.Location__c)){
                    adhocDetails.gstRate = packageObj.Location__r.Organisation__r.Tax_Rate__c;
                    adhocDetails.centerName = packageObj.Location__r.Name;
                }   
                //End: added by nishi: 17-Aug-2020: for manage facility fee is ossia related centers
                break;
            }
        }
        if(String.isNotBlank(student)){
            for(Account acc : [SELECT Id, FirstName, LastName, RecordType.Name FROM Account WHERE RecordType.Name = 'Customer' AND Id =: student]){
                adhocDetails.studentId = acc.Id;
                adhocDetails.studentFirstName = acc.FirstName;
                adhocDetails.studentLastName = acc.LastName;
                break;
            }
            
        }
        if(String.isNotBlank(teacherId)){
            for(Account acc : [SELECT Id, FirstName, LastName, RecordType.Name FROM Account WHERE RecordType.Name = 'Teacher' AND Id =: teacherId]){
                adhocDetails.teacherId = acc.Id;
                adhocDetails.teacherName = acc.FirstName + ' ' +acc.LastName;
                break;
            }
        }
        return adhocDetails;
    }   

    //nishi: 3-Nov-2020: In Aureus, Group ad-hoc booking should be created once the payment is successful whereas in Ossia, Group ad-hoc booking can be created even if the payment is failed.
    // Failed payments can be collected via dunning process as an outstanding invoice
    @RemoteAction
    public static Boolean createAdhocGroupClassBookings(String packageId, String centerId, String teacherId, String studentId, String recurring, String bookingDate,  String groupLessonId,String enrolmentId){
        Country__c countryOfCentre = new Country__c();
        Organisation__c organisationOfCentre = new Organisation__c();
        Boolean isOssiaOrganization = false;
        Boolean isSuccess;
        Double totalAmount = 0;
        string recordTypeCustomer = ConstantsClass.recordTypeCustomer;
        string recordTypeCentre = ConstantsClass.centerRecTypeName;
        String stripeId = '';
        List<Booking__c> bookingList = new List<Booking__c>();
        String parentId ;
        List<Account> accList = new List<Account>();
        if(String.isNotBlank(studentId) && String.isNotBlank(centerId)){
            accList = new List<Account>([SELECT Id, Name, Parent__c, RecordType.Name ,  Also_a_Student__c, Stripe_Customer_Id__c, Parent__r.Stripe_Customer_Id__c, 
                                         Country__c, Country__r.Id, Country__r.Tax_Rate__c, Country__r.Stripe_Base_Url__c, Country__r.Stripe_Secret_Key__c, 
                                         Country__r.Currency_Code__c,Organisation__r.Name,Organisation__r.Id, Organisation__r.Tax_Rate__c, Organisation__r.Stripe_Base_Url__c,
                                         Organisation__r.Stripe_Secret_Key__c, 
                                         Organisation__r.country__r.Currency_Code__c
                                         FROM Account 
                                         WHERE (RecordType.Name =: recordTypeCustomer AND Id =: studentId) OR Id =: centerId]);
        }
        system.debug('accList'+accList);
        if(accList.size() > 0){
            for(account acc : accList){
                if(acc.RecordType.Name == recordTypeCustomer){
                    if(String.isNotBlank(acc.Parent__c) && acc.Also_a_Student__c == false){
                        parentId = acc.Parent__c;
                        stripeId = string.isNotBlank(acc.Parent__r.Stripe_Customer_Id__c)?acc.Parent__r.Stripe_Customer_Id__c:'';
                        system.debug('stripeId...'+stripeId);
                    }else if(String.isBlank(acc.Parent__c) && acc.Also_a_Student__c == true){
                        parentId = acc.Id;
                        stripeId = string.isNotBlank(acc.Stripe_Customer_Id__c)?acc.Stripe_Customer_Id__c:'';
                        System.debug('parent stripeId...'+stripeId);
                    }    
                }else if(acc.RecordType.Name == recordTypeCentre){
                    countryOfCentre = acc.Country__r;
                    organisationOfCentre = acc.Organisation__r;
                    if(string.isnotBlank(acc.Organisation__c) && string.isnotBlank(acc.Organisation__r.Name) && 
                       acc.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name) ){
                           isOssiaOrganization= true;
                       }
                }
            }
            
        }
        system.debug('organisationOfCentre'+organisationOfCentre);
        List<Package__c> listOfPackage =[SELECT Name, Id, Unit_Fee__c, Duration__c//,facility_Fee__c
                                         FROM Package__c
                                         Where id =: packageId];
        system.debug('listOfPackage'+listOfPackage);
        Invoice__c objectOfInvoice = new Invoice__c(Status__c=ConstantsClass.dueStatus, Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                    Invoice_Date__c =system.today(), Parent_Account__c = parentId,Center__c=centerId);
        system.debug('objectOfInvoice'+objectOfInvoice);
        
        if(listOfPackage.size() > 0){
            system.debug('bookingDate'+bookingDate);
            Double gstAdded = 0;
            Date bookDate = Date.newInstance(Integer.valueOf(bookingDate.split('T')[0].split('-')[0]), Integer.valueOf(bookingDate.split('T')[0].split('-')[1]), Integer.valueOf(bookingDate.split('T')[0].split('-')[2]));
            if(isOssiaOrganization){
                bookingList = AureusCalendarControllerHelper.createAppointmentForAdhocGroupLesson(listOfPackage[0], teacherId, studentId, centerId, Integer.valueOf(recurring), bookingDate,
                                                                                                  parentId,groupLessonId,enrolmentId); 
            }else{
                bookingList = AureusCalendarControllerHelper.createAppointmentForAdhocGroupLesson(listOfPackage[0], teacherId, studentId, centerId, Integer.valueOf(recurring), bookingDate,
                                                                                                  parentId,groupLessonId,''); 
            }
            
            system.debug('bookingList'+bookingList);                                                            
            Boolean isChecked = bookingList != null && bookingList.size() > 0 ?AureusCalendarController.validateBookingTime(teacherId,bookDate,bookingList[0].End_Time__c) :true;
            if(string.isNotBlank(groupLessonId) && isChecked ){
                //isChecked = validateBookingIsAvailable(groupLessonId);
            }
            List<Invoice_Line_Item__c> listOfInvoiceLineItem = new List<Invoice_Line_Item__c>();
            Stripe_Payment_Log__c iLog = new Stripe_Payment_Log__c();
            Double packageFee =0;
            for(Integer i = 0; i < bookingList.size(); i++){
                packageFee =0;
                packageFee = listOfPackage[0].unit_Fee__c;
                totalAmount += BillingUtility.roundOffAmount(packageFee);
                if(packageFee > 0 && countryOfCentre.Tax_Rate__c > 0){
                    gstAdded += BillingUtility.roundOffAmount(packageFee * (countryOfCentre.Tax_Rate__c / 100));
                }
                
            }
            if(totalAmount > 0 && gstAdded > 0){
                totalAmount += gstAdded;
            }
            
            if(objectOfInvoice != NULL && totalAmount > 0 && isChecked && String.isNotBlank(organisationOfCentre.Id)){
                if(String.isNotBlank(stripeId)){ 
                    BillingUtility.StripeCharge objStripeCharge = new BillingUtility.StripeCharge();
                    objStripeCharge = AureusCalendarController.updateInvoice(objectOfInvoice, totalAmount, stripeId, organisationOfCentre.country__r.Currency_Code__c, organisationOfCentre.Stripe_Base_Url__c, organisationOfCentre.Stripe_Secret_Key__c);
                    system.debug('objStripeCharge'+objStripeCharge);  
                    if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                        objectOfInvoice.status__c = ConstantsClass.paidStatus;
                        string invoiceId = AureusCalendarController.createDueInvoice(objectOfInvoice,bookingList,listOfPackage,countryOfCentre.Tax_Rate__c);
                        if(String.isNotBlank(invoiceId)){
                            isSuccess = true;
                            system.debug('objectOfInvoice'+objectOfInvoice); 
                            objectOfInvoice = [SELECT Id,Name,Parent_Account__c,Total_Amount__c ,status__c FROM Invoice__c WHERE Id=: objectOfInvoice.Id];
                            system.debug('listOfInvoiceLineItem'+listOfInvoiceLineItem); 
                            Payment__c objPayment = BillingUtility.fillPayment(objectOfInvoice.Parent_Account__c,objectOfInvoice.Id,totalAmount,ConstantsClass.successStatus); 
                            objPayment.Transaction_ID__c = objStripeCharge.Id;
                            objPayment.Method_of_Payment__c = ConstantsClass.cardModeType;
                            insert objPayment;
                            system.debug('objPayment'+objPayment); 
                            if(String.isNotBlank(organisationOfCentre.Id)){
                                BillingUtility.updateCharge(objStripeCharge.Id,objectOfInvoice.Name, organisationOfCentre.Stripe_Base_Url__c, organisationOfCentre.Stripe_Secret_Key__c);    
                            }
                            if(objectOfInvoice != NULL && String.isNotBlank(objectOfInvoice.Id)){
                                BillingUtility.createAttachment(new Set<String>{objectOfInvoice.Id});
                                // added : for adhoc invoice to push on the sage
                                SageIntacctIntegrationUtility.adhocInvoice(objectOfInvoice.id);
                            }
                        }
                    }else{
                        isSuccess = false;
                            //if ossia organisation adhoc should be allowed and invoice should be still generated even if the card is failed
                        if(isOssiaOrganization){
                            string invoiceId = AureusCalendarController.createDueInvoice(objectOfInvoice,bookingList,listOfPackage,countryOfCentre.Tax_Rate__c);
                            if(String.isNotBlank(invoiceId)){
                                BillingUtility.createAttachment(new Set<String>{invoiceId});
                                // added : for adhoc invoice to push on the sage
                                SageIntacctIntegrationUtility.adhocInvoice(invoiceId);
                            }
                            isSuccess = true;
                        }
                         //if ossia organisation adhoc should be allowed and invoice should be still generated even if the card is failed
                    }
                    
                }//commmented by nishi:23-Nov-2020: for deployment of the Ossia enhancements not include anything from Enhancements part -2 
                /*else{
                    isSuccess = false;
                    //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                    if(isOssiaOrganization){
                        string invoiceId = AureusCalendarController.createDueInvoice(objectOfInvoice,bookingList,listOfPackage,countryOfCentre.Tax_Rate__c);
                        if(String.isNotBlank(invoiceId)){
                            // added : for adhoc invoice to push on the sage
                            SageIntacctIntegrationUtility.adhocInvoice(invoiceId);
                            BillingUtility.sendEmailsForOssiaNonStripeCustomers(new Set<string>{invoiceId});
                        }
                        isSuccess = true;
                    }
                    //19-Nov-2020:Send email with invoice attachment for if ossia organisation customers without card on file
                }//commmented by nishi:23-Nov-2020: for deployment of the Ossia enhancements not include anything from Enhancements part -2 */
            }else{
                isSuccess = false;
            }
            
            
            
        }
        system.debug('isSuccess'+isSuccess); 
        return isSuccess;
    }

    
    

    public static boolean validateBookingIsAvailable(string grouplessonId){
        Boolean isAvailableForBooking = false;
        Booking__c bookObj =  fetchSelectedBookingDetails(grouplessonId);
        if(string.isnotBlank(bookObj.Class__c) && bookObj.Class__r.Available_Capacity__c != null && bookObj.Class__r.Available_Capacity__c > 0){
            isAvailableForBooking = true;
        }
        return isAvailableForBooking;
    }

    public class deactivegroupClassLesson{
        public string errorCode;
        public string errormessage;
        public map<id,booking__c> mapOfDeleteBooking;
        public deactivegroupClassLesson(string errorCode,string errormessage){
            this.errorCode = errorCode;
            this.errormessage = errormessage;
            this.mapOfDeleteBooking = new map<id,booking__c>();
        }
        public deactivegroupClassLesson(string errorCode,string errormessage, map<id,booking__c> mapOfDeleteBooking){
            this.errorCode = errorCode;
            this.errormessage = errormessage;
            this.mapOfDeleteBooking = new map<id,booking__c>();
            this.mapOfDeleteBooking.putAll(mapOfDeleteBooking);
        }
    }
    /* nishi: 3-Nov-2020: Deactivating a group class for Aureus and Ossia [New requirement] ------------------
        1. All existing enrolment are already withdrawn
        2. System should allow deactivation of the class and remove all future class instances.
    */
    @RemoteAction
    public static deactivegroupClassLesson deactivateGroupClass(string dateOfAppointment,string groupClassId){
        if(string.isnotBlank(dateOfAppointment) && string.isnotBlank(groupClassId)){
            try{
                DateTime dateChange = DateTime.newInstance(Date.valueOf(dateOfAppointment.split('T')[0]), Time.newInstance(0, 0, 0, 0));
                deactivegroupClassLesson objdeactivegroupClassLesson  = DeactiveGroupclassConfirmation(dateOfAppointment,groupClassId);
                if(objdeactivegroupClassLesson.errorCode == '200'){
                    map<id,booking__c> mapOfDeleteBooking = objdeactivegroupClassLesson.mapOfDeleteBooking;
                    if(mapOfDeleteBooking != null && mapOfDeleteBooking.size() > 0){
                            delete mapOfDeleteBooking.values();
                    }
                    class__c objclass = new class__c(id=groupClassId,Active__c = false,Class_End_Date__c=dateChange.date());     
                    update objclass;  
                }
                return objdeactivegroupClassLesson;
            }catch(exception e){
                return new deactivegroupClassLesson('400',e.getMessage());
            }
        }
        return new deactivegroupClassLesson('400','Group Class Id not Found');
    }

    @RemoteAction
    public static deactivegroupClassLesson DeactiveGroupclassConfirmation(string dateOfAppointment,string groupClassId){
        if(string.isnotBlank(dateOfAppointment) && string.isnotBlank(groupClassId)){
            DateTime dateChange = DateTime.newInstance(Date.valueOf(dateOfAppointment.split('T')[0]), Time.newInstance(0, 0, 0, 0));
            Boolean getActiveEnrolment = getAnyActiveEnrolmentIsExist(groupClassId,dateChange.date());
            if(getActiveEnrolment){
                return new deactivegroupClassLesson('400','There are some Active Enrolment found in this class. Please ensure that all enrolments are cancelled before deactivating this class.');
            }else{
                map<id,booking__c> mapOfDeleteBooking = new Map<Id,booking__c>([Select id 
                                                                                from Booking__c 
                                                                                where Class__c =:groupClassId 
                                                                                and Booking_Date__c >=:dateChange.date()]);
                if(mapOfDeleteBooking != null && mapOfDeleteBooking.size() > 0){
                    List<booking__c> listOfgrouplesson = fetchAllBookingsForClass(mapOfDeleteBooking.keyset());
                    if(listOfgrouplesson != null && listOfgrouplesson.size() > 0){
                        return new deactivegroupClassLesson('400','There are some scheduled bookings found in this class. Please ensure that all future bookings and enrolments are cancelled before deactivating this class.');
                    }else{
                        return new deactivegroupClassLesson('200','Deactivated Group Class successfully...',mapOfDeleteBooking); 
                    }
                }
                return new deactivegroupClassLesson('200','Deactivated Group Class successfully...'); 
            }
        }
        return new deactivegroupClassLesson('400','Group Class Id not Found');
    }

    private static List<Booking__c> fetchAllBookingsForClass(Set<Id> bookingIds){
        String groupLessonBookingRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.groupLessonBookingRecordType).getRecordTypeId();
        //Set<String> statusSet = new Set<String>{ConstantsClass.pendingStatus, ConstantsClass.scheduledStatus};
        Set<String> bookingTypeSet = new Set<String>{ConstantsClass.groupLessonTypeBooking, ConstantsClass.busyBookingType,ConstantsClass.typeAdhoc,ConstantsClass.typeMakeup,ConstantsClass.trialStatus};
        return [SELECT Id, Name, Student__r.Name, Parent__r.Name, Status__c ,Booking_Date__c,start_Time__c ,
                Class__r.Instrument__c,Class__r.Class_Type__c,Type__c
                FROM Booking__c WHERE RecordTypeId =:groupLessonBookingRecordType 
                AND Group_Class__c In: bookingIds
                AND Status__c !=: ConstantsClass.statusCanceled
                AND Type__c In:bookingTypeSet];
    }

    // check Active enrolment is exist or not
    public static Boolean getAnyActiveEnrolmentIsExist(String groupClassId,date deactivateDate){
        Boolean anyActiveEnrolmentIsExist = true;
        String cancelStatus = ConstantsClass.enrollmentStageCancelled;
        List<Enrolment__c> enrolList = [SELECT Id, Package_Process_Type__c, Package_Process_Status__c, 
                                        Effective_Date__c  
                                        FROM Enrolment__c 
                                        WHERE class__c =: groupClassId 
                                        AND Stage__c = :ConstantsClass.enroledStatus
                                        AND Type__c = :ConstantsClass.enrolGroupType];
                                        system.debug('enrolList'+enrolList);
        if(enrolList != null && enrolList.size() > 0){
            Integer count = 0;
            for(Enrolment__c enrolObj : enrolList){
                system.debug('enrolObj.Package_Process_Type__c '+enrolObj.Package_Process_Type__c );
                system.debug('enrolObj.Effective_Date__c '+enrolObj.Effective_Date__c );
                system.debug('deactivateDate'+deactivateDate );
                if((enrolObj.Package_Process_Type__c == ConstantsClass.enrollmentProcessCancelType && enrolObj.Effective_Date__c < deactivateDate)){
                    count += 1;   
                }
            }
            system.debug('count'+count );
            if(count == enrolList.size()){
                anyActiveEnrolmentIsExist = false;
            }
        }else{
            anyActiveEnrolmentIsExist = false;
        }
        system.debug('anyActiveEnrolmentIsExist'+anyActiveEnrolmentIsExist);
        return anyActiveEnrolmentIsExist;
        
    }
}