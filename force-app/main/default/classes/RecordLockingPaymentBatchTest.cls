/**
 *   Name        :    RecordLockingPaymentBatchTest
 *   Date        :    25-Sep-2020
 *   Author      :    nishi jain
 *  Description  :    This RecordLockingPaymentBatchTest class is covered PreviousMonthRecordLockingSchedular with Two batch   1) RecordLockingCreditMemoBatch and 2) RecordLockingPaymentBatch
  
 */

@isTest
private class RecordLockingPaymentBatchTest {
    @isTest
    private static void UnitTest1(){
        
        Account accoutRecord = new Account();
        accoutRecord.Name = 'TestAccount';
        Insert accoutRecord;
        
        Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = country.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        Insert organisationRecord;
        
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        objCentr.Organisation__c = organisationRecord.id;
        INSERT objCentr;
     
        
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.Country_PI__pc = 'Singapore';
        insert objCustmr;
        
        Payment__c paymentRecord = TestUtil.createPayment( objCustmr.Id,false );
        paymentRecord.Parent_Account__c = objCustmr.id;
        paymentRecord.Payment_Date__c = date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 10);
        paymentRecord.Payment_Status__c ='Success';
        paymentRecord.Locked__c = false;
        Insert paymentRecord;
        
        
        Date startDate = date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 1);
        Integer daysInMonth = Date.daysInMonth(startDate.year(), startDate.month());
        Date endDate = Date.newInstance(startDate.year(), startDate.month(), daysInMonth);
        
        Test.startTest(); 
        Database.executeBatch(new RecordLockingPaymentBatch(startDate,endDate));
        Test.stopTest();
        
        PreviousMonthRecordLockingSchedular objPriviousMonthRecordLock = new PreviousMonthRecordLockingSchedular();
        objPriviousMonthRecordLock.execute(null);
        
        
    }
    @isTest()
    private static void unitTest2(){
        Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'Singapore';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = country.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
       
        Insert organisationRecord;
        
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        objCentr.Organisation__c = organisationRecord.id;
        INSERT objCentr;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Centre_Name__c = objCentr.Id;
          
        objCustmr.Country_PI__pc = 'Singapore';
        insert objCustmr;
        
        Payment__c paymentRecord = TestUtil.createPayment( objCustmr.Id,false );
        paymentRecord.Locked__c = true;
        paymentRecord.Parent_Account__c = objCustmr.id;
        paymentRecord.Payment_Date__c = date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 10);
        paymentRecord.Payment_Status__c ='Success';
        Insert paymentRecord;
        
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',false);
        objPack.Offer_Start_Date__c = System.today();
        objPack.Offer_End_Date__c = System.today().addDays(5);
        objPack.Type_of_package__c = 'Prepayment';
        objPack.Promotion_period_In_months__c = '6';
        objPack.Promotion_Discount__c = 100.00;
        objPack.Package_Fee__c = 300.00;
        insert objPack; 
        
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack.id,False);
        objEnrol.Lesson_Day__c= /*dt.format('EEEE')*/'Saturday';
        objEnrol.Stage__c='Enrolled';
        objenrol.Student__c = objCustmr.Id;
        objenrol.Parent__c = objCustmr.Id;
        insert objEnrol;
        
        Credit_Memo__c objCreditMemo = new Credit_Memo__c();
        objCreditMemo.Center__c = objCentr.id;
        objCreditMemo.Status__c = 'Success';
        objCreditMemo.Locked__c = false;
        objCreditMemo.Parent_Account__c = objCustmr.id;
        objCreditMemo.Payment_Method__c = 'Card';
        objCreditMemo.Credit_Memo_Date__c = date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 15);
        Insert objCreditMemo ;
        
        Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today();
        objINV.Center__c = objCentr.Id;
        objINV.Status__c='Paid';
        objINv.Admin_Fees__c=60;
        objINV.Locked__c = false;
        objINV.Invoice_Date__c = date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 15);
        insert objINV;
        
        Invoice_Line_Item__c objINVline=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline.Amount__c=30;
        objINVline.Discount_Amount__c=20;
        objINVline.Is_Deposit__c=false;
        objINVline.Enrolment__c=objEnrol.id;
        objINVline.Locked__c = false;
        
        insert objINVline;
        
        
        Credit_memo_line_item__c objCreditMemoLine = new Credit_memo_line_item__c();
        objCreditMemoLine.Credit_Memo_Number__c = objCreditMemo.id;
        objCreditMemoLine.Enrolment__c = objEnrol.id;
        objCreditMemoLine.Package__c = objPack.id;
        objCreditMemoLine.Invoice_Line_Item__c = objINVline.id;
        objCreditMemoLine.Locked__c = true;
        objCreditMemoLine.Amount__c = 300;
        Insert objCreditMemoLine;
        
        
        Date startDate = date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 1);
        Integer daysInMonth = Date.daysInMonth(startDate.year(), startDate.month());
        Date endDate = Date.newInstance(startDate.year(), startDate.month(), daysInMonth);
       
        
        Test.startTest(); 
        Database.executeBatch(new RecordLockingCreditMemoBatch(startDate,endDate));
        Test.stopTest();
        
        PreviousMonthRecordLockingSchedular objPriviousMonthRecordLock1 = new PreviousMonthRecordLockingSchedular();
        objPriviousMonthRecordLock1.execute(null);
        
    }
    
    
}