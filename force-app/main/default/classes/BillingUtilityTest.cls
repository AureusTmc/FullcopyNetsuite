@isTest
public class BillingUtilityTest{
    @testSetup
    private static void insertData(){
        Account acc = TestUtil.createAccount('Customer',TRUE,FALSE);
        acc.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        INSERT acc;
        
        Subscription__c subscription = testUtil.createSubscription(acc.id, true);
        subscription.Next_Bill_Date__c = system.today();
        subscription.Status__c = 'Active';
        subscription.Subscription_Start_Date__c = System.today().addMonths(-1);
        update subscription;
        
        Subscription_Line_Item__c subscriptionLineItem =  testUtil.createSubscriptionLineItem(subscription.id, False);
        subscriptionLineItem.Next_Bill_Date__c = system.today();
        subscriptionLineItem.Status__c = 'Active';
        INSERT subscriptionLineItem;
    }
  @isTest
    public static void unitTest(){
        Test.startTest();
        Account cust = [SELECT Id FROM Account WHERE RecordType.Name = 'Customer' LIMIT 1];
        Firebase_Settings__c objSetting = new Firebase_Settings__c();
        objSetting.Name = 'setting';
        objSetting.Enable_Notifications__c = false;
        insert objSetting;
        Country__c country = new Country__c(); 
        country.Name = 'IN'; 
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0; 
        country.Currency_Code__c = 'INR'; 
        country.Student_Policies_Template_Id__c = 'test'; 
        country.Stripe_Base_Url__c = 'www.test.com'; 
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede'; 
        insert country;

        Account accCentre = TestUtil.createAccount('Centre',TRUE,FALSE);
        accCentre.Country__c = country.Id;
        INSERT accCentre;
        
        Account accTecher = TestUtil.createAccount('Teacher',TRUE,TRUE);
        
        Program__c objProg = TestUtil.createProgram('Active','Piano', TRUE);
        Package__c objPack = TestUtil.createPackage(objProg.Id, accCentre.Id,'30',True);
        Enrolment__c objEnrol = TestUtil.createEnrolment(accCentre.Id,accTecher.id,cust.Id,objPack.Id,true);
         
        List<Subscription__c> subscriptionList = [Select Id,Parent__c,Parent__r.personContactId,Next_Bill_Date__c,Center__c,
                                            (Select Id,Amount__c,Enrolment__c,Plan_Package__c,Enrolment__r.Effective_Date__c,
                                            Enrolment__r.Package_Process_Type__c,Enrolment__r.Package_Process_Status__c,Enrolment__r.Lesson_day__c,
                                            Enrolment__r.New_Package_Id__c,Enrolment__r.Package_Process_Request_Date__c,
                                            Enrolment__r.New_Package_Id__r.Deposit_Fee__c,Enrolment__r.New_Package_Id__r.Unit_Fee__c,
                                            Enrolment__r.Package__c,
                                            Enrolment__r.Package__r.Deposit_Fee__c,Enrolment__r.Package__r.Unit_Fee__c,
                                            Next_Bill_Date__c 
                                             FROM Subscription_Line_Items__r 
                                             WHERE Status__c=:ConstantsClass.activeStatus AND Next_Bill_Date__c <=:system.today()) 
                                        FROM Subscription__c 
                                        WHERE Status__c=:ConstantsClass.activeStatus and Parent__c!=null 
                                        AND Subscription_Start_Date__c<=:system.today() 
                                        AND Next_Bill_Date__c <=:system.today()];
        
        //BillingUtility.createInvoiceFromSubscription(subscriptionList,null);
        
        //Added on 26 June 2019 by Karan ################################
         Invoice__C objInv1=Testutil.createInvoice(cust.Id,False);
        objInv1.Center__c = accCentre.Id;
        insert objInv1;
        String strRecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get(ConstantsClass.paymentAsDepositRecordType).getRecordTypeId();
        Payment__c objPay = TestUtil.createPayment(cust.Id, FALSE);
        objPay.Payment_Status__c = 'Pending';
        objPay.RecordTypeId = strRecordTypeId;
        objPay.Payment_Amount__c = 200;
		objPay.Payment_Date__c= date.today();
        INSERT objPay;
            BillingUtility.createInvoiceFromSubscription(subscriptionList, objInv1.id, date.today());
        //BillingUtility.getParentPayments(new set<String>{objPay.Id}, 'creditNote', date.today(), date.today());
        try{
        BillingUtility.sendDeclinedMail(new List<Invoice__c>{objInv1}, '3');    
        }catch(Exception e){}
        
        BillingUtility.invoiceWrapper objWrap = new BillingUtility.invoiceWrapper();
        BillingUtility.createAttachment(new set<String>{objInv1.Id});
         //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        //BillingUtility.getCustomerWithCard(cust.Id);
        //###############################################################
        List<Invoice__c> invoiceList = [Select Id,Name,Parent_Account__c,Center__r.Location__c,Total_Amount__c,Parent_Account__r.personContactId from Invoice__c];
        
        BillingUtility.emailInvoiceToParent(invoiceList);
        BillingUtility.createInvoiceAttachment(invoiceList);
        Set<String> invoiceIdSet = new Set<String>();
        for(Invoice__c objInv : invoiceList){
            invoiceIdSet.add(objInv.id);
        }
        BillingUtility.getCountryMap(country.Id);
        BillingUtility.getCountryMap('');
        BillingUtility.invoiceAttWithFuture(invoiceIdSet);
        /*BillingUtility.sendDeclinedMail(invoiceList, 'Declined');
        BillingUtility.sendDeclinedMail(invoiceList, '3');
        BillingUtility.sendDeclinedMail(invoiceList, '5');
        BillingUtility.sendDeclinedMail(invoiceList, '7');*/
        
        BillingUtility.createPaymentusingInvoice(invoiceList);
        BillingUtility.fillSubscription(invoiceList[0].Parent_Account__c,'Active',System.today());
        BillingUtility.fillSubscriptionLineItem(invoiceList[0].Parent_Account__c,subscriptionList[0].Id,objPack.id,objEnrol.id,50,'Active');
        BillingUtility.fillPayment(invoiceList[0].Parent_Account__c,invoiceList[0].Id,53,'Success');
        BillingUtility.fillEnrolment(cust.Id,cust.Id,accCentre.Id,accTecher.Id,objPack.Id,System.today(),Time.newInstance(18, 30, 0,0 )
,'Enrolled');
        //fillEnrolment(String parId, String stuId, String centerId, String tchrId, String pckgId, Date lessStDate, Time lessStTime,'Enrolled')
        
        BillingUtility.fillInvLnItm(invoiceList[0].Id,objEnrol.id,subscriptionList[0].Subscription_Line_Items__r[0].Id ,50,'aa','');
        Set<String> setOfStudent = new Set<String>();
        setOfStudent.add(invoiceList[0].Parent_Account__c);
        BillingUtility.rollUpMakeupCredits(setOfStudent);
        BillingUtility.getInvoiceLineItemEnrollmentIds(invoiceIdSet);
        BillingUtility.roundOffAmount(12.3457654);
        Test.stopTest();
    }
    
