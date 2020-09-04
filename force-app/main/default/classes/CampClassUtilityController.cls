/*
Name        :    AureusUtility
Date        :    11th Feb 2020 
Description :    This class is used for common methods to use in camp class controlllers.
Author      :   Jatin
*/
public  without sharing class CampClassUtilityController {
   

    // get camp list with related camp packages, days according to parameter 
    public static List<Camp__c> getCampList(string centerId ,string campId,String packageId,Set<string> campDates){
        List<Camp__c> listOfCamp = new List<Camp__c>();
        system.debug('centerId'+centerId);
        system.debug('campId'+campId);
        system.debug('packageId'+packageId);
        system.debug('campDates'+campDates);
        string campListString =  'Select Name,Centre__c,Centre__r.Name,Early_Bird_Discount__c,Early_Bird_End_Date__c,Early_Bird_Start_Date__c,Maximum_Age__c, Camp_Description__c,Minimum_Age__c ,Centre__r.Country__r.name, Centre__r.Country__r.Tax_Rate__c,';
        campListString += 'Centre__r.Country__r.Stripe_Base_Url__c,Centre__r.Country__r.Stripe_Publishable_Key__c,Centre__r.Country__r.Stripe_Secret_Key__c,Centre__r.Country__r.Currency_Code__c,Centre__r.Country__r.Folder__c,';
            // get camp package List 
            campListString += ' (SELECT Id, Name, Package__c,Package__r.Name,Package__r.Instrument__c,Package__r.package_Fee__c,Package__r.Package_Fee_with_GST__c, Active__c,No_of_days__c FROM Camp_Available_Packages__r Where Active__c= true';
            if(string.isNotBlank(packageId)){
                campListString += ' AND id=:packageId';
            }
            campListString+= ' Order by No_of_days__c DESC),';
            campListString += ' (SELECT Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c, Status__c, Camp_Name__c, Id, Name FROM Camp_Days__r';
            campListString += ' Where Status__c =\'Active\'';
            if(campDates != null && campDates.size() > 0){
                campListString += ' AND id in :campDates';
            }
            campListString +=' Order by Dates_Of_The_Camp__c';
            campListString+= ')';
            
            campListString += ' From Camp__c WHERE Status__c =\'Active\'' ;
            if(string.isnotBlank(campId)){
                campListString += ' AND id=:campId';
            }
            if(string.isnotBlank(centerId)){
                campListString += ' AND Centre__c =:centerId';
            }
            system.debug('campListString'+campListString);
        if(string.isNotBlank(campListString)){
            listOfCamp  = Database.query(campListString);
        }
        system.debug('listOfCamp'+listOfCamp);
        return listOfCamp;
    }
    
    // get camp list with related camp packages, days according to parameter 
    public static List<Camp__c> getCampList(string centerId ,string campId,Set<String> packageIds,Set<string> campDates){
        List<Camp__c> listOfCamp = new List<Camp__c>();
        string campListString =  'Select Name,Centre__r.Name,Early_Bird_Discount__c,Early_Bird_End_Date__c,Early_Bird_Start_Date__c,Maximum_Age__c, Camp_Description__c,Minimum_Age__c ,Centre__r.Country__r.name, Centre__r.Country__r.Tax_Rate__c,';
        campListString += 'Centre__r.Country__r.Stripe_Base_Url__c,Centre__r.Country__r.Stripe_Publishable_Key__c,Centre__r.Country__r.Stripe_Secret_Key__c,Centre__r.Country__r.Currency_Code__c,Centre__r.Country__r.Folder__c,';
            // get camp package List 
            campListString += ' (SELECT Id, Name, Package__c,Package__r.id,Package__r.Name,Package__r.Instrument__c,Package__r.package_Fee__c, Active__c,No_of_days__c FROM Camp_Available_Packages__r Where Active__c= true';
            if(packageIds != null && packageIds.size() > 0){
                campListString += ' AND id in:packageIds';
            }
            campListString+= ' Order by No_of_days__c DESC),';
            campListString += ' (SELECT Camp_Start_Time__c, Camp_End_Time__c, Dates_Of_The_Camp__c, No_of_Students_Enrolled__c, Status__c, Camp_Name__c, Id, Name FROM Camp_Days__r';
            campListString += ' Where Status__c =\'Active\'';
            if(campDates != null && campDates.size() > 0){
                campListString += ' AND id in :campDates';
            }
            campListString +=' Order by Dates_Of_The_Camp__c';
            campListString+= ')';
            
            campListString += ' From Camp__c WHERE Status__c =\'Active\'' ;
            if(string.isnotBlank(campId)){
                campListString += ' AND id=:campId';
            }
            if(string.isnotBlank(centerId)){
                campListString += ' AND Centre__c =:centerId';
            }
            system.debug('campListString'+campListString);
        if(string.isNotBlank(campListString)){
            listOfCamp  = Database.query(campListString);
        }
        system.debug('listOfCamp'+listOfCamp);
        return listOfCamp;
    }
    

    // get picklist values according to object and field name
    public static List<SelectOption> getPicklistValues(String ObjectApi_name,String Field_name){ 
        List<SelectOption> lstPickvals = new List<SelectOption>();        
        lstPickvals.add(new SelectOption('', '--None--'));
        
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(ObjectApi_name);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map    = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values   = field_map.get(Field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        
        for(Schema.PicklistEntry a : pick_list_values){ //for all values in the picklist list
            lstPickvals.add(new SelectOption(a.getValue(), a.getLabel()));
        }
        
        return lstPickvals;
    }
   

    // 12-Feb-2020: jatin: get teacher and teacher working hours 
    public static map<string,list<Teacher_Working_Hour__c>> getTeacherWorkingHoursList(Set<string> campTeacherIds,Set<string> campDays,string centerId){
        map<string,list<Teacher_Working_Hour__c>> mapOfTeacherWorkingHours = new map<string,list<Teacher_Working_Hour__c>>();
        string teacherWorkingStatus = ConstantsClass.teacherWorkingStatus;
        string query = 'SELECT Id,Name,Teacher_Name__c,Center_Name__c ,Teacher_Name__r.Name, Teacher_Name__r.FirstName, Teacher_Name__r.LastName,Teacher_Name__r.Teacher_Bio__c,Working_Day__c,Start_Time__c,End_Time__c,Active__c';
        query += ' FROM Teacher_Working_Hour__c WHERE Active__c = true AND Break_Time__c = False AND Start_Time__c != null AND End_Time__c != null AND Teacher_Name__r.Status__c =: teacherWorkingStatus';
        if(campTeacherIds != null && campTeacherIds.size() > 0 ){
            query += ' And Teacher_Name__c In: campTeacherIds ';
        }
        if(campDays != null && campDays.size() > 0 ){
            query += ' And Working_Day__c In: campDays ';
        }
        if(string.isNotBlank(centerId) ){
            query += ' AND Center_Name__c =: centerId  ';
        }

        for(Teacher_Working_Hour__c techWorkSchObj  : Database.query(query)){
            list<Teacher_Working_Hour__c> techWorkSchList = new list<Teacher_Working_Hour__c>();
            if(mapOfTeacherWorkingHours.containsKey(techWorkSchObj.Teacher_Name__c)){
                techWorkSchList = mapOfTeacherWorkingHours.get(techWorkSchObj.Teacher_Name__c);
            } 
            techWorkSchList.add(techWorkSchObj);
            mapOfTeacherWorkingHours.put(techWorkSchObj.Teacher_Name__c,techWorkSchList);
        }
        system.debug('mapOfTeacherWorkingHours'+mapOfTeacherWorkingHours);
        if(mapOfTeacherWorkingHours != null && mapOfTeacherWorkingHours.size() > 0){
            return mapOfTeacherWorkingHours;
        }
        return new map<string,list<Teacher_Working_Hour__c>>();
    }

    
    //added by jatin: 25-Feb-2020: for get multiple teachers on one camp days 
    public static  map<string,List<Camp_Day_Teachers__c>> getCampDaysTeachers(set<id> campDaysIds){
        map<string,List<Camp_Day_Teachers__c>> mapOfCampDayTeachers = new  map<string,List<Camp_Day_Teachers__c>>();
        List<Camp_Day_Teachers__c> listOfCampteacher = new List<Camp_Day_Teachers__c>();
        if(campDaysIds != null && campDaysIds.size() > 0){
            For(Camp_Day_Teachers__c objCampteacher : [Select id,Camp_Day__c,Camp_Teacher__c 
                                                        from Camp_Day_Teachers__c
                                                        Where Camp_Day__c In:campDaysIds
                                                        ANd Camp_Teacher__c != null
                                                        AND Status__c =: ConstantsClass.campTeacherActiveStatus]) {
                                                    listOfCampteacher = new List<Camp_Day_Teachers__c>(); 
                if(mapOfCampDayTeachers.containsKey(objCampteacher.Camp_Day__c)){
                    listOfCampteacher = mapOfCampDayTeachers.get(objCampteacher.Camp_Day__c);
                }     
                listOfCampteacher.add(objCampteacher);     
                mapOfCampDayTeachers.put(objCampteacher.Camp_Day__c,listOfCampteacher);                         
            }
        }
        return mapOfCampDayTeachers;
    }

    // 12-Feb-2020: jatin:create regular type camp booking and  return booking 
    public static Booking__c createCampBooking(string studentId,string enrolmentId,date startDate,time endtime,time starttime,string centerId,string packageId,
                                            string campId,string campDaysId,string teacherId){
        String campLessonRecId =  Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.bookingRecordsTypeCampLesson).getRecordTypeId();    
            
        Booking__c objBook = new Booking__c();
        objBook.Type__c   = ConstantsClass.typeRegular;
        objBook.Status__c = ConstantsClass.statusScheduled;
        objBook.RecordTypeId = campLessonRecId;
        if(string.isNotBlank(studentId))
        objBook.Student__c = studentId;
        if(string.isNotBlank(enrolmentId))
        objBook.Enrolment__c = enrolmentId;
        if(string.isNotBlank(teacherId))
        objBook.Teacher_Account__c = teacherId;
        if(string.isNotBlank(campId))
        objBook.Camp_Id__c = campId;
        if(string.isNotBlank(campDaysId))
        objBook.Camp_Days__c = campDaysId; 
        if(string.isNotBlank(packageId))
        objBook.Package__c = packageId; 
        if(string.isNotBlank(centerId))
        objBook.Center__c = centerId; 
        if(starttime != null)
        objBook.Start_Time__c = starttime;   
        if(endtime != null)
        objBook.End_Time__c = endtime;
        if(startDate != null)
        objBook.Booking_Date__c = startDate;                                    
        return objBook;
    }

     //camp class confirmation Email to the customer with the invoice PDF
     public static void sendEmailWithInvoiceAttachment(Map<string,map<String ,Blob>> mapOfEnrolmentAttachment,string templateName){
        system.debug('mapOfEnrolmentAttachment'+mapOfEnrolmentAttachment);   
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<String,OrgWideEmailAddress> mapOfOrgWide = new Map<String,OrgWideEmailAddress>(); 
        for(OrgWideEmailAddress objAddress : [SELECT Address, DisplayName, Id FROM OrgWideEmailAddress]){
            mapOfOrgWide.put(objAddress.DisplayName,objAddress);
        }
        map<String ,Blob> mapOfAttachment = new  map<String ,Blob> ();
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName =:templateName LIMIT 1];
        List<Enrolment__c> listOfEnrolment =[select id ,Parent__r.PersonContactId,Center__r.Location__c from Enrolment__c where id in: mapOfEnrolmentAttachment.keySet()];
        system.debug('listOfEnrolment'+listOfEnrolment);   
        system.debug('template'+template);   
        for(Enrolment__c objEnrolment : listOfEnrolment){   
            String location = objEnrolment.Center__r.Location__c;
            system.debug('location'+location);  
            Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(template.id,objEnrolment.Parent__r.personContactId,objEnrolment.Id,location);
            system.debug('objEnrolment.Parent__r.personContactId'+objEnrolment.Parent__r.personContactId);   
            List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
            mapOfAttachment = mapOfEnrolmentAttachment.get(objEnrolment.id); 
            system.debug('mapOfAttachment'+mapOfAttachment);   
            for(string attachmentName : mapOfAttachment.keySet()){
                Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                efa.setFileName(attachmentName);
                efa.setBody(mapOfAttachment.get(attachmentName));
                fileAttachments.add(efa);
                system.debug('attachmentName'+attachmentName);   
            }
            //mail.setFileAttachments(fileAttachments);
            emailList.add(mail);
        }
        system.debug('emailList'+emailList);   
        Messaging.SendEmailResult[] results = Messaging.sendEmail(emailList,false);
        if (results[0].success) {
            system.debug('sucess');
        } else {
            system.debug('error:'+results[0].errors[0].message);
        }
    }

    
}