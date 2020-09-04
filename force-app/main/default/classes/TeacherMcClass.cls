public class TeacherMcClass {
    private static string Teacher = ConstantsClass.teacherRecTypeName; 
    private static string lesson = ConstantsClass.recordTypeLesson;
    @AuraEnabled
    public static list<Account> getTeacherAccount(string AccountId){
        Id TeacherRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Teacher).getRecordTypeId();
        
        list<Account> accList =[select Id,Name,RecordType.Name From Account Where Id=:AccountId and RecordTypeId =:TeacherRecordTypeId];
        if(accList.size()>0)
            return accList;
        return accList;
    }
    
    public class LeaveRequestClass {
        
        @AuraEnabled
        public String Employee;
        @AuraEnabled
        public Date Leave_Start_Date;
        @AuraEnabled
        public Date Leave_End_Date;
        @AuraEnabled
        public string RecordTypeName;
        @AuraEnabled
        public String Remarks;
        
        public LeaveRequestClass(){
            
        }
    }
    public class BookingWrapper{
        @AuraEnabled
        Integer TotalTime{get;set;}
        @AuraEnabled
        Integer TotalCount{get;set;}
    }
    @AuraEnabled
    public static list<BookingWrapper> SaveLeaveRequest(string recordObj, string recordId){
        LeaveRequestClass reqObj = new LeaveRequestClass();
        list<BookingWrapper> BkgList = new list<BookingWrapper>();
        reqObj = (LeaveRequestClass)JSON.deserialize(recordObj, LeaveRequestClass.class);
        integer i=1;
        integer TotalTime =0;
        integer TotalCount =0;
        list<Booking__c> bookingList = [select Id,Start_Time__c,End_Time__c,Status__c,Type__c,Booking_Date__c  from Booking__c where Teacher_Account__c=:recordId AND Booking_Date__c >=: reqObj.Leave_Start_Date AND Booking_Date__c <=: reqObj.Leave_End_Date And Type__c in ('Trial','Regular','Make-up','Ad-hoc') And Status__c in ('Pending','Scheduled') AND Category__c !='Leave'];
        
        if(bookingList.size()>0){
            for(Booking__c bkg:bookingList){
                if(bkg.Type__c=='Regular' || bkg.Type__c=='Ad-hoc'){
                    TotalTime += ( bkg.End_Time__c.hour() * 60 + bkg.End_Time__c.minute() )  - ( bkg.Start_Time__c.hour()*60 + bkg.Start_Time__c.minute());  
                }
                TotalCount +=i; 
            }
        }
        BookingWrapper bkgWrap = new BookingWrapper();
        bkgWrap.TotalTime=TotalTime;
        bkgWrap.TotalCount=TotalCount;
        BkgList.add(bkgWrap);
        if(BkgList.size()>0){
            return BkgList;
        }
        return BkgList;
        
        
    }
    @AuraEnabled
    public static string UpdateBooking(string recordObj, string recordId,String LeaveType){
        string message='Success';
        Savepoint sp = Database.setSavepoint();
        try{
            // retrieved lesson record type for Booking
            Id lessonTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(lesson).getRecordTypeId();
            // retrieve service request record type from Case
            Id caseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
            // retrieved Sick leave record type from leave request 
            Id leaveTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByName().get('Sick Leave').getRecordTypeId();
            // For Cancelled Booking List
            list<Booking__c> BkgList = new list<Booking__c>();
            // for creating busy booking 
            list<Booking__c> BookingLeaveList = new list<Booking__c>();
            // For Placeholder Booking
            list<Booking__c> placeholdeBooking = new list<Booking__c>();
            string lessonRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
            
            List<Case> casList = new List<Case>();
            LeaveRequestClass reqObj = new LeaveRequestClass();
            reqObj = (LeaveRequestClass)JSON.deserialize(recordObj, LeaveRequestClass.class);
            // CHeck for the leave Availability for particular day
            //List<Leave_Request__c> LeaveRequestCheckList = new List<Leave_Request__c>([select Id from Leave_Request__c where Leave_Start_Date__c =:reqObj.Leave_Start_Date and ]);
            // Creating Leave request
            list<Leave_Request__c> leaveReqList = new list<Leave_Request__c>();
            Leave_Request__c leaveReqObj = new Leave_Request__c(Employee__c=reqObj.Employee,Leave_Start_Date__c=reqObj.Leave_Start_Date,Leave_End_Date__c=reqObj.Leave_End_Date,RecordTypeId=leaveTypeId,Remarks__c=reqObj.Remarks,Leave_Type__c=LeaveType);
            leaveReqList.add(leaveReqObj);
            if(leaveReqList.size()>0){
                insert leaveReqList;
            }
            // Booking list retrieved when given type and status
            //Sanjay Mankani : Added field Available_Make_up_Units__c, Make_up_Utilize_Bookings__c 
            list<Booking__c> bookingList = [select Id,End_Time__c,Teacher_Account__r.Name,Teacher_Account__r.Id,Type__c,Status__c,Booking_Date__c,Start_Time__c,Parent__c,Student__c,Parent__r.PersonContactId,Parent__r.personEmail,Center__c,Center__r.Location__c,Student__r.Name,Teacher_Account__c,Enrolment__c,Available_Make_up_Units__c,Make_up_Utilize_Bookings__c  from Booking__c where Teacher_Account__c=:recordId AND Booking_Date__c >=: reqObj.Leave_Start_Date AND Booking_Date__c <=: reqObj.Leave_End_Date  And Type__c in ('Trial','Regular','Make-up','Ad-hoc','Busy') And Status__c in ('Pending','Scheduled') AND Category__c !='Leave'];
            system.debug('bookingList===>' + bookingList.size() + 'bookingList' + bookingList);
            
            // store the Makeup booking  Id with the offered Min 
            Map<Id,Integer> makeupId= new Map<Id,Integer>();
            list<Booking__c> updateMakeupList = new list<Booking__c>();
            if(bookingList.size()>0){
                for(Booking__c bkgObj:bookingList){
                    // Creating Case For each Booking except Busy and Trial
                    if(bkgObj.Type__c != 'Busy' && bkgObj.Type__c != 'Trial'){
                     
                        //String SubjectCase='Teacher '+ bkgObj.Teacher_Account__r.Name +' is on leave from ' +reqObj.Leave_Start_Date.day() +' ' + month +' to '+ reqObj.Leave_End_Date.day() + ' ' + monthend;
                        Case casObj = new Case(Status='Closed',Type=bkgObj.Type__c,Origin='Automation',Priority='Medium',Booking__c=bkgObj.Id,
                                               Centre_Name__c=bkgObj.Center__c,Student_Name__c=bkgObj.Student__c,AccountId=bkgObj.Parent__c,
                                               Location__c=bkgObj.Center__r.Location__c,Leave_Start_Date__c=reqObj.Leave_Start_Date,Leave_End_Date__c=reqObj.Leave_End_Date);
                        casList.add(casObj);  
                    }
                    Booking__c bkg = new Booking__c();
                    // Updating Booking Status To Cancel except for Trial
                    if(bkgObj.Type__c !='Trial'){
                        bkgObj.Status__c='Canceled';
                        // Updated On 19 Nov 2019 changed Cancelleation Reason(By Ravi) 
                        bkgObj.Cancellation_Reason__c= LeaveType=='Teacher MC' ? 'Teacher MC':'Teacher Leave';
                        bkgObj.Make_up_Expiry_Date__c=bkgObj.Booking_Date__c.addDays(120);
                    }
                    if(bkgObj.Type__c=='Regular'){
                        string description='placeholder booking for cancelling '+ bkgObj.Student__r.Name +' booking';
                        Booking__c placIns= new Booking__c(Center__c=bkgObj.Center__c,RecordTypeId=lessonRecordType,
                                                           Teacher_Account__c=bkgObj.Teacher_Account__r.Id,Type__c='Busy',Category__c='Placeholder',Remarks__c=description,
                                                           Booking_Date__c=bkgObj.Booking_Date__c,Start_Time__c=bkgObj.Start_Time__c,End_Time__c=bkgObj.End_Time__c,Status__c='Scheduled');
                        placeholdeBooking.add(placIns);
                    }
                    // upating Available Make up min to sum of total given Credit for Regular and Ad-hoc  
                    if(bkgObj.Type__c=='Regular' || bkgObj.Type__c=='Ad-hoc')
                        bkgObj.Available_Make_up_Units__c= ( bkgObj.End_Time__c.hour() * 60 + bkgObj.End_Time__c.minute() )  - ( bkgObj.Start_Time__c.hour()*60 + bkgObj.Start_Time__c.minute());
                    if(bkgObj.Type__c =='Make-up'){
                        system.debug('---1'+bkgObj.Type__c + '----'+bkgObj.Make_up_Utilize_Bookings__c);
                        if(bkgObj.Make_up_Utilize_Bookings__c != null){
                            list<string> makeUpString=bkgObj.Make_up_Utilize_Bookings__c.split(';');
                            system.debug('===>makeUpString'+makeUpString);
                            for(String makeInstID:makeUpString){
                                //Adding the Make up bkg id with the offered min
                                //added on 7 nov 2019 
                                ////Adding the Make up bkg id with the offered min
                                if(makeupId.containsKey(makeInstID.split('-')[0])){
                                    integer offrMin=makeupId.get(makeInstID.split('-')[0]) + integer.valueOf(makeInstID.split('-')[1]);
                                    makeupId.put(string.valueOf(makeInstID.split('-')[0]), offrMin);
                                }else{
                                  makeupId.put(string.valueOf(makeInstID.split('-')[0]),integer.valueOf(makeInstID.split('-')[1]));
                                }
                            } 
                        }
                        //bkgObj.Available_Make_up_Units__c += integer.valueOf(bkgObj.Make_up_Utilize_Bookings__c.split('-')[1]);
                    } 
                    //system.debug('bkgObj.Parent__r.PersonContactId'+bkgObj.Parent__r.PersonContactId);
                    
                    BkgList.add(bkgObj);
                    // system.debug('BkgList'+BkgList + 'BkgList'+BkgList.size());
                }
                for(Booking__c book:[select Id,Make_up_Utilize_Bookings__c,Available_Make_up_Units__c from Booking__c where Id in :makeupId.keySet()]){
                    if(makeupId.containsKey(book.Id)){
                        book.Available_Make_up_Units__c=makeupId.get(book.Id);                    
                    }
                    
                    updateMakeupList.add(book);                
                }
                
            }
            // inserting case for each booking except for trial
            if(casList.size()>0){
                insert casList;
            }
            // Inserting Makeup Booking list
            if(updateMakeupList.size()>0){
                update updateMakeupList;
            }
            // creating placeholder booking for the Regular  booking
            if(placeholdeBooking.size()>0){
                insert placeholdeBooking;
            }
            // calling future method to send mail on case to respective parent
            list<Id> Ids = new List<Id>();
            for(Case CasObj:casList){
                Ids.add(CasObj.Id);
            }
            sendCaseEmail(Ids,LeaveType);
            /*   ------for(Case CasObject:[select Id,Booking__r.Type__c,Booking__r.Status__c,Booking__r.Start_Time__c,Booking__r.Parent__r.PersonContactId,Booking__r.Parent__r.personEmail,Booking__r.Center__c,Booking__r.Center__r.Location__c,Booking__r.Teacher_Account__c from Case where Id in:casList]){
            system.debug('CasObject---'+CasObject.Id);
            if(String.isNotBlank(templateId) && (CasObject.Booking__r.Type__c =='Regular' || CasObject.Booking__r.Type__c =='Ad-hoc' ||  CasObject.Booking__r.Type__c =='Make-up' ) ){
            personEmailList.add(CasObject.Booking__r.Parent__r.personEmail);
            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
            //mail.setToAddresses(personEmailList);
            emailList.add(mail);
            }
            }
            Messaging.sendEmail(emailList); -------*/
            //system.debug('casList.size()' + casList.size() + 'casList===>'+casList);
            // updating the Booking 
            if(BkgList.size()>0)
            {
                update BkgList;
            }
            // system.debug('BkgList--->'+BkgList);
            // Inserting the Busy schedule Booking  for the Teacher for each Day from 8 Am To 8 Pm
            Time StartTime =Time.newInstance(08, 00, 00, 00);
            Time EndTime=Time.newInstance(20, 00, 00, 00);
            Integer numberDaysDue = Date.valueOf(reqObj.Leave_Start_Date).daysBetween(Date.valueOf(reqObj.Leave_End_Date));
            //system.debug('numberDaysDue'+numberDaysDue+'StartTime' + StartTime + 'EndTime' + EndTime);
            //integer count=0;
            // storing Start leave date for the teacher
            
            list<Booking__c> bkgLeaveList= new List<Booking__c>([select Id from  Booking__c Where Type__c='Busy' and Category__c='Leave' and Status__c ='Scheduled' and Teacher_Account__c=:reqObj.Employee and Booking_Date__c >=:reqObj.Leave_Start_Date And Booking_Date__c <=:reqObj.Leave_End_Date]);
            // getting the record of working hour as per day for particular Teacher
            List<Teacher_Working_Hour__c> workingList=[select Working_Day__c,Start_Time__c,End_Time__c from Teacher_Working_Hour__c  where  Teacher_Name__c=:recordId and Break_Time__c=false];
            // store working day and  time 
            map<string,string> mapToworkinghour = new map<string,string>();
            for(Teacher_Working_Hour__c workInstance:workingList){
                mapToworkinghour.put(workInstance.Working_Day__c,workInstance.Start_Time__c + '/'+workInstance.End_Time__c);
            }
            // system.Debug('----mapToworkinghour'+mapToworkinghour);
            if(bkgLeaveList.size() == 0){
                // checking no of locating on which teacher works
                AggregateResult[] groupedResults
                    = [select Center_Name__c from Teacher_Working_Hour__c  where  Teacher_Name__c=:recordId group by Center_Name__c];
                for (AggregateResult ar : groupedResults)  {
                    Date leaveDate=reqObj.Leave_Start_Date;
                    // System.debug('Campaign ID' + ar.get('Center_Name__c'));
                    string CenterId =string.valueOf(ar.get('Center_Name__c'));
                    for(integer count=0;count<=numberDaysDue;count++){
                        Datetime dt = DateTime.newInstance(leaveDate, Time.newInstance(0, 0, 0, 0));
                        String dayOfWeek=dt.format('E');
                        if(mapToworkinghour.containsKey(dayOfWeek)){
                            integer hr=integer.valueOf(mapToworkinghour.get(dayOfWeek).split('/')[0].split(':')[0]);
                            integer min=integer.valueOf(mapToworkinghour.get(dayOfWeek).split('/')[0].split(':')[1]);
                            StartTime=Time.newInstance(hr,min,00,00);
                            integer Ehr=integer.valueOf(mapToworkinghour.get(dayOfWeek).split('/')[1].split(':')[0]);
                            integer Emin=integer.valueOf(mapToworkinghour.get(dayOfWeek).split('/')[1].split(':')[1]);
                            EndTime=Time.newInstance(Ehr,Emin,00,00);
                        }
                        String RemarkforTeacherLeave='';// Defining the remark for the Teacher Leave reason  
                        if(leaveType =='Teacher MC'){
                            RemarkforTeacherLeave ='Teacher MC';
                        }else{
                            RemarkforTeacherLeave ='Teacher Leave';
                        }
                        Booking__c bkgLeaveObj = new Booking__c(End_Time__c=EndTime,Start_Time__c=StartTime,Status__c='Scheduled',Type__c='Busy',Category__c='Leave',Center__c=CenterId,Teacher_Account__c=reqObj.Employee,Booking_Date__c=leaveDate,Remarks__c=RemarkforTeacherLeave);
                        BookingLeaveList.add(bkgLeaveObj);  
                        //count++;
                        // adding the no of days teacher will be on Leave 
                        leaveDate=leaveDate.addDays(1);
                    }
                }
                
            }
            // check for the Leave availability
            if(BookingLeaveList.size()>0 && bkgLeaveList.size() == 0){
                insert BookingLeaveList;
            }
            
            // New Process For Fifth lesson Booking
             List<Booking__c> fifthPlaceholderBooking = new List<Booking__c>();
            List<Fifth_Lesson__c> fifthPlaceholderList = new List<Fifth_Lesson__c>();
            for(Fifth_Lesson__c fifthObj:[Select Id,Student__r.Name,Enrolment__c,Parent__r.PersonContactId,End_Time__c,Center__c,Student__c,Parent__c,Start_Time__c,Remarks__c,Center__r.Location__c,Package__c,Parent__r.PersonEmail,Booking_Date__c,Teacher_Account__c from Fifth_Lesson__c where IsActive__c =true and Booking_Date__c =:reqObj.Leave_Start_Date and Teacher_Account__c=:recordId]){
                Booking__c placIns= new Booking__c(Center__c=fifthObj.Center__c,RecordTypeId=lessonRecordType,Student__c=fifthObj.Student__c,Parent__c=fifthObj.Parent__c,Package__c=fifthObj.Package__c,Enrolment__c=fifthObj.Enrolment__c,
                                                   Teacher_Account__c=fifthObj.Teacher_Account__c,Type__c='Busy',Category__c='Placeholder',Remarks__c='Placeholder booking for Cancelling 5th lesson of '+ fifthObj.Student__r.Name +'',
                                                   Booking_Date__c=fifthObj.Booking_Date__c,Start_Time__c=fifthObj.Start_Time__c,End_Time__c=fifthObj.End_Time__c,Status__c='Scheduled'); 
                fifthPlaceholderBooking.add(placIns);
                Fifth_Lesson__c fObj = new Fifth_Lesson__c();
                fObj.Id=fifthObj.Id;
                fObj.Remarks__c='Placeholder booking for 5th lesson of '+ fifthObj.Student__r.Name +'';
                fObj.IsActive__c=false;
                fObj.Booking__r=placIns;
                fifthPlaceholderList.add(fObj);
            }
            if(fifthPlaceholderBooking.size()>0){
                insert fifthPlaceholderBooking;
            }
            if(fifthPlaceholderList.size()>0){
                for(Fifth_Lesson__c fifthObject:fifthPlaceholderList){
                    fifthObject.Booking__c=fifthObject.Booking__r.Id;
                }
                update fifthPlaceholderList;
            }
          // New Process For Fifth lesson Booking  
            
        } catch(exception e){
            message='Exception';
            system.debug(e.getLineNumber()+'>>>'+e.getMessage());
            Database.rollback(sp);
            return message;
        }
         return message;
    }
    
    @AuraEnabled
    public static list<Booking__c> getrequestedBooking(string recordData,string accountId){
        try{
            LeaveRequestClass reqObj = new LeaveRequestClass();
            list<Booking__c> bookingList = new list<Booking__c>();
            reqObj = (LeaveRequestClass)JSON.deserialize(recordData, LeaveRequestClass.class);
            bookingList = [select Id,Parent__r.Name,Student__r.Name,Booking_Date__c,Duration__c,Start_Time__c,Parent__r.Phone,Parent__r.PersonEmail,Status__c,Type__c  from Booking__c where Teacher_Account__c=:accountId AND Booking_Date__c >=: reqObj.Leave_Start_Date AND Booking_Date__c <=: reqObj.Leave_End_Date And Type__c in ('Trial','Regular','Make-up','Ad-hoc','Busy') And Status__c in ('Pending','Scheduled')];
            
            if(bookingList.size()>0){
                return bookingList;
            }
            return bookingList;
            
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        
    }
    @AuraEnabled
    public static list<Report> getReport(){
        return [select Id,Name from Report where Name ='Teacher Bookings'];
        
    }
    
    @future
    private static void sendCaseEmail(list<Id> Ids,string leaveType){
       // Savepoint sp = Database.setSavepoint();
        string templateId ='';
        list<EmailTemplate> templateList= new list<EmailTemplate>();
        // list<string> personEmailList = new list<string>();
        if(leaveType =='Teacher MC'){
            // template when teacher is on medical leave
            templateList = [Select Id from EmailTemplate where name = 'Teacher MC' limit 1];  
        }else{
            // template when teacher is on Holiday
            templateList = [Select Id from EmailTemplate where name = 'Teacher Leave' limit 1];
        }
        if(templateList[0].Id != null){
            templateId = templateList[0].Id;  
        }
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Case CasObject:[select Id,Booking__r.Type__c,Booking__r.Status__c,Booking__r.Start_Time__c,Booking__r.Parent__r.PersonContactId,Booking__r.Parent__r.personEmail,Booking__r.Center__c,Booking__r.Center__r.Location__c,Booking__r.Teacher_Account__c from Case where Id in:Ids]){
             system.debug('CasObject---'+CasObject.Booking__r.Parent__r.PersonEmail);
            if(String.isNotBlank(templateId) && String.isNotBlank(CasObject.Booking__r.Parent__r.PersonEmail) && (CasObject.Booking__r.Type__c =='Regular' || CasObject.Booking__r.Type__c =='Ad-hoc' ||  CasObject.Booking__r.Type__c =='Make-up' ) ){
                //personEmailList.add(CasObject.Booking__r.Parent__r.personEmail);
                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, CasObject.Booking__r.Parent__r.PersonContactId, CasObject.Id, CasObject.Booking__r.Center__r.Location__c);
                //mail.setToAddresses(personEmailList);
                emailList.add(mail);
            }
        }
            system.debug('emailList'+emailList);
        if(!test.isRunningTest())
            for(Messaging.SendEmailResult results :Messaging.sendEmail(emailList,false)){
                if(!results.isSuccess())
                    system.debug(results.getErrors());
            }    
    }
    
    /*@AuraEnabled
public static list<string> getPickListValue(){
List<String> options = new List<String>();
Schema.DescribeFieldResult fieldResult = Leave_Request__c.Leave_Type__c.getDescribe();
List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
for (Schema.PicklistEntry p: pList) {
options.add(p.getLabel());
}
return options;
}*/
    
    
    
}