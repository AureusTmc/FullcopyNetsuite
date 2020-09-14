global class SubscriptionMonthlyInvoiceBatch implements Database.Batchable<sObject>,database.stateful{
    global Set<string> invIds;
    global DateTime startTime;
    global integer noOfRecords;
    global String  errorDesciption;
    global Set<String> enrolmentIds;
    
    global SubscriptionMonthlyInvoiceBatch(){
        invIds = new Set<string>();
        noOfRecords  = 0;
        startTime = system.now();
        errorDesciption = '';
        enrolmentIds = new Set<string>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        // @02/26/2019 Next Billing Date filter added by Sanjay Bhati
        return Database.getQueryLocator([Select Id,Parent__c,Parent__r.personContactId,Next_Bill_Date__c,Center__c,
                                            
                                         (Select Id,Amount__c,Enrolment__c,Plan_Package__c,Enrolment__r.Effective_Date__c,
                                          // Added by jatin: 28-jan-2020 : For create Invoices According to rental invoice fields
                                          Enrolment__r.Termination_request_date__c,Enrolment__r.recordtype.Name,
                                          Enrolment__r.Package_Process_Type__c,Enrolment__r.Package_Process_Status__c,Enrolment__r.Lesson_day__c,
                                          Enrolment__r.New_Package_Id__c,Enrolment__r.Package_Process_Request_Date__c,
                                          Enrolment__r.New_Package_Id__r.Deposit_Fee__c,Enrolment__r.New_Package_Id__r.Unit_Fee__c,
                                          Enrolment__r.Package__c,Enrolment__r.Teacher__c, Enrolment__r.New_Teacher__c,Enrolment__r.Promotional_Period_End_Date__c,
                                          Enrolment__r.Package__r.Deposit_Fee__c,Enrolment__r.Package__r.Unit_Fee__c,
                                          Next_Bill_Date__c, Enrolment__r.Center__r.Country__r.Id, Enrolment__r.Center__r.Country__r.Tax_Rate__c ,
                                          // added by nishi:18_aug-2020: for manage facility fee is ossia student Subscription invoice created
                                          Enrolment__r.Center__r.Organisation__r.Name,//Enrolment__r.New_Package_Id__r.Facility_Fee__c,Enrolment__r.Package__r.Facility_Fee__c,
                                          Enrolment__r.Package__r.Name,Enrolment__r.New_Package_Id__r.Name, Enrolment__r.Center__r.Organisation__r.Tax_Rate__c , Enrolment__r.Center__r.Organisation__r.Id,
                                            // added by nishi: 7-Sep-2020: for manage Change center subscription line item
                                          Enrolment__r.New_Centre__r.Country__r.Id, Enrolment__r.New_Centre__r.Country__r.Tax_Rate__c ,
                                          Enrolment__r.New_Centre__r.Organisation__r.Name, Enrolment__r.New_Centre__r.Organisation__r.Tax_Rate__c , Enrolment__r.New_Centre__r.Organisation__r.Id
                                            // added by nishi: 7-Sep-2020: for manage Change center subscription line item
                                          FROM Subscription_Line_Items__r 
                                          WHERE Status__c=:ConstantsClass.activeStatus 
                                          AND Next_Bill_Date__c <= :system.today()
                                          AND Subscription_Start_Date__c <=: system.today() 
                                          AND (Subscription_Expiry_Date__c=NULL 
                                               OR Subscription_Expiry_Date__c >: system.today())
                                         ) 
                                         FROM Subscription__c 
                                         WHERE Status__c=:ConstantsClass.activeStatus 
                                         AND Parent__c !=null 
                                         AND Subscription_Start_Date__c<=:system.today() 
                                         AND Next_Bill_Date__c <=:system.today() 
                                         AND (Subscription_End_Date__c=NULL 
                                              OR Subscription_End_Date__c >: system.today())
                                         
                                        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Subscription__c> subscriptions){
        //On 6th December 2019 to Add Custom Save Points so If Error Occures we can trace that.
        Savepoint monthInvoiceSavePoint;
        try{
            
            noOfRecords += subscriptions.size();
            Date today = System.today();
            monthInvoiceSavePoint = Database.setSavepoint();
            // 12-Nov-2019 : Commented by Jatin : for get current updated invoices 
            //invIds.addAll(BillingUtility.createInvoiceFromSubscription(subscriptions,NuLL,today));
            Set<string> invoiceIds  = BillingUtility.createInvoiceFromSubscription(subscriptions,NuLL,today);
            invIds.addAll(invoiceIds);
            system.debug('invoiceIds'+invoiceIds);
            // 12-Nov-2019 : Jatin: get current updated invoices ids then get related enrollments 
            enrolmentIds.addAll(BillingUtility.getInvoiceLineItemEnrollmentIds(invoiceIds));
        }catch (Exception e){
            //On 6th December 2019 to Add Custom Save Points so If Error Occures we can trace that.
            Database.rollback(monthInvoiceSavePoint);
            errorDesciption  += e.getStackTraceString()+'-'+e.getMessage() +';';
            System.debug('@@errorDesciption'+errorDesciption);
        }
        /*Commented by arpit, As No need to generate invoice here, generate invoice after billing*/
        //BillingUtility.addInvocieAttachment(invIds); //@07-05-2018 create the attachment for invoice By Sanjay Bhati
    }   
    
    global void finish(Database.BatchableContext BC){
        BillingUtility.createBatchLog('Subscription  Monthly Invoice Batch',startTime,system.now(),noOfRecords,errorDesciption);
        // Jatin : for call postInvoiceBatch class with enrolment Ids
        System.debug('@@@enrolmentIds'+enrolmentIds);
        if(enrolmentIds != NULL && enrolmentIds.size() > 0){
            
            Database.executeBatch(new PostInvoiceBatch(enrolmentIds), 200);
        }
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
    }
}