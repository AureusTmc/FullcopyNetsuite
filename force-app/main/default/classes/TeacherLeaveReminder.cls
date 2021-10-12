global class TeacherLeaveReminder implements Database.Batchable<sObject>{
    private Date  reqDate=system.today().addDays(7);
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'Select Id,Leave_Start_Date__c,Leave_End_Date__c,Employee__c From Leave_Request__c where Leave_Start_Date__c<=:reqDate AND Leave_End_Date__c >=:reqDate';
        return Database.getQueryLocator(query); 
      
    }
    global void execute (Database.BatchableContext bc ,List<sObject> recordsList){
        list<Booking__c> BookingList = new list<Booking__c>();
        set<String> cancellationReason = new set<String>{'Teacher MC','Teacher Leave'};
        system.debug('----'+recordsList);
        set<Date> leaveStartDate = new set<Date>();
        set<Date> leaveEndDate = new set<Date>();
        list<Leave_Request__c> leaveReqList =(list<Leave_Request__c>)recordsList;
        // store teacher Id with start  date  and end date
        Map<ID,Date> mapToTeacher = new  Map<Id,Date>();
        //list<EmailTemplate> templateList= new list<EmailTemplate>();
        for(Leave_Request__c leavReqObj:leaveReqList){
            mapToTeacher.put(leavReqObj.Employee__c,reqDate);
            leaveStartDate.add(reqDate);
        }
        string templateId='';
        //added by nishi: 12-Oct-2020:start: for send email according to organisation
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        map<string,EmailTemplate> templatemap= new map<string,EmailTemplate>();
        for(EmailTemplate objEmailTemplate :[Select Id,name from EmailTemplate 
									where name = 'Teacher Leave Reminder' 
									or name = 'Ossia_Teacher Leave Reminder' 
									]){
										templatemap.put(objEmailTemplate.name,objEmailTemplate);
									}
        /*//commented by nishi: 12-Oct-2020:start: for send email according to organisation
        templateList = [Select Id from EmailTemplate where name = 'Teacher Leave Reminder' limit 1];
        if(templateList[0].Id != null){
            templateId = templateList[0].Id;  
        }*/
        //added by nishi: 12-Oct-2020:start: for send email according to organisation
        BookingList=[Select Id,Name,Teacher_Account__r.Name,Parent__r.PersonContactId,Center__r.Location__c,Center__r.Organisation__r.Name ,Parent__r.PersonEmail,Booking_Date__c,Teacher_Account__c from Booking__c where Teacher_Account__c =:mapToTeacher.keySet() and Status__c='Canceled' and Cancellation_Reason__c in:cancellationReason and  Booking_Date__c =: leaveStartDate];
        //system.debug('===---'+BookingList);
        for(Booking__c bkgList:BookingList){
            if(bkgList.Booking_Date__c == mapToTeacher.get(bkgList.Teacher_Account__c) && mapToTeacher.containsKey(bkgList.Teacher_Account__c) ){
                if(templatemap != null && templatemap.size() > 0 && bkgList.Parent__r.PersonContactId != null && bkgList.Parent__r.PersonEmail != null){
                   //added by nishi: 12-Oct-2020:start: for send email according to organisation
                    if(string.isNotBlank(bkgList.Center__r.Organisation__r.Name)&&  bkgList.Center__r.Organisation__r.Name.equalsIgnoreCase(System.Label.Ossia_Organisation_Name)){
                        if(templatemap.containsKey('Ossia_Teacher Leave Reminder')){
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Ossia_Teacher Leave Reminder').id, bkgList.Parent__r.PersonContactId, bkgList.Id, bkgList.Center__r.Location__c);
                            emailList.add(mail); 
                        }
                    }else{
                        if(templatemap.containsKey('Teacher Leave Reminder')){
                            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templatemap.get('Teacher Leave Reminder').id, bkgList.Parent__r.PersonContactId, bkgList.Id, bkgList.Center__r.Location__c);
                            emailList.add(mail);
                        }
                    }

                   /* Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, bkgList.Parent__r.PersonContactId, bkgList.Id, bkgList.Center__r.Location__c);
                    emailList.add(mail);*/
                    //added by nishi: 12-Oct-2020:start: for send email according to organisation
                }
            } 
        }
        
        if(emailList.size()>0){
            for(Messaging.SendEmailResult results :Messaging.sendEmail(emailList,false)){
                if(!results.isSuccess())
                    system.debug(results.getErrors());
            }  
            //Messaging.sendEmail(emailList); 
        }
        
    }
    global void finish(Database.BatchableContext bc){
        System.debug('----Finish');
    }
}