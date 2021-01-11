public with sharing class InvoiceGeneraterController {
    //InvoiceGeneraterController.generateInvoiceSummary('a0I6D000003C0WyUAK');
    @AuraEnabled
    public static GenerateInvoiceSummaryWrapper generateInvoiceSummary(String subscriptionId){
        // aug biiling done then added new month date sep 
        Date nextMonthDate = Date.newInstance(system.today().addMonths(1).year(),system.today().addMonths(1).month(),01);
        Date nextBillingDate = nextMonthDate;
        list<SubscriptionStudentWrapper> listOfSubscriptionStudent = new list<SubscriptionStudentWrapper>();
        if(string.isNotBlank(subscriptionId)){
            Savepoint monthInvoiceSavePoint;
            try{
                monthInvoiceSavePoint = Database.setSavepoint();
                ActiveSubscritionWrapper objActiveSubscritionWrapper = new ActiveSubscritionWrapper(subscriptionId);
                if(objActiveSubscritionWrapper.isActiveSubscrition){
                    List<Subscription__c> listOfSub = getSubscriptionList(subscriptionId,nextMonthDate);
                    if(listOfSub!= null && listOfSub.size() > 0){
                        if(listOfSub[0].Subscription_Line_Items__r != null && listOfSub[0].Subscription_Line_Items__r.size() > 0 ){
                            //14-Aug-2020:Nishi:If any person monthly billing not created for any further reason then we create that month billing 
                            if(listOfSub[0].Next_Bill_Date__c <=   Date.newInstance(system.today().year(),system.today().month(),01)){
                                nextBillingDate = listOfSub[0].Next_Bill_Date__c;
                            }
                            //14-Aug-2020:Nishi:If any person monthly billing not created for any further reason then we create that month billing 
                            listOfSubscriptionStudent =  invoiceFromSubscriptionSummary(listOfSub,nextBillingDate);
                            system.debug('listOfSubscriptionStudent-'+listOfSubscriptionStudent); 
                            return new GenerateInvoiceSummaryWrapper(listOfSubscriptionStudent,nextBillingDate,'200',''+nextBillingDate);
                        }else{
                            return new GenerateInvoiceSummaryWrapper(listOfSubscriptionStudent,nextBillingDate,'400','Not Found any Subscription Line Item Next Bill date is greater then Next Month..');
                        }
                    }else{
                        return new GenerateInvoiceSummaryWrapper(listOfSubscriptionStudent,nextBillingDate,'400','Subscription Next Bill date is greater then Next Month..');
                    }
                }else{
                    return new GenerateInvoiceSummaryWrapper(listOfSubscriptionStudent,nextBillingDate,'400',objActiveSubscritionWrapper.errorMessage);
                }
            }catch(exception e){
                system.debug('e.getMessage()'+e.getMessage());
                Database.rollback(monthInvoiceSavePoint);
                return new GenerateInvoiceSummaryWrapper(listOfSubscriptionStudent,nextBillingDate,'400',e.getStackTraceString()+'-'+e.getMessage());
            }
        }
        return new GenerateInvoiceSummaryWrapper(listOfSubscriptionStudent,nextBillingDate,'400','Subscription Id not Found');
    }
    public class ActiveSubscritionWrapper{
        @AuraEnabled public string errorMessage;
        @AuraEnabled public Boolean isActiveSubscrition;
        public ActiveSubscritionWrapper(string subscriptionId){
            isActiveSubscrition = true;
            errorMessage = '';
            List<Subscription__c> listOfSub =  getActiveSubscriptionList(subscriptionId);
            if(listOfSub != null && listOfSub.size() > 0){
                if(listOfSub[0].Subscription_Line_Items__r != null && listOfSub[0].Subscription_Line_Items__r.size() > 0 ){
                    isActiveSubscrition = true;
                }else{
                    isActiveSubscrition = false;
                    errorMessage ='Not Fount Any Subscription Line Item Active Status...  ';
                }
            }else{
                isActiveSubscrition = false;
                errorMessage ='Selected Subscription Is Not Active Status...  ';
            }
        }
        
    } 

    public static list<SubscriptionStudentWrapper> invoiceFromSubscriptionSummary(List<Subscription__c> subscriptions, Date invDate){
        list<SubscriptionStudentWrapper> listOfSubscriptionStudent = new list<SubscriptionStudentWrapper>();
        map<string,Subscription_Line_Item__c> mapOfSubscriptionStudent = new map<string,Subscription_Line_Item__c>();
        map<string,SubscriptionStudentWrapper> mapOfSubscriptionStudentWrapper = new map<string,SubscriptionStudentWrapper>();
        Date nextBillingDate = invDate;
        system.debug('subscriptions'+subscriptions);
        system.debug('invDate'+invDate);
        Date firstDate = Date.newInstance(nextBillingDate.year(), nextBillingDate.month(), 01);
        Integer daysInMonth = Date.daysInMonth(nextBillingDate.year(), nextBillingDate.month());
        Date lastDate = Date.newInstance(nextBillingDate.year(), nextBillingDate.month(), daysInMonth);
        Map<String,List<Date>> mapOfDates = BillingUtility.getDateMap(firstDate,lastDate);
        Map<string,string> mapOfStudentAndPackageIdName = new Map<string,string>();
        List<PackageProcessHandler> listOfPackageToProcess = new List<PackageProcessHandler>();
        for(Subscription__c objSub : subscriptions){
            listOfPackageToProcess.add(new PackageProcessHandler(new Invoice__c(),objSub.Subscription_Line_Items__r,firstDate,lastDate));  
            for(Subscription_Line_Item__c objSubscriptionLineItem : objSub.Subscription_Line_Items__r){
                mapOfSubscriptionStudent.put(objSubscriptionLineItem.id,objSubscriptionLineItem);
            }       
        }
        system.debug('mapOfSubscriptionStudent-->'+mapOfSubscriptionStudent);    
       list<BillingSummary> listOfBillSummary = new list<BillingSummary>();
        for(PackageProcessHandler objProcessHandler : listOfPackageToProcess ){
            for(PackageProcessInterface objProcess : objProcessHandler.listOfPackageProcess){
                SubscriptionStudentWrapper objSubscriptionStudentWrapper = new SubscriptionStudentWrapper();
                List<Invoice_Line_Item__c> listinvLineItm =objProcess.createInvoiceLineItem(new Invoice__c(),mapOfDates );
                listOfBillSummary = new list<BillingSummary>();
                for(Invoice_Line_Item__c objinvLineItm : listinvLineItm){
                    if(mapOfSubscriptionStudent.containsKey(objinvLineItm.Subscription_Line_Item__c)){
                        Subscription_Line_Item__c objSubscriptionLineItem = mapOfSubscriptionStudent.get(objinvLineItm.Subscription_Line_Item__c);
                        if(mapOfSubscriptionStudentWrapper.containsKey(objinvLineItm.Subscription_Line_Item__c)){
                            listOfBillSummary = mapOfSubscriptionStudentWrapper.get(objinvLineItm.Subscription_Line_Item__c).listOfBillSummary;
                        }
                        string studentName ='';string packageName =''; string studentId ='';
                        if(string.isNotBlank(objinvLineItm.remarks__c)){
                            packageName = objinvLineItm.remarks__c;
                        }else{
                            if(string.isNotBlank(objSubscriptionLineItem.Enrolment__r.Package__c) && objinvLineItm.Package__c ==objSubscriptionLineItem.Enrolment__r.Package__c){
                                packageName = objSubscriptionLineItem.Enrolment__r.Package__r.name;
                            }
                            if(string.isNotBlank(objSubscriptionLineItem.Enrolment__r.New_Package_Id__c) && objinvLineItm.Package__c ==objSubscriptionLineItem.Enrolment__r.New_Package_Id__c){
                                packageName = objSubscriptionLineItem.Enrolment__r.New_Package_Id__r.name;
                            }
                        }
                        if(string.isNotBlank(objSubscriptionLineItem.Enrolment__r.Student_Name__c)){
                            studentName = objSubscriptionLineItem.Enrolment__r.Student_Name__c;
                            studentId = objSubscriptionLineItem.Enrolment__r.Student__c;
                        }
                        if(string.isBlank(studentId)){
                            studentName = objSubscriptionLineItem.Enrolment__r.parent__r.Name;
                            studentId = objSubscriptionLineItem.Enrolment__r.parent__c;
                        }
                        Decimal countryTaxRate = 0;
                        if(String.isNotBlank(objSubscriptionLineItem.Enrolment__r.Center__c) && String.isNotBlank(objSubscriptionLineItem.Enrolment__r.Center__r.Country__c) && 
                        objSubscriptionLineItem.Enrolment__r.Center__r.Country__r.Tax_Rate__c > 0){
                            countryTaxRate =  objSubscriptionLineItem.Enrolment__r.Center__r.Country__r.Tax_Rate__c;
                        }
                        listOfBillSummary.add(new BillingSummary(objinvLineItm.Amount__c,packageName,studentName,studentId,objinvLineItm.Package__c,0,countryTaxRate));
                        mapOfSubscriptionStudentWrapper.put(objinvLineItm.Subscription_Line_Item__c,
                                new SubscriptionStudentWrapper(listOfBillSummary,objSubscriptionLineItem,objSubscriptionLineItem.Enrolment__r.parent__c,
                                objSubscriptionLineItem.Enrolment__r.Parent__r.Centre_Name__r.Country__r.Tax_Rate__c));
                        system.debug('listOfBillSummary - '+listOfBillSummary);    
                        system.debug('objSubscriptionLineItem - '+objSubscriptionLineItem);    
                    }
                }
            }
            
        }
        system.debug('mapOfSubscriptionStudentWrapper -'+mapOfSubscriptionStudentWrapper);
        
        return mapOfSubscriptionStudentWrapper.values();
    }

    @AuraEnabled
    public static generateInvoiceWrapper generateInvoice(String subscriptionId){
        Date nextMonthDate = Date.newInstance(system.today().addMonths(1).year(),system.today().addMonths(1).month(),01);
        Date nextBillingDate = nextMonthDate;
        if(string.isNotBlank(subscriptionId)){
            Savepoint monthInvoiceSavePoint;
            try{
                monthInvoiceSavePoint = Database.setSavepoint();
                List<Subscription__c> listOfSub = getSubscriptionList(subscriptionId,nextMonthDate);
                if(listOfSub!= null && listOfSub.size() > 0){
                    if(listOfSub[0].Subscription_Line_Items__r != null && listOfSub[0].Subscription_Line_Items__r.size() > 0 ){
                         //14-Aug-2020:Nishi:If any person monthly billing not created for any further reason then we create that month billing 
                         if(listOfSub[0].Next_Bill_Date__c <=   Date.newInstance(system.today().year(),system.today().month(),01)){
                            nextBillingDate = listOfSub[0].Next_Bill_Date__c;
                        }
                        //14-Aug-2020:Nishi:If any person monthly billing not created for any further reason then we create that month billing 
                        Set<string> invoiceIds = BillingUtility.createInvoiceFromSubscription(listOfSub,NULL,nextBillingDate,true);
                        Set<String> enrolmentIds = new Set<String>();
                        enrolmentIds.addAll(BillingUtility.getInvoiceLineItemEnrollmentIds(invoiceIds));
                        if(enrolmentIds != NULL && enrolmentIds.size() > 0){
                            Database.executeBatch(new PostInvoiceBatch(enrolmentIds,datetime.newInstance(nextMonthDate, system.now().time())), 200);
                        }
                        List<string> invIds = new List<string>();
                        invIds.addAll(invoiceIds); 
                        return new generateInvoiceWrapper('200','',invIds[0]);
                    }else{
                        return new generateInvoiceWrapper('400','Not Found any Subscription Line Item Next Bill date is greater then Next Month..');
                    }
                }else{
                    return new generateInvoiceWrapper('400','Subscription Next Bill date is greater then Next Month..');
                }
            }catch(exception e){
                Database.rollback(monthInvoiceSavePoint);
                return new generateInvoiceWrapper('400',e.getStackTraceString()+'-'+e.getMessage());
            }
        }
         return new generateInvoiceWrapper('400','Subscription Id not Found');
    }

    @AuraEnabled
    public static generateInvoiceWrapper generateInvoicePayment(String invoiceId){
        Date nextBillingDate = Date.newInstance(system.today().addMonths(1).year(),system.today().addMonths(1).month(),01);
        if(string.isNotBlank(invoiceId)){
            Savepoint monthInvoiceSavePoint;
            try{
                monthInvoiceSavePoint = Database.setSavepoint();
                List<Invoice__c> invList = getDueInvoiceList(invoiceId,nextBillingDate.addDays(Integer.valueOf(Label.Invoice_Due_Day)));
                if(invList!= null && invList.size() > 0){
                    // List<string> invIds = new List<string>();    
                    // invIds.addAll(MonthlyPaymentBatchHelper.getPaymentForInvoices(invList));
                    // if(invIds != null && invIds.size() > 0){
                    //     return new generateInvoiceWrapper('200','',invIds[0]);
                    // }else{
                    //     return new generateInvoiceWrapper('400','Found Some Error Please Check Stripe Payment Log Records.');
                    // }
                    generatePayment(invoiceId,nextBillingDate);
                    return new generateInvoiceWrapper('200','',invList[0].id);
                }else{
                    return new generateInvoiceWrapper('400','Due Invoice Not Found.');
                }
            }catch(exception e){
                Database.rollback(monthInvoiceSavePoint);
                return new generateInvoiceWrapper('400',e.getStackTraceString()+'-'+e.getMessage());
            }
        }
         return new generateInvoiceWrapper('400','Subscription Id not Found');
    }
    @future(callout=true)
    public static void generatePayment(String invoiceId,date nextBillingDate){
        List<Invoice__c> invList = getDueInvoiceList(invoiceId,nextBillingDate.addDays(Integer.valueOf(Label.Invoice_Due_Day)));
        List<string> invIds = new List<string>();    
        invIds.addAll(MonthlyPaymentBatchHelper.getPaymentForInvoices(invList));
        system.debug('invIds'+invIds);
    }


    public static List<Invoice__c> getDueInvoiceList(String invoiceId, Date nextBillingDate){
        return [Select Id,Name,Parent_Account__c,Parent_Account__r.PersonContactId,Parent_Account__r.Stripe_Customer_Id__c, 
                Total_Amount__c,subscription__c,Balance_Amount__c,Paid_Amount__c,
                Parent_Account__r.personEmail,Parent_Account__r.Centre_Name__r.Location__c,
                Center__r.Country__c, Center__r.Country__r.Id, Center__r.Country__r.Tax_Rate__c, 
                Center__r.Country__r.Currency_Code__c, Center__r.Country__r.Stripe_Base_Url__c, 
                Center__r.Country__r.Stripe_Secret_Key__c ,
                Center__r.Organisation__r.Tax_Rate__c, 
                Center__r.Organisation__r.Country__r.Currency_Code__c, Center__r.Organisation__r.Stripe_Base_Url__c, 
                Center__r.Organisation__r.Stripe_Secret_Key__c 
                FROM Invoice__c 
                WHERE Parent_Account__r.Stripe_Customer_Id__c != NULL 
                AND Due_Date__c <= :nextBillingDate 
                AND Status__c=:ConstantsClass.dueStatus 
                AND Center__c != NULL 
                AND Parent_Account__r.Is_Club_Member__c != TRUE 
                AND Parent_Account__r.Membership_Type__c != :ConstantsClass.amcClubMember
                AND Id=:invoiceId];
    }

    public static List<Subscription__c> getSubscriptionList(String subscriptionId, Date nextBillingDate){
        return [Select Id,Parent__c,Parent__r.personContactId,Next_Bill_Date__c,Center__c,
                                                        (Select Id,Amount__c,Enrolment__c,Plan_Package__c,Enrolment__r.Effective_Date__c,
                                                            Enrolment__r.Parent__c,Enrolment__r.Student__c,Enrolment__r.Student_Name__c,Enrolment__r.Parent__r.Centre_Name__r.Country__r.Tax_Rate__c,
                                                            Enrolment__r.recordtype.Name,Enrolment__r.Termination_request_date__c,Enrolment__r.Parent__r.Name,
                                                            Enrolment__r.Package_Process_Type__c,Enrolment__r.Package_Process_Status__c,Enrolment__r.Lesson_day__c,
                                                        Enrolment__r.New_Package_Id__c,Enrolment__r.Package_Process_Request_Date__c,Enrolment__r.New_Package_Id__r.Name,
                                                        Enrolment__r.New_Package_Id__r.Deposit_Fee__c,Enrolment__r.New_Package_Id__r.Unit_Fee__c,
                                                        Enrolment__r.Package__c,Enrolment__r.Teacher__c, Enrolment__r.New_Teacher__c,Enrolment__r.Promotional_Period_End_Date__c,
                                                        Enrolment__r.Package__r.Deposit_Fee__c,Enrolment__r.Package__r.Unit_Fee__c,Enrolment__r.Package__r.Name,
                                                        Next_Bill_Date__c, Enrolment__r.Center__r.Country__r.Id, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                                        Enrolment__r.Center__r.Organisation__r.Name,/*Enrolment__r.New_Package_Id__r.Facility_Fee__c,Enrolment__r.Package__r.Facility_Fee__c,*/
                                                        Enrolment__r.Center__r.Organisation__r.Tax_Rate__c,
                                                        Enrolment__r.No_of_Stairs__c, // 9-oct-2020: for manage Additional pickup charges with stair case charges  
                                                        Enrolment__r.New_Centre__r.Country__r.Id, Enrolment__r.New_Centre__r.Country__r.Tax_Rate__c,
                                                        Enrolment__r.New_Centre__r.Organisation__r.Name,/*Enrolment__r.New_Package_Id__r.Facility_Fee__c,Enrolment__r.Package__r.Facility_Fee__c,*/
                                                        Enrolment__r.New_Centre__r.Organisation__r.Tax_Rate__c,
														Enrolment__r.Package_To_Be_Change__r.Unit_Fee__c,Enrolment__r.Package_To_Be_Change__c,///added by nishi:11-Jan-2020: for invoice packages amount according to Promo enrolment changed into regular package. 
                                                        Enrolment__r.Parent__r.Centre_Name__r.Organisation__r.Tax_Rate__c
                                                            FROM Subscription_Line_Items__r
                                                            WHERE Status__c=:ConstantsClass.activeStatus AND Next_Bill_Date__c <= :nextBillingDate
                                                            AND Subscription_Start_Date__c <=: nextBillingDate AND (Subscription_Expiry_Date__c=NULL OR Subscription_Expiry_Date__c >: nextBillingDate))
                                                    FROM Subscription__c
                                                    WHERE Status__c=:ConstantsClass.activeStatus and Parent__c!=null
                                                    AND Subscription_Start_Date__c<=:nextBillingDate
                                                    AND Next_Bill_Date__c <=:nextBillingDate AND
                                                    (Subscription_End_Date__c=NULL OR Subscription_End_Date__c >: nextBillingDate)
                                                        AND Id=:subscriptionId];
    }

    public static List<Subscription__c> getActiveSubscriptionList(String subscriptionId){
        return [Select Id,Parent__c,Parent__r.personContactId,Next_Bill_Date__c,Center__c,
                                                        (Select Id,Amount__c,Enrolment__c,Plan_Package__c,Enrolment__r.Effective_Date__c,
                                                            Enrolment__r.Parent__c,Enrolment__r.Student__c,Enrolment__r.Student_Name__c,Enrolment__r.Parent__r.Centre_Name__r.Country__r.Tax_Rate__c,
                                                            Enrolment__r.recordtype.Name,Enrolment__r.Termination_request_date__c,Enrolment__r.Parent__r.Name,
                                                            Enrolment__r.Package_Process_Type__c,Enrolment__r.Package_Process_Status__c,Enrolment__r.Lesson_day__c,
                                                        Enrolment__r.New_Package_Id__c,Enrolment__r.Package_Process_Request_Date__c,Enrolment__r.New_Package_Id__r.Name,
                                                        Enrolment__r.New_Package_Id__r.Deposit_Fee__c,Enrolment__r.New_Package_Id__r.Unit_Fee__c,
                                                        Enrolment__r.Package__c,Enrolment__r.Teacher__c, Enrolment__r.New_Teacher__c,Enrolment__r.Promotional_Period_End_Date__c,
                                                        Enrolment__r.Package__r.Deposit_Fee__c,Enrolment__r.Package__r.Unit_Fee__c,Enrolment__r.Package__r.Name,
                                                        Next_Bill_Date__c, Enrolment__r.Center__r.Country__r.Id, Enrolment__r.Center__r.Country__r.Tax_Rate__c,
                                                        Enrolment__r.Center__r.Organisation__r.Name,/*Enrolment__r.New_Package_Id__r.Facility_Fee__c,Enrolment__r.Package__r.Facility_Fee__c,*/
                                                        Enrolment__r.Center__r.Organisation__r.Tax_Rate__c,Enrolment__r.Parent__r.Centre_Name__r.Organisation__r.Tax_Rate__c
                                                            FROM Subscription_Line_Items__r
                                                            WHERE Status__c=:ConstantsClass.activeStatus 
                                                            AND (Subscription_Expiry_Date__c=NULL))
                                                    FROM Subscription__c
                                                    WHERE Status__c=:ConstantsClass.activeStatus 
                                                    and Parent__c!=null
                                                    AND Id=:subscriptionId];
    }

    public class GenerateInvoiceSummaryWrapper{
        @AuraEnabled public Decimal gstAmount{get;set;}
        @AuraEnabled public Decimal totalAmount{get;set;}
        @AuraEnabled public Decimal discountAmount{get;set;}
        @AuraEnabled public Decimal grossAmount{get;set;}
        @AuraEnabled public Decimal parentTaxRate{get;set;}
        @AuraEnabled public string errorCode;
        @AuraEnabled public string errorMessage;
        @AuraEnabled public list<BillingSummary> listOfBillSummary;
        @AuraEnabled public string invoiceDate;
        
        public GenerateInvoiceSummaryWrapper(){
            errorCode='';
            listOfBillSummary= new list<BillingSummary>();
            errorMessage='';
            totalAmount = 0;
            gstAmount =0;
            discountAmount = 0;
            grossAmount =0;
            parentTaxRate=0;
        }
        public GenerateInvoiceSummaryWrapper(list<SubscriptionStudentWrapper> listOfSubscriptionStudent,Date invoiceDate,string errorCode,string errorMessage){
            totalAmount = 0;
            gstAmount =0;
            discountAmount = 0;
            grossAmount =0;
            parentTaxRate =0.00;
            listOfBillSummary = new  list<BillingSummary>();
            this.invoiceDate = DateTime.newInstance(invoiceDate, Time.newInstance(0, 0, 0, 0)).format('MM,yyyy');
            map<string,decimal>  mapOfParentCountryTaxRate =new map<string,decimal>();
            Map<String,decimal> mapOfParentInv = new Map<String,decimal>();
            for(SubscriptionStudentWrapper objSubscriptionStudentWrapper:listOfSubscriptionStudent){
                Subscription_Line_Item__c objSubscriptionLineItem =  objSubscriptionStudentWrapper.objSubscriptionLineItems;
                if(objSubscriptionStudentWrapper.parenTaxRate != null && objSubscriptionStudentWrapper.parenTaxRate != 0){
                    mapOfParentCountryTaxRate.put(objSubscriptionStudentWrapper.parentId,objSubscriptionStudentWrapper.parenTaxRate);
                    parentTaxRate = BillingUtility.roundOffAmount(objSubscriptionStudentWrapper.parenTaxRate);
                }
                
                listOfBillSummary.addAll(objSubscriptionStudentWrapper.listOfBillSummary);
            }
            
            system.debug('listOfBillSummary -'+listOfBillSummary.size());
             // mange billing summary accoding to selected dates
             if(listOfBillSummary != NULL && listOfBillSummary.size() != 0){
                for(BillingSummary objBillingSummary : listOfBillSummary){
                    grossAmount += objBillingSummary.amount;
                    Decimal tempGstAmount =0;
                    if(objBillingSummary.countryTaxRate != null &&  objBillingSummary.countryTaxRate != 0 &&  objBillingSummary.amount != 0){
                        tempGstAmount = objBillingSummary.amount  * (objBillingSummary.countryTaxRate / 100);
                    }
                    gstAmount += tempGstAmount;
                }
                if(grossAmount > 0 && discountAmount >0){
                    grossAmount =  grossAmount - discountAmount;
                }
            }
            
            if(grossAmount > 0 && gstAmount > 0 ){
                totalAmount = BillingUtility.roundOffAmount(grossAmount + gstAmount);
            }
            for(string parentid : mapOfParentCountryTaxRate.keySet()){
                mapOfParentInv.put(parentid,totalAmount);
            }
            Map<String,Customer_Adhoc_Discount__c> customerDiscountsMap = new Map<String,Customer_Adhoc_Discount__c>();
            for(Customer_Adhoc_Discount__c discount : [SELECT Id,Discount_Amount__c,Parent__c,Status__c,Reason__c,Remark__c 
                                                    FROM Customer_Adhoc_Discount__c 
                                                    WHERE Parent__c IN :mapOfParentCountryTaxRate.keySet() AND
                                                    Status__c =: constantsClass.paymentPendingStatus 
                                                    AND Discount_Amount__c != NULL 
                                                    AND Discount_Date__c <=: invoiceDate
                                                    order by Discount_Amount__c Desc]){
            
                if(!customerDiscountsMap.containsKey(discount.Parent__c)){
                    customerDiscountsMap.put(discount.Parent__c,discount);
                }
            }

            for(String parentId : customerDiscountsMap.keySet()){
                Customer_Adhoc_Discount__c discount = customerDiscountsMap.get(parentId);
                string remarks='';
                if(mapOfParentInv.containsKey(parentId) && mapOfParentInv.get(parentId) >= discount.Discount_Amount__c){
                    if(String.isNotBlank(discount.Reason__c)){
                        if(discount.Reason__c == 'Admin Error'){
                            remarks = 'Referral';    
                        }else if(discount.Reason__c == 'Others'){
                            remarks = discount.Remark__c;  
                        }else{
                            remarks = discount.Reason__c;
                        }
                    }
                    listOfBillSummary.add(new BillingSummary((-1*discount.Discount_Amount__c),remarks,'','','',0,mapOfParentCountryTaxRate.get(parentId)));
                    totalAmount = 0;
                    gstAmount =0;
                    discountAmount = 0;
                    grossAmount =0;
                    system.debug('listOfBillSummary -'+listOfBillSummary.size());
                    if(listOfBillSummary != NULL && listOfBillSummary.size() != 0){
                        for(BillingSummary objBillingSummary : listOfBillSummary){
                            grossAmount += objBillingSummary.amount;
                            Decimal tempGstAmount =0;
                            if(objBillingSummary.countryTaxRate != null &&  objBillingSummary.countryTaxRate != 0 && objBillingSummary.amount != 0){
                                tempGstAmount = objBillingSummary.amount  * (objBillingSummary.countryTaxRate / 100);
                            }
                            gstAmount += BillingUtility.roundOffAmount(tempGstAmount);
                            system.debug('objBillingSummary -'+objBillingSummary);
                            system.debug('tempGstAmount -'+tempGstAmount);
                            system.debug('gstAmount -'+gstAmount);
                        }
                        if(grossAmount > 0 && discountAmount >0){
                            grossAmount =  grossAmount - discountAmount;
                        }
                    }
                    
                    if(grossAmount > 0 && gstAmount > 0 ){
                        totalAmount = BillingUtility.roundOffAmount(grossAmount + gstAmount);
                    }
                    
                }
            }
            system.debug('listOfBillSummary -'+listOfBillSummary.size());
            if(discountAmount > 0){
                discountAmount = -(BillingUtility.roundOffAmount(discountAmount));
            } 
            if(grossAmount > 0){
                grossAmount = (BillingUtility.roundOffAmount(grossAmount));
            } 
            if(gstAmount > 0){
                gstAmount = BillingUtility.roundOffAmount(gstAmount);
            } 
            system.debug('grossAmount -'+grossAmount);
            system.debug('gstAmount -'+gstAmount);
            system.debug('discountAmount -'+discountAmount);
            system.debug('totalAmount -'+totalAmount);
            this.errorCode =errorCode;
            this.errorMessage =errorMessage;
        }     
    }
    public class SubscriptionStudentWrapper{
        @AuraEnabled public Subscription_Line_Item__c objSubscriptionLineItems{get;set;}
        @AuraEnabled public List<BillingSummary> listOfBillSummary{get;set;}
        @AuraEnabled public String parentId{get;set;}
        @AuraEnabled public  decimal parenTaxRate{get;set;}
        public SubscriptionStudentWrapper(){
            objSubscriptionLineItems = new Subscription_Line_Item__c();
            listOfBillSummary = new list<BillingSummary>();
            parentId='';
        }
        public SubscriptionStudentWrapper(list<BillingSummary> listOfBillSummaries,Subscription_Line_Item__c objSubscriptionLineItem,string parentId,decimal parenTaxRate){
            listOfBillSummary = new list<BillingSummary>();
            objSubscriptionLineItems = new Subscription_Line_Item__c();
            this.parentId =parentId;
            this.objSubscriptionLineItems = objSubscriptionLineItem;
            this.listOfBillSummary = listOfBillSummaries;
            this.parenTaxRate = parenTaxRate;
        }

    }
    public class BillingSummary{
        @AuraEnabled public string studentName{get;set;}
        @AuraEnabled public string studentTempId{get;set;}
        @AuraEnabled public Decimal amount{get;set;}
        @AuraEnabled public string invoiceDate{get;set;}
        @AuraEnabled public String packageName{get;set;}
        @AuraEnabled public string packageId{get;set;}
        @AuraEnabled public Decimal discountAmount{get;set;}
        @AuraEnabled public Decimal countryTaxRate{get;set;}
        
        public BillingSummary(Decimal amount,String packageName,string studentName,string studentTempId,string packageId,decimal discountAmount,decimal countryTaxRate){
            this.amount = amount;
            this.packageName = packageName;
            this.studentName = studentName;
            this.packageId = packageId;
            this.discountAmount =  discountAmount;
            this.studentTempId = studentTempId;
            this.countryTaxRate =countryTaxRate;
        }
    }

    public class  generateInvoiceWrapper{
        @AuraEnabled public string errorCode;
        @AuraEnabled public string errorMessage;
        @AuraEnabled public string returnId;
        public generateInvoiceWrapper(string errorCode,string errorMessage,string returnId){
            this.errorCode =errorCode;
            this.errorMessage =errorMessage;
            this.returnId =returnId;
        }

        public generateInvoiceWrapper(string errorCode,string errorMessage){
            this.errorCode =errorCode;
            this.errorMessage =errorMessage;
            this.returnId = '';
            
        }
    }
}