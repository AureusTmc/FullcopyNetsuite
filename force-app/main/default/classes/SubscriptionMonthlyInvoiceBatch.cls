global class SubscriptionMonthlyInvoiceBatch implements Database.Batchable<sObject>,database.stateful{
    global Set<string> invIds;
    global DateTime startTime;
    global integer noOfRecords;
    global String  errorDesciption;
    global Set<String> enrolmentIds;
    global List<BillingUtility.MonthlyBatchClassChunkError> listOfSubscriptionChunkError;
    global SubscriptionMonthlyInvoiceBatch(){
        invIds = new Set<string>();
        noOfRecords  = 0;
        startTime = system.now();
        errorDesciption = '';
        enrolmentIds = new Set<string>();
        listOfSubscriptionChunkError = new List<BillingUtility.MonthlyBatchClassChunkError>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        date subscriptiondate = system.today();
        // @02/26/2019 Next Billing Date filter added by Sanjay Bhati
        return Database.getQueryLocator([Select Id,Name,Parent__c,Parent__r.personContactId,Next_Bill_Date__c,Center__c,
                                            
                                         (Select Id,Amount__c,Enrolment__c,Plan_Package__c,Enrolment__r.Effective_Date__c,
                                          // Added by jatin: 28-jan-2020 : For create Invoices According to rental invoice fields
                                          Enrolment__r.Termination_request_date__c,Enrolment__r.recordtype.Name,
                                          Enrolment__r.Package_Process_Type__c,Enrolment__r.Package_Process_Status__c,Enrolment__r.Lesson_day__c,
                                          Enrolment__r.New_Package_Id__c,Enrolment__r.Package_Process_Request_Date__c,
                                          Enrolment__r.New_Package_Id__r.Deposit_Fee__c,Enrolment__r.New_Package_Id__r.Unit_Fee__c,
                                          Enrolment__r.Package__c,Enrolment__r.Teacher__c, Enrolment__r.New_Teacher__c,Enrolment__r.Promotional_Period_End_Date__c,
                                          Enrolment__r.Package__r.Deposit_Fee__c,Enrolment__r.Package__r.Unit_Fee__c,
                                          Enrolment__r.Package_To_Be_Change__r.Unit_Fee__c,Enrolment__r.Package_To_Be_Change__c,///added by nishi:11-Jan-2020: for invoice packages amount according to Promo enrolment changed into regular package. 
                                          Next_Bill_Date__c, Enrolment__r.Center__r.Country__r.Id, Enrolment__r.Center__r.Country__r.Tax_Rate__c ,
                                          // added by nishi:18_aug-2020: for manage facility fee is ossia student Subscription invoice created
                                          Enrolment__r.Center__r.Organisation__r.Name,//Enrolment__r.New_Package_Id__r.Facility_Fee__c,Enrolment__r.Package__r.Facility_Fee__c,
                                          Enrolment__r.Package__r.Name,Enrolment__r.New_Package_Id__r.Name,/* Enrolment__r.Center__r.Organisation__r.Tax_Rate__c ,*/ Enrolment__r.Center__r.Organisation__r.Id,
                                          Enrolment__r.No_of_Stairs__c, // 9-oct-2020: for manage Additional pickup charges with stair case charges  
                                          // added by nishi: 7-Sep-2020: for manage Change center subscription line item
                                          Enrolment__r.New_Centre__r.Country__r.Id, Enrolment__r.New_Centre__r.Country__r.Tax_Rate__c ,
                                          Enrolment__r.New_Centre__r.Organisation__r.Name, /*Enrolment__r.New_Centre__r.Organisation__r.Tax_Rate__c ,*/ Enrolment__r.New_Centre__r.Organisation__r.Id
                                            // added by nishi: 7-Sep-2020: for manage Change center subscription line item
                                          FROM Subscription_Line_Items__r 
                                          WHERE Status__c=:ConstantsClass.activeStatus 
                                          AND Next_Bill_Date__c <= :subscriptiondate
                                          AND Subscription_Start_Date__c <=: subscriptiondate 
                                          AND (Subscription_Expiry_Date__c=NULL 
                                               OR Subscription_Expiry_Date__c >: subscriptiondate)
                                         ) 
                                         FROM Subscription__c 
                                         WHERE Status__c=:ConstantsClass.activeStatus 
                                         AND Parent__c !=null 
                                         AND Subscription_Start_Date__c<=:subscriptiondate 
                                         AND Next_Bill_Date__c <=:subscriptiondate 
                                         AND (Subscription_End_Date__c=NULL 
                                              OR Subscription_End_Date__c >: subscriptiondate)
                                        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Subscription__c> subscriptions){
        //On 6th December 2019 to Add Custom Save Points so If Error Occures we can trace that.
        Savepoint monthInvoiceSavePoint;
        string subIds = getSubscriptionsIds(subscriptions);
        try{
            noOfRecords += subscriptions.size();
            Date today = System.today();
            monthInvoiceSavePoint = Database.setSavepoint();
            // 12-Nov-2019 : Commented by Jatin : for get current updated invoices 
            //invIds.addAll(BillingUtility.createInvoiceFromSubscription(subscriptions,NuLL,today));
            Set<string> invoiceIds  = BillingUtility.createInvoiceFromSubscription(subscriptions,NuLL,today,false);
            invIds.addAll(invoiceIds);
            system.debug('invoiceIds'+invoiceIds);
            // 12-Nov-2019 : Jatin: get current updated invoices ids then get related enrollments 
            enrolmentIds.addAll(BillingUtility.getInvoiceLineItemEnrollmentIds(invoiceIds));
        }catch (Exception e){
            //On 6th December 2019 to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(monthInvoiceSavePoint);
            errorDesciption  += e.getStackTraceString()+'-'+e.getMessage() +';';
            
            // added by nishi:15-Dec-2020: if any error found then we send a email with subscription ids and error details
            //errMsgMap.put(subIds, e.getStackTraceString()+'-'+e.getMessage() +';');commented by nishi: 16-Dec-2020 : change requirement we create batch chunk error  Log records 
            string errorDescription = 'Rollback Subscription Ids are "'+subIds+'" and Failure Reason '+ e.getStackTraceString()+'-'+e.getMessage() +';';
            listOfSubscriptionChunkError.add(new BillingUtility.MonthlyBatchClassChunkError(errorDescription,subscriptions.size(),subscriptions.size()));// 16-dec-2020:nishi create batch chunk error  Log records
        }
        /*Commented by arpit, As No need to generate invoice here, generate invoice after billing*/
        //BillingUtility.addInvocieAttachment(invIds); //@07-05-2018 create the attachment for invoice By Sanjay Bhati
    }   
    
    global void finish(Database.BatchableContext BC){
        string batchjobId = BillingUtility.createBatchJobLog('Subscription  Monthly Invoice Batch',startTime,system.now(),noOfRecords,errorDesciption);
        BillingUtility.createBatchChunkErrorLogs(listOfSubscriptionChunkError,batchjobId);// 16-dec-2020:nishi create batch chunk error  Log records
        // Jatin : for call postInvoiceBatch class with enrolment Ids
        /*Commented by Nishi 7-Oct-2020: for call postInvoiceBatch class without enrolment Ids
        System.debug('@@@enrolmentIds'+enrolmentIds);
        if(enrolmentIds != NULL && enrolmentIds.size() > 0){
            
            Database.executeBatch(new PostInvoiceBatch(enrolmentIds), 200);
        }*/
        // Nishi 7-Oct-2020:start for call postInvoiceBatch class without enrolment Ids
        Database.executeBatch(new PostInvoiceBatch(), 200);
         // Nishi 7-Oct-2020:end: for call postInvoiceBatch class without enrolment Ids
        if(invIds!=null && invIds.size()>0){
            //database.executeBatch(new EmailInvoicebatch(invIds));
            /*
Commented because need to disable payment batch
*/
            //Database.executeBatch(new MonthlyPaymentBatch(),99);
            
            
            //Sanjay Mankani : Sage Code
            //Temprary stop sage pushing, Immediate step due to COVID-19 by Rajesh on 2nd april 2020
            //Database.executeBatch(new SageInvoicePushBatch(invIds),Integer.valueOf(label.SageBatchSize));
            //database.executeBatch(new SagePaymentPushBatch('Invoice',invIds),Integer.valueOf(label.SageBatchSize));
        }
        // added by nishi: 15-Dec-2020: for if in batch class found any error then we send a email to Tmc users with error details
        /*commented by nishi: 16-Dec-2020 : change requirement we create batch chunk error  Log records 
        if(errMsgMap != null && errMsgMap.size() > 0){
            
            AsyncApexJob a = [Select Id, Status,ExtendedStatus,NumberOfErrors,     JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            from AsyncApexJob where Id =:BC.getJobId()];
                system.debug('a'+a);
                system.debug('errMsgMap'+errMsgMap);
                system.debug('a.CreatedBy.Email'+a.CreatedBy.Email);
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {};
                if(string.isnotBlank(label.Batch_Error_User_id)){
                    List<user> listUserList = [select id,email from user where id=:label.Batch_Error_User_id];
                    if(listUserList.size() > 0 ){
                        toAddresses.add(listUserList[0].email);
                    }else{
                        toAddresses.add('aureus@techmatrixconsulting.com');
                    }
                }else{
                    toAddresses.add('aureus@techmatrixconsulting.com');
                }
                mail.setToAddresses(toAddresses);
                mail.setSubject('Subscription  Monthly Invoice Batch Job Details :' + BC.getJobId());
                mail.setSaveAsActivity(false);
                string htmlbody='Batch Job Items : '+a.TotalJobItems;
                htmlbody+= '\n Total Subscription Records : ' + noOfRecords ;
                htmlbody+= '\n Total Records Processed : ' + invIds.size() ;
                htmlbody+= ' \n  Error Description : \n\n';
                Integer errorNumber = 1;
                for(string subscriptionids :errMsgMap.keySet()){
                    htmlbody+= errorNumber +'. Rollback Subscription Ids are "'+subscriptionids+'" and Failure Reason '+ errMsgMap.get(subscriptionids)+' \n\n';
                    errorNumber++;
                }
                mail.setPlainTextBody(htmlbody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                system.debug('mail'+mail);
        }*/
        // added by nishi: 15-Dec-2020: for if we for found any error log then we send a email to Tmc users
        
    }
    private  string getSubscriptionsIds(List<Subscription__c> subscriptions){
        set<string> subIds = new set<string>(); 
        for(Subscription__c objSubscription  : subscriptions){
            subIds.add(objSubscription.Name);
        }
        return string.join(new List<string>(subIds),', ');
    }
}