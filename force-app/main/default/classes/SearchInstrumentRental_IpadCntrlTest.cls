@isTest
public class SearchInstrumentRental_IpadCntrlTest {
    
    
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
            
            Country__c country2 = new Country__c();
            country2.Name = 'SG';
            country2.Country_Name__c = 'India';
            country2.Tax_Rate__c = 7.0;
            country2.Currency_Code__c = 'SGD';
            country2.Student_Policies_Template_Id__c = 'test';
            country2.Stripe_Base_Url__c = 'www.test.com';
            country2.Stripe_Publishable_Key__c = 'ABC';
            country2.Stripe_Secret_Key__c = 'deede';
            insert country2;
            
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
            centrAcc.Country__c = country.id;
            centrAcc.CentreName_Cust__c = 'Aureus Academy - Northpoint South W (#02-179/180)';
            update centrAcc;
            
            Account cstmrAcc = TestUtil.createAccount('Customer', False, true);
            cstmrAcc.Stripe_Customer_Id__c =cstmrAcc.id;
            cstmrAcc.PersonEmail = 's@g.com';
            cstmrAcc.Card_Number__c='818';
            cstmrAcc.Card_Type__c='Visa';
            cstmrAcc.BillingCountryCode = 'SG';
            update cstmrAcc;
            
            Account objTeacher=TestUtil.createAccount('Teacher',False,true);
            objTeacher.Job_Title__c = 'Sales Executive';
            update objTeacher;
            
            Centre_Users__c cntrUsr = testUtil.createCentreUser(true);
            cntrUsr.User_Name__c = u.id;
            cntrUsr.Centre_Name__c = centrAcc.id;
            update cntrUsr;
            
            Program__c pgm = TestUtil.createProgram('Active', 'Music Exploration', true);
            
            Package__c pack=new Package__c();
            pack.Name='Piano';
            pack.Program__c=pgm.Id;
            pack.Duration__c='30';
            pack.Package_Fee__c=05.00;
            pack.Active__c=true;
            pack.Unit_Fee__c=05.00;
            pack.Registration_Fee__c=08.00;
            pack.Deposit_Fee__c=08.00;
            insert pack;
            
            Enrolment__c enrl = testUtil.createEnrolment(centrAcc.id, objTeacher.id, cstmrAcc.id, pack.id, true);
            enrl.name = 'test'; 
            enrl.Trial_Date__c = date.today();
            enrl.Type__c='Instrument';
            enrl.Parent__c = cstmrAcc.id;
            enrl.Stage__c='Piano Viewing Completed';
            enrl.Center__c = centrAcc.id;
            
            update enrl; 
            
            
            
            SearchInstrumentRental_IpadCntrl srchIns = new SearchInstrumentRental_IpadCntrl();
            srchIns.GetToday =date.today();
            srchIns.getCenters();
            srchIns.getPaymentTypePicklist();
            srchIns.getSampleController();
            srchIns.getType();
            srchIns.getEnrolments();
            srchIns.parentAcc =  cstmrAcc;
            SearchInstrumentRental_IpadCntrl.fetchEnrolments('test', 'SGD');
            srchIns.slcdEnrolment = enrl;
            srchIns.isRentalOrSellType = 'Rent';
            Booking__c bkng = new Booking__c();
            bkng.Enrolment__c = srchIns.slcdEnrolment.id;
            bkng.Type__c = 'Trial';
            bkng.Status__c ='Canceled';
            insert bkng;
            
            
            Subscription__C sub = TestUtil.createSubscription(cstmrAcc.id,true);
            sub.Center__c = srchIns.slcdEnrolment.Center__c;
            sub.Status__c = 'Active';
            sub.Parent__c =  srchIns.parentAcc.id;
            update sub;
            srchIns.SaveAndCompleteProcessViaReferenceId();
            SearchInstrumentRental_IpadCntrl.FeeModel fm = new SearchInstrumentRental_IpadCntrl.FeeModel();
            fm.instrumentChrg=4;
            fm.depFee=4;
            fm.deliCharges=5;
            fm.tuningFee=6;
            fm.stairDelCharges=5;
            fm.heatingRodInsFee=5;
            