    @isTest
    private static void unitTest1(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        
        BillingUtility.createStripeCustomer('Test','TMC','tmc@gmail.com','test', 'www.google.com', '2135');
        BillingUtility.createChargeForCustomer('Test',500,'SGD', 'www.google.com', '2135'); 
        BillingUtility.createChargeForCustomerWithInvoice('Test',500,'SGD','INV-120', 'www.google.com', '2135');
        BillingUtility.createOneTimeCharge('Test',500,'SGD', 'www.google.com', '2135'); 
        BillingUtility.AddCardWithCustomer('Test','xyz', 'www.google.com', '2135'); 
        BillingUtility.setDefaultCard('Test','xyz', 'www.google.com', '2135');
        BillingUtility.updateCharge('test','inv 120', 'www.google.com', '2135'); 
        BillingUtility.createBatchLog('Test',System.now(),System.now(),20);
        BillingUtility.calculateCurrentMonthPckFees(System.today(),52);
        Test.stopTest();
    }
    @isTest
    private static void unitTest2(){
        BillingUtility.roundOffAmount(10.21);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        BillingUtility.createRefundForCharge('ch_1AxWbTFytruJp2FXW6iuRd1X',150, 'www.google.com', '2135');
        Test.stopTest();       
    }
    @isTest
    private static void unitTest3(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        BillingUtility.updateCard('ch_1AxWbTFytruJp2FXW6iuRd1X','xxxxxxxx','June','2015', 'www.google.com', '2135');
        Test.stopTest();
    }
    
    @isTest
    private static void unitTest4(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        BillingUtility.getCustomerWithCard('ch_1AxWbTFytruJp2FXW6iuRd1X','www.google.com', '2135');
        Test.stopTest();       
    }
}