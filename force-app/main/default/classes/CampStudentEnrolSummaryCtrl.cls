/***
* name: CampStudentEnrolSummaryCtrl
* author: jatin
* date: 9-Feb-2020
* description: This Controller will Show the details of Enrolment and update it.

* 
*/
public without sharing class CampStudentEnrolSummaryCtrl {
    public CampStudentSummaryWrapperClass studentSummaryDetails{get;set;}
    public String accountModalDetails{get;set;}
    public Boolean isError{get;set;}
    public String errorMsg{get;set;}
    public string stripeToken{get;set;}
    public String parentId{get;set;}
    public Boolean isSiteGuestUser{get;set;}
    public string  personEmail{get;set;}
    public string sessionId{get;set;}
    public Boolean agreementCheckbox{get;set;}
    public Boolean isOssia{get;set;}//Juneid 28 Aug 2020 for cheking org
    
    public PandaDocUtility.CreateDocument documentDetails;
    PandaDocUtility.SessionDocument sessionDetails;
    Boolean isCreateStudent; // for manage multiple time create one student and realated invoice so we check and restrict this creation.
    String templateId;
    String folderId;
    Public string pandaDocAttachmentName;
    Public CampStudentEnrolSummaryCtrl(){
        studentSummaryDetails = new CampStudentSummaryWrapperClass();
        isSiteGuestUser = (UserInfo.getName()).contains('Site');
        templateId = Label.Student_Policies_Template;
        isCreateStudent = false;
        isOssia = false;//Juneid 28 Aug 2020 for cheking org
      
    }
    
    
    // get enrolment detials 
    public CampStudentSummaryWrapperClass getEnrolStudentDetails(){
        studentSummaryDetails = new CampStudentSummaryWrapperClass();
        if(string.isNotBlank(accountModalDetails)){
            CampDetailsForEnrolStudentController.AccountModal studentDetails= (CampDetailsForEnrolStudentController.AccountModal)JSON.deserialize(accountModalDetails, CampDetailsForEnrolStudentController.AccountModal.class); // Jsonstring is the above JSON
            system.debug('studentDetails'+studentDetails);
            studentSummaryDetails = new CampStudentSummaryWrapperClass(studentDetails);
            //Juneid 28 Aug 2020 for cheking org is ossia or not
            if(studentSummaryDetails.organisationOfCentre.name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                isOssia= true;
            }
        }
        
        return studentSummaryDetails;
    }
    
    // create parent and student account according to user enrterd details
    public void createParentDetails(){
        CampDetailsForEnrolStudentController.AccountModal newStudentDetails = studentSummaryDetails.studentDetails ;
        map<string,Account> mapOfStudentAndParentAccount = new map<string,Account>();
        newStudentDetails.parentAccDetails.Centre_Name__c = newStudentDetails.centerId;
        
        List<Account> centerlist =  [Select id,Name,Organisation__c,country__r.name,Organisation__r.name from account where id=:newStudentDetails.centerId and recordtype.Name=:ConstantsClass.centerRecTypeName];
        String customerRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
        //Check that customer is already exist or not on the bases of email
        if(newStudentDetails.parentAccDetails.PersonEmail != null){
            List<Account> accList = [SELECT Id,Name FROM Account 
                                    WHERE PersonEmail =: newStudentDetails.parentAccDetails.PersonEmail
                                    And Centre_Name__r.Organisation__c =: centerlist.get(0).Organisation__c // Added by nishi: 30-nov-2020: for Change customer key from email address to email address+Organisation name
                                    ]; 
            if(accList.size() > 0)
                newStudentDetails.parentAccDetails.Id = accList.get(0).Id;
             // Added by nishi:Start: 30-nov-2020: for Change customer key from email address to email address+Organisation name
             string useremail=newStudentDetails.parentAccDetails.PersonEmail+'.';
             if(centerlist.get(0).Organisation__r.name == Label.Ossia_Organisation_Name){
                 useremail +='ossia'+centerlist.get(0).country__r.name; 
             }else{
                 useremail += 'aureus'+centerlist.get(0).country__r.name;
             }
             newStudentDetails.parentAccDetails.User_Email__c = useremail;
             // Added by nishi:end: 30-nov-2020: for Change customer key from email address to email address+Organisation name     
        }
        newStudentDetails.parentAccDetails.Enroled__c     = false;
        newStudentDetails.parentAccDetails.Enroled_Date__c= System.today();
        newStudentDetails.parentAccDetails.PersonMobilePhone = newStudentDetails.parentAccDetails.phone;
        newStudentDetails.parentAccDetails.phone = newStudentDetails.parentAccDetails.phone;
        newStudentDetails.parentAccDetails.RecordtypeId = customerRecId;
        //newStudentDetails.parentAccDetails.Instrument__c  = studentSummaryDetails.objCampPackage.Package__r.Instrument__c;
        
        
        /*commmented by jatin: 22-feb-2020: for change requirement now we manage multiple students
if(newStudentDetails.isParAlsoAStudent){
newStudentDetails.parentAccDetails.Also_a_Student__c = true;
newStudentDetails.parentAccDetails.PersonBirthdate   = newStudentDetails.studentAccDetails.PersonBirthdate;
newStudentDetails.parentAccDetails.Learning_Style__c = newStudentDetails.studentAccDetails.Learning_Style__c;
newStudentDetails.parentAccDetails.Description       = newStudentDetails.studentAccDetails.Description;
newStudentDetails.parentAccDetails.Current_Engagement_Status__c = ConstantsClass.activeStatus;
newStudentDetails.parentAccDetails.Gender__c = newStudentDetails.studentAccDetails.Gender__c;

}*/
        
        
        upsert newStudentDetails.parentAccDetails;
        parentId = newStudentDetails.parentAccDetails.id;
        //   mapOfStudentAndParentAccount.put('parent',new List<Account>(newStudentDetails.parentAccDetails));
        system.debug('newStudentDetails.parentAccDetails'+newStudentDetails.parentAccDetails);
        /*commmented by jatin: 22-feb-2020: for change requirement now we manage multiple students
if(!newStudentDetails.isParAlsoAStudent){
//To find existing student for the sepecific parent
if(newStudentDetails.existingStudentList != null && newStudentDetails.existingStudentList.size() > 0)
newStudentDetails.studentAccDetails.Id = newStudentDetails.existingStudentList[0];
newStudentDetails.studentAccDetails.Parent__c = newStudentDetails.parentAccDetails.Id;
newStudentDetails.studentAccDetails.Current_Engagement_Status__c = ConstantsClass.activeStatus;
newStudentDetails.studentAccDetails.Centre_Name__c =  newStudentDetails.centerId;
if(centrList.size() > 0){
newStudentDetails.studentAccDetails.Location__c = centrList.get(0).Location__c;
if(centrList.get(0).Country__r.Country_Name__c != null)
newStudentDetails.studentAccDetails.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
}
// To find existing student for the sepecific parent
upsert newStudentDetails.studentAccDetails;
mapOfStudentAndParentAccount.put('student',newStudentDetails.studentAccDetails);
system.debug(newStudentDetails.studentAccDetails);
}else{
mapOfStudentAndParentAccount.put('student',newStudentDetails.parentAccDetails);
}*/
        //  return newStudentDetails;
    }
    
    public CampDetailsForEnrolStudentController.AccountModal createStudentDetails(CampDetailsForEnrolStudentController.AccountModal newStudentDetails,List<Account> centrList){
        // jatin: 22-feb-2020: for change requirement now we create  multiple students with different ditails  
        String customerRecId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();  
        if(newStudentDetails.mapOfStudentAccount != null && newStudentDetails.mapOfStudentAccount.size() > 0){
            for(string studentTempId : newStudentDetails.mapOfStudentAccount.keyset()){
                if(newStudentDetails.mapOfStudentAccount.containsKey(studentTempId)){
                    Account studentAccDetails = newStudentDetails.mapOfStudentAccount.get(studentTempId);
                    if(newStudentDetails.existingStudentList != null && newStudentDetails.existingStudentList.size() > 0)
                        studentAccDetails.Id = newStudentDetails.existingStudentList[0];
                    studentAccDetails.Parent__c = parentId;
                    studentAccDetails.Current_Engagement_Status__c = ConstantsClass.activeStatus;
                    studentAccDetails.Centre_Name__c =  newStudentDetails.centerId;
                    studentAccDetails.RecordtypeId = customerRecId;
                    if(centrList.size() > 0){
                        studentAccDetails.Location__c = centrList.get(0).Location__c;
                        if(centrList.get(0).Country__r.Country_Name__c != null)
                            studentAccDetails.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                    }
                    newStudentDetails.mapOfStudentAccount.put(studentTempId,studentAccDetails);
                }
            }
            upsert newStudentDetails.mapOfStudentAccount.values();
            isCreateStudent = true;
        }
        system.debug('newStudentDetails'+newStudentDetails);
        return newStudentDetails;
    }
    
    // create camp type enrolment with start time and end time 
    public static map<string,Enrolment__c> createCampEnrolment(CampDetailsForEnrolStudentController.AccountModal newStudentDetails,string centerId,CampStudentSummaryWrapperClass studentSummaryDetails){
        String lessonRecId =  Schema.SObjectType.Enrolment__c.getRecordTypeInfosByName().get(ConstantsClass.enrollmentLessonRecTypeName).getRecordTypeId();
        List<Enrolment__c> listOfEnrolment = new List<enrolment__C>();
        map<string,Enrolment__c> mapOfEnrolment = new map<string,Enrolment__c>();
        // 20-feb-2020: jatin: manage multiple enrolment for multiple students
        for(CampDetailsForEnrolStudentController.StudentDetail objStudentDetail :  newStudentDetails.listOfStudentDetails){
            Enrolment__c enrl  = new Enrolment__c(Type__c = ConstantsClass.enrollmentTypeCamp,Stage__c = ConstantsClass.enroledStatus,
                                                  Previous_Experience_if_any__c  = objStudentDetail.student.stuPreExperience,
                                                  Center__c     = centerId,
                                                  Cancellation_Policy_Agreed__c  = true);
            if(studentSummaryDetails.mapOfCampPackage != null && studentSummaryDetails.mapOfCampPackage.size() >0){
                system.debug('newStudentDetails.mapOfStudentAccount'+studentSummaryDetails.mapOfCampPackage);
                if(studentSummaryDetails.mapOfCampPackage.containsKey(objStudentDetail.packageId) && string.isNotBlank(studentSummaryDetails.mapOfCampPackage.get(objStudentDetail.packageId).Package__c)){
                    system.debug('newStudentDetails.mapOfStudentAccount'+studentSummaryDetails.mapOfCampPackage.get(objStudentDetail.packageId).Package__c);
                    enrl.package__c  = studentSummaryDetails.mapOfCampPackage.get(objStudentDetail.packageId).Package__c;
                }
            }
            if( studentSummaryDetails.objCampClass != null )
                enrl.Camp__c = studentSummaryDetails.objCampClass.Id;
            if(studentSummaryDetails.mapOfStudentCampDays != null && studentSummaryDetails.mapOfStudentCampDays.size() > 0){
                if(studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Dates_Of_The_Camp__c != null)
                    enrl.Lessons_Start_Date__c = studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Dates_Of_The_Camp__c;
                if(studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Camp_Start_Time__c != null)
                    enrl.Lesson_Start_time__c = studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Camp_Start_Time__c;
                if(studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Camp_Start_Time__c != null && 
                   studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Dates_Of_The_Camp__c != null )
                    enrl.Lesson_Day__c = dateTime.newInstance(studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Dates_Of_The_Camp__c,
                                                              studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Camp_Start_Time__c).format('EEEE');
            }
            enrl.RecordtypeId = lessonRecId;
            mapOfEnrolment.put(objStudentDetail.student.id,enrl);
        }
        system.debug('newStudentDetails.mapOfStudentAccount'+newStudentDetails.mapOfStudentAccount);
        // add student is and parent id in enrolment using student temparery_id
        for(string studentTempId:  newStudentDetails.mapOfStudentAccount.keyset()){
            if(mapOfEnrolment.containsKey(studentTempId)){
                Enrolment__c enrl = mapOfEnrolment.get(studentTempId);
                enrl.Parent__c     = newStudentDetails.mapOfStudentAccount.get(studentTempId).Parent__c;
                enrl.Student__c    = newStudentDetails.mapOfStudentAccount.get(studentTempId).Id;
                mapOfEnrolment.put(studentTempId,enrl);
            }     
        }   
        insert mapOfEnrolment.values();
        system.debug('@@@createCampEnrolment'+mapOfEnrolment.values());
        return mapOfEnrolment;
    }
    
    // added by jatin: 20-feb-2020: for manage booking date according to multiple students seleted different camp packages and dates list
    public static void createCampClassBooking(map<string,Enrolment__c> mapOfEnrolment,string centerId,CampStudentSummaryWrapperClass studentSummaryDetails,CampDetailsForEnrolStudentController.AccountModal newStudentDetails){
        List<Booking__c> bookList = new List<Booking__c>();
        String campLessonRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.bookingRecordsTypeCampLesson).getRecordTypeId();    
        set<string> campTeacherIds = new set<string>();
        Set<string> campDays = new set<string>();
        List<Camp_Day_Teachers__c> listOfCampteacher = new List<Camp_Day_Teachers__c>();
        for(Camp_Days__c campDayObj : studentSummaryDetails.objCampClass.Camp_Days__r){
            //campTeacherIds.add(campDayObj.Camp_Teacher__c);
            listOfCampteacher = new List<Camp_Day_Teachers__c>();
            if(studentSummaryDetails.mapOfCampDayTeachers.containsKey(campDayObj.id) ){
                listOfCampteacher = studentSummaryDetails.mapOfCampDayTeachers.get(campDayObj.id);
                if(listOfCampteacher != null && listOfCampteacher.size() > 0 ){
                    campTeacherIds.Add(string.valueOf(listOfCampteacher[0].Camp_Teacher__c));
                }
            }
            campDays.add(DateTime.newInstance(campDayObj.Dates_Of_The_Camp__c, campDayObj.Camp_Start_Time__c).format('E'));
        }  
        map<string,list<Teacher_Working_Hour__c>> mapOfTeacherWorkingHours = new map<string,list<Teacher_Working_Hour__c>>();
        if(campTeacherIds != null && campDays != null && campTeacherIds.size() > 0 && campDays.size() > 0 && string.isNotBlank(centerId)) 
            mapOfTeacherWorkingHours = CampClassUtilityController.getTeacherWorkingHoursList(campTeacherIds,campDays,centerId); 
        if(mapOfEnrolment != null && mapOfEnrolment.size() > 0){
            string CampTeacherId = '';
            for(string studentTempId :  newStudentDetails.mapOfStudentAccount.keyset()){
                Account objStudent = newStudentDetails.mapOfStudentAccount.get(studentTempId);
                List<CampStudentSummaryWrapperClass.StudentCampDays> listOfStudentCampDays = studentSummaryDetails.mapOfStudentCampDays.get(studentTempId);
                for(CampStudentSummaryWrapperClass.StudentCampDays objStudentCampDays : listOfStudentCampDays){
                    Camp_Days__c  campDayObj = objStudentCampDays.objCampDays;
                    CampTeacherId = '';
                    /*commented by jatin: 25-Feb-2020: for change requirement now we manage multiple teachers on one camp days
if(string.isNotBlank(campDayObj.Camp_Teacher__c)){
CampTeacherId = campDayObj.Camp_Teacher__c;
}*/
                    if(studentSummaryDetails.mapOfCampDayTeachers.containsKey(campDayObj.id) ){
                        if(studentSummaryDetails.mapOfCampDayTeachers.get(campDayObj.id) != null && studentSummaryDetails.mapOfCampDayTeachers.get(campDayObj.id).size() > 0 ){
                            CampTeacherId =  studentSummaryDetails.mapOfCampDayTeachers.get(campDayObj.id)[0].Camp_Teacher__c;
                        }
                    }
                    if(campDayObj.Dates_Of_The_Camp__c != null && campDayObj.Camp_Start_Time__c != null && campDayObj.Camp_End_Time__c != null){
                        Booking__c book = CampClassUtilityController.createCampBooking(objStudent.Id,
                                                                                       mapOfEnrolment.get(studentTempId).id,
                                                                                       campDayObj.Dates_Of_The_Camp__c,campDayObj.Camp_End_Time__c,campDayObj.Camp_Start_Time__c,
                                                                                       centerId,mapOfEnrolment.get(studentTempId).Package__c,
                                                                                       studentSummaryDetails.objCampClass.id,campDayObj.id,'');
                        /*commented by jatin: 4-Mar-2020: for new feedbacks BID for camps should not be under a teacher as there are multiple teachers teaching a single camp day
CampTeacherId);*/
                        bookList.add(book);
                        /*if(newStudentDetails.isAureusAtHome && mapOfTeacherWorkingHours != null && mapOfTeacherWorkingHours.size() > 0 ){
if(string.isNotBlank(CampTeacherId) && mapOfTeacherWorkingHours.containsKey( CampTeacherId)){
list<Teacher_Working_Hour__c> techWorkSchList = mapOfTeacherWorkingHours.get(CampTeacherId);
if(techWorkSchList != null && techWorkSchList.size() > 0 && techWorkSchList[0].Start_Time__c != campDayObj.Camp_Start_Time__c){
//Filling booking for the Before travel  
Booking__c befBook = CampClassUtilityController.createCampBooking(objStudent.Id, mapOfEnrolment.get(studentTempId).id,campDayObj.Dates_Of_The_Camp__c,campDayObj.Camp_Start_Time__c,
campDayObj.Camp_Start_Time__c.addMinutes(-newStudentDetails.travelDuration),
centerId,mapOfEnrolment.get(studentTempId).Package__c,studentSummaryDetails.objCampClass.id,campDayObj.id,
CampTeacherId);
befBook.Type__c    = ConstantsClass.busyBookingType;
befBook.Status__c 	   = ConstantsClass.scheduledStatus;
befBook.Category__c= 'Travel';
befBook.Remarks__c = 'Travel time slot for home trial booking';
bookList.add(befBook);    
}
}

}*/
                    } 
                }
            }
            insert bookList;
            system.debug('@@@bookList'+bookList);
        }
    }
    
    //bookings according to selected dated create booking and added camp and camp days
    /* commented by jatin :21-feb-2020:for manage multiple enrolment 
public static void createCampClassBooking(string enrolmentid,string centerId,StudentSummaryModal studentSummaryDetails){
CampDetailsForEnrolStudentController.AccountModal newStudentDetails = studentSummaryDetails.studentDetails ;

if(studentSummaryDetails.objCampClass != null &&
studentSummaryDetails.campDayList != null && studentSummaryDetails.campDayList.size() > 0){
List<Booking__c> bookList = new List<Booking__c>();
String campLessonRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.bookingRecordsTypeCampLesson).getRecordTypeId();    
set<string> campTeacherIds = new set<string>();
Set<string> campDays = new set<string>();
for(Camp_Days__c campDayObj : studentSummaryDetails.objCampClass.Camp_Days__r){
campTeacherIds.add(campDayObj.Camp_Teacher__c);
campDays.add(DateTime.newInstance(campDayObj.Dates_Of_The_Camp__c, campDayObj.Camp_Start_Time__c).format('E'));
}   
map<string,list<Teacher_Working_Hour__c>> mapOfTeacherWorkingHours = CampClassUtilityController.getTeacherWorkingHoursList(campTeacherIds,campDays,centerId); 
for(Camp_Days__c campDayObj : studentSummaryDetails.campDayList){
if(campDayObj.Dates_Of_The_Camp__c != null && campDayObj.Camp_Start_Time__c != null && campDayObj.Camp_End_Time__c != null){
Booking__c book = CampClassUtilityController.createCampBooking(mapOfStudentAndParentAccount.get('student').Id,
enrolmentId,campDayObj.Dates_Of_The_Camp__c,campDayObj.Camp_End_Time__c,campDayObj.Camp_Start_Time__c,
centerId,studentSummaryDetails.objCampPackage.Package__c,studentSummaryDetails.objCampClass.id,campDayObj.id,
campDayObj.Camp_Teacher__c);
bookList.add(book);

if(newStudentDetails.isAureusAtHome){
if(mapOfTeacherWorkingHours.containsKey(campDayObj.Camp_Teacher__c)){
list<Teacher_Working_Hour__c> techWorkSchList = mapOfTeacherWorkingHours.get(campDayObj.Camp_Teacher__c);
if(techWorkSchList.size() > 0 && techWorkSchList[0].Start_Time__c != campDayObj.Camp_Start_Time__c){
//Filling booking for the Before travel  
Booking__c befBook = CampClassUtilityController.createCampBooking(mapOfStudentAndParentAccount.get('student').Id,enrolmentId,campDayObj.Dates_Of_The_Camp__c,campDayObj.Camp_Start_Time__c,
campDayObj.Camp_Start_Time__c.addMinutes(-newStudentDetails.travelDuration),
centerId,studentSummaryDetails.objCampPackage.Package__c,studentSummaryDetails.objCampClass.id,campDayObj.id,
campDayObj.Camp_Teacher__c);
befBook.Type__c    = ConstantsClass.busyBookingType;
befBook.Status__c 	   = ConstantsClass.scheduledStatus;
befBook.Category__c= 'Travel';
befBook.Remarks__c = 'Travel time slot for home trial booking';
bookList.add(befBook);    
}
}
}
}
}
insert bookList;
system.debug(bookList);
}
}*/
    
    // 17-Feb-2020: insert attachment and Email confirmation to the customer with the invoice PDF
    @future(callout=true)
    public static void insertPdfAndSendEmail(String invoices,string pandaDocAttachmentName,string enrolmentId){
        DateTime now = DateTime.now();
        system.debug('@@@invoices'+invoices);
        system.debug('@@@enrolmentId'+enrolmentId);
        Boolean isOssia = false;
        if(string.isNotBlank(invoices)){
            List<Invoice__c> invoiceList = [SELECT Id,Name,Total_Amount__c,
                                            Center__r.Location__c,Parent_Account__r.personContactId,
                                            Center__r.Organisation__r.Name,
                                            status__c FROM Invoice__c 
                                            WHERE Id =:invoices];
            map<String ,Blob> mapOfAttachment = new map<String,Blob>();
            List<Attachment> listOfAttachment = new List<Attachment>();
            if(invoiceList != null && invoiceList.size() > 0){
                Invoice__c inv = invoiceList[0];
                if(string.isNotBlank(inv.Center__r.Organisation__r.Name) && inv.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                    isOssia= true;
                }
                map<string,Attachment> mapOfInvoiceAttachment  = PianoRentalHelperController.createInvoiceAttachment(invoiceList);
                if(string.isnotBlank(pandaDocAttachmentName)){
                    pandaDocAttachmentName ='%'+pandaDocAttachmentName+'%';
                    List<Attachment> listOfPandaDocAttachment = [SELECT Id,name, Body, createdDate From Attachment
                                                                 WHERE Name Like:pandaDocAttachmentName 
                                                                 AND contentType = 'application/pdf'
                                                                 AND CreatedDate = today
                                                                 ORDER BY createdDate DESC];
                    system.debug('listOfPandaDocAttachment'+listOfPandaDocAttachment);
                    if(listOfPandaDocAttachment != null && listOfPandaDocAttachment.size() > 0){
                        mapOfAttachment.put(listOfPandaDocAttachment[0].name,listOfPandaDocAttachment[0].Body);
                    }
                }
                if(mapOfInvoiceAttachment.containsKey(inv.id)){
                    mapOfAttachment.put(inv.Name+'.pdf',mapOfInvoiceAttachment.get(inv.id).body);
                }
                system.debug('mapOfAttachment'+mapOfAttachment);
                if(mapOfAttachment != null && mapOfAttachment.size() > 0){
                    //sendCustomerEmail(mapOfAttachment, enrolmentId);
                    // 21-feb-2020: manage send email and invoice attachment 
                    //PianoRentalHelperController.sendEmailWithInvoiceAttachment(new Map<string,map<String ,Blob>>{inv.id =>mapOfAttachment}, invoiceList,'Camp Class Enrolment Confirmation');
                    // 3-Mar-2020: for send email for enrolmentid
                    //added by nishi: 12-Oct-2020: for send email according to organisation
                    if(isOssia){
                        CampClassUtilityController.sendEmailWithInvoiceAttachment(new Map<string,map<String ,Blob>>{enrolmentId=>mapOfAttachment},'Ossia_Camp_Enrolment');
                    }else{
                        CampClassUtilityController.sendEmailWithInvoiceAttachment(new Map<string,map<String ,Blob>>{enrolmentId=>mapOfAttachment},'Camp_Enrolment');
                    }
                    //added by nishi: 12-Oct-2020: for send email according to organisation
                    
                }
            }
        }
    }
    
    // 17-Feb-2020: insert attachment and Email confirmation to the customer with the invoice PDF
    /*commented by jaitn: 20-feb-2020: for we change template now we use invoice detials for sending emails 
public static void sendCustomerEmail(map<String ,Blob> mapOfAttachment,string enrolmentId){
List<EmailTemplate> listOfEmailTemplate = [SELECT Id, Name ,DeveloperName
FROM EmailTemplate 
WHERE DeveloperName =:'Camp_Class_Enrolment_Confirmation'];
List<Enrolment__c> listOfenrolment  = PianoRentalHelperController.getRentalEnrolmentList(new Set<string> {enrolmentId});
List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();  
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
string personContactId ='';
string centerId ='';
if(listOfenrolment != null && listOfenrolment.size() > 0 ){
Enrolment__c objEnrolment = listOfenrolment[0];
if(objEnrolment.Parent__c != null && string.isNotBlank(objEnrolment.Parent__r.PersonContactId)){
personContactId = objEnrolment.Parent__r.PersonContactId;
}
if(objEnrolment.Center__c != null && objEnrolment.Center__r != null &&
string.isNotBlank(objEnrolment.Center__r.Location__c) ){
centerId = objEnrolment.Center__r.Location__c;
}
if(listOfEmailTemplate != null && listOfEmailTemplate.size() > 0 ){
mail = AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id,personContactId,objEnrolment.id,centerId);
List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
for(string attachmentName : mapOfAttachment.keySet()){
Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
efa.setFileName(attachmentName);
efa.setBody(mapOfAttachment.get(attachmentName));
fileAttachments.add(efa);
}
mail.setFileAttachments(fileAttachments);
emailList.add(mail);
} 

Messaging.sendEmail(emailList, FALSE); 
}
}*/
    
    // if new customer or not found stripe Id then we create stripe id and insert card details
    public static map<string,string> createStripeCustomer(Account parentAcc,string stripeToken,string stripeBaseUrl,string stripeApiSecKey){
        map<string,string> stripeCstmrDetails = new map<string,string>();
        String cusName = String.isNotBlank(parentAcc.FirstName) ? parentAcc.FirstName : ' ';
        cusName += parentAcc.LastName;
        
        BillingUtility.StripeCustomer sCstmr = BillingUtility.createStripeCustomer(stripeToken, cusName, parentAcc.PersonEmail, 'Parent customer', stripeBaseUrl, stripeApiSecKey); 
        
        if(sCstmr.statusCode == 200 && String.isNotBlank(sCstmr.id)){ 
            stripeCstmrDetails.put('stripeCstmrId',sCstmr.id);
            BillingUtility.cls_sources srcs = sCstmr.sources;
            if(srcs.stripeData.size() > 0 && ! test.isRunningTest()){
                BillingUtility.cls_data clData  = srcs.stripeData.get(0);
                stripeCstmrDetails.put('last4CardNumber',clData.last4);
                stripeCstmrDetails.put('cardType',clData.brand);
                stripeCstmrDetails.put('exp_month',string.valueOf(clData.exp_month));
                stripeCstmrDetails.put('exp_year', string.valueOf(clData.exp_year));
            }
        }else{
            stripeCstmrDetails.put('Error', sCstmr.error.message);
        }
        system.debug('stripeCstmrDetails'+stripeCstmrDetails);
        return stripeCstmrDetails;
    }
    
    // 5-Mar-2020: Jatin: If Customer enrolment For the camp using site then will always need the card to be typed in when it is using the site. otherwise using SF then we call stripe and update in Account card Details.  
    public void saveParentCardDetailsSiteUser(){
        Savepoint sp;
        CampDetailsForEnrolStudentController.AccountModal newStudentDetails = studentSummaryDetails.studentDetails ;
        try{
            List<Account> centrList  = [SELECT Id, Name, Location__c, Country__c, Country__r.Country_Name__c FROM Account WHERE Id =: newStudentDetails.centerId];
            newStudentDetails.parentAccDetails.id = parentId;
            sp = Database.setSavepoint();
            updateCustomerAndGenerateInvoice(newStudentDetails,centrList,new BillingUtility.stripeCharge());
            isError  = false;
        }catch(Exception e){
            Database.rollback(sp);
            System.debug('Error:  '+e.getMessage());
            errorMsg = e.getMessage();
            isError  = true;
        }
    }
    public void updateCustomerAndGenerateInvoice(CampDetailsForEnrolStudentController.AccountModal newStudentDetails,List<Account> centrList,BillingUtility.stripeCharge sc){
        newStudentDetails = createStudentDetails(newStudentDetails,centrList);
        //commented by jatin: 20-feb-2020: manage multiple enrolement for multiple students
        //string EnrolmentId = createCampEnrolment(newStudentDetails.centerId,studentSummaryDetails);
        map<string,Enrolment__c> mapOfEnrolment = createCampEnrolment(newStudentDetails,newStudentDetails.centerId,studentSummaryDetails);
        if(mapOfEnrolment != null && mapOfEnrolment.size() > 0){
            //createCampClassBooking(EnrolmentId,newStudentDetails.centerId,studentSummaryDetails);
            createCampClassBooking(mapOfEnrolment,newStudentDetails.centerId,studentSummaryDetails,newStudentDetails);
            List<Invoice__c> listOfInvoices = createInvoiceAndPayment(studentSummaryDetails, sc,mapOfEnrolment,newStudentDetails);
            system.debug('listOfInvoices'+listOfInvoices);
            if(listOfInvoices != null && listOfInvoices.size() > 0){
                List<Enrolment__c> listOfEnrolment = mapOfEnrolment.values();
                insertPdfAndSendEmail(listOfInvoices[0].id,pandaDocAttachmentName,listOfEnrolment[0].id); 
                //insertPdfAndSendEmail(listOfInvoices[0].id,enrolmentId); 
                //Added by Jatin, 03th Mar 2020.  For push invoice on sageIntaccount describe by Sanjay
                SageIntacctIntegrationUtility.newEnrolment(parentId, new Set<string>{listOfInvoices[0].id});
            }
        }
    }
    
    // create invoice and generate payemnt records 
    Public void saveParentCardDetailsAndGenerateInvoice(){
        Savepoint sp;
        isError = false;
        errorMsg = '';
        // Map<String,Account> mapOfStudentAndParentAccount  = new Map<String,Account>();
        EnrollmentProcessErrorLogs.errorLogObj errorObj = new EnrollmentProcessErrorLogs.errorLogObj();
        string countryCurrencyCode = studentSummaryDetails.objCountry.Currency_Code__c;
        decimal gstTaxPer			=  Integer.valueOf(studentSummaryDetails.objCountry.Tax_Rate__c);
        CampDetailsForEnrolStudentController.AccountModal newStudentDetails = studentSummaryDetails.studentDetails ;
        map<string,string> stripeCstmrDetails = new map<string,string>();
        system.debug('stripeToken'+stripeToken);
        if(!isCreateStudent){
            if(studentSummaryDetails.isAmcClubMember || studentSummaryDetails.isAlreadyStripCstmr || (stripeToken!=null && stripeToken.trim().length()>0)){
                try{  
                    
                    Account parentAcc =  newStudentDetails.parentAccDetails;
                    //for American club member
                    if(!studentSummaryDetails.isAmcClubMember && (!studentSummaryDetails.isAlreadyStripCstmr || String.isBlank(studentSummaryDetails.stripeCstmrId))){                    
                        //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                        //stripeCstmrDetails = createStripeCustomer(newStudentDetails.parentAccDetails,stripeToken,studentSummaryDetails.objCountry.Stripe_Base_Url__c,studentSummaryDetails.objCountry.Stripe_Secret_Key__c);
                        stripeCstmrDetails = createStripeCustomer(newStudentDetails.parentAccDetails,stripeToken,studentSummaryDetails.organisationOfCentre.Stripe_Base_Url__c,studentSummaryDetails.organisationOfCentre.Stripe_Secret_Key__c);
                        if(stripeCstmrDetails != null && stripeCstmrDetails.size() > 0){
                            if(stripeCstmrDetails.containsKey('Error')){
                                isError = true;
                                errorMsg = stripeCstmrDetails.get('Error');
                            }else{
                                if(stripeCstmrDetails.containsKey('stripeCstmrId')){
                                    studentSummaryDetails.stripeCstmrId = stripeCstmrDetails.get('stripeCstmrId');
                                }
                            }
                        }
                    }
                    
                    // for American club member
                    if(studentSummaryDetails.isAmcClubMember || String.isNotBlank(studentSummaryDetails.stripeCstmrId)){ 
                        
                        Decimal amountInSmallUnit      = studentSummaryDetails.totalAmount;
                        BillingUtility.stripeCharge sc = new BillingUtility.stripeCharge(); 
                        // Skip stripe customer creation for the American club member
                        if(!studentSummaryDetails.isAmcClubMember){
                            ////commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                            //      sc = BillingUtility.createChargeForCustomer(studentSummaryDetails.stripeCstmrId,amountInSmallUnit, countryCurrencyCode, studentSummaryDetails.objCountry.Stripe_Base_Url__c, studentSummaryDetails.objCountry.Stripe_Secret_Key__c);
                            sc = BillingUtility.createChargeForCustomer(studentSummaryDetails.stripeCstmrId,amountInSmallUnit, countryCurrencyCode, studentSummaryDetails.organisationOfCentre.Stripe_Base_Url__c, studentSummaryDetails.organisationOfCentre.Stripe_Secret_Key__c);
                        }
                        
                        //for the American club member
                        // Paid condition for check the payment is success/unsucess(In case of declined)
                        if(studentSummaryDetails.isAmcClubMember || (sc.statusCode == 200 && sc.paid)){
                            sp = Database.setSavepoint();
                            List<Account> centrList  = [SELECT Id, Name, Location__c, Country__c, Country__r.Country_Name__c FROM Account WHERE Id =: newStudentDetails.centerId];
                            if(centrList.size() > 0){
                                newStudentDetails.parentAccDetails.Location__c = centrList.get(0).Location__c;
                                if(centrList.get(0).Country__r.Country_Name__c != null)
                                    newStudentDetails.parentAccDetails.Country_PI__pc = centrList.get(0).Country__r.Country_Name__c;
                            }
                            if(!studentSummaryDetails.isAmcClubMember){
                                newStudentDetails.parentAccDetails.Stripe_Customer_Id__c = studentSummaryDetails.stripeCstmrId;
                                if(!test.isRunningTest()){
                                    if(stripeCstmrDetails.containsKey('last4CardNumber'))
                                        newStudentDetails.parentAccDetails.Card_Number__c = stripeCstmrDetails.get('last4CardNumber');
                                    if(stripeCstmrDetails.containsKey('cardType'))
                                        newStudentDetails.parentAccDetails.Card_Type__c = stripeCstmrDetails.get('cardType');
                                    if(stripeCstmrDetails.containsKey('exp_month'))
                                        newStudentDetails.parentAccDetails.Expiry_Month__c = decimal.valueOf(stripeCstmrDetails.get('exp_month'));
                                    if(stripeCstmrDetails.containsKey('exp_year'))
                                        newStudentDetails.parentAccDetails.Expiry_Year__c =  decimal.valueOf(stripeCstmrDetails.get('exp_year'));
                                }
                            }
                            newStudentDetails.parentAccDetails.id = parentId;
                            update newStudentDetails.parentAccDetails;
                            //newStudentDetails = createParentStudentsAccountDetails(studentSummaryDetails,studentSummaryDetails.stripeCstmrId,stripeCstmrDetails);
                            // to create error logs if exception occurs
                            //Below mapping will also be used to refund the amount back to the customer.
                            
                            errorObj.customerStripeId = studentSummaryDetails.stripeCstmrId;
                            errorObj.stripeTransactionId = sc.id;
                            errorObj.stripeChargeAmount = sc.amount;
                            errorObj.customerSalesforceId = parentId;
                            //commented by @nishi 24 Aug 2020,Organisation wise charge as per new logic
                            // errorObj.baseUrl = studentSummaryDetails.objCountry.Stripe_Base_Url__c;
                            // errorObj.apiKey  = studentSummaryDetails.objCountry.Stripe_Secret_Key__c;
                            errorObj.baseUrl = studentSummaryDetails.organisationOfCentre.Stripe_Base_Url__c;
                            errorObj.apiKey  = studentSummaryDetails.organisationOfCentre.Stripe_Secret_Key__c;
                            updateCustomerAndGenerateInvoice(newStudentDetails,centrList,sc);
                            
                            isError  = false;
                            
                        }else{
                            errorMsg = sc.error.message;
                            isError  = true;
                            
                            //showing custom error messagge if card decliend
                            if(String.isNotBlank(sc.error.decline_code))
                                errorMsg= 'Payment Failed. Please try with a different card.';
                        }
                    }
                }catch(Exception e){
                    System.debug('Error:  '+e.getMessage());
                    System.debug('Error:  '+e.getLineNumber());
                    Database.rollback(sp);
                    
                    errorMsg = e.getMessage();
                    isError  = true;
                    
                    //Create error log and refund amount
                    errorObj.exceptionMessage = errorMsg;
                    String jsonObj = JSON.serialize(errorObj);
                    
                    system.debug('jsonObj-->'+jsonObj);
                    
                    EnrollmentProcessErrorLogs.generateErrorLogsAndRefundAmount(jsonObj);                
                    
                }
            }
        }
    } 
    
    // create invoice and payment records if found early birds then give discount to  user 
    public static List<Invoice__c> createInvoiceAndPayment(CampStudentSummaryWrapperClass studentSummaryDetails, BillingUtility.stripeCharge sc,  map<string,Enrolment__c> mapOfEnrolment,CampDetailsForEnrolStudentController.AccountModal newStudentDetails){
        string countryCurrencyCode = studentSummaryDetails.objCountry.Currency_Code__c;
        decimal gstTaxPer			=  Integer.valueOf(studentSummaryDetails.objCountry.Tax_Rate__c);
        Map<Id, Invoice__c> cntrInvMap      = new Map<Id, Invoice__c>();
        Map<Id, Payment__c> cntrPayMap      = new Map<Id, Payment__c>();
        List<Invoice_Line_Item__c> invLineItmList     = new List<Invoice_Line_Item__c>();
        
        Invoice__c inv        = new Invoice__c();
        inv = BillingUtility.fillInvoice(null, newStudentDetails.parentAccDetails.Id, ConstantsClass.paidStatus);
        inv.Center__c = newStudentDetails.centerId; 
        inv.invoice_type__c = 'Camp';
        if(studentSummaryDetails.isAmcClubMember){
            inv.Status__c   = ConstantsClass.dueStatus; 
        }
        cntrInvMap.put(newStudentDetails.centerId, inv);
        //Filling Payment
        String payTrnRecId =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentTransactionRecType).getRecordTypeId();
        Payment__c pay     = new Payment__c(RecordtypeId = payTrnRecId);
        Decimal totAmtTemp = studentSummaryDetails.totalAmount;
        
        pay = BillingUtility.fillPayment(newStudentDetails.parentAccDetails.Id, null, totAmtTemp, ConstantsClass.successStatus);
        pay.RecordtypeId      = payTrnRecId;
        pay.Method_of_Payment__c = 'Card';
        if( string.isNotBlank( sc.id)){
            pay.Transaction_ID__c = sc.id; 
        }
        pay.Invoice__r        = inv;
        
        //No need to create payment for the American club member
        if(!studentSummaryDetails.isAmcClubMember)
            cntrPayMap.put(newStudentDetails.centerId, pay);
        // 20-Feb-2020: Jatin: manage mulitple students related package fee for creating pay amount invoice
        for(CampStudentSummaryWrapperClass.BillingSummary objBillingSummary :studentSummaryDetails.listOfBillSummary){
            decimal packageFee=0 ;
            if(string.isNotBlank(objBillingSummary.packageId) && objBillingSummary.amount  != null){
                packageFee= objBillingSummary.amount;
            }
            Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, BillingUtility.roundOffAmount(packageFee), '', null);
            
            if(string.isNotBlank(objBillingSummary.studentTempId) && mapOfEnrolment.containsKey(objBillingSummary.studentTempId)){
                invLnItm.Package__c   = mapOfEnrolment.get(objBillingSummary.studentTempId).Package__c;
                invLnItm.Enrolment__c = mapOfEnrolment.get(objBillingSummary.studentTempId).id;
                // 25-Feb-2020: populate the student name in invoice line item.
                invLnItm.Remarks__c = objBillingSummary.studentName;
            }
            
            // 20-Feb-2020: Jatin: for add discount amount per package fee
            decimal netGrossAmount = 0;
            if(objBillingSummary.netDiscountAmount != null && objBillingSummary.netDiscountAmount > 0){
                invLnItm.Discount_Amount__c = BillingUtility.roundOffAmount(objBillingSummary.netDiscountAmount);
                netGrossAmount = packageFee - objBillingSummary.netDiscountAmount;
            }else{
                netGrossAmount = packageFee;
            }
            invLnItm.Invoice__r   = inv;
            invLnItm.Is_Deposit__c = false;
            invLnItm.Month__c  =  System.today();
            
            if(netGrossAmount != null && netGrossAmount >  0 && gstTaxPer != null && gstTaxPer > 0 ){
                Double gstAmount = BillingUtility.roundOffAmount(netGrossAmount * (gstTaxPer / 100));
                invLnItm.gst_Amount__c = gstAmount;
            }
            invLineItmList.add(invLnItm);
        }
        
        
        
        //calcuate individual gst amount for the line items
        
        /* if(studentSummaryDetails.campDayList != null && studentSummaryDetails.campDayList.size() > 0){

decimal packageFee = 0;
if(string.isNotBlank(studentSummaryDetails.objCampPackage.id) && studentSummaryDetails.objCampPackage.Package__r != null && 
studentSummaryDetails.objCampPackage.Package__r.package_Fee__c  != null){
packageFee= studentSummaryDetails.objCampPackage.Package__r.package_Fee__c;
}/* // commented by jatin: 13-feb : manage by a selected package fees not a days wise calculation

for(Camp_Days__c campDayObj : studentSummaryDetails.campDayList){
Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, BillingUtility.roundOffAmount(packageFee), '', campDayObj.Camp_Teacher__c);
if(string.isNotBlank(studentSummaryDetails.objCampPackage.id) && studentSummaryDetails.objCampPackage.Package__r != null && string.isNotBlank(studentSummaryDetails.objCampPackage.Package__c)){
invLnItm.Package__c   = studentSummaryDetails.objCampPackage.Package__c;
}
if(string.isNotBlank(enrolmentId)){
invLnItm.Enrolment__c = enrolmentId;
}
invLnItm.Invoice__r   = inv;
invLnItm.Is_Deposit__c = false;
invLnItm.Month__c  =  campDayObj.Dates_Of_The_Camp__c;
if(gstTaxPer >  0 && gstTaxPer > 0 ){
Double gstAmount = BillingUtility.roundOffAmount(packageFee * (gstTaxPer / 100));
invLnItm.gst_Amount__c = gstAmount;
}
invLineItmList.add(invLnItm);
}
// 13-feb-2020:jatin:check early bird start and date is exist and discount amount is greater then 0 
// user enrol in middel of this early dates then give discount other wise not so we manage gross amount and add gst according to gross amount

/*commented by jatin: 20-feb:2020: for create invoice_ line itme for multiple student packages  
Invoice_Line_Item__c invLnItm = BillingUtility.fillInvLnItm(null, null, null, BillingUtility.roundOffAmount(packageFee), '', null);
if(string.isNotBlank(studentSummaryDetails.objCampPackage.id) && studentSummaryDetails.objCampPackage.Package__r != null && string.isNotBlank(studentSummaryDetails.objCampPackage.Package__c)){
invLnItm.Package__c   = studentSummaryDetails.objCampPackage.Package__c;
}
if(string.isNotBlank(enrolmentId)){
invLnItm.Enrolment__c = enrolmentId;
}
// 14-Feb-2020: Jatin: for add discount amount
invLnItm.Discount_Amount__c = math.abs(studentSummaryDetails.discountAmount);
invLnItm.Invoice__r   = inv;
invLnItm.Is_Deposit__c = false;
invLnItm.Month__c  =  System.today();
if(studentSummaryDetails.grossAmount != null && studentSummaryDetails.grossAmount >  0 && gstTaxPer != null && gstTaxPer > 0 ){
Double gstAmount = BillingUtility.roundOffAmount(studentSummaryDetails.grossAmount * (gstTaxPer / 100));
invLnItm.gst_Amount__c = gstAmount;
}
invLineItmList.add(invLnItm);
}*/
        system.debug('cntrInvMap'+cntrInvMap);  
        //Insert Invoice
        if(cntrInvMap.size() > 0){
            Insert cntrInvMap.values();
        }
        system.debug('cntrInvMap'+cntrInvMap);  
        system.debug('cntrPayMap'+cntrPayMap);  
        //Insert Payment
        if(cntrPayMap.size() > 0){
            for(Payment__c payobj: cntrPayMap.values()){
                payobj.Invoice__c = pay.Invoice__r.id;
                payobj.Payment_Amount__c = BillingUtility.roundOffAmount(payobj.Payment_Amount__c);
            }    
            insert cntrPayMap.values(); 
        }
        system.debug('cntrPayMap'+cntrPayMap);  
        system.debug('invLineItmList'+invLineItmList);  
        if(invLineItmList.size() > 0){
            for(Invoice_Line_Item__c invLnItm: invLineItmList){
                invLnItm.Invoice__c = invLnItm.Invoice__r.Id;
            }
            
            insert invLineItmList;
        }
        system.debug('invLineItmList'+invLineItmList);
        return cntrInvMap.values();
    }
    
    
    
    
    Public void signAgreement(){
        documentDetails = new PandaDocUtility.CreateDocument();
        if(String.isNotBlank(parentId)){
            String body = fillCreateDocumentWrapper(studentSummaryDetails);  
            documentDetails = PandaDocUtility.createDocument(body);  
            system.debug('documentDetails'+documentDetails);
        }  
        
    }
    
    
    // jatin:21-feb-2020: for wait to some mins then check Aggrement 
    Public Void waitAgreement(){
        system.debug('documentDetails.id'+documentDetails.id);
        PandaDocUtility.Document document = new PandaDocUtility.Document();
        if(String.isNotBlank(documentDetails.id)){
            document = PandaDocUtility.viewDocument(documentDetails.id);
            system.debug('documentDetails'+documentDetails);
        } 
    }
    //jatin:21-feb-2020:for wait to some mins then send Aggrement 
    Public void sendAgreement(){
        DocumentWrapper.SendDocument sendDocument;
        String body = '';
        system.debug('documentDetails.id'+documentDetails.id);
        if(String.isNotBlank(documentDetails.id)){
            sendDocument = new DocumentWrapper.SendDocument('Hello! This document was sent from the PandaDoc API.', true);      
            body = JSON.serialize(sendDocument);
            documentDetails = PandaDocUtility.sendDocument(body, documentDetails.id);
            System.debug('@@@documentDetails'+documentDetails);
        }
    }
    
    // jatin:21-feb-2020: for create session Id for show aggrement 
    Public void createSession(){
        
        if(String.isNotBlank(documentDetails.id) && String.isNotBlank(personEmail)){
            sessionId = PianoRentalHelperController.createSession(documentDetails.id,personEmail);
        }
    }
    
    
    
    private String fillCreateDocumentWrapper(CampStudentSummaryWrapperClass studentSummaryDetails){     
        string campStartTime='';
        string campEndTime='';
        if(studentSummaryDetails.listOfcampStudentCampDays != null && studentSummaryDetails.listOfcampStudentCampDays.size() >0 ){
            if(studentSummaryDetails.listOfcampStudentCampDays[0].listOfCampDays != null && studentSummaryDetails.listOfcampStudentCampDays[0].listOfCampDays.size()> 0 ){
                campStartTime  = studentSummaryDetails.listOfcampStudentCampDays[0].listOfCampDays[0].campStartTime;
                campEndTime = studentSummaryDetails.listOfcampStudentCampDays[0].listOfCampDays[0].campEndTime;
            }
        }
        String jsonBody = '';       
        DocumentWrapper.Fields field;      
        CampDetailsForEnrolStudentController.AccountModal newStudentDetails = studentSummaryDetails.studentDetails ;
        DocumentWrapper.recipients recipient = new DocumentWrapper.recipients();        
        List<DocumentWrapper.Rows> rows = new List<DocumentWrapper.Rows>();     
        List<DocumentWrapper.Sections> sections = new List<DocumentWrapper.Sections>();     
        List<DocumentWrapper.PricingTable> pricingTables = new List<DocumentWrapper.PricingTable>();        
        DocumentWrapper.CreateDocument createDocWrapper = new DocumentWrapper.CreateDocument();     
        //@Juneid 28 Aug 2020 commneted because as per new requiermnt Teplate is pull from orgnization
        //createDocWrapper.template_uuid = Label.Camp_Class_Template_Id;   
        createDocWrapper.template_uuid = studentSummaryDetails.organisationOfCentre.Camp_Class_Template__c;
    
        createDocWrapper.folder_uuid = studentSummaryDetails.objCountry.Folder__c;
        if(String.isNotBlank(parentId)){       
            createDocWrapper.metadata.salesforceAccount_id = parentId;     
            recipient.first_name = newStudentDetails.parentAccDetails.firstName;        
            recipient.last_name = newStudentDetails.parentAccDetails.lastName;      
            recipient.email = newStudentDetails.parentAccDetails.PersonEmail;     
            field = new DocumentWrapper.Fields(newStudentDetails.parentAccDetails.firstName +' '+newStudentDetails.parentAccDetails.lastName, 'Parent Name');       
            createDocWrapper.fields = new DocumentWrapper.CustomField(field);       
            recipient.role = 'Client';      
            createDocWrapper.recipients = new List<DocumentWrapper.Recipients>();       
            createDocWrapper.recipients.add(recipient);  
            personEmail = newStudentDetails.parentAccDetails.PersonEmail;
        } 
        
        if(newStudentDetails.listOfStudentDetails != null && newStudentDetails.listOfStudentDetails.size() > 0){      
            DateTime enrolmentDateTime;     
            createDocWrapper.name = '';     
            DocumentWrapper.Rows row;  
            // To populate updated information in panda doc
            for(CampDetailsForEnrolStudentController.StudentDetail objStudentDetail :  newStudentDetails.listOfStudentDetails){
                if(studentSummaryDetails.mapOfStudentCampDays != null && studentSummaryDetails.mapOfStudentCampDays.size() > 0){
                    enrolmentDateTime = dateTime.newInstance(studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Dates_Of_The_Camp__c,
                                                             studentSummaryDetails.mapOfStudentCampDays.get(objStudentDetail.student.id)[0].objCampDays.Camp_Start_Time__c);
                }string packageName='';
                if(studentSummaryDetails.mapOfCampPackage != null && studentSummaryDetails.mapOfCampPackage.size() >0){
                    system.debug('newStudentDetails.mapOfStudentAccount'+studentSummaryDetails.mapOfCampPackage);
                    if(studentSummaryDetails.mapOfCampPackage.containsKey(objStudentDetail.packageId) && string.isNotBlank(studentSummaryDetails.mapOfCampPackage.get(objStudentDetail.packageId).name)){
                        system.debug('newStudentDetails.mapOfStudentAccount'+studentSummaryDetails.mapOfCampPackage.get(objStudentDetail.packageId).Package__c);
                        packageName = studentSummaryDetails.mapOfCampPackage.get(objStudentDetail.packageId).Name;
                    }
                }
                createDocWrapper.name += objStudentDetail.student.firstname + '-';       
                List<string>  campDates = new List<string>();
                for(CampDetailsForEnrolStudentController.CampDays objcampDays : objStudentDetail.campDays){
                    campDates.add(objcampDays.campDate);
                }
                string campDateString = string.join(campDates,',');
                row = new DocumentWrapper.Rows(new DocumentWrapper.Data(objStudentDetail.student.firstname + ' ' + objStudentDetail.student.LastName), 
                                               new DocumentWrapper.CustomFields(packageName, /*campStartTime+' - '+campEndTime,*/ campDateString,studentSummaryDetails.objCampClass.Centre__r.Name));      
                rows.add(row);   
            }    
            
            sections.add(new DocumentWrapper.Sections('Sample Title', rows));       
            pricingTables.add(new DocumentWrapper.PricingTable('PricingTable1', sections));     
            createDocWrapper.pricing_tables = new List<DocumentWrapper.PricingTable>();     
            createDocWrapper.pricing_tables = pricingTables;        
            createDocWrapper.name += 'CampStudentPolicy';    
            pandaDocAttachmentName = createDocWrapper.name;
            
        }       
        
        if(String.isNotBlank(createDocWrapper.name)){       
            jsonBody = JSON.Serialize(createDocWrapper).replaceAll('pandadoc_Default_Section_XYZ','default');   
            jsonBody = jsonBody.replaceAll('pandadoc_Currency_Code_XYZ','currency');     
            System.debug('createDocWrapper '+createDocWrapper);     
            System.debug('createDocWrapper '+createDocWrapper.metadata);        
            jsonBody = jsonBody.replaceAll('salesforceAccount_id','salesforce.account_id');     
            JSONBody = jsonBody;        
        }       
        
        System.debug('@@@jsonBody'+jsonBody);       
        
        
        
        return jsonBody;        
    }
    
    
    
}