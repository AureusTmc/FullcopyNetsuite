global class PublicHolidayProcess  implements Database.Batchable<sObject>, Database.Stateful{
    private static string lesson = ConstantsClass.recordTypeLesson;
    
    // retrieved lesson record type for Booking
    private Id lessonTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(lesson).getRecordTypeId();
    // retrieve service request record type from Case
    private Id caseId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Request').getRecordTypeId();
    // retrieved Sick leave record type from leave request 
    private Id leaveTypeId = Schema.SObjectType.Leave_Request__c.getRecordTypeInfosByName().get('Sick Leave').getRecordTypeId();
     // retrieved teacher recordType
    private string teacherTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Teacher').getRecordTypeId();
    
    // retriving case id 
   // private List<Id> Ids = new List<Id>();
    // definig the Case List
    private List<Case> casList = new List<Case>();
     // retriving the holiday date
    global set<Date> holidayDate= new set<Date>();
    // global to set the Organisation Id
    global set<String> organisationId = new set<String>();
    // Definig record Type for lesson
    private string lessonRecordType = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
     
     global Database.QueryLocator start(Database.BatchableContext BC) {
        // Collecting the list of all public holiday
         set<string> status = new set<String>{'Pending','Scheduled'};
         set<string> type = new set<String>{'Trial','Regular','Make-up','Ad-hoc','Busy'};
         set<string> Category = new set<string>{'Leave','Holiday','Placeholder'};
        String query = 'select Id,Package__c, Center__r.Organisation__c,Center__r.Organisation__r.Name,Teacher_Account__r.Employee_Duty_Type__c,End_Time__c,Teacher_Account__r.Name,Teacher_Account__r.Id,Duration__c,Type__c,Status__c,Booking_Date__c,Start_Time__c,Parent__c,Student__c,Parent__r.PersonContactId,Parent__r.personEmail,Center__c,Center__r.Location__c,Student__r.Name,Teacher_Account__c,Enrolment__c,Available_Make_up_Units__c,Make_up_Utilize_Bookings__c  from Booking__c where  Booking_Date__c in: holidayDate  And Type__c in:type   And Status__c in:status AND Category__c Not in:Category and RecordTypeId=:lessonTypeId and Center__r.Organisation__c in:organisationId';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Booking__c> bookingList) { 
        Savepoint sp = Database.setSavepoint();
        List<Id> Ids = new List<Id>();
        // For Cancelled Booking List
        list<Booking__c> BkgList = new list<Booking__c>();
        // For Placeholder Booking
        list<Booking__c> placeholdeBooking = new list<Booking__c>();
        // store the Makeup booking  Id with the offered Min 
        Map<Id,Integer> makeupId= new Map<Id,Integer>();
        list<Booking__c> updateMakeupList = new list<Booking__c>();
        //List<Case> casList = new List<Case>();
         
        // added by nishi: 29-Jul-2020: for manage ossia organization student we added Makeup expiry days will be 365 days.
         List<Ossia_Organisation_Settings__mdt> listOfOssia_Organisation_Settings = [SELECT Id, 
         Label,  Makeup_Expiry_Days__c,Makeup_Expiry_Days_For_Public_Holiday__c,
         Makeup_Expiry_Days_Teacher__c FROM Ossia_Organisation_Settings__mdt
         WHERE Label =:System.Label.Ossia_Organisation_Name];
         // added by nishi: 29-Jul-2020: for manage ossia organization student  we added Makeup expiry days will be 365 days.


        // New Code Start
        Map<string,List<Booking__c>> mapToHolidatDate= new Map<string,List<Booking__c>>();
        try{
            for(Booking__c bkgo:bookingList){
                if(mapToHolidatDate.containsKey(bkgo.Booking_Date__c +'/'+ bkgo.Center__r.Organisation__c)){
                    list<Booking__c> bokList= mapToHolidatDate.get(bkgo.Booking_Date__c +'/'+ bkgo.Center__r.Organisation__c);
                    bokList.add(bkgo); 
                    mapToHolidatDate.put(bkgo.Booking_Date__c +'/'+ bkgo.Center__r.Organisation__c ,bokList);     
                }else{
                    List<Booking__c> bokObj = new List<Booking__c>(); 
                    bokObj.add(bkgo);
                    mapToHolidatDate.put(bkgo.Booking_Date__c +'/'+ bkgo.Center__r.Organisation__c,bokObj);
                }
            }
            for(Public_Holiday__c holidayObj : [SELECT Id,Organisation__c,Name,Public_Holiday_Date__c,Organisation_Status__c,Execution_Date__c,Status__c FROM Public_Holiday__c where Organisation_Status__c != null and Execution_Date__c = today]){ 
                if(mapToHolidatDate.containsKey(holidayObj.Public_Holiday_Date__c + '/'+ holidayObj.Organisation__c )){
                    for(Booking__c bkgObj :mapToHolidatDate.get(holidayObj.Public_Holiday_Date__c + '/'+ holidayObj.Organisation__c)){
                        if( (holidayObj.Organisation_Status__c == 'Closed' && bkgObj.Teacher_Account__r.Employee_Duty_Type__c != null) || (holidayObj.Organisation_Status__c == 'Open' && bkgObj.Teacher_Account__r.Employee_Duty_Type__c=='Duty')){
                            if(bkgObj.Type__c != 'Busy' && bkgObj.Type__c != 'Trial'){
                                Ids.add(bkgObj.Id);
                            }
                            Booking__c bkg = new Booking__c();
                            // Updating Booking Status To Cancel except for Trial
                            if(bkgObj.Type__c !='Trial'){
                                bkgObj.Status__c='Canceled';
                                bkgObj.Public_Holiday_Status__c ='Closed';
                                bkgObj.Cancellation_Reason__c='Holidays';
                            }
                            if(bkgObj.Type__c=='Regular'){

                                 //Start: Added by nishi: 29-Jul-2020:Start: for ossia students booking will cancel then we added Makeup expiry days will be 365 days.
                                // otherwise we added 120 days for other students
                                if(String.isNotBlank(bkgObj.Center__c) && 
                                String.isNotBlank(bkgObj.Center__r.Organisation__c) && 
                                String.isNotBlank(bkgObj.Center__r.Organisation__r.Name) && 
                                bkgObj.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){ 
                                    if(listOfOssia_Organisation_Settings != null && listOfOssia_Organisation_Settings.size() > 0){
                                        bkgObj.Make_up_Expiry_Date__c=bkgObj.Booking_Date__c.addDays(Integer.valueOf((listOfOssia_Organisation_Settings[0].Makeup_Expiry_Days_For_Public_Holiday__c)));
                                    }
                                }else{
                                    bkgObj.Make_up_Expiry_Date__c=bkgObj.Booking_Date__c.addDays(120);
                                }
                                //End: Added by nishi: 29-Jul-2020:end: for ossia students booking will cancel then we added Makeup expiry days will be 365 days.
                                // otherwise we added 120 days for other students

                                string description='placeholder booking for cancelling '+ bkgObj.Student__r.Name +' booking';
                                Booking__c placIns= new Booking__c(Center__c=bkgObj.Center__c,RecordTypeId=lessonRecordType,Enrolment__c=bkgObj.Enrolment__c,Student__c=bkgObj.Student__c,Package__c=bkgObj.Package__c,
                                                                   Teacher_Account__c=bkgObj.Teacher_Account__r.Id,Type__c='Busy',Category__c='Placeholder',Remarks__c=description,Parent__c=bkgObj.Parent__c,
                                                                   Booking_Date__c=bkgObj.Booking_Date__c,Start_Time__c=bkgObj.Start_Time__c,End_Time__c=bkgObj.End_Time__c,Status__c='Scheduled');
                                placeholdeBooking.add(placIns);
                            }
                            // upating Available Make up min to sum of total given Credit for Regular and Ad-hoc  
                            if(bkgObj.Type__c=='Regular' || bkgObj.Type__c=='Ad-hoc'){
                                bkgObj.Available_Make_up_Units__c= bkgObj.Duration__c;
                                // bkgObj.Available_Make_up_Units__c= ( bkgObj.End_Time__c.hour() * 60 + bkgObj.End_Time__c.minute() )  - ( bkgObj.Start_Time__c.hour()*60 + bkgObj.Start_Time__c.minute()); 
                            }
                            if(bkgObj.Type__c =='Make-up'){
                                //system.debug('---1'+bkgObj.Type__c + '----'+bkgObj.Make_up_Utilize_Bookings__c);
                                if(bkgObj.Make_up_Utilize_Bookings__c != null){
                                    list<string> makeUpString=bkgObj.Make_up_Utilize_Bookings__c.split(';');
                                    for(String makeInstID:makeUpString){
                                        //added on 7 nov 2019 
                                        ////Adding the Make up bkg id with the offered min
                                        if(makeupId.containsKey(makeInstID.split('-')[0])){
                                            integer offrMin=makeupId.get(makeInstID.split('-')[0]) + integer.valueOf(makeInstID.split('-')[1]);
                                            makeupId.put(string.valueOf(makeInstID.split('-')[0]), offrMin);
                                        }else{
                                          makeupId.put(string.valueOf(makeInstID.split('-')[0]),integer.valueOf(makeInstID.split('-')[1]));  
                                        }
                                        // end added on 7 nov 2019
                                    } 
                                }
                            } 
                            BkgList.add(bkgObj);
                        }
                        
                    }
                }
                
            }
            // New Code End
            for(Booking__c book:[select Id,Make_up_Utilize_Bookings__c,Available_Make_up_Units__c from Booking__c where Id in :makeupId.keySet()]){
                if(makeupId.containsKey(book.Id)){
                    book.Available_Make_up_Units__c=makeupId.get(book.Id);                    
                }
                
                updateMakeupList.add(book);                
            }
            system.debug('===>updateMakeupList.size()'+updateMakeupList.size());
            // Inserting Makeup Booking list
            if(updateMakeupList.size()>0){
                update updateMakeupList;
            }
            system.debug('===>placeholdeBooking.size()'+placeholdeBooking.size());
            // creating placeholder booking for the Regular  booking
            if(placeholdeBooking.size()>0){
                insert placeholdeBooking;
            }
            // calling future method to send mail on case to respective parent
            system.debug('BkgList'+BkgList.size());
            if(BkgList.size()>0){
                update BkgList;
            }
        }catch(Exception e){
            system.debug(e.getLineNumber()+'>>>'+e.getMessage());
            Database.rollback(sp);
        } 
        string templateId ='';
        string templateListOpenId ='';
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        list<EmailTemplate> templateList= new list<EmailTemplate>();
        map<string,EmailTemplate> templatemap= new map<string,EmailTemplate>();
        // template when teacher is on Holiday
        /*Commented by nishi: 12-Oct-2020: for send email according to organisation
        templateList = [Select Id from EmailTemplate where name = 'Public Holiday Closed Cancellation Execution' limit 1];
         if(templateList[0].Id != null){
            templateId = templateList[0].Id;  
        }*/
        //add by nishi: 12-Oct-2020:Start for send email according to organisation
        for(EmailTemplate objEmailTemplate :[Select Id,name from EmailTemplate 
                                            where name = 'Public Holiday Closed Cancellation Execution' 
                                            or name = 'Ossia_Public Holiday Closed Cancellation Execution' 
                                            ]){
                                                templatemap.put(objEmailTemplate.name,objEmailTemplate);
                                            }
       //add by nishi: 12-Oct-2020:end: for send email according to organisation
       /*Commented by nishi: 12-Oct-2020: for send email according to organisation list<EmailTemplate> templateListOpen= new list<EmailTemplate>();
        // template when teacher is on Holiday
        templateListOpen = [Select Id from EmailTemplate where name = 'Public Holiday Open' limit 1];
        if(templateListOpen[0].Id != null){
            templateListOpenId = templateListOpen[0].Id;  
        }*/
        //add by nishi: 12-Oct-2020:Start for send email according to organisation
        map<string,EmailTemplate> templateMapOpen= new map<string,EmailTemplate>();
        for(EmailTemplate objEmailTemplate :[Select Id,name from EmailTemplate 
        where name = 'Public Holiday Open' 
        or name = 'Ossia_Public Holiday Open' 
        ]){
            templateMapOpen.put(objEmailTemplate.name,objEmailTemplate);
        }   
        //add by nishi: 12-Oct-2020:end: for send email according to organisation 
        if(Ids.size()>0){
            for(Booking__c bkgiList:[Select Id,Public_Holiday_Status__c,Parent__r.PersonContactId,Center__r.Location__c,Parent__r.PersonEmail,
                                    Booking_Date__c,Teacher_Account__c ,Center__r.Organisation__r.name
                                    from Booking__c where Id in:Ids and Status__c='Canceled' and Cancellation_Reason__c='Holidays']){
                //system.debug('----'+bkgiList.Id);
                if(templatemap!= null && templatemap.size() > 0 && String.isNotBlank(bkgiList.Center__r.Organisation__r.Name) && bkgiList.Parent__r.PersonContactId != null && bkgiList.Parent__r.PersonEmail != null && bkgiList.Public_Holiday_Status__c=='Closed'){
                    //system.debug('=bkgList.Id' + bkgiList.Id );
                    //add by nishi: 12-Oct-2020:Start for send email according to organisation
                    if(bkgiList.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                        if(templatemap.containsKey('Ossia_Public Holiday Closed Cancellation Execution')){
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Ossia_Public Holiday Closed Cancellation Execution').id, bkgiList.Parent__r.PersonContactId, bkgiList.Id, bkgiList.Center__r.Location__c);
                            emailList.add(mail);
                        }
                    }else{
                        if(templatemap.containsKey('Public Holiday Closed Cancellation Execution')){
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Public Holiday Closed Cancellation Execution').id, bkgiList.Parent__r.PersonContactId, bkgiList.Id, bkgiList.Center__r.Location__c);
                            emailList.add(mail);
                        }
                    }
                    //add by nishi: 12-Oct-2020:end: for send email according to organisation
                        /* Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, bkgiList.Parent__r.PersonContactId, bkgiList.Id, bkgiList.Center__r.Location__c);
                    emailList.add(mail);*/    
                }else if(templateMapOpen!= null && templateMapOpen.size() > 0 && String.isNotBlank(bkgiList.Center__r.Organisation__r.Name)  /*String.isNotBlank(templateListOpenId)*/ && bkgiList.Parent__r.PersonContactId != null && bkgiList.Parent__r.PersonEmail != null && bkgiList.Public_Holiday_Status__c=='Open'){
                    //add by nishi: 12-Oct-2020:Start for send email according to organisation
                    if(bkgiList.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                        if(templatemap.containsKey('Ossia_Public Holiday Open')){
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Ossia_Public Holiday Open').id, bkgiList.Parent__r.PersonContactId, bkgiList.Id, bkgiList.Center__r.Location__c);
                            emailList.add(mail);
                        }
                    }else{
                        if(templatemap.containsKey('Public Holiday Open')){
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Public Holiday Open').id, bkgiList.Parent__r.PersonContactId, bkgiList.Id, bkgiList.Center__r.Location__c);
                            emailList.add(mail);
                        }
                    }
                    //add by nishi: 12-Oct-2020:end: for send email according to organisation
                    //system.debug('=bkgList.Id' + bkgiList.Id );
                    /*Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateListOpenId, bkgiList.Parent__r.PersonContactId, bkgiList.Id, bkgiList.Center__r.Location__c);
                    emailList.add(mail);*/
                }
            }
            
            system.debug('--->'+emailList);
            if(!test.isRunningTest())
                for(Messaging.SendEmailResult results :Messaging.sendEmail(emailList,false)){
                    if(!results.isSuccess())
                        system.debug(results.getErrors());
                } 
            
            //PublicHolidayMail.sendMail(Ids,'Teacher Leave');  
        }
        
        
    }   
    
    global void finish(Database.BatchableContext BC) {
         Savepoint sp = Database.setSavepoint();
        try{
            // List defined to store fifth Lesson Booking for required Holiday Date
            Map<string,List<Fifth_Lesson__c>> mapToFifthHolidatDate= new Map<string,List<Fifth_Lesson__c>>();
            
            // here Creating placeholder for the Fifth Lesson Booking as per the status of CLosed and Open
            List<Booking__c> fifthPlaceholderBooking = new List<Booking__c>();
            List<Fifth_Lesson__c> fifthPlaceholderList = new List<Fifth_Lesson__c>();
            list<Fifth_Lesson__c> FifthLessonList= new list<Fifth_Lesson__c>([Select Id,Center__r.Organisation__c,Teacher_Account__r.Employee_Duty_Type__c,Student__r.Name,Parent__r.PersonContactId,End_Time__c,Center__c,Start_Time__c,Remarks__c,Center__r.Location__c,Parent__r.PersonEmail,Booking_Date__c,Teacher_Account__c from Fifth_Lesson__c where IsActive__c =true and Booking_Date__c in :holidayDate and Center__r.Organisation__c in:organisationId]);
            for(Fifth_Lesson__c fifthObj:FifthLessonList){
                if(mapToFifthHolidatDate.containsKey(fifthObj.Booking_Date__c +'/'+ fifthObj.Center__r.Organisation__c)){
                    list<Fifth_Lesson__c> fifList= mapToFifthHolidatDate.get(fifthObj.Booking_Date__c  +'/'+ fifthObj.Center__r.Organisation__c);
                    fifList.add(fifthObj); 
                    mapToFifthHolidatDate.put(fifthObj.Booking_Date__c +'/'+ fifthObj.Center__r.Organisation__c,fifList);     
                }else{
                    List<Fifth_Lesson__c> fifObj = new List<Fifth_Lesson__c>(); 
                    fifObj.add(fifthObj);
                    mapToFifthHolidatDate.put(fifthObj.Booking_Date__c +'/'+ fifthObj.Center__r.Organisation__c,fifObj);
                }
            }
            for(Public_Holiday__c holidayObj : [SELECT Id,Organisation__c,Name,Public_Holiday_Date__c,Organisation_Status__c,Execution_Date__c,Status__c FROM Public_Holiday__c where Organisation_Status__c != null and Execution_Date__c =today]){ 
                if(mapToFifthHolidatDate.containsKey(holidayObj.Public_Holiday_Date__c +'/'+ holidayObj.Organisation__c)){
                    for(Fifth_Lesson__c fifthObj :mapToFifthHolidatDate.get(holidayObj.Public_Holiday_Date__c + +'/'+ holidayObj.Organisation__c)){
                        if( (holidayObj.Organisation_Status__c == 'Closed' && fifthObj.Teacher_Account__r.Employee_Duty_Type__c != null) || (holidayObj.Organisation_Status__c == 'Open' && fifthObj.Teacher_Account__r.Employee_Duty_Type__c=='Duty')){
                            
                            Booking__c placIns= new Booking__c(Center__c=fifthObj.Center__c,RecordTypeId=lessonRecordType,
                                                               Teacher_Account__c=fifthObj.Teacher_Account__c,Type__c='Busy',Category__c='Placeholder',Remarks__c='Placeholder booking for Cancelling 5th lesson of '+ fifthObj.Student__r.Name +'',
                                                               Booking_Date__c=fifthObj.Booking_Date__c,Start_Time__c=fifthObj.Start_Time__c,End_Time__c=fifthObj.End_Time__c,Status__c='Scheduled'); 
                            fifthPlaceholderBooking.add(placIns);
                            Fifth_Lesson__c fObj = new Fifth_Lesson__c();
                            fObj.Id=fifthObj.Id;
                            fObj.Booking__r=placIns;
                            fObj.Remarks__c='Placeholder booking for 5th lesson of '+ fifthObj.Student__r.Name +'';
                            fObj.IsActive__c=false;
                            fifthPlaceholderList.add(fObj);   
                        }
                    }
                }
                
                
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
            // this code update the public holiday with execution for completed status
            List<Public_Holiday__c> pbHolObjList = new List<Public_Holiday__c>();
            for(Public_Holiday__c holidayObj : [SELECT Id,Name,Public_Holiday_Date__c,Organisation_Status__c,Execution_Date__c,Status__c FROM Public_Holiday__c where Organisation_Status__c != null and Execution_Date__c = today and Status__c='Pending for execution']){ 
                Public_Holiday__c pbHolObj = new Public_Holiday__c();
                pbHolObj.Id=holidayObj.Id; 
                pbHolObj.Status__c='Execution completed';
                pbHolObjList.add(pbHolObj);
            }
            if(pbHolObjList.size()>0){
                update pbHolObjList;
            }
        }catch(Exception e){
            system.debug(e.getLineNumber()+'>>>'+e.getMessage());
            Database.rollback(sp);
        } 
        system.debug('--->'+'Finish');
  }

}