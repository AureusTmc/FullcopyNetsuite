@isTest
public class PosHomeComponentCntrlTest {
    
    @testSetup
    public static void createData(){
        User usr = TestUtil.createUser(true);
        Account acc = TestUtil.createAccount('Centre',False,true);
        System.debug('accid==>'+acc.id);
        Account acc2 =  TestUtil.createAccount('Customer',False,true);
        Account acc3 =  TestUtil.createAccount('Teacher',False,true);
        Centre_Users__c cntrUsr = TestUtil.createCentreUser(true);
        Payment__c pymnt = TestUtil.createPayment(acc2.id, true);
        Invoice__c inv = TestUtil.createInvoice(acc2.id, true);
    }
    
    
    public static testMethod void test1(){
        User u = [SELECT ID from User LIMIT 1];
        System.runAs(u){
            
            Organisation__c org = new Organisation__c();
            org.Sage_Company__c = 'AGP';
            org.Bank_Account_Number__c = 'er45678i';
            org.Bank_Name__c = 'test bank';
            org.Branch_Code__c = '56789';
            org.UEN__c = 'test';
            org.CPF_Advice_Code__c = 'test code';
            org.CPF_Payment_Type__c = 'test';
            insert org;
            
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
            
            Account acc = [SELECT ID from Account WHERE RecordType.name= 'Centre' LIMIT 1];
            acc.Country__c = country.id;
            acc.Organisation__c = org.id;
            update acc;
            Account acc2 = [SELECT ID from Account WHERE RecordType.name = 'Customer' LIMIT 1]; 
            acc2.Stripe_Customer_Id__c = acc2.id;
            update acc2;
            
            Invoice__c inv = [SELECT ID FROM Invoice__c LIMIT 1];
            inv.Invoice_Date__c = date.today();
            inv.Center__c= acc.id;
            update inv;
            
            Payment__c pymnt = [SELECT ID FROM Payment__c LIMIT 1]; 
            pymnt.recordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
            pymnt.Payment_Status__c = 'Pending';
            pymnt.Payment_Amount__c =10000;
            update pymnt;
            Centre_Users__c cusr = [SELECT ID FROM Centre_Users__c];
            cusr.User_Name__c = u.id;
            cusr.Centre_Name__c = acc.id;
            update cusr;
            
            
            
            Adhoc_POS_Services__c ps = new Adhoc_POS_Services__c ();
            ps.Status__c = 'Active';
            ps.Country__c = country.id;
            insert ps;
            PosHomeComponentCntrl.getCenters(); 
            PosHomeComponentCntrl.getPocAdhocServicesNames(acc.id);
            PosHomeComponentCntrl.getAdhocPOSServicesList(ps.Id);
            //PosHomeComponentCntrl.getRecords('', '', '', '', '',2);
            PosHomeComponentCntrl.getSageProductItems();
            PosHomeComponentCntrl.insrtCstmr(acc2,true);
            PosHomeComponentCntrl.linkDummyCstmr();
            PosHomeComponentCntrl.checkCstmrCard(acc2.id);
            PosHomeComponentCntrl.SageProductItems posHmWrppr = new  PosHomeComponentCntrl.SageProductItems();
            posHmWrppr.recNo = '2';
            posHmWrppr.quantity = '10';
            posHmWrppr.price= 50;
            
            System.debug('acc==>'+acc);
            System.debug('acc2==>'+acc2);
            PosHomeComponentCntrl.payAndRedirect(acc.id, acc2.id, 'Card', new List< PosHomeComponentCntrl.SageProductItems>{ posHmWrppr});
            // PosHomeComponentCntrl.sendPaymentCollectionEmail('','','');
            PosHomeComponentCntrl.pushInvoiceToSage(inv.id,acc2.id,'');
            SageIntacctIntegrationUtility.sessionWrapper sw = new  SageIntacctIntegrationUtility.sessionWrapper();
            
            inv = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,
                   Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,
                   SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,
                   Internal_Ref_No__c,SageOrderEntryKey__c,
                   (Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,
                    package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,
                    GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) 
                   from Invoice__c where Id =: inv.id];
            PosHomeComponentCntrl.createInvoice(sw,inv,'');
        }
    }
    public static testMethod void test2(){
        User u = [SELECT ID from User LIMIT 1];
        Sage_Intacct_Credentials__c objSage_Intacct_Credentials = new Sage_Intacct_Credentials__c(name ='Aureus Group-imp',Endpoint__c='https://api.intacct.com/ia/xml/xmlgw.phtml',
                                                                                                  Sender_ID__c	='Aureus Group',Sender_Password__c='AureusTMC9012!',
                                                                                                  Webservice_User_ID__c='ws_tek',Webservice_User_Password__c='2If2hvQ9M#Z');
        insert objSage_Intacct_Credentials;
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
            
            Account acc = [SELECT ID,Location__c from Account WHERE RecordType.name= 'Centre' LIMIT 1];
            acc.Country__c = country.id;
            acc.Organisation__c = org.id;
            update acc;
            Account acc2 = [SELECT ID,PersonEmail, PersonContactId, Stripe_Customer_Id__c, Total_Payment_Credit_Available__c, MovedToSage__c, SageCustomerKey__c, 
                            Sage_Error_Message__c, Centre_Name__r.Organisation__r.Sage_Company__c  from Account WHERE RecordType.name = 'Customer' LIMIT 1]; 
            acc2.Stripe_Customer_Id__c = acc2.id;
            update acc2;
            Account acc3 = [SELECT ID from Account WHERE RecordType.name= 'Teacher' LIMIT 1];
            Invoice__c inv = [SELECT ID FROM Invoice__c LIMIT 1];
            inv.Invoice_Date__c = date.today();
            inv.Center__c= acc.id;
            update inv;
            
            Payment__c pymnt = [SELECT ID FROM Payment__c LIMIT 1]; 
            pymnt.recordTypeId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
            pymnt.Payment_Status__c = 'Pending';
            pymnt.Payment_Amount__c =10;
            update pymnt;
            Centre_Users__c cusr = [SELECT ID FROM Centre_Users__c];
            cusr.User_Name__c = u.id;
            cusr.Centre_Name__c = acc.id;
            update cusr;
            Program__C objProg=TestUtil.createProgram('Active','Piano',true);
            Package__c objPack=testUtil.createPackage(objProg.id,acc.id,'45',true); 
            Enrolment__c objENrol=TestUtil.createEnrolment(acc.Id,acc3.Id,acc2.Id,objPack.id,false);
            objENrol.Parent__c = acc2.Id;
            objENrol.Lesson_Day__c = 'Tuesday';
            insert objENrol;
            List<Invoice_Line_Item__c> listOfInvoice_Line_Item = new List<Invoice_Line_Item__c>();
            listOfInvoice_Line_Item.add(AureusCalendarControllerTestHelper.createInvLineItem(inv.id,10,acc3.id,date.today().addDays(2),objENrol.id,null,objPack.id,1.00,false));
            insert listOfInvoice_Line_Item;  
            
            
            Adhoc_POS_Services__c ps = new Adhoc_POS_Services__c ();
            ps.Status__c = 'Active';
            ps.Country__c = country.id;
            insert ps;
            PosHomeComponentCntrl.getCenters(); 
            PosHomeComponentCntrl.getPocAdhocServicesNames(acc.id);
            PosHomeComponentCntrl.getAdhocPOSServicesList(ps.Id);
            PosHomeComponentCntrl.getSageProductItems();
            PosHomeComponentCntrl.insrtCstmr(acc2,true);
            PosHomeComponentCntrl.linkDummyCstmr();
            PosHomeComponentCntrl.checkCstmrCard(acc2.id);
            PosHomeComponentCntrl.SageProductItems posHmWrppr = new  PosHomeComponentCntrl.SageProductItems();
            posHmWrppr.recNo = '2';
            posHmWrppr.quantity = '10';
            posHmWrppr.price= 50;
            
            System.debug('acc==>'+acc);
            System.debug('acc2==>'+acc2);
            PosHomeComponentCntrl.payAndRedirect(acc.id, acc2.id, 'Online email', new List< PosHomeComponentCntrl.SageProductItems>{ posHmWrppr});
            PosHomeComponentCntrl.sendPaymentCollectionEmail(acc2.PersonContactId,inv.id,acc.Location__c);
            PosHomeComponentCntrl.pushInvoiceToSage(inv.id,acc2.id,'');
            SageIntacctIntegrationUtility.sessionWrapper objnew = new SageIntacctIntegrationUtility.sessionWrapper();
            objnew.senderId='sdsd';
            objnew.senderPassword='csd';
            objnew.endPointUrl='sdd';
            objnew.sessionId='sds';
            objnew.errorMsg='dcsds';
            
            //PosHomeComponentCntrl.SageWarehouseDetails sgWrap = new PosHomeComponentCntrl.SageWarehouseDetails(acc.id,acc.id,acc.id,2,45);
            
            inv = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,
                   Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,
                   SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,
                   Internal_Ref_No__c,SageOrderEntryKey__c,
                   (Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,
                    package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,
                    GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) 
                   from Invoice__c where Id =: inv.id];
            PosHomeComponentCntrl.createInvoice(objnew,inv,'');
            PosHomeComponentCntrl.getRecords('test','Account','Id','Name','',10);
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>a0P0p000000AKnAEAW</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><data><itemwarehouseinfo><RECORDNO>1</RECORDNO></itemwarehouseinfo><api><sessionid>oSHwMnFypzWA7wmIPlLj332aNYHvCQ..</sessionid><endpoint>https://api.intacct.com/ia/xml/xmlgw.phtml</endpoint><locationid>AGP</locationid></api></data><locationid>AGP</locationid><sessiontimestamp>2019-08-28T03:47:39-07:00</sessiontimestamp><sessiontimeout>2019-08-28T09:47:39-07:00</sessiontimeout> </authentication><result><status>success</status><function>getAPISession</function><controlid>a0P0p000000AKnAEA</result></operation></response>'));
            PosHomeComponentCntrl.getSageProductItemWareHouseDetails(posHmWrppr);
            test.stopTest();
        }
        
    }
    
    
    public static testMethod void test3(){
        Country__c country = new Country__c();
        country.Name = 'SGD';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        country.Stripe_Base_Url__c ='https://api.stripe.com';
        country.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        country.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
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
        
        Account acc = [SELECT ID,Location__c from Account WHERE RecordType.name= 'Centre' LIMIT 1];
        acc.Country__c = country.id;
        acc.Organisation__c = org.id;
        update acc;
        Account acc2 = [SELECT ID,PersonEmail, PersonContactId, Stripe_Customer_Id__c, Total_Payment_Credit_Available__c, MovedToSage__c, SageCustomerKey__c, 
                        Sage_Error_Message__c, Centre_Name__r.Organisation__r.Sage_Company__c  from Account WHERE RecordType.name = 'Customer' LIMIT 1]; 
        acc2.Stripe_Customer_Id__c = acc2.id;
        update acc2;
        
        PosHomeComponentCntrl.SageProductItems posHmWrppr = new  PosHomeComponentCntrl.SageProductItems();
        posHmWrppr.recNo = '2';
        posHmWrppr.quantity = '10';
        posHmWrppr.price= 50;
        Account accTest = new Account(firstname ='test',lastname ='test');
        PosHomeComponentCntrl.insrtCstmr(accTest,false);
        acc2.FirstName ='';
        acc2.lastName = Label.WalkInCstmr;
        update acc2;
        PosHomeComponentCntrl.insrtCstmr(acc2,true);
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        PosHomeComponentCntrl.payAndRedirect(acc.id, acc2.id, 'Card', new List< PosHomeComponentCntrl.SageProductItems>{ posHmWrppr});
        PosHomeComponentCntrl.SageWarehouseDetails objSageWarehouseDetails = new PosHomeComponentCntrl.SageWarehouseDetails();
        objSageWarehouseDetails.recNo = '1';
        objSageWarehouseDetails.wareHouseId = '1';
        objSageWarehouseDetails.itemiD = '1';
        objSageWarehouseDetails.avlailbleQntity = 1;
        objSageWarehouseDetails.price = 10;
        
        test.stopTest();
        
    }
    
}