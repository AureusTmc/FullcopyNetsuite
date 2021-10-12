/*
        Name        :    CreateGroupClassBatch
        Date        :    09/1/20202
        Author      :  
        Description :    This batch class is used for the following:
                         1. creating 13th Month Bookings (group Class)
        
*/
global class CreateGroupClassBatch implements Database.Batchable<sObject>, database.stateful{
    global Set<string> classIds;
    global integer noOfRecords;
    global String  errorDesciption;
    global Date startDate ;
    global List<BillingUtility.MonthlyBatchClassChunkError> listOfSubscriptionChunkError;
    global CreateGroupClassBatch(){
        classIds = new Set<string>();
        startDate = System.today().addMonths(13);
        noOfRecords =0;
        listOfSubscriptionChunkError = new List<BillingUtility.MonthlyBatchClassChunkError>();
    
    }
    global CreateGroupClassBatch(Set<string> classIds, date startDate){
        this.classIds = classIds;
        this.startDate = startDate;
        noOfRecords =0;
         listOfSubscriptionChunkError = new List<BillingUtility.MonthlyBatchClassChunkError>();
     
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        string query ='SELECT Id,name, Centre_Name__c, Package_Fee__c, Program__c, Total_Capacity__c, Class_Type__c, Class_Start_Date__c, End_Time__c, Start_Time__c, Teacher__c, Package__c, Active__c, Total_Enrolment__c, Class_Date__c, Class_End_Date__c,';
        query +=  'Class_Day__c, Minimum_age__c, Maximum_age__c, Instrument__c, Available_Capacity__c';
        query += ' FROM Class__c ';
        query += ' WHERE Active__c = true ';
        query += ' AND Class_Start_Date__c <= THIS_MONTH ';
        query +=' And (Class_End_Date__c = null OR Class_End_Date__c >=:startDate)';
        if(classIds != null && classIds.size() > 0 ){
            query += ' AND Id In: classIds';
        }
        return Database.getQueryLocator(query);
     }
     
     global void execute(Database.BatchableContext BC, List<Class__c> classList){
        Savepoint monthClassSavePoint;
        string classIds = getclassListIds(classList);
        //List<Class__c> listOfClass = new List<Class__c>();
        List<Booking__c> bookingListForClass = new List<Booking__c>();
        System.debug(classList);
        noOfRecords += classList.size();
        try{
            monthClassSavePoint = Database.setSavepoint();
            for(Class__c objClass : classList){
                System.debug(objClass);
                //commented by jatin: 17-Mar-2020 : 
                //if(objClass.Class_End_Date__c != null && objClass.Start_Time__c != null ){   
                if(objClass.Start_Time__c != null ){    
                    DateTime startTime  = AureusUtility.getFirstWeekDayDate(objClass.Class_Day__c,startDate.month(),startDate.year());
                    DateTime endTime = objClass.Class_End_Date__c != null && objClass.Class_End_Date__c.month() == startDate.month() ? 
                                        DateTime.newInstance(objClass.Class_End_Date__c,objClass.Start_Time__c) :
                                        DateTime.newInstance(Date.newInstance(startDate.year(),startDate.month(),Date.daysInMonth(startDate.month(),startDate.year())),objClass.Start_Time__c);
                
                    /*commented by jatin: 17-Mar-2020: according to new requirement  Class_End_Date__c field  is only update manually 
                    so its possible Class_End_Date__c is blank now we create start time to current 13 month booking otherwise enddate is found then we create class_end_date 
                    dateTime startTime = AureusUtility.getFirstWeekDayDate(objClass.Class_Day__c,objClass.Class_End_Date__c.month(),objClass.Class_End_Date__c.year());
                */
                bookingListForClass.addAll(ClassTriggerHelper.createBookingsForClass(objClass,startTime,endTime));
                //commented by jatin: 17-Mar-2020: according to new requirement  Class_End_Date__c field  is only update manually
                // listOfClass.add(new Class__c (id=objClass.id,Class_End_Date__c = endTime.date()));
                }
            }
            System.debug('@@@@bookingListForClass'+bookingListForClass);
            if(bookingListForClass.size() > 0){
                upsert   bookingListForClass;     
            }
            //System.debug('@@@@listOfClass'+listOfClass);
        /*  if(listOfClass.size() > 0){
                update  listOfClass;     
            }*/
        }catch (Exception e){
            //On 18th Mar 2020 to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(monthClassSavePoint);
            errorDesciption  += e.getStackTraceString()+'-'+e.getMessage() +';';
            System.debug('@@errorDesciption'+errorDesciption);
            string errorDescription = 'Rollback Group Class Ids are "'+classIds+'" and Failure Reason '+ e.getStackTraceString()+'-'+e.getMessage() +';';
            listOfSubscriptionChunkError.add(new BillingUtility.MonthlyBatchClassChunkError(errorDescription,classList.size(),classList.size()));// 16-dec-2020:nishi create batch chunk error  Log records
         
        }
     }
    
      //16-Dec-2020:nishi: get class ids in string format
      private  string getclassListIds(List<Class__c> classList){
        set<string> objClassIds = new set<string>(); 
        for(Class__c objClass  : classList){
           objClassIds.add(objClass.name);
        }
        return string.join(new List<string>(objClassIds),', ');
     }
    

    global void finish(Database.BatchableContext BC){
        string batchjobId = BillingUtility.createBatchJobLog('Group Class Monthly Batch', system.now(),system.now(),noOfRecords,errorDesciption);
        BillingUtility.createBatchChunkErrorLogs(listOfSubscriptionChunkError,batchjobId);// 16-dec-2020:nishi create batch chunk error  Log records
    }
}