            srchIns.slcdEnrId=enrl.id;
            srchIns.procssSlcdEnrolment();
            srchIns.nextBtnCmp1();
            srchIns.backBtnCmp2();
            srchIns.backBtnCmp3();
            srchIns.backBtnCmp4();
            // srchIns.nextBtnCmp3();
            srchIns.slcdSlot='12-12000';
            srchIns.htmtxt='22@@22';
            srchIns.slcdSlotDate = System.today().format();
            srchIns.setSlots();
            srchIns.detSlots();
            srchIns.GetToday=date.today();
            srchIns.addDate();
            srchIns.subDate();
            srchIns.prcToRental();
            srchIns.prcToSell();
            srchIns.nextWeek();
            srchIns.prevWeek();
            srchIns.updateCstmrDetail();
            srchIns.getCountries();
            srchIns.SaveAndCompleteProcessViaReferenceId();
            srchIns.nextBtnCmp3();
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201,'{ "id": "R33xS4Ybe3qtBbRyke2p6a", "name": "[DEV] Enr-13456-RentalPolicy", "date_created": "2020-01-22T08:20:58.179132Z", "date_modified": "2020-01-22T08:20:58.652923Z", "template": { "id": "5jfk4yvnNWaqsjmg4tdnbm", "name": "Delivery Order Template" }, "tokens": [{ "name": "Delivery_Person.FirstName" }], "fields": [{ "uuid": "NmobNHTwG6fdu5bVcnAUbZ", "name": "Stairs", "title": "Stairs", "assigned_to": { "id": "QpQRqhYV4k9K95kAqrgaof", "first_name": "Ashish", "last_name": "Bansal", "email": "ashish@outlook.com", "recipient_type": "signer", "has_completed": false, "role": "Delivery_Person", "type": "recipient" }, "value": "0" }] }'));
            PandaDocUtility.viewDocumentDetails('R33xS4Ybe3qtBbRyke2p6a','stairs');
            PandaDocUtility.CreateDocument documentDetails = new PandaDocUtility.CreateDocument();
            documentDetails.id = 'R33xS4Ybe3qtBbRyke2p6a';
            srchIns.signAgreement();
            srchIns.waitAgreement();
            srchIns.sendAgreement();
            srchIns.parentAcc.id = cstmrAcc.id;
            srchIns.parentAcc.personemail= cstmrAcc.PersonEmail;
            srchIns.createSession();
            srchIns.createSessForAureusGrp();
            //Test.stopTest();
            
            Postal_code__c pc = new Postal_code__c();
            pc.Country__c = country2.id;
            pc.Name = '426731';
            insert pc;
            string postalCode = Apexpages.currentPage().getParameters().put('postalCode','426731');
            srchIns.fetchFullAddress();
            Test.stopTest();
            
        }
    }
    
    public static testMethod void test2(){
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
            
            Country__c country2 = new Country__c();
            country2.Name = 'SG';
            country2.Country_Name__c = 'India';
            country2.Tax_Rate__c = 7.0;
            country2.Currency_Code__c = 'SGD';
            country2.Student_Policies_Template_Id__c = 'test';
            country2.Stripe_Base_Url__c = 'www.test.com';
            country2.Stripe_Publishable_Key__c = 'ABC';
            country2.Stripe_Secret_Key__c = 'deede';
            insert country2;
            
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
            centrAcc.Country__c = country.id;
            centrAcc.CentreName_Cust__c = 'Aureus Academy - Northpoint South W (#02-179/180)';
            update centrAcc;
            
            Account cstmrAcc = TestUtil.createAccount('Customer', False, true);
            cstmrAcc.Stripe_Customer_Id__c =cstmrAcc.id;
            cstmrAcc.PersonEmail = 's@g.com';
            cstmrAcc.Card_Number__c='818';
            cstmrAcc.Card_Type__c='Visa';
            cstmrAcc.BillingCountryCode = 'SG';
            update cstmrAcc;
            
            Account objTeacher=TestUtil.createAccount('Teacher',False,true);
            objTeacher.Job_Title__c = 'Sales Executive';
            update objTeacher;
            
            Centre_Users__c cntrUsr = testUtil.createCentreUser(true);
            cntrUsr.User_Name__c = u.id;
            cntrUsr.Centre_Name__c = centrAcc.id;
            update cntrUsr;
            
            Program__c pgm = TestUtil.createProgram('Active', 'Music Exploration', true);
            
            Package__c pack=new Package__c();
            pack.Name='Piano';
            pack.Program__c=pgm.Id;
            pack.Duration__c='30';
            pack.Package_Fee__c=05.00;
            pack.Active__c=true;
            pack.Unit_Fee__c=05.00;
            pack.Registration_Fee__c=08.00;
            pack.Deposit_Fee__c=08.00;
            insert pack;
            
            Enrolment__c enrl = testUtil.createEnrolment(centrAcc.id, objTeacher.id, cstmrAcc.id, pack.id, true);
            enrl.name = 'test'; 
            enrl.Trial_Date__c = date.today();
            enrl.Type__c='Instrument';
            enrl.Parent__c = cstmrAcc.id;
            enrl.Stage__c='Piano Viewing Completed';
            enrl.Center__c = centrAcc.id;
            
            update enrl; 
            
            
            
            SearchInstrumentRental_IpadCntrl srchIns = new SearchInstrumentRental_IpadCntrl();
            srchIns.GetToday =date.today();
            srchIns.getCenters();
            srchIns.getPaymentTypePicklist();
            srchIns.getSampleController();
            srchIns.getType();
            srchIns.getEnrolments();
            srchIns.parentAcc =  cstmrAcc;
            SearchInstrumentRental_IpadCntrl.fetchEnrolments('test', 'SGD');
            srchIns.slcdEnrolment = enrl;
            srchIns.isRentalOrSellType = 'Rent';
            Booking__c bkng = new Booking__c();
            bkng.Enrolment__c = srchIns.slcdEnrolment.id;
            bkng.Type__c = 'Trial';
            bkng.Status__c ='Canceled';
            insert bkng;
            
            
            Subscription__C sub = TestUtil.createSubscription(cstmrAcc.id,true);
            sub.Center__c = srchIns.slcdEnrolment.Center__c;
            sub.Status__c = 'Active';
            sub.Parent__c =  srchIns.parentAcc.id;
            update sub;
            srchIns.SaveAndCompleteProcessViaReferenceId();
            SearchInstrumentRental_IpadCntrl.FeeModel fm = new SearchInstrumentRental_IpadCntrl.FeeModel();
            fm.instrumentChrg=4;
            fm.depFee=4;
            fm.deliCharges=5;
            fm.tuningFee=6;
            fm.stairDelCharges=5;
            fm.heatingRodInsFee=5;
            
            srchIns.slcdEnrId=enrl.id;
            srchIns.procssSlcdEnrolment();
            srchIns.nextBtnCmp1();
            srchIns.backBtnCmp2();
            srchIns.backBtnCmp3();
            srchIns.backBtnCmp4();
            // srchIns.nextBtnCmp3();
            srchIns.slcdSlot='12-12000';
            srchIns.htmtxt='22@@22';
            srchIns.slcdSlotDate = System.today().format();
            srchIns.setSlots();
            srchIns.detSlots();
            srchIns.GetToday=date.today();
            srchIns.isAlreadyStripCstmr =true;
            
            
            test.startTest();
            Account customer = TestUtil.createAccount('Customer',TRUE,TRUE);
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"Paid": "succeeded","Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
            EnrollmentProcessErrorLogs.errorLogObj logObj = new EnrollmentProcessErrorLogs.errorLogObj();
            logObj.customerSalesforceId= customer.id;
            logObj.customerStripeId = 'cus_123';
            logObj.stripeTransactionId='xyz';
            logObj.stripeChargeAmount=10.50;
            logObj.exceptionMessage='test error';
            EnrollmentProcessErrorLogs.generateErrorLogsAndRefundAmount(JSON.serialize(logObj));
            srchIns.saveAndCompleteProcess();
            test.stopTest();
        }
        
        
    }
    
    public static testMethod void test3(){
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
            
            Country__c country2 = new Country__c();
            country2.Name = 'SG';
            country2.Country_Name__c = 'India';
            country2.Tax_Rate__c = 7.0;
            country2.Currency_Code__c = 'SGD';
            country2.Student_Policies_Template_Id__c = 'test';
            country2.Stripe_Base_Url__c = 'www.test.com';
            country2.Stripe_Publishable_Key__c = 'ABC';
            country2.Stripe_Secret_Key__c = 'deede';
            insert country2;
            
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
            centrAcc.Country__c = country.id;
            centrAcc.CentreName_Cust__c = 'Aureus Academy - Northpoint South W (#02-179/180)';
            update centrAcc;
            
            Account cstmrAcc = TestUtil.createAccount('Customer', False, true);
            cstmrAcc.Stripe_Customer_Id__c ='';
            cstmrAcc.PersonEmail = 's@g.com';
            cstmrAcc.Card_Number__c='818';
            cstmrAcc.Card_Type__c='Visa';
            cstmrAcc.BillingCountryCode = 'SG';
            update cstmrAcc;
            
            Account objTeacher=TestUtil.createAccount('Teacher',False,true);
            objTeacher.Job_Title__c = 'Sales Executive';
            update objTeacher;
            
            Centre_Users__c cntrUsr = testUtil.createCentreUser(true);
            cntrUsr.User_Name__c = u.id;
            cntrUsr.Centre_Name__c = centrAcc.id;
            update cntrUsr;
            
            Program__c pgm = TestUtil.createProgram('Active', 'Music Exploration', true);
            
            Package__c pack=new Package__c();
            pack.Name='Piano';
            pack.Program__c=pgm.Id;
            pack.Duration__c='30';
            pack.Package_Fee__c=05.00;
            pack.Active__c=true;
            pack.Unit_Fee__c=05.00;
            pack.Registration_Fee__c=08.00;
            pack.Deposit_Fee__c=08.00;
            insert pack;
            
            Enrolment__c enrl = testUtil.createEnrolment(centrAcc.id, objTeacher.id, cstmrAcc.id, pack.id, true);
            enrl.name = 'test'; 
            enrl.Trial_Date__c = date.today();
            enrl.Type__c='Instrument';
            enrl.Parent__c = cstmrAcc.id;
            enrl.Stage__c='Piano Viewing Completed';
            enrl.Center__c = centrAcc.id;
            
            update enrl; 
            
            SearchInstrumentRental_IpadCntrl srchIns = new SearchInstrumentRental_IpadCntrl();
            srchIns.isAlreadyStripCstmr =true;
            srchIns.procssSlcdEnrolment();
            srchIns.customerRefId='';
            srchIns.paymentType='';
            test.startTest();
            SageIntacctIntegrationUtility.sessionWrapper objnew = new SageIntacctIntegrationUtility.sessionWrapper();
            objnew.senderId='sdsd';
            objnew.senderPassword='csd';
            objnew.endPointUrl='sdd';
            objnew.sessionId='sds';
            objnew.errorMsg='dcsds';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>a0P0p000000AKnAEAW</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-08-28T03:47:39-07:00</sessiontimestamp><sessiontimeout>2019-08-28T09:47:39-07:00</sessiontimeout></authentication><result><status>success</status><function>getAPISession</function><controlid>a0P0p000000AKnAEAW</controlid><data><api><sessionid>oSHwMnFypzWA7wmIPlLj332aNYHvCQ..</sessionid><endpoint>https://api.intacct.com/ia/xml/xmlgw.phtml</endpoint><locationid>AGP</locationid></api></data></result></operation></response>'));
            
            
            srchIns.getProducts();
            test.stopTest();
        }
    }
    
    
    public static testMethod void test4(){
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
            
            Country__c country2 = new Country__c();
            country2.Name = 'SG';
            country2.Country_Name__c = 'India';
            country2.Tax_Rate__c = 7.0;
            country2.Currency_Code__c = 'SGD';
            country2.Student_Policies_Template_Id__c = 'test';
            country2.Stripe_Base_Url__c = 'www.test.com';
            country2.Stripe_Publishable_Key__c = 'ABC';
            country2.Stripe_Secret_Key__c = 'deede';
            insert country2;
            
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
            centrAcc.Country__c = country.id;
            centrAcc.CentreName_Cust__c = 'Aureus Academy - Northpoint South W (#02-179/180)';
            update centrAcc;
            
            Account cstmrAcc = TestUtil.createAccount('Customer', False, true);
            cstmrAcc.Stripe_Customer_Id__c ='';
            cstmrAcc.PersonEmail = 's@g.com';
            cstmrAcc.Card_Number__c='818';
            cstmrAcc.Card_Type__c='Visa';
            cstmrAcc.BillingCountryCode = 'SG';
            update cstmrAcc;
            
            Account objTeacher=TestUtil.createAccount('Teacher',False,true);
            objTeacher.Job_Title__c = 'Sales Executive';
            update objTeacher;
            
            Centre_Users__c cntrUsr = testUtil.createCentreUser(true);
            cntrUsr.User_Name__c = u.id;
            cntrUsr.Centre_Name__c = centrAcc.id;
            update cntrUsr;
            
            Program__c pgm = TestUtil.createProgram('Active', 'Music Exploration', true);
            
            Package__c pack=new Package__c();
            pack.Name='Piano';
            pack.Program__c=pgm.Id;
            pack.Duration__c='30';
            pack.Package_Fee__c=05.00;
            pack.Active__c=true;
            pack.Unit_Fee__c=05.00;
            pack.Registration_Fee__c=08.00;
            pack.Deposit_Fee__c=08.00;
            insert pack;
            
            Enrolment__c enrl = testUtil.createEnrolment(centrAcc.id, objTeacher.id, cstmrAcc.id, pack.id, true);
            enrl.name = 'test'; 
            enrl.Trial_Date__c = date.today();
            enrl.Type__c='Instrument';
            enrl.Parent__c = cstmrAcc.id;
            enrl.Stage__c='Piano Viewing Completed';
            enrl.Center__c = centrAcc.id;
            
            update enrl; 
            
            
            
            SearchInstrumentRental_IpadCntrl srchIns = new SearchInstrumentRental_IpadCntrl();
            srchIns.GetToday =date.today();
            srchIns.getCenters();
            srchIns.getPaymentTypePicklist();
            srchIns.getSampleController();
            srchIns.getType();
            srchIns.getEnrolments();
            srchIns.parentAcc =  cstmrAcc;
            SearchInstrumentRental_IpadCntrl.fetchEnrolments('test', 'SGD');
            srchIns.slcdEnrolment = enrl;
            srchIns.isRentalOrSellType = 'Rent';
            Booking__c bkng = new Booking__c();
            bkng.Enrolment__c = srchIns.slcdEnrolment.id;
            bkng.Type__c = 'Trial';
            bkng.Status__c ='Canceled';
            insert bkng;
            
            
            Subscription__C sub = TestUtil.createSubscription(cstmrAcc.id,true);
            sub.Center__c = srchIns.slcdEnrolment.Center__c;
            sub.Status__c = 'Active';
            sub.Parent__c =  srchIns.parentAcc.id;
            update sub;
            srchIns.SaveAndCompleteProcessViaReferenceId();
            SearchInstrumentRental_IpadCntrl.FeeModel fm = new SearchInstrumentRental_IpadCntrl.FeeModel();
            fm.instrumentChrg=4;
            fm.depFee=4;
            fm.deliCharges=5;
            fm.tuningFee=6;
            fm.stairDelCharges=5;
            fm.heatingRodInsFee=5;
            
            srchIns.slcdEnrId=enrl.id;
            srchIns.procssSlcdEnrolment();
            srchIns.nextBtnCmp1();
            srchIns.backBtnCmp2();
            srchIns.backBtnCmp3();
            srchIns.backBtnCmp4();
            // srchIns.nextBtnCmp3();
            srchIns.slcdSlot='12-12000';
            srchIns.htmtxt='22@@22';
            srchIns.slcdSlotDate = System.today().format();
            srchIns.setSlots();
            srchIns.detSlots();
            srchIns.GetToday=date.today();
            srchIns.isAlreadyStripCstmr =false;
            srchIns.stripeToken = 'test test';
            srchIns.customerRefId ='';
            srchIns.paymentType ='';
            test.startTest();
            Account customer = TestUtil.createAccount('Customer',TRUE,TRUE);
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"status": "succeeded","Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
            EnrollmentProcessErrorLogs.errorLogObj logObj = new EnrollmentProcessErrorLogs.errorLogObj();
            logObj.customerSalesforceId= customer.id;
            logObj.customerStripeId = 'cus_123';
            logObj.stripeTransactionId='xyz';
            logObj.stripeChargeAmount=10.50;
            logObj.exceptionMessage='test error';
            EnrollmentProcessErrorLogs.generateErrorLogsAndRefundAmount(JSON.serialize(logObj));
            srchIns.saveAndCompleteProcess();
            test.stopTest();
        }
        
    }
    
    
    public static testMethod void test5(){
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
            
            Country__c country2 = new Country__c();
            country2.Name = 'SG';
            country2.Country_Name__c = 'India';
            country2.Tax_Rate__c = 7.0;
            country2.Currency_Code__c = 'SGD';
            country2.Student_Policies_Template_Id__c = 'test';
            country2.Stripe_Base_Url__c = 'www.test.com';
            country2.Stripe_Publishable_Key__c = 'ABC';
            country2.Stripe_Secret_Key__c = 'deede';
            insert country2;
            
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
            centrAcc.Country__c = country.id;
            centrAcc.CentreName_Cust__c = 'Aureus Academy - Northpoint South W (#02-179/180)';
            update centrAcc;
            
            Account cstmrAcc = TestUtil.createAccount('Customer', False, true);
            cstmrAcc.Stripe_Customer_Id__c ='';
            cstmrAcc.PersonEmail = 's@g.com';
            cstmrAcc.Card_Number__c='818';
            cstmrAcc.Card_Type__c='Visa';
            cstmrAcc.BillingCountryCode = 'SG';
            update cstmrAcc;
            
            Account objTeacher=TestUtil.createAccount('Teacher',False,true);
            objTeacher.Job_Title__c = 'Sales Executive';
            update objTeacher;
            
            Centre_Users__c cntrUsr = testUtil.createCentreUser(true);
            cntrUsr.User_Name__c = u.id;
            cntrUsr.Centre_Name__c = centrAcc.id;
            update cntrUsr;
            
            Program__c pgm = TestUtil.createProgram('Active', 'Music Exploration', true);
            
            Package__c pack=new Package__c();
            pack.Name='Piano';
            pack.Program__c=pgm.Id;
            pack.Duration__c='30';
            pack.Package_Fee__c=05.00;
            pack.Active__c=true;
            pack.Unit_Fee__c=05.00;
            pack.Registration_Fee__c=08.00;
            pack.Deposit_Fee__c=08.00;
            insert pack;
            
            Enrolment__c enrl = testUtil.createEnrolment(centrAcc.id, objTeacher.id, cstmrAcc.id, pack.id, true);
            enrl.name = 'test'; 
            enrl.Trial_Date__c = date.today();
            enrl.Type__c='Instrument';
            enrl.Parent__c = cstmrAcc.id;
            enrl.Stage__c='Piano Viewing Completed';
            enrl.Center__c = centrAcc.id;
            
            update enrl; 
            
            
            
            SearchInstrumentRental_IpadCntrl srchIns = new SearchInstrumentRental_IpadCntrl();
            srchIns.GetToday =date.today();
            srchIns.getCenters();
            srchIns.getPaymentTypePicklist();
            srchIns.getSampleController();
            srchIns.getType();
            srchIns.getEnrolments();
            srchIns.parentAcc =  cstmrAcc;
            SearchInstrumentRental_IpadCntrl.fetchEnrolments('test', 'SGD');
            srchIns.slcdEnrolment = enrl;
            srchIns.isRentalOrSellType = 'Rent';
            Booking__c bkng = new Booking__c();
            bkng.Enrolment__c = srchIns.slcdEnrolment.id;
            bkng.Type__c = 'Trial';
            bkng.Status__c ='Canceled';
            insert bkng;
            
            
            Subscription__C sub = TestUtil.createSubscription(cstmrAcc.id,true);
            sub.Center__c = srchIns.slcdEnrolment.Center__c;
            sub.Status__c = 'Active';
            sub.Parent__c =  srchIns.parentAcc.id;
            update sub;
            srchIns.SaveAndCompleteProcessViaReferenceId();
            SearchInstrumentRental_IpadCntrl.FeeModel fm = new SearchInstrumentRental_IpadCntrl.FeeModel();
            fm.instrumentChrg=4;
            fm.depFee=4;
            fm.deliCharges=5;
            fm.tuningFee=6;
            fm.stairDelCharges=5;
            fm.heatingRodInsFee=5;
            
            srchIns.slcdEnrId=enrl.id;
            srchIns.procssSlcdEnrolment();
            srchIns.nextBtnCmp1();
            srchIns.backBtnCmp2();
            srchIns.backBtnCmp3();
            srchIns.backBtnCmp4();
            // srchIns.nextBtnCmp3();
            srchIns.slcdSlot='12-12000';
            srchIns.htmtxt='22@@22';
            srchIns.slcdSlotDate = System.today().format();
            srchIns.setSlots();
            srchIns.detSlots();
            srchIns.GetToday=date.today();
            srchIns.isAlreadyStripCstmr =false;
            srchIns.stripeToken = 'test test';
            srchIns.customerRefId ='';
            srchIns.paymentType ='';
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
            BillingUtility.getCustomerWithCard('ch_1AxWbTFytruJp2FXW6iuRd1X','www.google.com', '2135');
            BillingUtility.createStripeCustomer('Test','TMC','tmc@gmail.com','test', 'www.google.com', '2135');
            BillingUtility.createChargeForCustomer('Test',500,'SGD', 'www.google.com', '2135'); 
            BillingUtility.createChargeForCustomerWithInvoice('Test',500,'SGD','INV-120', 'www.google.com', '2135');
            BillingUtility.createOneTimeCharge('Test',500,'SGD', 'www.google.com', '2135'); 
            BillingUtility.AddCardWithCustomer('Test','xyz', 'www.google.com', '2135'); 
            BillingUtility.setDefaultCard('Test','xyz', 'www.google.com', '2135');
            BillingUtility.updateCharge('test','inv 120', 'www.google.com', '2135'); 
            BillingUtility.createBatchLog('Test',System.now(),System.now(),20);
            BillingUtility.calculateCurrentMonthPckFees(System.today(),52);
            
            srchIns.saveAndCompleteProcess();
            test.stopTest();
        }
    }
    
    // jatin 20-mar-2020
    public static testMethod void test6(){
        User u = [SELECT ID from User LIMIT 1];
        System.runAs(u){
            
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
            
            Country__c country2 = new Country__c();
            country2.Name = 'SG';
            country2.Country_Name__c = 'India';
            country2.Tax_Rate__c = 7.0;
            country2.Currency_Code__c = 'SGD';
            country2.Student_Policies_Template_Id__c = 'test';
            country2.Stripe_Base_Url__c = 'www.test.com';
            country2.Stripe_Publishable_Key__c = 'ABC';
            country2.Stripe_Secret_Key__c = 'deede';
            insert country2;
            
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
            centrAcc.Country__c = country.id;
            centrAcc.CentreName_Cust__c = 'Aureus Academy - Northpoint South W (#02-179/180)';
            update centrAcc;
            
            Account cstmrAcc = TestUtil.createAccount('Customer', False, true);
            cstmrAcc.Stripe_Customer_Id__c ='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
            cstmrAcc.PersonEmail = 's@g.com';
            cstmrAcc.Card_Number__c='818';
            cstmrAcc.Card_Type__c='Visa';
            cstmrAcc.BillingCountryCode = 'SG';
            update cstmrAcc;
            
            Account objTeacher=TestUtil.createAccount('Teacher',False,true);
            objTeacher.Job_Title__c = 'Sales Executive';
            update objTeacher;
            
            Centre_Users__c cntrUsr = testUtil.createCentreUser(true);
            cntrUsr.User_Name__c = u.id;
            cntrUsr.Centre_Name__c = centrAcc.id;
            update cntrUsr;
            
            Program__c pgm = TestUtil.createProgram('Active', 'Music Exploration', true);
            
            Package__c pack=new Package__c();
            pack.Name='Piano';
            pack.Program__c=pgm.Id;
            pack.Duration__c='30';
            pack.Package_Fee__c=05.00;
            pack.Active__c=true;
            pack.Unit_Fee__c=05.00;
            pack.Registration_Fee__c=08.00;
            pack.Deposit_Fee__c=08.00;
            insert pack;
            
            Enrolment__c enrl = testUtil.createEnrolment(centrAcc.id, objTeacher.id, cstmrAcc.id, pack.id, true);
            enrl.name = 'test'; 
            enrl.Trial_Date__c = date.today();
            enrl.Type__c='Instrument';
            enrl.Parent__c = cstmrAcc.id;
            enrl.Stage__c='Piano Viewing Completed';
            enrl.Center__c = centrAcc.id;
            
            update enrl; 
            
            
            
            SearchInstrumentRental_IpadCntrl srchIns = new SearchInstrumentRental_IpadCntrl();
            srchIns.GetToday =date.today();
            srchIns.getCenters();
            srchIns.getPaymentTypePicklist();
            srchIns.getSampleController();
            srchIns.getType();
            srchIns.getEnrolments();
            srchIns.parentAcc =  cstmrAcc;
            SearchInstrumentRental_IpadCntrl.fetchEnrolments('test', 'SGD');
            srchIns.slcdEnrolment = enrl;
            srchIns.isRentalOrSellType = 'Rent';
            Booking__c bkng = new Booking__c();
            bkng.Enrolment__c = srchIns.slcdEnrolment.id;
            bkng.Type__c = 'Trial';
            bkng.Status__c ='Canceled';
            insert bkng;
            
            
            Subscription__C sub = TestUtil.createSubscription(cstmrAcc.id,true);
            sub.Center__c = srchIns.slcdEnrolment.Center__c;
            sub.Status__c = 'Active';
            sub.Parent__c =  srchIns.parentAcc.id;
            update sub;
            srchIns.SaveAndCompleteProcessViaReferenceId();
            SearchInstrumentRental_IpadCntrl.FeeModel fm = new SearchInstrumentRental_IpadCntrl.FeeModel();
            fm.instrumentChrg=4;
            fm.depFee=4;
            fm.deliCharges=5;
            fm.tuningFee=6;
            fm.stairDelCharges=5;
            fm.heatingRodInsFee=5;
            
            srchIns.slcdEnrId=enrl.id;
            srchIns.procssSlcdEnrolment();
            srchIns.nextBtnCmp1();
            srchIns.backBtnCmp2();
            srchIns.backBtnCmp3();
            srchIns.backBtnCmp4();
            srchIns.nextBtnCmp3();
            srchIns.slcdSlot='9am - 1pm';
            srchIns.htmtxt='22@@22';
            srchIns.slcdSlotDate = System.today().format();
            srchIns.setSlots();
            srchIns.detSlots();
            srchIns.GetToday=date.today();
            srchIns.isAlreadyStripCstmr =false;
            srchIns.stripeToken = 'sk_test_BQokikJOvBiI2HlWgH4olfQ2';
            srchIns.customerRefId ='';
            srchIns.paymentType ='';
            
            test.startTest();
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "paid": true,"id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
            srchIns.saveAndCompleteProcess();
            test.stopTest();
            
            DocumentWrapperForPianoAgreement.SendDocument sd = new DocumentWrapperForPianoAgreement.SendDocument('',false);
        }
    }
}