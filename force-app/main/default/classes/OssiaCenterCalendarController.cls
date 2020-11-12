/*
Name        :        OssianCalendarController
Date        :        26 -sep- 2020 
Author      :        Nishi
Description :        this class for ossia oragnaisation realted changes in aureus calendar.
test class:	OssianCalendarControllertest
*/ 
public with sharing class OssiaCenterCalendarController {

    @RemoteAction
    public static OssiaCalendarResponse getOssiaStudentDetail(String bookingId){
        List<OssiaStudentCancelBooking>  listOfOssiaStudentCancelBooking = new List<OssiaStudentCancelBooking>();
        Set<string> recordTypes = new set<string>{ConstantsClass.recordTypeLesson,ConstantsClass.groupLessonBookingRecordType};
        datetime last12Month = system.today().addDays(-365);
        if(string.isNotBlank(bookingId)){ 
            Booking__c objOssiaEnrolmentBooking =getOssiaStudentEntolment(bookingId);
            string enrolmentId =objOssiaEnrolmentBooking.enrolment__c;
            string studentName ='';
            string parentName ='';
            if(string.isNotBlank(objOssiaEnrolmentBooking.Student__c)){
                studentName = objOssiaEnrolmentBooking.Student__c+';'+objOssiaEnrolmentBooking.Student__r.Name;
            }
            if(string.isNotBlank(objOssiaEnrolmentBooking.Parent__c)){
               if(string.isBlank(objOssiaEnrolmentBooking.Student__c)){
                    parentName = objOssiaEnrolmentBooking.Parent__c+';'+objOssiaEnrolmentBooking.Parent__r.name;
                }else if(objOssiaEnrolmentBooking.Student__c != objOssiaEnrolmentBooking.Parent__c ){
                    parentName = objOssiaEnrolmentBooking.Parent__c+';'+objOssiaEnrolmentBooking.Parent__r.name;
                }
            }
            if(string.isNotBlank(enrolmentId)){
                for(Booking__c objBooking: [SELECT Teacher_Account__r.Name ,Student__r.Name, Type__c, Student__c, Status__c, Start_Time__c, 
                                                Parent_Name__c, Parent__c,Parent__r.name, Package__c, Name, Makeup_Reason__c, Enrolment__c, Id,
                                                Instrument__c, Center__c,Center__r.Name,Available_Make_up_Units__c, Cancellation_Reason__c,Canceled_Date__c ,Booking_date__c,package__r.Duration__c
                                                FROM Booking__c where 
                                                enrolment__C=:enrolmentId
                                                AND (Canceled_Date__c >=: last12Month
                                                AND status__c =: ConstantsClass.statusCanceled
                                                //AND Type__c =: ConstantsClass.typeRegular
                                                AND RecordType.Name in:recordTypes)
                                                Order by Booking_date__c DESC]){
                                                    DateTime bookingDate = DateTime.newInstance(objBooking.Booking_date__c, objBooking.Start_Time__c);
                                                    listOfOssiaStudentCancelBooking.add(new OssiaStudentCancelBooking(
                                                    objBooking.Canceled_Date__c.format('EEE, dd MMM yyyy') +' '+objBooking.Canceled_Date__c.format('h:mm a')
                                                    ,objBooking.Teacher_Account__c +';'+objBooking.Teacher_Account__r.Name,
                                                    objBooking.Center__c+';'+objBooking.Center__r.Name,
                                                    objBooking.Id+';'+objBooking.Name,
                                                    bookingDate.format('EEE, dd MMM yyyy') +' '+bookingDate.format('h:mm a'),
                                                    objBooking.package__r.Duration__c,
                                                    objBooking.status__c,objBooking.Cancellation_Reason__c,
                                                    string.valueOf(objBooking.Available_Make_up_Units__c),
                                                    objBooking.type__c));
                                                   
                }
            }
            return new OssiaCalendarResponse(studentName,parentName,'200','Please see the cancellations for this student in the previous 12-month.',listOfOssiaStudentCancelBooking);
        }else {
            return new OssiaCalendarResponse('400','Booking Id is not found.');
        }
    }
    public static Booking__c  getOssiaStudentEntolment(String bookingId){
        return [SELECT enrolment__c,Student__c,Student__r.name,Parent__c,Parent__r.Name FROM Booking__c where Id=:bookingId];
    }
    public class OssiaCalendarResponse{
         public String errorCode{get;set;}
         public String message{get;set;}
         public List<OssiaStudentCancelBooking>  listOfOssiaStudentCancelBooking {get;set;}
        public Integer cancelBookingrecordsSize{get;set;}
        public string studentName{get;set;}
        public string parentName{get;set;}
        public OssiaCalendarResponse(string studentName,string parentName,String errorCode,String message, List<OssiaStudentCancelBooking>  listOfOssiaStudentCancelBooking){
            this.studentName = studentName;
            this.parentName = parentName;
            this.errorCode = errorCode;
            this.message = message;
            this.listOfOssiaStudentCancelBooking =new List<OssiaStudentCancelBooking> ();
            this.listOfOssiaStudentCancelBooking = listOfOssiaStudentCancelBooking;
            this.cancelBookingrecordsSize = listOfOssiaStudentCancelBooking.size();
        }
        public OssiaCalendarResponse(String errorCode,String message){
            this.errorCode = errorCode;
            this.message = message;
            this.cancelBookingrecordsSize  =0;
            listOfOssiaStudentCancelBooking =new List<OssiaStudentCancelBooking> ();

        }
        public OssiaCalendarResponse(){
            this.errorCode = '';
            this.message = '';
            this.cancelBookingrecordsSize  =0;
            listOfOssiaStudentCancelBooking =new List<OssiaStudentCancelBooking> ();
        }
    }
    public class OssiaStudentCancelBooking{
        public String cancelDateTime{get;set;}
        public string teacherName{get;set;}
        // 23-Jul-2020:Nishi:start we added cancellation table new columns
        public string status{get;set;}
        public string cancellationReason{get;set;}
        public Integer availableMakeupMinutes {get;set;}
        // 23-Jul-2020:Nishi:end: we added cancellation table new columns
        public string centerName{get;set;}
        public string bookingName{get;set;}
        public string bookingDateTime{get;set;}
        public string duration{get;set;}
        public string bookingtype{get;set;} //18-aug-2020 for show booking type
        
        public OssiaStudentCancelBooking(){
            this.cancelDateTime ='';
            this.teacherName = '';
            this.centerName ='';
            this.bookingName ='';
            this.bookingDateTime = '';
            this.duration ='';
            this.status ='';
            this.cancellationReason ='';
            this.availableMakeupMinutes =0;
            this.bookingtype = '';
        }
        public OssiaStudentCancelBooking(string  cancelDateTime,string teacherName,string centerName,
        string  bookingName,string  bookingDateTime,string  duration,string status,string cancellationReason,String availableMakeupMinutes,string bookingtype){
                this.cancelDateTime =cancelDateTime;
                this.teacherName = teacherName;
                this.status = status;
                this.cancellationReason = cancellationReason;
                this.availableMakeupMinutes = String.isNotBlank(availableMakeupMinutes)? Integer.valueOf(availableMakeupMinutes ):0;
                this.centerName =centerName;
                this.bookingName =bookingName;
                this.bookingDateTime = bookingDateTime;
                this.duration =duration;
                this.bookingtype =bookingtype;
        }
        
    }
    // cancel Ossia Student Booking 
    @RemoteAction 
    public static AureusCalendarController.ProcessResult cancelOssiaMakeupBooking(String bookingId, String cancelReason, 
    String redirectCase, string caseId, String isFuture,Boolean isNoMakeup,String makeUpReason, String makeupRemark ){
        AureusCalendarController.ProcessResult objResult = new AureusCalendarController.ProcessResult();
        List<Booking__c> bookingList = new List<Booking__c>();
        List<Booking__c> placeholderList = new List<Booking__c>();
        //to check that booking is adhoc and it should be fifth
        Boolean adhocInvoiceCheck = false;
                                                                                  
        /*  Boolean isNoMakeup = false;
            if(makeUpReason == 'NoMakeUpForToday'){
                isNoMakeup = true;
                makeUpReason = '';
            }*/
            //String msg = '';
            if(String.isNotBlank(bookingId)){
                bookingList = [SELECT Id, Name, Status__c, Type__c, Make_up_Utilize_Bookings__c, Center__c,Group_Class__c,
                            Make_up_Expiry_Date__c, Booking_Date__c, Makeup_Reason__c, Teacher_Account__c, 
                            Make_up_Credit_Note__c, Start_Time__c, Duration__c, Student__c, Student__r.Name, 
                            Student__r.Parent__c, End_Time__c, Available_Make_up_Units__c, Cancellation_Reason__c, 
                            RecordtypeId, RecordType.Name, Category__c, Appointment_Day__c, Is_fifth_booking__c,
                            Center__r.Name,Center__r.Organisation__r.Name
                             FROM Booking__c 
                            WHERE Id =: bookingId];
                if(bookingList != null && bookingList.size() > 0 && String.isNotBlank(bookingList[0].Center__c) && 
                String.isNotBlank(bookingList[0].Center__r.Organisation__c) && 
                String.isNotBlank(bookingList[0].Center__r.Organisation__r.Name) && 
                bookingList[0].Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                     
                    List<Ossia_Organisation_Settings__mdt> listOfOssia_Organisation_Settings = [SELECT Id, DeveloperName, MasterLabel, 
                    Language, NamespacePrefix, Label, QualifiedApiName, Makeup_Expiry_Days__c,
                    Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
                    WHERE Label =:System.Label.Ossia_Organisation_Name];
                        if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){ 
                //system.debug('@@@bookingList'+bookingList);
                    Date expiryDate;
                    // @@jatin : 17-dec-2019: added Booking type is 'Group lesson' then this booking work same as regular booking 
                    if(bookingList[0].Type__c == ConstantsClass.typeRegular || 
                    /* commented by nishi jain: 21-Jul-2020 bookingList[0].Type__c == ConstantsClass.typePianoViewing || */
                        bookingList[0].Type__c == ConstantsClass.groupLessonTypeBooking   ||
                        bookingList[0].Type__c == ConstantsClass.typeAdhoc){
                        
                        bookingList[0].Status__c = ConstantsClass.statusCanceled;
                        
                        //Check that booking is adhoc and its Invoice status is paid -- @jatin Due to change in Functionality by julius
                        if((bookingList[0].Type__c == ConstantsClass.typeAdhoc /*&& checkAdhocIsPaid(bookingList[0].Id)*/) 
                            || bookingList[0].Type__c == ConstantsClass.typeRegular
                            // @@jatin : 17-dec-2019: added Booking type is 'Group lesson' then this booking work same as regular booking 
                            /*commented by nishi : 21-Jul-2020*/
                            || bookingList[0].Type__c == ConstantsClass.groupLessonTypeBooking){
                            if(bookingList[0].Booking_Date__c != null){
                                expiryDate = bookingList[0].Booking_Date__c.addDays(Integer.valueOf(listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days__c));
                               //System.debug('listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days__c'+listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days__c);
                               //System.debug('listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_Teacher__c'+listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_Teacher__c);
                                if(string.isNotBlank(cancelReason) &&(cancelReason.equalsIgnoreCase('Teacher MC') || cancelReason.equalsIgnoreCase('Teacher Leave'))){
                                    expiryDate = bookingList[0].Booking_Date__c.addDays(Integer.valueOf(listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_Teacher__c));
                                }else if(string.isNotBlank(makeUpReason) && (makeUpReason.equalsIgnoreCase('Teacher MC') || makeUpReason.equalsIgnoreCase('Teacher leaves'))){
                                    expiryDate = bookingList[0].Booking_Date__c.addDays(Integer.valueOf(listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_Teacher__c));
                                }
                               //System.debug('bookingList[0].Booking_Date__c'+bookingList[0].Booking_Date__c);
                               //System.debug('expiryDate'+expiryDate);
                                
                                
                            }

                            if(isNoMakeup == false ){
                                if((string.isNotBlank(cancelReason) && cancelReason != 'MC') 
                                ||(string.isNotBlank(makeUpReason) && makeUpReason != 'Student MC') ){
                                    bookingList[0].Available_Make_up_Units__c = bookingList[0].Duration__c; 
                                    bookingList[0].Make_up_Expiry_Date__c  = expiryDate;
                                }
                            }
                            
                            
                            
                            if(String.isNotBlank(makeUpReason) && (makeUpReason == ConstantsClass.makeupReasonOther 
                            ||  makeUpReason == ConstantsClass.makeupAdminException) 
                                && String.isNotBlank(makeupRemark)){
                                bookingList[0].Makeup_Reason__c =  makeUpReason;
                                bookingList[0].Make_up_Credit_Note__c = makeupRemark;
                            }else if(String.isNotBlank(makeUpReason)){
                                bookingList[0].Makeup_Reason__c =  makeUpReason;
                            }    
                        }
                    }else if(bookingList[0].Type__c == ConstantsClass.typeTrial 
                        || bookingList[0].Type__c == ConstantsClass.typeMakeup
                        || bookingList[0].Type__c == ConstantsClass.typeBusy ){
                        if(bookingList[0].Type__c == ConstantsClass.typeBusy && isFuture == 'true'){
                            if(!AureusCalendarController.cancelAllFutureBusyBookings(AureusCalendarController.getFutureBusyBookings(bookingList[0]))){
                                objResult.msg = 'Error';
                            }
                        }
                        bookingList[0].Status__c = ConstantsClass.statusCanceled;
                        
                        if(bookingList[0].Type__c == ConstantsClass.typeMakeup){
                            List<String> makeupReferenceList = new List<String>();
                            Set<String> bookingIds = new Set<String>();
                            List<Booking__c> bookingListObj = new List<Booking__c>();
                            List<Booking__c> bookingUpdatedList = new List<Booking__c>();
                            if(String.isNotBlank(bookingList[0].Make_up_Utilize_Bookings__c)){
                                makeupReferenceList.addAll(bookingList[0].Make_up_Utilize_Bookings__c.split(';'));
                                if(makeupReferenceList.size() > 0){
                                    for(String makeup : makeupReferenceList){
                                        if(String.isNotBlank(makeup)){
                                            bookingIds.add(makeup.split('-')[0]);
                                        }
                                    }
                                }    
                                if(bookingIds.size() > 0){
                                    bookingListObj = [SELECT Id, Available_Make_up_Units__c, Make_up_Expiry_Date__c
                                     FROM Booking__c WHERE Make_up_Expiry_Date__c >= TODAY AND Id IN: bookingIds];
                                    if(bookingListObj.size() > 0){
                                        for(Booking__c booking : bookingListObj){
                                            for(String currentMakeup : makeupReferenceList){
                                                if(currentMakeup.contains(booking.Id)){
                                                    bookingUpdatedList.add(new Booking__c(Id = booking.Id, Available_Make_up_Units__c = booking.Available_Make_up_Units__c + Decimal.valueOf(currentMakeup.split('-')[1])));
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                                if(bookingUpdatedList.size() > 0){
                                    update bookingUpdatedList;
                                }
                                bookingList[0].Make_up_Utilize_Bookings__c = '';
                            }
                        }
                    }
                    bookingList[0].Cancellation_Reason__c = cancelReason;
                    Database.SaveResult saveResult = Database.update(bookingList[0], false);
                    
                    if (saveResult.isSuccess()) {
                        Boolean isError = false;
                    //system.debug('@@@bookingList'+bookingList[0]);
                        List<Booking__c> bookList = new List<Booking__c>();
                        bookList.add(bookingList[0]);
                        objResult.msg = 'Event Cancelled Successfully';
                        String parentId='';
                        
                        if(bookList[0].Type__c == ConstantsClass.typeRegular ){
                            placeholderList.addAll(AureusCalendarController.createPlaceholder(bookList, 'cancel', ''));
                        }
                        /// @@jatin: 1-jan-2020 for create placeholder for group lesson
                        if(bookList[0].Type__c == ConstantsClass.groupLessonTypeBooking ){
                            placeholderList.addAll(AureusCalendarController.createPlaceholderForGroupClass(bookList, 'cancel', ''));
                        }
                        Database.SaveResult[] saveResults = Database.insert(placeholderList, false);
                        for(Database.SaveResult sr : saveResults){
                            if (!sr.isSuccess()) {
                                isError = true;
                            }
                        }
                        
                        if(!isError && bookList.size() > 0 && bookList[0].Type__c != ConstantsClass.typeBusy && redirectCase == 'true'){
                            Case objCase =  AureusCalendarControllerHelper.createCase(caseId, bookList[0].Id, 'cancel');
                            objResult.caseId = objCase.Id;
                        }
                        
                    }else{
                        for(Database.Error err : saveResult.getErrors()) {
                        //system.debug('@@@The following error has occurred. '+err.getStatusCode() + ' : ' + err.getMessage());
                            objResult.msg = 'The following error has occurred. '+err.getStatusCode() + ' : ' + err.getMessage();
                        }
                    }
                }
            }
        }
        return objResult;
    }
    //22-Jul-2020: Nishi:  for get ossia student enrolment Ids which Available_Make_up_mins__c greater then 0
    @RemoteAction 
    public static EnrolmentWrapper getOssiaStudentInstrument(string studentId,string parentId,String centerId){
        EnrolmentWrapper objEnrolmentWrapper = new EnrolmentWrapper();
        List<EnrolmentInstrumentWrapper> listOfEnrolmentInstrumentWrapper  = new List<EnrolmentInstrumentWrapper>();
        Map<string,List<Enrolment__c>> mapOfEnrolmentRelatedStudent = new Map<string,List<Enrolment__c>>();
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        list<string> accountIds = new list<string>();
        
        // if(string.isNotBlank(parentId)){
        //     accountIds.add(parentId);
        // }
        if(string.isNotBlank(studentId)){
            accountIds.add(studentId);
        }
        Set<string> instrumentlist= new Set<String>();
        if(accountIds != null && accountIds.size() >0 && string.isNotBlank(centerId)){
            
            for(Enrolment__c objEnrol: [SELECT Id,Name, Center__c, Parent__c,Center__r.Organisation__c,Center__r.Organisation__r.Name, 
                                        Student__c, Teacher__c, Type__c, Stage__c ,Available_Make_up_mins__c,Instrument__c
                                        FROM Enrolment__c where 
                                        // (Parent__c In: accountIds 
                                        // Or 
                                        Student__c In: accountIds
                                        //)
                                        AND Stage__c =:ConstantsClass.enroledStatus
                                        AND Type__c =: ConstantsClass.enrolRegularStatus
                                        //AND Center__c = :centerId  // commented by nishi: 5-Oct-2020: Makeup credit for Ossia should allow booking across the other Ossia centres
                                        and Center__r.Organisation__r.Name = :System.Label.Ossia_Organisation_Name
                                        //AND Teacher__c = :teacherId
                                        ]){
                    if(string.isNotBlank(objEnrol.Center__c) && string.isNotBlank(objEnrol.Center__r.Organisation__c) &&
                    string.isNotBlank(objEnrol.Center__r.Organisation__r.Name) && 
                    objEnrol.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                        EnrolmentInstrumentWrapper sObj = new EnrolmentInstrumentWrapper();
                        sObj.teacherId = objEnrol.Teacher__c;
                        sObj.instrument =objEnrol.Instrument__c;
                        instrumentlist.add(objEnrol.Instrument__c);
                        sObj.enrolmentId = objEnrol.Id;
                        sObj.enrolmentName = objEnrol.Name;
                        if(objEnrol.Available_Make_up_mins__c != null && objEnrol.Available_Make_up_mins__c > 0){
                            sObj.makeupHours = Integer.valueOf(objEnrol.Available_Make_up_mins__c);
                        }else{
                            sObj.makeupHours = 0;
                        }
                        listOfEnrolmentInstrumentWrapper.add(sObj);     
                }
            }
        }
        objEnrolmentWrapper.listOfEnrolmentInstrumentWrapper = listOfEnrolmentInstrumentWrapper;
        // if(instrumentlist != null && instrumentlist.size() > 0){
        //     //objEnrolmentWrapper.teacherList =  getListOfTeachersByInstrument(centerId,String.join((Iterable<String>)instrumentlist,','));
        //   //  objEnrolmentWrapper.teacherList =  getListOfTeacher(centerId);
        // }
        objEnrolmentWrapper.teacherList =  getListOfTeacher(centerId);
        return objEnrolmentWrapper;
    }

     //22-Jul-2020: Nishi:  for get ossia student enrolment Ids which Available_Make_up_mins__c greater then 0
     @RemoteAction 
     public static EnrolmentWrapper getOssiaGroupClassStudentInstrument(String centerId,String teacherId,string groupClassId,string studentId){
         EnrolmentWrapper objEnrolmentWrapper = new EnrolmentWrapper();
         List<EnrolmentInstrumentWrapper> listOfEnrolmentInstrumentWrapper  = new List<EnrolmentInstrumentWrapper>();
         Map<string,List<Enrolment__c>> mapOfEnrolmentRelatedStudent = new Map<string,List<Enrolment__c>>();
         List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
         list<string> accountIds = new list<string>();
         Set<string> instrumentlist= new Set<String>();
         if(String.isNotBlank(studentId) && string.isNotBlank(centerId)){
             for(Enrolment__c objEnrol: [SELECT Id,Name, Center__c, Parent__c,Center__r.Organisation__c,Center__r.Organisation__r.Name, 
                                         Student__c, Teacher__c, Type__c, Stage__c ,Available_Make_up_mins__c,Instrument__c,Package__c,Package__r.name
                                         FROM Enrolment__c where 
                                         Student__c =: studentId
                                         AND Stage__c =:ConstantsClass.enroledStatus
                                         AND Type__c =: ConstantsClass.enrolGroupType
                                         //AND Center__c = :centerId  // commented by nishi: 5-Oct-2020: Makeup credit for Ossia should allow booking across the other Ossia centres
                                         and Center__r.Organisation__r.Name = :System.Label.Ossia_Organisation_Name
                                         ]){
                                             if(string.isNotBlank(objEnrol.Center__c) && string.isNotBlank(objEnrol.Center__r.Organisation__c) &&
                                                string.isNotBlank(objEnrol.Center__r.Organisation__r.Name) && 
                                                objEnrol.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                                                    EnrolmentInstrumentWrapper sObj = new EnrolmentInstrumentWrapper();
                                                    sObj.teacherId = objEnrol.Teacher__c;
                                                    sObj.instrument =objEnrol.Instrument__c;
                                                    sObj.enrolmentId = objEnrol.Id;
                                                    sObj.enrolmentName = objEnrol.Name;
                                                    if(objEnrol.Available_Make_up_mins__c != null && objEnrol.Available_Make_up_mins__c > 0){
                                                        sObj.makeupHours = Integer.valueOf(objEnrol.Available_Make_up_mins__c);
                                                    }else{
                                                        sObj.makeupHours = 0;
                                                    }
                                                    listOfEnrolmentInstrumentWrapper.add(sObj);  
                                                }
            }
         }
         objEnrolmentWrapper.listOfEnrolmentInstrumentWrapper = listOfEnrolmentInstrumentWrapper;
         List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c 
                                    FROM Account WHERE Id =:teacherId];
            if(tchrList.size() > 0){        

                for(Account acc: tchrList){        

                    if(acc.Major_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Major_Instruments_Disciplines__c.split(';'))        
                            instrumentlist.add(strIns);        
                    }       

                    if(acc.Minor_Instruments_Disciplines__c != null){       
                        for(String strIns : acc.Minor_Instruments_Disciplines__c.split(';'))        
                            instrumentlist.add(strIns);        
                    }       

                }
            }
            List<Ossia_Group_Grade_Package__c> listOfclass =  [SELECT Class_Name__c, Package__c,Package__r.name,  Name, Id ,Package__r.Program__r.Instrument__c
                                                FROM Ossia_Group_Grade_Package__c
                                                Where Class_Name__c =:groupClassId
                                                AND Package__r.Program__r.Instrument__c In:instrumentlist ];
                if(listOfclass != null && listOfclass.size() > 0){
                    Set<string> classInstrumentList= new Set<String>();
                    for(Ossia_Group_Grade_Package__c classObj : listOfclass ){
                        classInstrumentList.add(classObj.Package__r.Program__r.Instrument__c);
                    }
                    objEnrolmentWrapper.classInstrument = String.join(new List<String>(classInstrumentList),';') ; 
                    objEnrolmentWrapper.packageId = listOfclass[0].Package__c;
                    objEnrolmentWrapper.packageName = listOfclass[0].Package__r.name;
                }                                    
        
            return objEnrolmentWrapper;
        }

     //2-Nov-2020: Nishi:  for get ossia student enrolment Ids which Available_Make_up_mins__c greater then 0 and get Adhoc-Group type packages accroding to duration
    @RemoteAction 
    public static EnrolmentWrapper getOssiaGroupClassAdhocPackages(String centerId,String teacherId,string groupClassId,string studentId,Boolean isOssia){
        EnrolmentWrapper objEnrolmentWrapper = new EnrolmentWrapper();
        List<EnrolmentInstrumentWrapper> listOfEnrolmentInstrumentWrapper  = new List<EnrolmentInstrumentWrapper>();
        Map<string,List<Enrolment__c>> mapOfEnrolmentRelatedStudent = new Map<string,List<Enrolment__c>>();
        List<Enrolment__c> listOfEnrolment = new List<Enrolment__c>();
        list<string> accountIds = new list<string>();
        Set<string> instrumentlist= new Set<String>();
        Package__c packageObj = new Package__c();
        if(String.isNotBlank(studentId) && string.isNotBlank(centerId)){
            set<string> enrolmenttype = new Set<string>{ConstantsClass.enrolGroupType,ConstantsClass.enrolRegularStatus};
            List<Enrolment__c> enrolmentList = [SELECT Id,Name, Center__c, Parent__c,Center__r.Organisation__c,Center__r.Organisation__r.Name, 
                                                    Student__c, Teacher__c, Type__c, Stage__c ,Available_Make_up_mins__c,Instrument__c,Package__c,Package__r.name,
                                                    package__r.Grade_new__c,Package__r.Duration__c,Package__r.Program__r.Instrument__c
                                                    FROM Enrolment__c where 
                                                    Student__c =: studentId
                                                    AND Stage__c =:ConstantsClass.enroledStatus
                                                   AND Type__c In: enrolmenttype
                                                    and Center__r.Organisation__r.Name = :System.Label.Ossia_Organisation_Name
                                                    ];
            for(Enrolment__c objEnrol: enrolmentList){
                                          
                EnrolmentInstrumentWrapper sObj = new EnrolmentInstrumentWrapper();
                sObj.teacherId = objEnrol.Teacher__c;
                sObj.instrument =objEnrol.Instrument__c;
                sObj.enrolmentId = objEnrol.Id;
                sObj.enrolmentName = objEnrol.Name;
                if(isOssia){
                    if(objEnrol.Available_Make_up_mins__c != null && objEnrol.Available_Make_up_mins__c > 0){
                        sObj.makeupHours = Integer.valueOf(objEnrol.Available_Make_up_mins__c);
                    }else{
                        sObj.makeupHours = 0;
                    }
                }
                listOfEnrolmentInstrumentWrapper.add(sObj);  
            
            }
            system.debug('enrolmentList'+enrolmentList);
            objEnrolmentWrapper.listOfEnrolmentInstrumentWrapper = listOfEnrolmentInstrumentWrapper;
            List<Account> tchrList = [SELECT Id,Major_Instruments_Disciplines__c,Minor_Instruments_Disciplines__c 
                                        FROM Account WHERE Id =:teacherId];
                if(tchrList.size() > 0){        

                    for(Account acc: tchrList){        

                        if(acc.Major_Instruments_Disciplines__c != null){       
                            for(String strIns : acc.Major_Instruments_Disciplines__c.split(';'))        
                                instrumentlist.add(strIns);        
                        }       

                        if(acc.Minor_Instruments_Disciplines__c != null){       
                            for(String strIns : acc.Minor_Instruments_Disciplines__c.split(';'))        
                                instrumentlist.add(strIns);        
                        }       

                    }
                }
                system.debug('objEnrolmentWrapper.classInstrument '+objEnrolmentWrapper.classInstrument );
                system.debug('instrumentlist'+instrumentlist);
                Map<String, Package__c> adhocPackageMap = new Map <String, Package__c>();
                if(isOssia){
                    Set<string> gradeList = new Set<string>();
                    List<Ossia_Group_Grade_Package__c> listOfclass =  [SELECT Class_Name__c, Package__c,Package__r.Duration__c,Package__r.name,  Name, Id ,
                                                                        Package__r.Program__r.Instrument__c,Class_Name__r.Grade__c
                                                                        FROM Ossia_Group_Grade_Package__c
                                                                        Where Class_Name__c =:groupClassId
                                                                        AND Package__r.Program__r.Instrument__c In:instrumentlist ];
                    if(listOfclass != null && listOfclass.size() > 0){
                        Set<string> classInstrumentList= new Set<String>();
                        for(Ossia_Group_Grade_Package__c classObj : listOfclass ){
                            /*if(string.isnotBlank(classObj.Class_Name__r.Grade__c) && classObj.Class_Name__r.Grade__c.split(';') != null && classObj.Class_Name__r.Grade__c.split(';').size() > 0){
                                gradeList.addAll(classObj.Class_Name__r.Grade__c.split(';'));
                            }*/
                            classInstrumentList.add(classObj.Package__r.Program__r.Instrument__c);
                        }
                        objEnrolmentWrapper.classInstrument = String.join(new List<String>(classInstrumentList),';') ; 
                    }  
                    /*adhocPackageMap = fetchOssiaAdhocLessons(centerId,listOfclass[0].Package__r.Duration__c,new set<string>{enrolmentList[0].Package__r.Program__r.Instrument__c},gradeList);
                    if( string.isNotBlank(enrolmentList[0].package__r.Grade_new__c) && enrolmentList[0].package__r.Grade_new__c.split(';') != null &&  enrolmentList[0].package__r.Grade_new__c.split(';').size() >0){
                        for(string grade :enrolmentList[0].package__r.Grade_new__c.split(';')){
                            system.debug('grade'+grade);
                            if(adhocPackageMap.containsKey(centerId + '-'+ listOfclass[0].Package__r.Duration__c + '-'+ grade+ '-'+ enrolmentList[0].Package__r.Program__r.Instrument__c)){
                                packageObj = adhocPackageMap.get(centerId + '-'+ listOfclass[0].Package__r.Duration__c + '-'+ grade+ '-'+ enrolmentList[0].Package__r.Program__r.Instrument__c);
                                objEnrolmentWrapper.packageId = packageObj.id;
                                objEnrolmentWrapper.packageName = packageObj.name;
                                break;
                            }
                        }
                    }*/
                }/*else{
                    List<class__c> classList = [select id,Package__r.Duration__c from class__C where id=:groupClassId];
                    adhocPackageMap = fetchAdhocLessons(centerId,classList[0].Package__r.Duration__c);
                    //added by nishi:22-Oct-2020:end: for ossia center we get adhoc packages accoding to enrolment grade and instrument
                    if( adhocPackageMap.containsKey(centerId + '-'+ classList[0].Package__r.Duration__c)){
                        packageObj = adhocPackageMap.get(centerId + '-'+ classList[0].Package__r.Duration__c);
                        objEnrolmentWrapper.packageId = packageObj.id;
                        objEnrolmentWrapper.packageName = packageObj.name;
                    }
                }*/
                //system.debug('adhocPackageMap'+adhocPackageMap);
                //system.debug('packageObj'+packageObj);
               
            }                                 
            return objEnrolmentWrapper;
        }
        /*public static Map<String, Package__c> fetchAdhocLessons(string centerId,string duration){
            Map<String, Package__c> mapOfAdhocPackage = new Map<String, Package__c>();
            if(string.isNotBlank(centerId) && string.isNotBlank(duration)  ){
                for(Package__c packageObj : [SELECT Id,name, Location__c, Duration__c,Program__r.Instrument__c,Grade_new__c, unit_Fee__c FROM Package__c 
                                             WHERE Active__c = TRUE AND Type__c =: ConstantsClass.typeAdhocGroup AND Location__c =:centerId AND 
                                             Duration__c =:duration]){
                    mapOfAdhocPackage.put(packageObj.Location__c + '-' + packageObj.Duration__c, packageObj);
                } 
            }
            return mapOfAdhocPackage;
        }
        
        //added by nishi:22-Oct-2020: for ossia center we get adhoc packages accoding to enrolment grade and instrument
        public static  Map<String, Package__c> fetchOssiaAdhocLessons(string centerId,string duration,Set<string> instruments,Set<string> gradeList){
            Map<String, Package__c> mapOfAdhocPackage = new Map<String, Package__c>();
            if(string.isNotBlank(centerId) && string.isNotBlank(duration) ){
                for(Package__c packageObj : [SELECT Id,name, Location__c, Duration__c, unit_Fee__c,Grade_new__c,Program__r.Instrument__c FROM Package__c 
                                             WHERE Active__c = TRUE 
                                             AND Type__c =: ConstantsClass.typeAdhocGroup 
                                             AND Location__c = :centerId 
                                             AND Duration__c =:duration
                                             And Program__r.Instrument__c In: instruments]){
                                                system.debug('packageObj.Grade_new__c'+packageObj.Grade_new__c);
                    if(string.isNotBlank(packageObj.Grade_new__c)){
                        for(String grade : packageObj.Grade_new__c.split(';')){
                            system.debug('grade'+grade);
                            if(gradeList.contains(grade)){ 
                                mapOfAdhocPackage.put(packageObj.Location__c + '-' + packageObj.Duration__c+ '-' + grade+ '-' + packageObj.Program__r.Instrument__c, packageObj);
                            }
                        }
                    } 
                }
            }
            system.debug('mapOfAdhocPackage'+mapOfAdhocPackage);
            return mapOfAdhocPackage;
        }
*/
        // 21-Sep-2020: nsihi: for get time slots according to selected teacher,package, effective dates 
        public static List<Booking__c> getGroupClassOssiaBookingsOnSelectedDates(String centerId, String teacherId,string selectedPackage, Set<Date> dates){
            String groupBookingRecordType = ConstantsClass.groupBookingRecordType;
            Set<string> bookingStatus = new Set<String>{ConstantsClass.statusPending, ConstantsClass.statusScheduled, ConstantsClass.statusReScheduled, ConstantsClass.statusCompleted, ConstantsClass.blockStatus};
            Set<String> bookTypeSet = new Set<String>{ConstantsClass.groupTypeBooking};
            Set<String> busyStatusSet  = new Set<String>{ConstantsClass.leaveCategory, ConstantsClass.holidayCategory};     
            Date dt, endDt;
            String busyType = ConstantsClass.typeBusy;
            Set<string> classIds = new Set<string>();
            String weekDay;
            for(Ossia_Group_Grade_Package__c objclass :  [SELECT Class_Name__c, Package__c,Package__r.name,  Name, Id ,Package__r.Program__r.Instrument__c
                                                            FROM Ossia_Group_Grade_Package__c
                                                            Where Class_Name__r.Centre_Name__c =: centerId
                                                            AND  Class_Name__r.Teacher__c =: teacherId
                                                            And Package__c=:selectedPackage]){
                                                                classIds.add(objclass.Class_Name__c);
            }
            if(classIds != null && classIds.size() > 0){
                String queryStr = 'SELECT Id, Name,Class__C, start_Time__c, End_Time__c, status__c, type__c, RecordType.Name, Center__c, Teacher_Account__c, Booking_Date__c FROM Booking__c';
                queryStr += ' WHERE RecordType.Name =: groupBookingRecordType AND Start_Time__c != NULL AND End_Time__c != NULL AND Class__C != null and Class__r.Is_Makeup_Class__c = false';
                if(String.isNotBlank(centerId)){
                    queryStr += ' AND Center__c =: centerId';
                }
                if(String.isNotBlank(teacherId)){
                    queryStr += ' AND Teacher_Account__c =: teacherId';
                }
                    queryStr += ' and Class__C In: classIds';
                
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
                return Database.query(queryStr);
            }

            //System.debug('@@@@queryStr'+queryStr);
            return new List<Booking__c>();
            
        }    
     
    //21-Sep-2020:nishi: show ossia group class teachers list according to selected Advance action button if click GroupToSameClass then show same package fee reocrds
    // and GroupToHigherPackage show higher package fee records
    public static List<Account> getListOfOssiaClassTeacher(string centerId,string packageId,string changeEnrolType){
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
                string queryClass= 'SELECT Class_Name__c, Package__c,Package__r.name, Class_Name__r.Teacher__c, Name, Id ,Package__r.Program__r.Instrument__c FROM Ossia_Group_Grade_Package__c';
                queryClass += ' Where Class_Name__r.Available_Capacity__c > 0 ';
                If(string.isNotBlank(centerId)){
                    queryClass += ' And Class_Name__r.Centre_Name__c =:centerId ';
                }
                If(mapOfTeachers != null && mapOfTeachers.size() > 0){
                    set<Id> teacherIds = mapOfTeachers.keySet();
                    queryClass += ' AND Class_Name__r.Teacher__c In:teacherIds ';
                }
                If(string.isNotBlank(objpackage.Id) && objpackage.Package_Fee__c != null && objpackage.Package_Fee__c > 0 ){
                    decimal packageFee = objpackage.Package_Fee__c;
                    if(changeEnrolType.equalsIgnoreCase('GroupToSameClass') ){
                        queryClass += ' AND package__r.Package_Fee__c =: packageFee ';
                    }else if(changeEnrolType.equalsIgnoreCase('GroupToHigherPackage')){
                        queryClass += ' AND package__r.Package_Fee__c >: packageFee ';
                    }
                }
                List<Ossia_Group_Grade_Package__c> listOfCLass = DataBase.Query(queryClass);
                if(listOfCLass != null && listOfCLass.size() > 0){
                    for(Ossia_Group_Grade_Package__c objClass :listOfCLass){
                        if(mapOfTeachers.containsKey(objClass.Class_Name__r.Teacher__c) && mapOfInstruments.containsKey(objClass.Class_Name__r.Teacher__c)){
                            if(mapOfInstruments.get(objClass.Class_Name__r.Teacher__c).contains(objClass.Package__r.Program__r.Instrument__c)){
                                mapOfGroupClassTeachers.put(objClass.Class_Name__r.Teacher__c,mapOfTeachers.get(objClass.Class_Name__r.Teacher__c));
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

    @RemoteAction
    public static List<Account> getListOfTeacher(String centerId){
        List<Account> accList = new List<Account>();
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        Set<String> teachersIdSet = new Set<String>();
        
        if(String.isNotBlank(centerId)){
            List<Teacher_Working_Hour__c> teacherWorkingHourList = new List<Teacher_Working_Hour__c>();
            teacherWorkingHourList = [SELECT id, Center_Name__c, Teacher_Name__c, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c 
                                    WHERE Center_Name__c =: centerId ];
            for(Teacher_Working_Hour__c twh : teacherWorkingHourList){
                teachersIdSet.add(twh.Teacher_Name__c);
            }
        }
        
        String query = '';             
        if(teachersIdSet.size() > 0){
            query = 'SELECT Id, Name,Minor_Instruments_Disciplines__c, Major_Instruments_Disciplines__c FROM Account WHERE RecordType.Name =: teacherRecType AND Status__c =: teacherWorkingStatus';
            query+= ' AND id IN : teachersIdSet';
            query+= ' ORDER BY Name';
        }
        if(String.isNotBlank(query))
            accList = Database.query(query);
        
        return accList;
    }

    public static List<Account> getListOfTeachersByInstrument(String centerId, string instruments){
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        String teacherRecType = ConstantsClass.teacherRecordType;
        Set<String> teachersIdSet = new Set<String>();
        
        if(String.isNotBlank(centerId)){
            List<Teacher_Working_Hour__c> teacherWorkingHourList = new List<Teacher_Working_Hour__c>();
            teacherWorkingHourList = [SELECT id, Center_Name__c, Teacher_Name__c, Start_Time__c, End_Time__c FROM Teacher_Working_Hour__c WHERE Center_Name__c =: centerId ];
            for(Teacher_Working_Hour__c twh : teacherWorkingHourList){
                teachersIdSet.add(twh.Teacher_Name__c);
            }
        }
        
        String query = 'SELECT Id, Name, Minor_Instruments_Disciplines__c, Major_Instruments_Disciplines__c FROM Account WHERE RecordType.Name =: teacherRecType AND Status__c =: teacherWorkingStatus';
        if(teachersIdSet.size() > 0){
            query+= ' AND (Minor_Instruments_Disciplines__c includes (:instruments) OR Major_Instruments_Disciplines__c includes (:instruments)) AND id IN : teachersIdSet';
        }
        
        query+= ' ORDER BY Name';
        
        return Database.query(query);
    }

    // added by nishi: 22-jul-2020:Start for is student belongs to ossia center then we get makeupmins to enrolment other wise 
    //we get makeup hrs to parent 
    public class EnrolmentWrapper{
        public List<EnrolmentInstrumentWrapper> listOfEnrolmentInstrumentWrapper ;
        public List<Account> teacherList;
        public string packageName;
        public string packageId;
        public string classInstrument;
    }
    public class EnrolmentInstrumentWrapper{
        public string enrolmentId;
        public string enrolmentName;
        public string teacherId;
        public Integer makeupHours;
        public string instrument;
    }
    // added by nishi: 22-jul-2020:END for is student belongs to ossia center then we get makeupmins to enrolment other wise 
    //we get makeup hrs to parent 
   

     //23-Jul-2020: Nishi:Start:  deduct makeup hours and minus available mins and calculate utilize min then update parent 
    //  according to new requiremnt While utilizing Make up credit, 
     //it should consider those makeup minutes which are related to the booking with the cancellation reason – Teacher MC/Leave first.
              
     public static void deductOssiaMakeupHours(List<Booking__c> bookingList, String bookingParentId,Set<string> enrolmentIds){
       //System.debug('deductOssiaMakeupHours Deduct Makeup hours called');
        String statusCanceled = ConstantsClass.statusCanceled;
        Boolean isError = false;
        String studentId;
        List<Booking__c> bookingUpdatedList = new List<Booking__c>();
        Integer hoursToDeduct = 0;
        Booking__c bookObj = new Booking__c();
        Set<Id> setOfBookings = new Set<Id>();
        Map<Id, Integer> mapOfHours = new Map<Id, Integer>();
        Map<Id, Integer> mapOfTeacherCancellationHours = new Map<Id, Integer>();
        Set<String> setOfParentStudent = new Set<String>();
        //System.debug('bookingParentId '+bookingParentId);
        if(String.isNotBlank(bookingParentId)){
            setOfParentStudent = AureusCalendarController.getParentsChild(bookingParentId);
        }
        
        if(bookingList.size() > 0){
            studentId = bookingList[0].Student__c;
            for(Booking__c bObj : bookingList){
                if(string.isNotBlank(bObj.Enrolment__c)){
                    enrolmentIds.add(bObj.Enrolment__c);
                }
            }
            //System.debug('setOfParentStudent '+setOfParentStudent.size());
            if(setOfParentStudent.size() > 0){
                // 23-Jul-2020: Nishi:Start: according to new requiremnt While utilizing Make up credit, 
                //it should consider those makeup minutes which are related to the booking with the cancellation reason – Teacher MC/Leave first.
                List<string> teacherCancellation = new List<string>{'Teacher MC','Teacher Leave'};
                List<Booking__c> cancelTeacherCancellationBookings =teacherLeaveReasonCancelBooking(enrolmentIds);
                if(cancelTeacherCancellationBookings != null && cancelTeacherCancellationBookings.size() > 0){
                    for(Booking__c cancelBooking : cancelTeacherCancellationBookings){
                        mapOfTeacherCancellationHours.put(cancelBooking.Id, Integer.valueOf(cancelBooking.Available_Make_up_Units__c)); 
                    }
                }
                List<Booking__c> cancelBookings = teacherLeaveWithOutReasonCancelBooking(enrolmentIds);
                if(cancelBookings != null && cancelBookings.size() > 0){
                    for(Booking__c cancelBooking : cancelBookings){
                        mapOfHours.put(cancelBooking.Id, Integer.valueOf(cancelBooking.Available_Make_up_Units__c)); 
                    }
                }
                
                if((mapOfTeacherCancellationHours != null && mapOfTeacherCancellationHours.size() > 0) || (mapOfHours != null && mapOfHours.size() > 0)){
                    for(Booking__c bookingObj : bookingList){
                        hoursToDeduct = Integer.valueOf(bookingObj.duration__c);
                        bookObj = new Booking__c();
                        bookObj.Id = bookingObj.Id;
                        bookObj.Make_up_Utilize_Bookings__c = '';
                        if(cancelTeacherCancellationBookings != null && cancelTeacherCancellationBookings.size() > 0){
                            for(Booking__c canceledBookings : cancelTeacherCancellationBookings){
                                if( mapOfTeacherCancellationHours.containsKey(canceledBookings.Id) && mapOfTeacherCancellationHours.get(canceledBookings.Id) > 0){
                                    if(hoursToDeduct > mapOfTeacherCancellationHours.get(canceledBookings.Id)){
                                        bookObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+mapOfTeacherCancellationHours.get(canceledBookings.Id)+';';
                                        hoursToDeduct -= mapOfTeacherCancellationHours.get(canceledBookings.Id);
                                        mapOfTeacherCancellationHours.put(canceledBookings.Id, 0);
                                    }else if(hoursToDeduct <= mapOfTeacherCancellationHours.get(canceledBookings.Id)){
                                        mapOfTeacherCancellationHours.put(canceledBookings.Id, mapOfTeacherCancellationHours.get(canceledBookings.Id) - hoursToDeduct);
                                        bookObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+hoursToDeduct+';';
                                        hoursToDeduct = 0;
                                    }
                                    //}
                                    if(hoursToDeduct <= 0){
                                        break;   
                                    }
                                }
                            }
                        }
                        if(hoursToDeduct > 0 && cancelBookings != null && cancelBookings.size() > 0){
                            for(Booking__c canceledBookings : cancelBookings){
                                if( mapOfHours.containsKey(canceledBookings.Id) && mapOfHours.get(canceledBookings.Id) > 0 ){
                                    //if(mapOfHours.get(key) > 0){
                                    if(hoursToDeduct > mapOfHours.get(canceledBookings.Id)){
                                        bookObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+mapOfHours.get(canceledBookings.Id)+';';
                                        hoursToDeduct -= mapOfHours.get(canceledBookings.Id);
                                        mapOfHours.put(canceledBookings.Id, 0);
                                    }else if(hoursToDeduct <= mapOfHours.get(canceledBookings.Id)){
                                        mapOfHours.put(canceledBookings.Id, mapOfHours.get(canceledBookings.Id) - hoursToDeduct);
                                        bookObj.Make_up_Utilize_Bookings__c  += canceledBookings.Id +'-'+hoursToDeduct+';';
                                        hoursToDeduct = 0;
                                    }
                                    //}
                                    if(hoursToDeduct <= 0){
                                        break;   
                                    }
                                }
                            }
                        }
                        //System.debug('bookObj '+bookObj);
                        bookingUpdatedList.add(bookObj);
                    }
                }
                for(String keysetValue : mapOfTeacherCancellationHours.keyset()){
                    if(mapOfTeacherCancellationHours.containsKey(keysetValue)){
                        bookingUpdatedList.add(new Booking__c(Id = keysetValue, 
                        Available_Make_up_Units__c = (Decimal)mapOfTeacherCancellationHours.get(keysetValue)));
                    }
                }

                for(String keysetValue : mapOfHours.keyset()){
                    if(mapOfHours.containsKey(keysetValue)){
                        bookingUpdatedList.add(new Booking__c(Id = keysetValue, 
                        Available_Make_up_Units__c = (Decimal)mapOfHours.get(keysetValue)));
                    }
                }
               //System.debug('bookingUpdatedList '+bookingUpdatedList);
                if(bookingUpdatedList.size() > 0){
                    Database.SaveResult[] saveResults = Database.update(bookingUpdatedList, false);
                    for(Database.SaveResult saveResult : saveResults){
                        if(!saveResult.isSuccess()){
                            isError = true;
                        }
                    }
                }
                String parentId;
                if(isError == false){
                    /// update parent available mins for cancel bookings only 
                    // beacuse trigger not calculate canceled booking available mins
                    if(enrolmentIds != null && enrolmentIds.size() >0 ){
                        cancelOssiaBookingProceed(enrolmentIds);
                    }
                }
                
            }   
        }
    }

    // cancel Ossia Booking Process 
    public static void cancelOssiaBookingProceed(Set<string> enrolmentIds){
        string lessonRecordtype = ConstantsClass.recordTypeLesson;
        string grouplessonRecordtype = ConstantsClass.groupLessonBookingRecordType;
        string statusCanceled = ConstantsClass.statusCanceled; 
        Map<String, Integer> sumOfEnrolmentMakupHours = new Map<String, Integer>();
        List<Enrolment__c> EnrolmentList = new List<Enrolment__c>();
        
        if(enrolmentIds != null && enrolmentIds.size() > 0){
            integer count = 0;
            for (AggregateResult ar : [SELECT  Enrolment__c, SUM(Available_Make_up_Units__c) 
                                        sumOfHours 
                                        FROM Booking__c 
                                        WHERE Recordtype.Name =: lessonRecordtype 
                                        AND status__c =: statusCanceled 
                                        AND Enrolment__c IN :enrolmentIds 
                                        AND Make_up_Expiry_Date__c > TODAY
                                        AND Make_up_Expiry_Date__c != NULL 
                                        GROUP BY Enrolment__c ])  {
                if(ar.get('sumOfHours') != NULL){
                    sumOfEnrolmentMakupHours.put(String.valueOf(ar.get('Enrolment__c')),
                        Integer.valueOf(ar.get('sumOfHours'))); 
                }
                
            }
           
            if(sumOfEnrolmentMakupHours !=null && sumOfEnrolmentMakupHours.size() >= 0){
                for(string enrolmentId : sumOfEnrolmentMakupHours.keySet()){
                    EnrolmentList.add(new Enrolment__c(Id = enrolmentId, Available_Make_up_mins__c = sumOfEnrolmentMakupHours.get(enrolmentId)));
                }
            }
        }
       //System.debug('EnrolmentList'+EnrolmentList);
        if(EnrolmentList.size() > 0){
            update EnrolmentList;
        }
    }

     // added by nishi: 10-aug-2020: for manage ossia Upgrade ,downGrade Subscription model
    @RemoteAction
    public static AureusCalendarController.EnrolmentEdit getOssiaEnrolmentUpdateDetails(String enrolmentId){
        return AureusCalendarController.getEnrolmentUpdateDetails(enrolmentId); 
        
    }
     // added by nishi: 10-aug-2020: for manage ossia Upgrade ,downGrade Subscription model
    

     //// added by nishi: 11-aug-2020: for manage ossia Upgrade ,downGrade package 
     //based on the selected teacher’s skills) – duration, Monthly fee including Facility fee, Grade
    //Packages whose monthly fee is greater than the current monthly fee will be displayed  

     @RemoteAction
     public static List<packageData> getPackageAccordingToOssiaTeacher(String centerId, String teacherId, Integer duration,
     String bookingId,string bookingType,Boolean isPackagePromotional){
            List<packageData> packageList = new List<packageData>();
            packageData dt = new packageData();
            Set<String> instruments =  new Set<String>();       
            List<Booking__c> bookingList = new List<Booking__c>();
            List<String> athomeCenterIds = new  List<String>();
            List<Ossia_Organisation_Settings__mdt> listOfOssia_Organisation_Settings = [SELECT Id, DeveloperName, MasterLabel, 
                                                Language, NamespacePrefix, Label, QualifiedApiName, Makeup_Expiry_Days__c,Ossia_at_Home_Id__c ,
                                                Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
                                                WHERE Label =:System.Label.Ossia_Organisation_Name];
                                                athomeCenterIds.add(Label.Aureus_at_Home_Id);   
            if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0 && string.isNotBlank(listOfOssia_Organisation_Settings[0].Ossia_at_Home_Id__c)){
                athomeCenterIds.add(listOfOssia_Organisation_Settings[0].Ossia_at_Home_Id__c);   
            }                        
            String pkgLessRecId =  Schema.SObjectType.Package__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId(); 
            if(String.isNotBlank(bookingId)){
                bookingList = [SELECT Id, Name, Package__c,Type__c, Package__r.Name, Package__r.Active__c, enrolment__r.Package__c,
                                enrolment__r.Package__r.Package_Fee__c, enrolment__c,// enrolment__r.Package__r.facility_Fee__c,
                                 // added by nishi: 28-Oct-2020: for if enrolment package type is Promotionl then we get Promotion detials 
                                enrolment__r.Package__r.Promotion_period_In_months__c,enrolment__r.Package__r.Promotion_Discount__c,enrolment__r.Package__r.Type_of_package__c,
                                enrolment__r.Package__r.Duration__c, enrolment__r.Lesson_Day__c, enrolment__r.Package__r.Type__c, 
                                enrolment__r.Package__r.Location__c, enrolment__r.Package__r.Program__r.Instrument__c
                                FROM Booking__c 
                                WHERE Id =: bookingId];
                if(bookingList.size() > 0){
                    
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
                    if(instruments.size() > 0 && String.isNotBlank(centerId) && String.isNotBlank(bookingType)){  

                        List<Package__c> getPackageList = new List<Package__c> ();
                        if(bookingType =='UpgradeEnrolment'){
                            getPackageList = [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c,//facility_Fee__c,
                                                Grade_new__c
                                                FROM Package__c 
                                                WHERE 
                                                //Duration__c > :bookingList[0].enrolment__r.Package__r.Duration__c AND 
                                                Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                                                Location__c =: bookingList[0].enrolment__r.Package__r.Location__c AND 
                                                Program__r.Instrument__c IN: instruments   AND 
                                                Active__c = true AND 
                                                Is_Promotion_Discount__c = false AND 
                                                Type_of_package__c = 'Normal' AND
                                                Package_Fee__c >:bookingList[0].enrolment__r.Package__r.Package_Fee__c  
                                                //AND facility_Fee__c >=:bookingList[0].enrolment__r.Package__r.facility_Fee__c
                                                ORDER BY Duration__c];
                            
                        }else if(bookingType =='DowngradeEnrolment'){
                            getPackageList = [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c,//facility_Fee__c,
                                                Grade_new__c
                                                FROM Package__c 
                                                WHERE 
                                                //Duration__c < :bookingList[0].enrolment__r.Package__r.Duration__c AND 
                                                Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                                                Location__c =: bookingList[0].enrolment__r.Package__r.Location__c AND 
                                                Program__r.Instrument__c IN: instruments   AND 
                                                Active__c = true AND 
                                                Is_Promotion_Discount__c = false AND 
                                                Type_of_package__c = 'Normal' AND
                                                Package_Fee__c <:bookingList[0].enrolment__r.Package__r.Package_Fee__c  
                                                //AND facility_Fee__c <=:bookingList[0].enrolment__r.Package__r.facility_Fee__c
                                                ORDER BY Duration__c];
                        }else if(bookingType =='UpdateEnrolment'){
                            // added by nishi: 28-oct-2020: if enrolment packages type is prepayement and user want to change enrolment then we show prepayment  packages not normal packages
                            if(isPackagePromotional){
                                getPackageList = [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c,//facility_Fee__c,
                                                Grade_new__c
                                                FROM Package__c 
                                                WHERE 
                                                Duration__c =: bookingList[0].enrolment__r.Package__r.Duration__c AND 
                                                Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                                                Location__c =: bookingList[0].enrolment__r.Package__r.Location__c AND 
                                                Program__r.Instrument__c IN: instruments   AND 
                                                Active__c = true AND 
                                                Type_of_package__c =: bookingList[0].enrolment__r.Package__r.Type_of_package__c AND
                                                Package_Fee__c =:bookingList[0].enrolment__r.Package__r.Package_Fee__c   AND
                                                Promotion_period_In_months__c =:bookingList[0].enrolment__r.Package__r.Promotion_period_In_months__c AND
                                                Promotion_Discount__c =:bookingList[0].enrolment__r.Package__r.Promotion_Discount__c
                                                ORDER BY Duration__c];
                            }
                            // added by nishi: 28-oct-2020: if enrolment packages type is prepayement and user want to change enrolment then we show prepayment  packages not normal packages
                            else{
                                getPackageList = [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c,//facility_Fee__c,
                                                Grade_new__c
                                                FROM Package__c 
                                                WHERE 
                                                //Duration__c = :bookingList[0].enrolment__r.Package__r.Duration__c AND 
                                                Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                                                Location__c =: bookingList[0].enrolment__r.Package__r.Location__c AND 
                                                Program__r.Instrument__c IN: instruments   AND 
                                                Active__c = true AND 
                                                Is_Promotion_Discount__c = false AND 
                                                Type_of_package__c = 'Normal' AND
                                                Package_Fee__c =:bookingList[0].enrolment__r.Package__r.Package_Fee__c  
                                                //AND facility_Fee__c =:bookingList[0].enrolment__r.Package__r.facility_Fee__c
                                                ORDER BY Duration__c];
                            }
                        } else if(bookingType =='UpdateEnrolmentCenter'){
                            //31-Aug-2020: nishi:start-  all those packages where new price is > then current price if the target centre is Home
                            // other wise Packages whose monthly fee is equal to the current monthly fee 
                            if(athomeCenterIds.contains(centerId)){
                                getPackageList = [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c,//facility_Fee__c,
                                                Grade_new__c
                                                FROM Package__c 
                                                WHERE 
                                                //Duration__c = :bookingList[0].enrolment__r.Package__r.Duration__c AND 
                                                Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                                                Location__c =: centerId AND 
                                                Program__r.Instrument__c IN: instruments   AND 
                                                Active__c = true AND 
                                                Is_Promotion_Discount__c = false AND 
                                                Type_of_package__c = 'Normal' AND
                                                Package_Fee__c >: bookingList[0].enrolment__r.Package__r.Package_Fee__c  
                                                //AND facility_Fee__c =:bookingList[0].enrolment__r.Package__r.facility_Fee__c
                                                ORDER BY Duration__c];
                            }else{
                                getPackageList = [SELECT Id, Name, Program__r.Instrument__c, Active__c, Package_Fee__c, Location__c, Duration__c,//facility_Fee__c,
                                                Grade_new__c
                                                FROM Package__c 
                                                WHERE 
                                                //Duration__c = :bookingList[0].enrolment__r.Package__r.Duration__c AND 
                                                Type__c =: bookingList[0].enrolment__r.Package__r.Type__c AND 
                                                Location__c =: centerId AND 
                                                Program__r.Instrument__c IN: instruments   AND 
                                                Active__c = true AND 
                                                Is_Promotion_Discount__c = false AND 
                                                Type_of_package__c = 'Normal' AND
                                                Package_Fee__c =:bookingList[0].enrolment__r.Package__r.Package_Fee__c  
                                                //AND facility_Fee__c =:bookingList[0].enrolment__r.Package__r.facility_Fee__c
                                                ORDER BY Duration__c];
                            }
                            //31-Aug-2020: nishi:start-  all those packages where new price is > then current price if the target centre is Home
                            // other wise Packages whose monthly fee is equal to the current monthly fee 
                        }
                        for(Package__c pkg : getPackageList){
                            dt = new packageData();
                            dt.Id = pkg.Id;
                            dt.name = pkg.Name;
                            dt.duration = pkg.Duration__c;
                            //dt.facilityFee = BillingUtility.roundOffAmount(pkg.facility_Fee__c);
                            dt.grade = string.isnotBlank(pkg.Grade_new__c)?pkg.Grade_new__c:'';
                            dt.packageFee = BillingUtility.roundOffAmount(pkg.Package_Fee__c);
                            packageList.add(dt);
                        }    
    
                    }
                }
            }
        }
        return packageList;
    }

    // Added By Nishi on 2-Sep-2020 : show Ossia Group class package accoding to selected grades...
    @RemoteAction
    public static List<ossiaGroupPackage> getOssiaGroupClassPackages(String centreId,String teacherId,List<String> listOfgrades,String duration){
        List<ossiaGroupPackage> ossiaGroupPackages = new List<ossiaGroupPackage> ();
        List<AureusCalendarController.GroupPackage> grpPackages = new List<AureusCalendarController.GroupPackage>();
        List<string> instruments = New List<string>();
        AureusCalendarController.GroupPackage grpPackage = new AureusCalendarController.GroupPackage(); 
        Set<string> grades = new Set<String>();
        if(listOfgrades != null && listOfgrades.size() > 0){
            grades.addAll(listOfgrades);
            if(String.isNotBlank(centreId) && String.isNotBlank(teacherId)){
                // 7-jan-2020: show packages according to teachers instruements
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
                Map<string,List<AureusCalendarController.GroupPackage>> mapOfGradePackages = new Map<string,List<AureusCalendarController.GroupPackage>>();
                //system.debug('instruments'+instruments);
                set<string> packageIds = new set<string>();
                if(instruments != null && instruments.size() > 0){
                    for(Package__c packageObj : [SELECT Id, Name, of_Students__c, Duration__c, Package_Fee__c,Instrument__c,Grade_new__c,Deposit_Fee__c
                                                FROM Package__c WHERE
                                                Type__c =: ConstantsClass.packageTypeGroup
                                                AND Active__c = TRUE 
                                                AND Location__c =: centreId
                                                AND Duration__c=:duration
                                                AND Program__r.Status__c =:  ConstantsClass.activeStatus
                                                AND Program__r.Instrument__c IN: instruments]){
                        grpPackages = new List<AureusCalendarController.GroupPackage>();
                        if(string.isNotBlank(packageObj.Grade_new__c)){
                            for(String grade : packageObj.Grade_new__c.split(';')){ 
                                if(grades.contains(grade)){   
                                    if(mapOfGradePackages.containsKey(grade)){
                                        grpPackages = mapOfGradePackages.get(grade);
                                    }
                                    for(AureusCalendarController.GroupPackage objgrpPackage : grpPackages){
                                        packageIds.add(objgrpPackage.id);
                                    }
                                    if(!packageIds.contains(packageObj.Id)){
                                        grpPackage = new AureusCalendarController.GroupPackage();
                                        grpPackage.isOssia = false; //added by nishi: for get organisation is related to  ossia or not
                                        grpPackage.id =  packageObj.Id;
                                        grpPackage.name = packageObj.Name;
                                        grpPackage.price = packageObj.Package_Fee__c;
                                        grpPackage.deposit = packageObj.Deposit_Fee__c;
                                        grpPackage.instrument = packageObj.Instrument__c;
                                        grpPackages.add(grpPackage);
                                    }
                                    mapOfGradePackages.put(grade,grpPackages);
                                }
                            }
                        }
                    } 
                    if(mapOfGradePackages != null && mapOfGradePackages.size() > 0){
                        for(string grade:mapOfGradePackages.keySet()){
                            if(grades.contains(grade)){
                                ossiaGroupPackages.add(new ossiaGroupPackage(grade,mapOfGradePackages.get(grade)));
                            }
                        }
                    }
                }   
            }
        }
        return ossiaGroupPackages;
    }



     //Class Packages
     public class ossiaGroupPackage{
        public String grade ;
        public List<AureusCalendarController.GroupPackage> grpPackages;
        public ossiaGroupPackage(string grade,List<AureusCalendarController.GroupPackage> listOfGrpPackages){
            this.grade = grade;
            this.grpPackages = new List<AureusCalendarController.GroupPackage> ();
            this.grpPackages = listOfGrpPackages;
        }
    }
    
     /*
    * Save Class object record for whole year for that perticular centre, teacher and package.
    */ 
    @RemoteAction
    public static Boolean saveNewOssiaClass(String centreId, String teacherId, map<string,string> gradevalues, 
                                        String classDateStr, String classTimeStr, 
                                        String duration, Integer countOfStudent,
                                        string classType,Integer minAge,Integer maxAge,list<string> grades,Boolean isGroupclassEndDate,String classEndDateStr){
        Boolean isSuccess = false;
                                            
        string insertedClassid =  AureusCalendarController.saveNewGroupClass(centreId,  teacherId,  '',  classDateStr, classTimeStr,  duration, countOfStudent,
                                 classType, minAge, maxAge,true,string.join(grades, ';'),isGroupclassEndDate, classEndDateStr);
        if(string.isNotBlank(insertedClassid)){
            List<Ossia_Group_Grade_Package__c> listOfOssiaGroupGradePackage = new List<Ossia_Group_Grade_Package__c>();
            if(gradevalues != null && gradevalues.size() > 0){
                for(string gradeStr :gradevalues.keyset()){
                    if(string.isNotBlank(gradeStr) && string.isNotBlank(gradevalues.get(gradeStr))){
                        listOfOssiaGroupGradePackage.add(new Ossia_Group_Grade_Package__c(
                            Name =gradeStr,
                            Class_Name__c = insertedClassid,
                            Package__c = gradevalues.get(gradeStr)
                        ));
                    }
                }
                if(listOfOssiaGroupGradePackage != null && listOfOssiaGroupGradePackage.size() > 0){
                    insert listOfOssiaGroupGradePackage;
                }
            }
            isSuccess = true;
        }         
        return isSuccess;
    }

    // Added By Nishi on 2-Sep-2020 : show Ossia Group class grade details...
    @RemoteAction
    public static List<AureusCalendarController.GroupPackage> getlistOfOssiaGroupGradePackage(string groupClassId){
       List<Ossia_Group_Grade_Package__c> listOfOssiaGroupGradePackage = new List<Ossia_Group_Grade_Package__c>();
       List<AureusCalendarController.GroupPackage> grpPackages = new List<AureusCalendarController.GroupPackage>();
       if(string.isNotBlank(groupClassId)){
           for(Ossia_Group_Grade_Package__c objOssiaGroupGradePackage : [Select Id,Name,Package__c,Package__r.Name,Package__r.Instrument__c,Package__r.Package_Fee__c,
                                                                        Package__r.Deposit_Fee__c
                                                                        from Ossia_Group_Grade_Package__c
                                                                        Where Class_Name__c =:groupClassId
                                                                        ORDER BY CreatedDate]){
                AureusCalendarController.GroupPackage grpPackage = new AureusCalendarController.GroupPackage();
                grpPackage.id =  objOssiaGroupGradePackage.Name;
                grpPackage.name = objOssiaGroupGradePackage.Package__r.Name;
                grpPackage.price = objOssiaGroupGradePackage.Package__r.Package_Fee__c;
                grpPackage.deposit = objOssiaGroupGradePackage.Package__r.Deposit_Fee__c;
                grpPackage.instrument = objOssiaGroupGradePackage.Package__r.Instrument__c;
                grpPackages.add(grpPackage);
            }
       }
       return grpPackages;
    }

    // manage Upgarade down grade Package summary according to user Selection with teacher details
    @RemoteAction
    public static AureusCalendarController.UpgradeDowngradePackageSummary getUpgradeDowngradePackageSummary(String oldPackageId, String newPackageId, 
                                                                                    String effectiveDate, String availTimeSlots, 
                                                                                    String enrolmentId, String  typeOfSummary,
                                                                                     String oldTeacher, String  newTeacher           
                                                                                    ){
        AureusCalendarController.UpgradeDowngradePackageSummary summary = AureusCalendarController.getUpgradeDowngradePackageSummary(oldPackageId,newPackageId,effectiveDate,availTimeSlots,enrolmentId,typeOfSummary);
        if(string.isNotBlank(newTeacher) && string.isNotBlank(oldTeacher) ){
            set<String> teacherIds = new Set<String>{newTeacher,oldTeacher};
            Map<String,Account> mapOfAccount = New Map<String,Account>([Select id,Name from Account where Id in :teacherIds]);
            if(mapOfAccount.containsKey(newTeacher)){
                summary.newTeacherName = mapOfAccount.get(newTeacher).Name;
                summary.newTeacherId = mapOfAccount.get(newTeacher).Id;
            }
            if(mapOfAccount.containsKey(oldTeacher)){
                summary.oldTeacherName = mapOfAccount.get(oldTeacher).Name;
                summary.oldTeacherId = mapOfAccount.get(oldTeacher).Id;
            }
            
        }  
        return summary;                                                                             
    }

    // upgrade ossia enrolment   with user selected package,date,time,teacher
    @RemoteAction
    public static String updatePackageOfCustomer(String bookingId, String effectiveDateStr, String newPackageId, 
                                                 String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
        Map<String, String> caseValues,String oldTeacherId,String newTeacherId){
            String caseIdToReturn;
            if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
            String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot) && String.isNotBlank(oldTeacherId) && String.isNotBlank(newTeacherId)){
                IAdvanceAction upgradePackageObj;
                upgradePackageObj = new UpgradeEnrolmentProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                        oldPackageId, timeSlot, myCaseId, caseRedirect, caseValues,oldTeacherId,newTeacherId);
                caseIdToReturn = upgradePackageObj.initProcess();
            }
            return caseIdToReturn;
        
        }

        // downgrade ossia enrolment   with user selected package,date,time,teacher
        @RemoteAction
        public static String downgradeSubscriptionRequest(String bookingId, String effectiveDateStr, String newPackageId, 
                                                          String oldPackageId, String timeSlot, String myCaseId, String caseRedirect, 
                                                          String amount, String depositAmount, String lessonsFees, Map<String, String> caseValues,
                                                          String oldTeacherId,String newTeacherId){
            String caseIdToReturn;
            if(String.isNotBlank(bookingId) && String.isNotBlank(effectiveDateStr) && String.isNotBlank(newPackageId) && 
                String.isNotBlank(oldPackageId) && String.isNotBlank(timeSlot)&& String.isNotBlank(oldTeacherId) && String.isNotBlank(newTeacherId)){
                    IAdvanceAction downgradePackageObj;
                    downgradePackageObj = new DowngradeEnrolmentProcessController(bookingId, effectiveDateStr, newPackageId, 
                                                                            oldPackageId, timeSlot, myCaseId, caseRedirect,
                                                                            amount,depositAmount,lessonsFees, caseValues,oldTeacherId,newTeacherId);
                    caseIdToReturn = downgradePackageObj.initProcess();
            }
            return caseIdToReturn;
            
        }

        //12-aug-2020: Nishi:Start:  deduct makeup hours and minus available mins and calculate utilize min then update parent 
    //  according to new requiremnt While utilizing Make up credit, 
     //it should consider those makeup minutes which are related to the booking with the cancellation reason – Teacher MC/Leave first. 
     //If user  upgrade enrolement then we get fifth lesson makeup bookings 
        public static void createOssiaFifthBookingOnUpgrade(Enrolment__c enrol, Map<String, Booking__c> mapOfFifthBookings, Integer timeDiff, Time startTime, 
                                                            Integer duration){
            List<Booking__c> bookingsinsertList = new List<Booking__c>();
            map<string,Booking__c> mapbookingsupdate = new map<string,Booking__c>();
            List<Booking__c> cancelBookings = new List<Booking__c>();
            List<Booking__c> cancelTeacherCancellationBookings = new List<Booking__c>();
            Decimal availableUnits = 0;
           //System.debug('enrol'+enrol);
           //System.debug('timeDiff'+timeDiff);
           //System.debug('mapOfFifthBookings'+mapOfFifthBookings);
            //Set<String> setOfParentStudent = AureusCalendarControllerHelper.fetchChildrens(enrol.Parent__c);
            Package__c makeupPackage = AureusCalendarControllerHelper.fetchDesiredPackage(enrol.Center__c , String.valueOf(timeDiff));
            String utilizedBookings = '';
            if(enrol.Available_Make_up_mins__c != null){
                availableUnits = enrol.Available_Make_up_mins__c;
            }
            if(availableUnits >= timeDiff && String.isNotBlank(enrol.Parent__c)){
                List<string> teacherCancellation = new List<string>{'Teacher MC','Teacher Leave'};
                cancelTeacherCancellationBookings =teacherLeaveReasonCancelBooking(new Set<string>{enrol.id});
                cancelBookings = teacherLeaveWithOutReasonCancelBooking(new Set<string>{enrol.id});
           
            }
           //System.debug('availableUnits'+availableUnits);
           //System.debug('cancelTeacherCancellationBookings'+cancelTeacherCancellationBookings);
           //System.debug('cancelBookings'+cancelBookings);
           Booking__c bookObj = new Booking__c();
       Booking__c newBook = new Booking__c();
            for(String bookingId : mapOfFifthBookings.keySet()){
                bookObj = mapOfFifthBookings.get(bookingId);
                newBook = new Booking__c();

                if(startTime != NULL && duration > 0){
                    bookObj.start_Time__c = startTime;
                    bookObj.end_Time__c = bookObj.start_Time__c.addMinutes(duration);
                }
                
                newBook.Booking_Date__c = bookObj.Booking_Date__c;
                if(bookObj.Type__c == ConstantsClass.typeMakeup){
                   //System.debug('availableUnits'+availableUnits);
                   //System.debug('timeDiff'+timeDiff);
                    if(availableUnits >= timeDiff){
                        newBook.Type__c = ConstantsClass.typeMakeup;
                        newBook.Status__c = ConstantsClass.statusScheduled;
                        newBook.Package__c = makeupPackage.Id;
                        newBook.Student__c = bookObj.Student__c;
                        newBook.Enrolment__c =enrol.id;
                        Integer hoursToDeduct = timeDiff;
                       //System.debug('cancelTeacherCancellationBookings'+cancelTeacherCancellationBookings);
                        if(hoursToDeduct > 0 && cancelTeacherCancellationBookings != null && cancelTeacherCancellationBookings.size() > 0){
                            for(Booking__c bookingObj : cancelTeacherCancellationBookings){
                                // hoursToDeduct = timeDiff;
                                if(hoursToDeduct <= bookingObj.Available_Make_up_Units__c){
                                    bookingObj.Available_Make_up_Units__c = bookingObj.Available_Make_up_Units__c - hoursToDeduct;
                                    utilizedBookings += bookingObj.Id+'-'+hoursToDeduct+';'; 
                                    hoursToDeduct = 0;
                                }else{
                                    utilizedBookings += bookingObj.Id+'-'+bookingObj.Available_Make_up_Units__c+';';
                                    hoursToDeduct -= Integer.valueOf(bookingObj.Available_Make_up_Units__c);
                                    bookingObj.Available_Make_up_Units__c = 0;
                                   
                                }
                                mapbookingsupdate.put(bookingObj.id,bookingObj);
                                
                                if(hoursToDeduct == 0){
                                    break;
                                }
                            }   
                        } 
                       //System.debug('hoursToDeduct'+hoursToDeduct);
                       //System.debug('cancelBookings'+cancelBookings);
                        if(hoursToDeduct > 0 && cancelBookings != null && cancelBookings.size() > 0){
                            for(Booking__c bookingObj : cancelBookings){
                               // hoursToDeduct = timeDiff; 15<30
                              //System.debug('hoursToDeduct = '+hoursToDeduct);
                              //System.debug('bookObj.Available_Make_up_Units__c= '+bookingObj.Available_Make_up_Units__c);
                              //System.debug('if-'+(hoursToDeduct <= bookingObj.Available_Make_up_Units__c));
                                if(hoursToDeduct <= bookingObj.Available_Make_up_Units__c){
                                    bookingObj.Available_Make_up_Units__c = bookingObj.Available_Make_up_Units__c - hoursToDeduct;
                                    utilizedBookings += bookingObj.Id+'-'+hoursToDeduct+';'; 
                                    hoursToDeduct = 0;
                                }else{
                                    utilizedBookings += bookingObj.Id+'-'+bookingObj.Available_Make_up_Units__c+';';
                                    hoursToDeduct -= Integer.valueOf(bookingObj.Available_Make_up_Units__c);
                                    bookingObj.Available_Make_up_Units__c = 0;
                                }
                                mapbookingsupdate.put(bookingObj.id,bookingObj);
                               //System.debug('bookingObj-'+bookingObj);
                                if(hoursToDeduct == 0){
                                    break;
                                }
                            }
                        }   
                       //System.debug('hoursToDeduct = '+hoursToDeduct);
                        newBook.Make_up_Utilize_Bookings__c=utilizedBookings;
                    }else{
                        newBook.Type__c = ConstantsClass.typeBusy;
                        newBook.Status__c = ConstantsClass.statusScheduled;
                        newBook.package__c = NULL;
                        newBook.Remarks__c = 'Placeholder for '+bookObj.Student__r.Name;
                        newBook.Category__c = 'Placeholder';
                        newBook.enrolment__c = NULL;
                        newBook.Student__c = bookObj.Student__c;
                    }
                    newBook.start_Time__c = bookObj.end_Time__c;
                    newBook.End_Time__c = bookObj.end_Time__c.addMinutes(timeDiff);
                    newBook.Center__c = bookObj.Center__c;
                    newBook.Teacher_Account__c = bookObj.Teacher_Account__c;
                }else if(bookObj.Type__c == ConstantsClass.typeBusy){
                    bookObj.end_Time__c = bookObj.end_Time__c.addMinutes(timeDiff);
                }
                
            mapbookingsupdate.put(bookingId,bookObj);
            bookingsinsertList.add(newBook);
               //System.debug('bookObj'+bookObj);
               //System.debug('newBook'+newBook);
            }
           //System.debug('bookingsList'+bookingsList);
           if(bookingsinsertList.size() > 0){
                upsert bookingsinsertList; 
            }
            if(mapbookingsupdate.size() > 0){
                upsert mapbookingsupdate.values(); 
            }
           //System.debug('bookingsList'+bookingsList);
    }
    public static List<Booking__c> teacherLeaveReasonCancelBooking(Set<String> setOfEnrolmentId){
        List<string> teacherCancellation = new List<string>{'Teacher MC','Teacher Leave'};
        return [SELECT Id, Available_Make_up_Units__c, Make_up_Expiry_Date__c,Enrolment__C,
                Student__c,Parent__c,Enrolment__r.Package__r.Duration__c,Type__c, Duration__c,
                Status__c
                FROM Booking__c 
                WHERE Status__c =: ConstantsClass.statusCanceled 
                AND Cancellation_Reason__c IN:teacherCancellation
                AND Enrolment__C IN: setOfEnrolmentId 
                AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL)
                ORDER BY Make_up_Expiry_Date__c Desc];
    }
    public static List<Booking__c> teacherLeaveWithOutReasonCancelBooking(Set<String> setOfEnrolmentId){
        List<string> teacherCancellation = new List<string>{'Teacher MC','Teacher Leave'};
        return [SELECT Id, Available_Make_up_Units__c, Status__c, Make_up_Expiry_Date__c,Enrolment__C, 
                Parent__c,Enrolment__r.Package__r.Duration__c,
                Student__c, Type__c, Duration__c
                FROM Booking__c
                WHERE Status__c =: ConstantsClass.statusCanceled 
                AND Enrolment__C IN: setOfEnrolmentId 
                AND Cancellation_Reason__c Not IN:teacherCancellation
                AND  Make_up_Expiry_Date__c >= TODAY 
                AND (Available_Make_up_Units__c > 0 AND Available_Make_up_Units__c != NULL) 
                ORDER BY Make_up_Expiry_Date__c Desc];
    }

     //Create 5th Booking for the month of the enrolments
     public static void createOssiaFifthBooking(Map<Enrolment__c,Date> enrollmentMap){

        List<Enrolment__c> makeupsCreated = new List<Enrolment__c>();
        List<Enrolment__c> makeupsNotCreated = new List<Enrolment__c>();
        List<Invoice__c> invoices = new List<Invoice__c>();
        List<Invoice_Line_Item__c> invoiceLineItems = new List<Invoice_Line_Item__c>();
        Set<String> setOfEnrolmentIds= new Set<String>(); // hold ids of parent which has available makeup minutes
        
        // fill  enrollment which has available makeup credits.
        for(Enrolment__c enroll : enrollmentMap.keyset()){
            if(String.isNotBlank(enroll.Id) && enroll.Available_Make_up_mins__c > 0){
                setOfEnrolmentIds.add(enroll.id); 
            }
        }
       
        //Map<String,List<Booking__c>> parentBookingMap = getParentBookingMap(enrollmentMap);
        Map<String,List<Booking__c>> teacherLeaveCancelBookingMap = getCancelBookingMap(enrollmentMap,setOfEnrolmentIds,true);
        Map<String,List<Booking__c>> teacherLeaveWithoutCancelBookingMap = getCancelBookingMap(enrollmentMap,setOfEnrolmentIds,false);
        Set<String> existingFifthBookings = AureusUtility.processFifthBookingsOfMonth();
        Map<String,Id> packageMap = AureusUtility.getPackageMap();

        Map<String,Booking__c> bookingsToUpsert = new Map<String,Booking__c>();
        List<Booking__c> bookingsToInsert = new List<Booking__c>();
        List<Booking__c> finalBookingsToDML = new List<Booking__c>();

        Map<String, Package__c> mapOfAdhocPackage = AureusUtility.fetchAdocPackage(enrollmentMap);
        Map<String, String> mapOfFifthLesson =  AureusUtility.processFifthLessonsOfMonth();
		System.debug('@@@mapOfFifthLesson'+mapOfFifthLesson);
        Map<String, Integer> parentAvailableMinutes = new Map<String, Integer>();
        Integer parentMakeupHours = 0;

        List<Fifth_Lesson__c> fifthLessons = new List<Fifth_Lesson__c>();
        Fifth_Lesson__c fifthLesson = new Fifth_Lesson__c();
        List<Fifth_Lesson__c> fifthLessonToUpdate = new List<Fifth_Lesson__c>();
        for(Enrolment__c enrol : enrollmentMap.keySet()){

            parentMakeupHours = 0;
            Date bookingDate = enrollmentMap.get(enrol);
            String type='';
            String status ='';
            String packageId = '';
            String utilizedBookings ='';

            
            if(!parentAvailableMinutes.containsKey(enrol.Id)){
                parentMakeupHours = Integer.valueOf(enrol.Available_Make_up_mins__c);
                parentAvailableMinutes.put(enrol.Id, Integer.valueOf(enrol.Available_Make_up_mins__c));
            }
            ////System.debug('@@@enrol.Center__c'+enrol.Center__c);
			////System.debug('@@+enrol.Teacher__c..'+enrol.Teacher__c);
            ////System.debug('@@+enrol.Lesson_Day__c'+enrol.Lesson_Day__c);
            ////System.debug('@@enrol.Lesson_Start_time__c'+enrol.Lesson_Start_time__c);
            ////System.debug('@@enrol.Package__r.Duration__c'+enrol.Package__r.Duration__c);
            ////System.debug('@@bookingDate'+bookingDate);
            if(mapOfFifthLesson.containsKey(enrol.Center__c+'-'+enrol.Teacher__c+'-'+enrol.Id+'-'+bookingDate+'-'+enrol.Lesson_Start_time__c+'-'+enrol.Package__r.Duration__c)){
                
                
                if(parentAvailableMinutes.containsKey(enrol.Id) && parentAvailableMinutes.get(enrol.Id) != NULL && 
                   parentAvailableMinutes.get(enrol.Id) >= Integer.valueOf(enrol.package__r.Duration__c) 
                   && ((teacherLeaveCancelBookingMap != null && teacherLeaveCancelBookingMap.size() > 0  && teacherLeaveCancelBookingMap.containsKey(enrol.id)) || 
                   (teacherLeaveWithoutCancelBookingMap != null && teacherLeaveWithoutCancelBookingMap.size() > 0 && teacherLeaveWithoutCancelBookingMap.containsKey(enrol.id)))){
                       
                       // check is parent has make up , then creates make up booking
                       fifthLesson = new Fifth_Lesson__c();
                       fifthLesson.Id = mapOfFifthLesson.get(enrol.Center__c+'-'+enrol.Teacher__c+'-'+enrol.Id+'-'+bookingDate+'-'+enrol.Lesson_Start_time__c+'-'+enrol.Package__r.Duration__c);
                       fifthLesson.isActive__c = FALSE;
                       type = ConstantsClass.typeMakeup;
                       status = ConstantsClass.statusScheduled;

                       if(packageMap.containsKey(enrol.package__r.Duration__c+'-'+enrol.Center__r.Name)){
                           packageId = packageMap.get(enrol.package__r.Duration__c+'-'+enrol.Center__r.Name);
                       }

                       Integer hoursToDeduct = Integer.valueOf(enrol.package__r.Duration__c);
                       parentMakeupHours -= hoursToDeduct;
                       if(teacherLeaveCancelBookingMap != null && teacherLeaveCancelBookingMap.size() > 0 && teacherLeaveCancelBookingMap.containsKey(enrol.id)){
                            for(Booking__c objBook : teacherLeaveCancelBookingMap.get(enrol.id)){
                                if(objBook.Available_Make_up_Units__c > 0){
                                    if(hoursToDeduct <= objBook.Available_Make_up_Units__c){
                                        objBook.Available_Make_up_Units__c = objBook.Available_Make_up_Units__c - hoursToDeduct;
                                        utilizedBookings += objBook.Id+'-'+hoursToDeduct+';'; 
                                        hoursToDeduct = 0;
                                        
                                    }else{
                                        utilizedBookings += objBook.Id+'-'+objBook.Available_Make_up_Units__c+';';
                                        hoursToDeduct -= Integer.valueOf(objBook.Available_Make_up_Units__c);
                                        objBook.Available_Make_up_Units__c = 0;
                                        
                                    }
                                    bookingsToUpsert.put(objBook.id,objBook);
                                    
                                    if(hoursToDeduct == 0){
                                        break;
                                    }    
                                }  
                            }
                        }
                        if(hoursToDeduct > 0 && teacherLeaveWithoutCancelBookingMap != null && teacherLeaveWithoutCancelBookingMap.size() > 0 && teacherLeaveWithoutCancelBookingMap.containsKey(enrol.id)){
                            for(Booking__c objBook : teacherLeaveWithoutCancelBookingMap.get(enrol.id)){
                                if(objBook.Available_Make_up_Units__c > 0){
                                    if(hoursToDeduct <= objBook.Available_Make_up_Units__c){
                                        objBook.Available_Make_up_Units__c = objBook.Available_Make_up_Units__c - hoursToDeduct;
                                        utilizedBookings += objBook.Id+'-'+hoursToDeduct+';'; 
                                        hoursToDeduct = 0;
                                    }else{
                                        utilizedBookings += objBook.Id+'-'+objBook.Available_Make_up_Units__c+';';
                                        hoursToDeduct -= Integer.valueOf(objBook.Available_Make_up_Units__c);
                                        objBook.Available_Make_up_Units__c = 0;
                                        
                                    }
                                    bookingsToUpsert.put(objBook.id,objBook);
                                    
                                    if(hoursToDeduct == 0){
                                        break;
                                    }    
                                }  
                            }
                        }
                       
                       parentAvailableMinutes.put(enrol.Id, parentMakeupHours);
                       
                       makeupsCreated.add(enrol);
                       Booking__c objBook = AureusUtility.addBooking(enrol, type, status, bookingDate, TRUE, packageId, utilizedBookings);
                       fifthLesson.Booking__r = objBook;
                       bookingsToInsert.add(objBook);
                       fifthLessons.add(fifthLesson);
                       
                   }else{
                       makeupsNotCreated.add(enrol);
                   }   
            }
        }
        if(bookingsToInsert.size() > 0){
            finalBookingsToDML.addAll(bookingsToInsert);
        }
        if(bookingsToUpsert.size() > 0){
            finalBookingsToDML.addAll(bookingsToUpsert.values());
        }
        
        if(finalBookingsToDML.size() > 0){
            upsert finalBookingsToDML;
        }

        for(Fifth_Lesson__c fifthLessonObj : fifthLessons){
            fifthLessonObj.Booking__c = fifthLessonObj.Booking__r.Id;
            fifthLessonToUpdate.add(fifthLessonObj);
        }

        if(fifthLessonToUpdate.size() > 0){
            update fifthLessonToUpdate;
        }
        
        if(invoices.size() > 0){
            insert invoices;        
        }
        
        for(Invoice_Line_Item__c lineItemObj : invoiceLineItems){
            lineItemObj.Invoice__c = lineItemObj.Invoice__r.Id;
            lineItemObj.Booking__c = lineItemObj.Booking__r.Id;
        }
        
        if(invoiceLineItems.size() > 0){
            insert invoiceLineItems;
        }

        if(makeupsCreated.size() > 0 || makeupsNotCreated.size() > 0){
            AureusUtility.makeupCreationNotification(makeupsCreated, makeupsNotCreated);
        }
    }
    // this method return the list of cancelled booking of all students including parent itself, within 120 days
    // this method return the list of cancelled booking of all students including parent itself, within 120 days
    public static Map<String,List<Booking__c>> getCancelBookingMap(Map<Enrolment__c,Date> enrollmentMap,Set<string>setOfEnrolmentIds,boolean withTeacherLeave){
        Map<String,List<Booking__c>> enrolmentBookingMap = new Map<String,List<Booking__c>>();
       
         if(setOfEnrolmentIds.size() > 0){
             List<Booking__c> listBooking = new  List<Booking__c> ();
             if(withTeacherLeave){
                listBooking =teacherLeaveReasonCancelBooking(setOfEnrolmentIds);
             }else{
                listBooking =teacherLeaveWithOutReasonCancelBooking(setOfEnrolmentIds);
             }
            for(Booking__c booking : listBooking ){
                if(String.isNotBlank(booking.Enrolment__C)){
                    List<Booking__c> bookingList = enrolmentBookingMap.containsKey(booking.Enrolment__C) ?enrolmentBookingMap.get(booking.Enrolment__C) : new List<Booking__c>();
                    bookingList.add(booking);
                    enrolmentBookingMap.put(booking.Enrolment__C, bookingList);
                }
            }
        }
        return enrolmentBookingMap;
    }

     // 9-dec-2019:jatin: if user change enrllment then show this summary
     @RemoteAction
     public static AureusCalendarController.UpgradeDowngradePackageSummary getChangeEnrollmentPackageSummary(String typeOfSummary,String enrolmentId,
                                                                                      String newTeacher, String oldTeacher,                 
                                                                                     String newPackageId, String oldPackageId, 
                                                                                     String newEffectiveDate,  
                                                                                     String newAvailTimeSlots,String oldAvailTimeSlots,
                                                                                     String newCenter, String oldCenter ){
         Map<String, String> enrolSummary = new Map<String, String>();
         AureusCalendarController.UpgradeDowngradePackageSummary summary = new  AureusCalendarController.UpgradeDowngradePackageSummary();
         DateTime newDateTime,currentDateTime;
         set<String> teacherIds = new Set<String>();
         //system.debug('@@oldPackageId'+oldPackageId);
         //system.debug('@@newPackageId'+newPackageId);
         if(String.isNotBlank(oldPackageId) && String.isNotBlank(newPackageId)){
             summary =  AureusCalendarController.getPackageDetailsUpgradeDowngrade(oldPackageId, newPackageId);
             //system.debug('@@summary.newPackageId = '+summary.newPackageId);
             //system.debug('@@summary.newPackageName = '+summary.newPackageName);
         }
         if(String.isNotBlank(newEffectiveDate) && String.isNotBlank(newAvailTimeSlots)){
             newDateTime =  AureusCalendarController.getDateTimeFromString(newAvailTimeSlots);
             newDateTime = DateTime.newInstance(Date.valueOf(newEffectiveDate), newDateTime.time());
             //summary.newDayAndTime = newDateTime.format('EEE, MMM dd YYYY h:mm a');
             summary.newDayAndTime = newDateTime.format('EEE @ h:mm a');
             summary.effectiveDate = newDateTime.format('EEE, MMM dd YYYY');
         }
         
         if(string.isNotBlank(newTeacher) && string.isNotBlank(oldTeacher) ){
            teacherIds.add(newTeacher);
            teacherIds.add(oldTeacher);
        }
        if(string.isNotBlank(newCenter) && string.isNotBlank(oldCenter) ){
            teacherIds.add(newCenter);
            teacherIds.add(oldCenter);
        }
        if(teacherIds != null && teacherIds.size()>0 ){
            Map<String,Account> mapOfAccount = New Map<String,Account>([Select id,Name from Account where Id in :teacherIds]);
            if(mapOfAccount.containsKey(newTeacher)){
                summary.newTeacherName = mapOfAccount.get(newTeacher).Name;
                summary.newTeacherId = mapOfAccount.get(newTeacher).Id;
            }
            if(mapOfAccount.containsKey(newCenter)){
                summary.newCenterName = mapOfAccount.get(newCenter).Name;
                summary.newCenterId = mapOfAccount.get(newCenter).Id;
            }
        }
         
        
          // 12-dec-2019:jatin: get all pervious fields teacher,package,parent , studentname ,day
         if(String.isNotBlank(enrolmentId)){
             enrolSummary =  AureusCalendarController.getEnrolmentDetailsUpgradeDowngrade(enrolmentId);
             if(enrolSummary.containsKey('currentCenterName')){
                summary.oldCenterName = enrolSummary.get('currentCenterName');
            }
            if(enrolSummary.containsKey('currentCenter')){
                summary.oldCenterId = enrolSummary.get('currentCenter');
            }
             if(enrolSummary.containsKey('currentTeacher')){
                 summary.oldTeacherName = enrolSummary.get('currentTeacher');
             }
             if(enrolSummary.containsKey('currentTeacherId')){
                 summary.oldTeacherId = enrolSummary.get('currentTeacherId');
             }
             if(enrolSummary.containsKey('currentPackage')){
                 summary.oldPackageName = enrolSummary.get('currentPackage');
             } 
             if(enrolSummary.containsKey('currentPackageId')){
                 summary.oldPackageId = enrolSummary.get('currentPackageId');
             } 
                 
             if(enrolSummary.containsKey('currentDay')){
                 summary.currentDayAndTime = enrolSummary.get('currentDay');
             }
              if(enrolSummary.containsKey('studentName')){
                 summary.studentName = enrolSummary.get('studentName');
             }
             if(enrolSummary.containsKey('parentName')){
                 summary.parentName = enrolSummary.get('parentName');
             }
         }
         return summary;
     }
    

     @RemoteAction
     public static String changeEnrolmentCenter(String enrolmentId, String teacherId,String centerId, String packageId, 
                                          String newEffectiveDateStr, String timeStr, String myCaseId, 
                                          String caseRedirect, String previousTime, String oldPackageName, String newPackageName,String oldCenterId){
        String caseIdToReturn;
        if(String.isNotBlank(enrolmentId)){
                IAdvanceAction changeCenterEnrolmentProcessObj;
                
                changeCenterEnrolmentProcessObj = new ChangeCenterEnrolmentProcessController(enrolmentId, teacherId,centerId, packageId, 
                                                                        newEffectiveDateStr,timeStr,myCaseId,caseRedirect,
                                                                        previousTime,oldPackageName,newPackageName,oldCenterId);
                caseIdToReturn = changeCenterEnrolmentProcessObj.initProcess();
        }
        return caseIdToReturn;
    }
    public class packageData{      
        public String Id;       
        public String Name;   
        public String duration; 
        //public Decimal facilityFee; 
        public String grade; 
        public Decimal packageFee;     
    }  
}