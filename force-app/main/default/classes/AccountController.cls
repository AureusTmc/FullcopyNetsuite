public class AccountController {
    
    /*
    Name        :        AccountController
    Author      :        Ravi Gupta
    Description :        It is the  class of HomePageComponent.
    */
    Private static String Centre = ConstantsClass.centerRecTypeName;
    private static String Trial = ConstantsClass.trialStatus;
    private static string OpenStat =constantsClass.OpenStatus;
    private static string salesEnquiryRecordType=ConstantsClass.caseSalesEnqRecTypeName;
    private static string serviceEnquiryRecordType=ConstantsClass.caseServiceEnqRecTypeName;
    private static string InstrumentRentalEnquiryRecordType=ConstantsClass.InstrumentRentalEnquiryRecordType;
    @AuraEnabled
    public static  List<Account> fetchAccount() {
        return [Select Id,Name from Account Where RecordType.Name=:Centre ORDER BY Name DESC];
    }
    @AuraEnabled
    public static  List<Task> getTaskDesc(string tskId) {
        return [select id,Status,Description from Task where id=:tskId];
    }
    
    @AuraEnabled
    public static list<TaskWrapperClass> findTask(String searchKey,string filter) {
        string userQuery;
        string query='SELECT id,WhatId,Subject,ActivityDate,Who.Name,Who.Id,What.Name,Priority,Owner.name,Status FROM Task WHERE Status =:OpenStat ';
        list<TaskWrapperClass> taskList = new list<TaskWrapperClass>();
        set<id> ids = new set<id>();
        if(filter =='All'){
            string currentId=UserInfo.getUserId();
            userQuery='select Id,User_Name__c from Centre_Users__c where Centre_Name__c=:searchKey and User_Name__c !=:currentId';
            list<Centre_Users__c> CentreUsersList = Database.query(userQuery);
            for(Centre_Users__c centerIds:CentreUsersList){
            if(centerIds.User_Name__c <> null){
                ids.add(centerIds.User_Name__c);
            }
        }
            query +='And OwnerId in:ids And ActivityDate <= Today ORDER BY ActivityDate DESC';
        }else if(filter =='My Tasks'){
            ids.add(UserInfo.getUserId());
            query +='And OwnerId in:ids And ActivityDate <= Today ORDER BY ActivityDate DESC';
        }else{
            ids.add(UserInfo.getUserId());
            query +='And OwnerId in:ids And ActivityDate > Today ORDER BY ActivityDate DESC';
        }
        list<Task> tskList =Database.query(query);
        for(Task Tsk: tskList){
            TaskWrapperClass tskClass = new TaskWrapperClass();
            tskClass.id=Tsk.Id;
            tskClass.Subject=Tsk.Subject;
            tskClass.ActivityDate=tsk.ActivityDate;
            tskClass.Owner=tsk.Owner.name;
            if (tsk.ActivityDate < Date.today()){
               tskClass.overDue='Red';
            }
            if (tsk.Priority =='High'){
               tskClass.imageClass='Priority';
            }
            tskClass.Name=tsk.Who.Name;
            tskClass.WhoId=tsk.Who.Id;
            tskClass.Center=tsk.what.Name;
            tskClass.What=tsk.WhatId;
            tskClass.Priority=tsk.Priority;
            taskList.add(tskClass);
        }
        return taskList;
    }
    public class TaskWrapperClass{
        @AuraEnabled
        Id id{get;set;}
        @AuraEnabled
        string Subject{get;set;}
        @AuraEnabled
        Date ActivityDate{get;set;}
        @AuraEnabled
        string Name{get;set;}
        @AuraEnabled
        string Center{get;set;}
        @AuraEnabled
        string Priority{get;set;}
        @AuraEnabled
        string Owner{get;set;}
        @AuraEnabled
        string Status{get;set;}
        @AuraEnabled
        string overDue{get;set;}
        @AuraEnabled
        string imageClass{get;set;}
        @AuraEnabled
        string WhoId{get;set;}
        @AuraEnabled
        string What{get;set;}
    }
     @AuraEnabled
    public static void updatePendingEnrolmentStage(string actVal,string bkgId){
          list<Booking__c> updateBookingData = new List<Booking__c>();
          list<Enrolment__c> enrolmentList = new list<Enrolment__c>();
        
        list<Booking__c> bookingData = new List<Booking__c>([SELECT Id,Status__c,Booking_Date__c FROM Booking__c WHERE Enrolment__c=:bkgId  AND Type__c =:Trial]);
        
        if(actVal =='Confirm'){
            for(Enrolment__c enrolData:[SELECT Id,Stage__c FROM Enrolment__c WHERE id=: bkgId AND Type__c =:Trial]){
                enrolData.Stage__c='Booked';
                enrolmentList.add(enrolData);                              
            }
             for(Booking__c bkng : bookingData){
                bkng.Status__c='Scheduled';
                updateBookingData.add(bkng);
            }
            
        }else{
            for(Enrolment__c enrolData:[SELECT Id,Stage__c FROM Enrolment__c WHERE id=: bkgId   AND Type__c =:Trial]){
                enrolData.Stage__c='Cancelled';
                enrolmentList.add(enrolData);                              
            }
            for(Booking__c bkng : bookingData){
                bkng.Status__c='Rejected';
                updateBookingData.add(bkng);
            }
        }
        if(updateBookingData.size()>0){
            update bookingData;   
        }
        if(enrolmentList.size()>0){
            update enrolmentList;   
        }
        
    }
    
    
     @AuraEnabled
    public static void updateTaskStage(string tskId,string descriptionTask){
        list<Task> taskList = new list<Task>();
        for(Task tsk:[select id,Status,Description from Task where id=:tskId]){
            if(descriptionTask !=null){
                tsk.Description=descriptionTask;
            }
            tsk.Status='Completed';
            taskList.add(tsk);
        }
        if(taskList.size()>0){
            update taskList;
        }
        
    }
    @AuraEnabled
    public static list<Case> findPendingEnrolmentCase(string searchKey){
         Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get(salesEnquiryRecordType).getRecordTypeId();
        list<Case> caseList =[SELECT Id,RecordTypeId,Enrolment__r.Id,Enrolment__r.Type__c,Enrolment__r.Instrument__c,Enrolment__r.Student__r.Name,Enrolment__r.Parent__r.Name,Enrolment__r.Center__r.Name,Enrolment__r.Teacher__r.Name,Enrolment__r.Stage__c,Enrolment__r.Trial_Start_Time__c,Enrolment__r.Trial_Date__c   FROM Case where Id=:searchKey AND RecordTypeId=:recorId AND Enrolment__r.Type__c =:Trial AND (Enrolment__r.Stage__c='Requested' OR Enrolment__r.Stage__c='Booked' OR Enrolment__r.Stage__c='Cancelled')];
        return caseList;
     
    }
     @AuraEnabled
        public static List<Enrolment__c> findRegularBooking(String searchKey,string dateFilter) {
            if(dateFilter =='Last 7 Days' ){
                dateFilter='LAST_N_DAYS:7';
            }
            else if(dateFilter =='Last 30 Days'){
                dateFilter='LAST_N_DAYS:30';
            }else{
             	dateFilter='LAST_N_DAYS:0';   
            }
            set<string> enrolmenttypes = new set<string>{'Regular','Group'};
            string str='SELECT Id,Student__r.Name,Parent__r.Name,Enrolment_Created_Date__c,Teacher__r.Name,Package__r.Name,Lessons_Start_Date__c,Lesson_Start_time__c FROM Enrolment__c WHERE  Center__c =:searchKey  AND DAY_ONLY(Enrolment_Created_Date__c)='+ dateFilter +' And Type__c IN: enrolmenttypes AND Stage__c=\'Enrolled\' ORDER BY Lessons_Start_Date__c DESC';
            
            list<Enrolment__c> regEnr = Database.query(str);
            if(regEnr.size() >0){
                return regEnr;   
            }
            return regEnr;
        }
    
    @AuraEnabled
    public static List<Booking__c> findMakeUpBooking(String searchKey) {
        
           string  dateFilter='LAST_N_DAYS:7';
        
        /* else if(dateFilter =='Last 30 Days'){
            dateFilter='LAST_N_DAYS:30';
        }else{
            dateFilter='LAST_N_DAYS:0';   
        }*/
       	String customLabelValue = Label.aureusacademy_Site_GuestUser;
        set<string> Status = new set<string>{'Completed','Pending','Scheduled'};
        string str='SELECT Id,Name,Student__r.Name,Parent__r.Name,Parent__c,CreatedDate,Teacher_Account__r.Name,Package__r.Name,Booking_Date__c,Start_Time__c,Duration__c FROM Booking__c WHERE  Center__c =:searchKey  AND CreatedDate='+ dateFilter +' And Type__c= \'Make-up\' and Status__c In:Status AND  CreatedBy.Name =:customLabelValue ORDER BY CreatedDate DESC' ;
        system.debug('str'+str);
        list<Booking__c> makBookList = Database.query(str);
        system.debug('makBookList'+makBookList);
        if(makBookList.size() >0){
            return makBookList;   
        }
        return makBookList;
    }
    @AuraEnabled
    public static list<User> findUserprofile(){
        string custSystemAdmin = Label.custome_Aureus_Admin;
        return [select Id,Profile.Name  from User where  Id=:UserInfo.getUserId()];
    }
    @AuraEnabled
        public static List<Booking__c> findStudioBooking(String searchKey) {
           
            string dateFilter='LAST_N_DAYS:7';   
            
            string str='SELECT Id,Name,Student__r.Name,Resource__r.Name,Start_Time__c,Booking_Date__c FROM Booking__c WHERE  Center__c =:searchKey  AND CreatedDate ='+ dateFilter +' And Type__c = \'Studio\' ORDER BY CreatedDate DESC';
            
            list<Booking__c> StudioEnrList = Database.query(str);
            if(StudioEnrList.size() >0){
                return StudioEnrList;   
            }
            return StudioEnrList;
        }
    
    @AuraEnabled
        public static List<App_Feeds__c> getAppFeedsHomePage(String searchKey) {
           system.debug('new func called');
            string str='SELECT Id,Name,Booking_Date__c,Booking_Time__c,Instrument__c,Parent__r.Name,Student__r.Name,Teacher__r.Name,Type__c FROM App_Feeds__c WHERE  Center__c =:searchKey  AND CreatedDate =TODAY ORDER BY CreatedDate DESC';
            
            list<App_Feeds__c> appfeedsList = Database.query(str);
            system.debug('queried recs'+appfeedsList);
            if(appfeedsList.size() >0){
                return appfeedsList;   
            }
            return appfeedsList;
        }
    
    
    @AuraEnabled
        public static List<App_Feeds__c> getAppFeeds(String searchKey) {
           
            string dateFilter='LAST_N_DAYS:7';   
            
            string str='SELECT Id,Name,Booking_Date__c,Booking_Time__c,Instrument__c,Parent__r.Name,Student__r.Name,Teacher__r.Name,Type__c FROM App_Feeds__c WHERE  Center__c =:searchKey  AND CreatedDate ='+ dateFilter +' ORDER BY CreatedDate DESC';
            
            list<App_Feeds__c> appfeedsList = Database.query(str);
            if(appfeedsList.size() >0){
                return appfeedsList;   
            }
            return appfeedsList;
        }
    
    @AuraEnabled
    Public static list<string> findDateList(){
      	   list<string> lst = new list<string>{'Today','Last 7 Days','Last 30 Days'}; 
               return lst;  
    }
   @AuraEnabled
    Public static list<string> findUserList(){
        list<string> userList = new List<string>{'My Tasks','My Future Tasks','All'};
            return userList;
    }
    @AuraEnabled
    public static List<Case> findCases(String searchKey) {
        Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get(serviceEnquiryRecordType).getRecordTypeId();
        return [SELECT Id,CaseNumber,Channel__c,LastModifiedDate,Status_Image__c,Last_Inbound_Email__c,OwnerId,Account.Name,Contact.Name,Subject,ParentId,Type,Reason,CreatedDate,ClosedDate,Status,Owner.Name FROM Case where Centre_Name__c =:searchKey AND Status IN ('New','Open') AND RecordTypeId=:recorId  ORDER BY LastModifiedDate DESC];
    }

  
    @AuraEnabled
    public static List<Case> findAllNullCases(string searchKeys) {
        List<Case> caseList = new List<Case>();
        Account acc = [Select Id,Country__r.Name from Account where Id=:searchKeys];
        if(acc.Country__r.Name !='HK'){
            //Added by Rajesh on 19th may 2020, To exclude enquiry of employee or teacher as per Alex request and guided by Prashant
            caseList =[SELECT Id,CaseNumber,Last_Inbound_Email__c,LastModifiedDate,Channel__c,Status_Image__c,OwnerId,Account.Name,Contact.Name,Subject,ParentId,Type,Reason,CreatedDate,ClosedDate,Status,Owner.Name FROM Case where Status IN ('New','Open') ANd (Centre_Name__c=Null OR Centre_Name__r.Location__c='XXXX') and Centre_Name__r.Country__r.Name !='HK' AND Account.RecordType.Name NOT IN('Employee','Teacher')  ORDER BY LastModifiedDate DESC];
        }
        return caseList;
           
    }
    @AuraEnabled
    public static list<Case> findSalesEnquiryCases(String searchKey) {
        Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get(salesEnquiryRecordType).getRecordTypeId();
        return [SELECT Id,CaseNumber,Channel__c,LastModifiedDate,Status_Image__c,OwnerId,Stage__c,Last_Inbound_Email__c,Account.Name,Contact.Name,Subject,ParentId,Type,Reason,CreatedDate,ClosedDate,Status,Owner.Name FROM Case where Centre_Name__c =:searchKey AND Status IN ('New','Open') AND RecordTypeId=:recorId  ORDER BY LastModifiedDate DESC];
       
    }   
    // 28-Apr-2021: Nishi:show Case accoridng to  isSalesEnquiery if its true then we show salesEnquiryRecordType records otherwise Instrument Rental Enquiry records
    @AuraEnabled
    public static List<Case> findSalesEnquiryCases(String searchKey,Boolean isSalesEnquiery) {
        Id recorId = isSalesEnquiery ? Schema.SObjectType.case.getRecordTypeInfosByName().get(salesEnquiryRecordType).getRecordTypeId():Schema.SObjectType.case.getRecordTypeInfosByName().get(InstrumentRentalEnquiryRecordType).getRecordTypeId();
        return [SELECT Id,CaseNumber,Channel__c,LastModifiedDate,Status_Image__c,OwnerId,Stage__c,Last_Inbound_Email__c,Account.Name,Contact.Name,Subject,ParentId,Type,Reason,CreatedDate,ClosedDate,Status,Owner.Name FROM Case where Centre_Name__c =:searchKey AND Status IN ('New','Open') AND RecordTypeId=:recorId  ORDER BY LastModifiedDate DESC];
          
    }
    @AuraEnabled
    public static List<InvoiceWrapperClass> findInvoices(String searchKey,Boolean FrontPage) {
        List<InvoiceWrapperClass> InvoicWrapList = new List<InvoiceWrapperClass>();
        List<Invoice__c> InvoiceList= [SELECT Id,Name,Parent_Account__r.Name,Subscription__c,Total_Amount__c,Customer_Name__c,Due_Date__c,Status__c FROM Invoice__c where Center__c =:searchKey AND Status__c='Due' ORDER By Due_Date__c Asc];
       	Integer listSize=InvoiceList.size();
        if(FrontPage){
            if(InvoiceList.size()>0){
                integer i=1;
                for(Invoice__c invInstance:InvoiceList){
                    InvoiceWrapperClass InvWrapInstance = new InvoiceWrapperClass();
                    InvWrapInstance.Inv=invInstance;
                    InvWrapInstance.listLength=listSize;
                    InvoicWrapList.add(InvWrapInstance);
                    if(i==5){
                        break;
                    }
                    i++; 
                } 
            }else{
                InvoiceWrapperClass InvWrapInstance = new InvoiceWrapperClass();
                Invoice__c InvInstance= new Invoice__c(); 
                InvWrapInstance.Inv=InvInstance;
                InvWrapInstance.listLength=listSize;
                InvoicWrapList.add(InvWrapInstance);
            }  
        }else{
            if(InvoiceList.size()>0){
                for(Invoice__c invInstance:InvoiceList){
                    InvoiceWrapperClass InvWrapInstance = new InvoiceWrapperClass();
                    InvWrapInstance.Inv=invInstance;
                    InvoicWrapList.add(InvWrapInstance);
                }
             }else{
                 InvoiceWrapperClass InvWrapInstance = new InvoiceWrapperClass();
                 Invoice__c InvInstance= new Invoice__c(); 
                 InvWrapInstance.Inv=InvInstance;
                 InvWrapInstance.listLength=listSize;
                 InvoicWrapList.add(InvWrapInstance);
            }
        }
        return InvoicWrapList;
    }
    
    
    public class InvoiceWrapperClass{
        @AuraEnabled
        public Invoice__c Inv {get;set;}
        @AuraEnabled
        public integer listLength {get;set;} 
        public InvoiceWrapperClass(){
            
        }
        
    }
    
    @auraEnabled
    public static Map<string, integer> getChartMap(String searchKey){
        Map<string, integer> mp = new Map<string, integer>(); 
        for(AggregateResult agr:[Select count(Student__c) cnt,Package__r.Duration__c pkgName
                                 from Enrolment__c 
                                 Where Center__c =:searchKey And Type__c='Regular' AND Stage__c='Enrolled'
                                 Group By Package__r.Duration__c]){
                                     if(agr.get('pkgName') != NULL )
                                         mp.put((String) agr.get('pkgName'),(Integer)agr.get('cnt'));
                                     else
                                         mp.put('NULL',(Integer)agr.get('cnt'));
                                 }
        return mp;
    }
    
    @AuraEnabled
    Public static list<Centre_Users__c> getUser(){
        list<Centre_Users__c> centerName= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name from Centre_Users__c where User_Name__c=:UserInfo.getUserId()]);
        
        return centerName;
    }
    
    @AuraEnabled
    public static void updateOwner(string caseSalesId){
        Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get(salesEnquiryRecordType).getRecordTypeId();
        List<Case> caseList= new List<Case>();
        for(Case cas:[SELECT Id,Status,OwnerId FROM Case where Id=:caseSalesId AND RecordTypeId=:recorId ]){
            cas.OwnerId=UserInfo.getUserId();
            caseList.add(cas);
        }
        if(caseList.size()>0){
            update caseList;
        }
    }
    
     @AuraEnabled
    public static void updateServiceOwner(string caseSalesId){
        Id recorId = Schema.SObjectType.case.getRecordTypeInfosByName().get(serviceEnquiryRecordType).getRecordTypeId();
        List<Case> caseList= new List<Case>();
        for(Case cas:[SELECT Id,Status,OwnerId FROM Case where Id=:caseSalesId AND RecordTypeId=:recorId ]){
            cas.OwnerId=UserInfo.getUserId();
            caseList.add(cas);
        }
        if(caseList.size()>0){
            update caseList;
        }
    }
    
      @AuraEnabled
    public static void updateAllNullOwner(string caseSalesId){
        List<Case> caseList= new List<Case>();
        for(Case cas:[SELECT Id,Status,OwnerId FROM Case where Id=:caseSalesId ]){
            cas.OwnerId=UserInfo.getUserId();
            caseList.add(cas);
        }
        if(caseList.size()>0){
            update caseList;
        }
    }
    @AuraEnabled
    public static void setDefaultLocation(string locationVal){
        List<Centre_Users__c> centerUserList = new List<Centre_Users__c>();
        Centre_Users__c[] cenUserList=[select Id,Centre_Name__c from Centre_Users__c WHERE User_Name__c=:UserInfo.getUserId()];
        if(cenUserList.size()>0){
            for(Centre_Users__c cenUser:cenUserList){
                cenUser.Centre_Name__c=locationVal;
                centerUserList.add(cenUser);
            } 
        }else{
            Centre_Users__c newRecord = new Centre_Users__c(Centre_Name__c = locationVal, User_Name__c = UserInfo.getUserId());
            centerUserList.add(newRecord);
        }
            try {
                upsert centerUserList;
            } catch (DmlException e) {
            }
    }
    
}