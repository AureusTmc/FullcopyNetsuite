/*
Name        :        SubscriptionInvoicePDFControllerTest
Date        :        27 June 2019
Description :        It is the test class of SubscriptionInvoicePDFControllerClone.
*/
@isTest
public class SubscriptionInvoicePDFControllerTest {
	@isTest
    public static void invokeubscriptionInvoicePDFController(){
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
          //updated by @nishi 23 sep 2020
       
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
        
        
        Account objCustmr=TestUtil.createAccount('Customer',True,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Available_Make_up_Units__c=30;
        insert objCustmr;
		
		DateTime dt = System.today();
        
        Account objCentr=TestUtil.createAccount('Centre',false,false);
        objCentr.Phone = '123456789';
        objCentr.Country__c = country.Id;
        objCentr.Center_Email__c = 'test@test.com';
        objCentr.Website = 'www.aureusacademy.com';
        //updated by @nishi 23 sep 2020
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        
        insert objCentr;
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
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubsLine;
        
        Invoice__C objINV=TestUtil.createInvoice(objCustmr.Id,False);
        objINV.Due_Date__c=Date.today();
        objINV.Center__c = objCentr.Id;
        objINV.Status__c='Due';
        objINv.Admin_Fees__c=60;
        insert objINV;
        
        Invoice_Line_Item__c objINVline=TestUtil.createInvLineItem(objInv.Id,false);
        objINVline.Amount__c=30;
        objINVline.Discount_Amount__c=20;
        objINVline.Is_Deposit__c=false;
        objINVline.Enrolment__c=objEnrol.id;
        insert objINVline;
        
        Payment__c objpay = TestUtil.createPayment(objCustmr.Id, False);
        objPay.Invoice__c = objINV.Id;
        insert objpay;
        
        ApexPages.currentPage().getParameters().put('Id', objINV.id);
        SubscriptionInvoicePDFControllerClone subsInvoice = new SubscriptionInvoicePDFControllerClone();
    }
}