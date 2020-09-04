@isTest
public class ExchangeInstrumntCLassTest {
    
    @testSetup
    public static void createData(){
        User usr = TestUtil.createUser(true);
    }
    
    public static testMethod void test1(){
        User u = [SELECT ID from User LIMIT 1];
        System.runAs(u){
            
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
            
            Organisation__c org = new Organisation__c();
            org.Sage_Company__c = 'AGP';
            org.Bank_Account_Number__c = 'er45678i';
            org.Bank_Name__c = 'test bank';
            org.Branch_Code__c = '56789';
            org.UEN__c = 'test';
            org.CPF_Advice_Code__c = 'test code';
            org.CPF_Payment_Type__c = 'test';
            org.Country__c = country.id;
            insert org;
            
           
            Account centrAcc = TestUtil.createAccount('Centre',False,true);
            centrAcc.Organisation__c = org.id;
            update centrAcc;
            
            Account cstmrAcc = TestUtil.createAccount('Customer', False, true);
            cstmrAcc.Stripe_Customer_Id__c =cstmrAcc.id;
            update cstmrAcc;
            
            Firebase_Settings__c settings = new  Firebase_Settings__c();
            settings.name = 'setting';
            settings.Enable_Notifications__c =true;
            insert settings;
            Invoice__c inv = TestUtil.createInvoice(cstmrAcc.id, true);
            inv.Invoice_Type__c = 'POS';
            inv.Status__c = 'Paid';
            inv.Customer_Name__c =cstmrAcc.id;
            inv.Center__c = centrAcc.id;
            update inv;
            Invoice_Line_Item__c invItm = TestUtil.createInvLineItem(inv.Id, true);
            
            Payment__c pymnt = TestUtil.createPayment(cstmrAcc.Id, true);
            pymnt.Payment_Status__c = 'Success';
            pymnt.RecordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment Transaction').getRecordTypeId();
            pymnt.Invoice__c = inv.id;
            update pymnt;
            
            Centre_Users__c cntrUsr = testUtil.createCentreUser(true);
            cntrUsr.User_Name__c = u.id;
            cntrUsr.Centre_Name__c = centrAcc.id;
            update cntrUsr;
            
            ExchangeInstrumntCLass.getInvoiceData(inv.id);
            ExchangeInstrumntCLass.peformActionInvoice(inv.id);
            ExchangeInstrumntCLass.reverseInvOrPayment(inv.Id, pymnt.id);
            ExchangeInstrumntCLass.getInvoiceRefundData(inv.id);
            ExchangeInstrumntCLass.performBankTrnsfrAct(inv.ID);
           
            
            inv = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,
                   Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,
                   SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,
                   Internal_Ref_No__c,SageOrderEntryKey__c,
                   (Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,
                    package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,
                    GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) 
                   from Invoice__c where Id =: inv.id];
            
            Set<String> setOfInvIds = new Set<String>();
            setOfInvIds.add(inv.Id);
            setOfInvIds.add('asdf');
            
            cntrUsr =[select Id,Centre_Name__c,Centre_Name__r.Name, Centre_Name__r.Organisation__r.Sage_Company__c 
                                                                                         from Centre_Users__c 
                                                                                         where User_Name__c=:UserInfo.getUserId()
                      AND Centre_Name__r.Organisation__r.Sage_Company__c != null];
            System.debug('cntrUsr==>'+cntrUsr);
            test.startTest();
            
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>a0P0p000000AKnAEAW</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-08-28T03:47:39-07:00</sessiontimestamp><sessiontimeout>2019-08-28T09:47:39-07:00</sessiontimeout></authentication><result><status>success</status><function>getAPISession</function><controlid>a0P0p000000AKnAEAW</controlid><data><api><sessionid>oSHwMnFypzWA7wmIPlLj332aNYHvCQ..</sessionid><endpoint>https://api.intacct.com/ia/xml/xmlgw.phtml</endpoint><locationid>AGP</locationid></api></data></result></operation></response>'));
            
            SageIntacctIntegrationUtility.sessionWrapper objnew = new SageIntacctIntegrationUtility.sessionWrapper();
            objnew.senderId='sdsd';
            objnew.senderPassword='csd';
            objnew.endPointUrl='sdd';
            objnew.sessionId='sds';
            objnew.errorMsg='dcsds';
            
             ExchangeInstrumntCLass.perfrmCardAction(inv.ID);
            ExchangeInstrumntCLass.createInvoice(objnew, inv);
            test.stopTest();
        }
    }
    
}