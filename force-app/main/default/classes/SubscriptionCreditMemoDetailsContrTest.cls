/**
 *   Name        :    SubscriptionCreditMemoDetailsContrTest
 *   Date        :    26-Sep-2020
 *   Author      :    nishi jain
 *  Description  :    This SubscriptionCreditMemoDetailsContrTest class is covered SubscriptionCreditMemoDetailsController
  
 */

@isTest
private class SubscriptionCreditMemoDetailsContrTest {
    @isTest
    private static void testUnit1(){
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
        objCentr.GST_Number__c = '23456789';
       // objCentr.PersonEmail = 'Test@gmail.com';
       // objCentr.personMobilePhone = '1234567890';
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.GST_Number__c = '12345678';
        objCentr.Phone ='1234567890';
        objCentr.Center_Email__c =  'Test@gmail.com';
        objCentr.Website = 'www.test.com';
        INSERT objCentr;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Centre_Name__c = objCentr.Id;
        objCustmr.Card_Number__c = '1234';
        objCustmr.Country_PI__pc = 'Singapore';
        //objCustmr.Person_Email__c ='Test@gmail.com';
        objCustmr.Admin_Fees__c = '1';
        
        //objCustmr.personMobilePhone = '1234567890';
        insert objCustmr;
        
        Payment__c paymentRecord = TestUtil.createPayment( objCustmr.Id,false );
        paymentRecord.Parent_Account__c = objCustmr.id;
        paymentRecord.Payment_Date__c = date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 10);
        paymentRecord.Payment_Status__c ='Success';
        paymentRecord.Locked__c = false;
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
        objenrol.Teacher__c = objTchr.id;
        
        insert objEnrol;
           
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
        Stripe_Payout_Log__c objStripe = new Stripe_Payout_Log__c();
        objStripe.Stripe_Payout_Id__c = 'Test';
        Insert objStripe;
        
        
        Credit_Memo__c objCreditMemo = new Credit_Memo__c();
        objCreditMemo.Center__c = objCentr.id;
        objCreditMemo.Status__c = 'Success';
        objCreditMemo.Locked__c = false;
        objCreditMemo.Parent_Account__c = objCustmr.id;
        objCreditMemo.Payment_Method__c = 'Card';
        objCreditMemo.Credit_Memo_Date__c = system.today();//date.newInstance(system.today().addMonths(-1).year(), system.today().addMonths(-1).month(), 15);
        objCreditMemo.Invoice_Number__c = objINV.id;
        objCreditMemo.Refund_ID__c = 'Test';
        objCreditMemo.Stripe_Fee__c = 200;
        objCreditMemo.Field_1__c = 'Testfield';
        objCreditMemo.Comments__c = 'TestComment';
        objCreditMemo.Stripe_Payout_Id__c = objStripe.id;
        objCreditMemo.Cheque_Date__c = system.today();
        objCreditMemo.Cheque_No__c = '123456789';
        objCreditMemo.NETS_Code__c = '2345678';
       
        Insert objCreditMemo ;
                
        Credit_memo_line_item__c objCreditMemoLine = new Credit_memo_line_item__c();
        objCreditMemoLine.Credit_Memo_Number__c = objCreditMemo.id;
        objCreditMemoLine.Package__c = objPack.id;
        objCreditMemoLine.Invoice_Line_Item__c = objINVline.id;
        objCreditMemoLine.Locked__c = true;
        objCreditMemoLine.Enrolment__c = objEnrol.id;
        objCreditMemoLine.Amount__c = 300;
        objCreditMemoLine.Remarks__c = 'TestRemarks';
        //objCreditMemoLine.Month__c = (System.today()).month();
        objCreditMemoLine.Is_Deposit__c = true;
        objCreditMemoLine.Is_Discount__c = true;
        objCreditMemoLine.Field_1__c = 'Test';
       // Invoice_Line_Item__c
        Insert objCreditMemoLine;
        
        PageReference pageRef = Page.SubscriptionCreditMemoDetailsPdf; // Add your VF page Name here
        pageRef.getParameters().put('Id',objCreditMemo.id);
        Test.setCurrentPage(pageRef);
        
        SubscriptionCreditMemoDetailsController obj = new SubscriptionCreditMemoDetailsController();
    }

}