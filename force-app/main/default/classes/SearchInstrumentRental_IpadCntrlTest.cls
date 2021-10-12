//Karan Singh 28 Sep 2020 : need to re write the whole class is failing with too many soql/dml etc
@isTest
public class SearchInstrumentRental_IpadCntrlTest {
    
    
    //_________________________________________________________________  Test Setup ___________________________________________________________________
    //Karan Singh 28 Sep 2020
    @testSetup
    public static void createTestData(){ 
        
        test.startTest();
        
        NetSuite_Integration_Creds__c objNetSuiteInventorySearch = new NetSuite_Integration_Creds__c();
        objNetSuiteInventorySearch.Name  =  'Aureus Inventory Search';
        objNetSuiteInventorySearch.Endpoint__c  =  'Test';
        objNetSuiteInventorySearch.script__c  =  'Test';
        objNetSuiteInventorySearch.deploy__c  =  'Test';
        objNetSuiteInventorySearch.Consumer_Secret__c  =  'Test';
        objNetSuiteInventorySearch.Signature_Method__c  =  'HMAC-SHA256';
        objNetSuiteInventorySearch.Consumer_Key__c  =  'Test';
        objNetSuiteInventorySearch.Access_Token__c  =  'Test';
        objNetSuiteInventorySearch.Token_Secret__c  =  'Test';
        objNetSuiteInventorySearch.Version__c  =  'Test';
        objNetSuiteInventorySearch.Realm__c  =  'Test';
        objNetSuiteInventorySearch.Method__c  =  'Test';
        objNetSuiteInventorySearch.Content_Type__c  =  'Test';
        objNetSuiteInventorySearch.Crypto_Class_Encrypt_Method__c  = 'HmacSHA256';
        objNetSuiteInventorySearch.Enable_Logging__c  =  true;
        objNetSuiteInventorySearch.Maximum_API_Retry_Count__c  =  10;
        
        NetSuite_Integration_Creds__c objNetSuiteconvert = objNetSuiteInventorySearch.clone(false, true, false, false );
        objNetSuiteconvert.Name = 'Convert Item to Fixed Asset';
        
        insert new list<NetSuite_Integration_Creds__c> { objNetSuiteInventorySearch, objNetSuiteconvert };
            
            Country__c country = new Country__c();
        country.Name = 'SG';
        country.Country_Name__c = 'India';
        country.Tax_Rate__c = 7.0;
        country.Currency_Code__c = 'SGD';
        country.Student_Policies_Template_Id__c = 'test';
        country.Stripe_Base_Url__c = 'www.test.com';
        country.Stripe_Publishable_Key__c = 'ABC';
        country.Stripe_Secret_Key__c = 'deede';
        insert country;
        
        Postal_code__c pc = new Postal_code__c();
        pc.Country__c = country.id;
        pc.Name = '426731';
        insert pc;
        
        Organisation__c organisationRecord = new Organisation__c();
        organisationRecord.Name = 'Aureus Academy Singapore';
        organisationRecord.Bank_Account_Number__c = '1123456789';
        organisationRecord.Branch_Code__c = 'test';
        organisationRecord.Country__c = country.id;
        organisationRecord.Stripe_Base_Url__c = 'www.test.com';
        organisationRecord.Stripe_Publishable_Key__c = 'ABC';
        organisationRecord.Stripe_Secret_Key__c = 'test_key';
        organisationRecord.Sage_Company__c = 'AGP';
        insert organisationRecord;  
        
        Account objCustmr=TestUtil.createAccount('Customer',true,False);
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = country.Id;
        objCentr.Organisation__c = organisationRecord.id;
        objCentr.Organisation_Sharing__c ='Aureus Academy Singapore';
        insert objCentr;
        
        //create  Centre_Users__c
        Centre_Users__c objCentre_Users = AureusCalendarControllerTestHelper.createCentreUsers(objCentr.id,true);
        
        Account objTchr=TestUtil.createAccount('Teacher',false,false);
        objTchr.Personal_Email__c = 'Test@gmail.com';
        insert objTchr;
        
        List<Teacher_working_Hour__c> listTwh=TestUtil.createTeacher_Working_Hour(objTchr.Id, objCentr.Id,true,false,7);
        
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Package__c objPack2=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        
        Lead objLead =TestUtil.createLead(objCentr.Location__c, 'Website', 'testEmaillead@gmail.com', objCentr.id, false);
        objLead.IsConverted=false;
        insert objLead;
        
        objCustmr.Lead__c=objLead.id;
        objCustmr.Person_Email__c = 'test@xyz.com';
        objCustmr.PersonEmail  = 'test@xyz.com';
        objCustmr.Stripe_Customer_Id__c = 'cus_HeouTt4xRrpAPG';
        objCustmr.Card_Number__c = '4242';
        objCustmr.Card_Type__c = 'Visa';
        objCustmr.BillingCountryCode = 'SG'; 
        insert objCustmr;
        
        Enrolment__C objEnrol=new Enrolment__C();
        objEnrol.Center__c=objCentr.id;
        objEnrol.Teacher__c=objTchr.id;
        objEnrol.Parent__c=objCustmr.id;
        objEnrol.Student__c=objCustmr.id;
        objEnrol.Package__c=objPack.id;
        objEnrol.Type__c='Instrument';
        objEnrol.Stage__c='Piano Viewing Completed';
        objEnrol.Trial_Date__c = system.today();
        objEnrol.Trial_Start_Time__c = Time.newInstance(11, 11, 11, 11);
        objEnrol.RecordTypeId = Schema.SObjectType.Enrolment__C.getRecordTypeInfosByName().get('Instrument Rental').getRecordTypeId();
        insert objEnrol;
        
        Booking__C objBook=Testutil.createBooking(objTchr.Id,'Lesson','Regular',False);
        objbook.Enrolment__c=objEnrol.id;
        insert objBook;
        
        Subscription__C objSubs=new Subscription__C();
        objSubs.Parent__c = objCustmr.Id;
        objSubs.Center__c = objCentr.Id;
        objSubs.Subscription_Start_Date__c = date.today();
        objSubs.Next_Bill_Date__c = date.today().addMonths(1);
        insert objSubs;
        
        Subscription_Line_Item__C objSLI  =new Subscription_Line_Item__C();
        objSLI.Subscription__c = objSubs.Id;
        objSLI.Enrolment__c = objEnrol.Id;
        objSLI.Next_Bill_Date__c = Date.newInstance(System.today().addMonths(1).year(), System.today().month() + 1, 1);
        objSLI.Status__c = 'Active';
        objSLI.Amount__c = 10.2;
        objSLI.Subscription_Start_Date__c = Date.newInstance(System.today().year(), System.today().month(), 1);
        insert objSLI;
        system.debug(' SOQL --> ' + Limits.getSoslQueries());
        system.debug(' DML --> ' + Limits.getDmlStatements());
        test.stopTest();
    }//end of test setup
    
    //Karan Singh 28 Sep 2020
    public static testMethod void testMethod1(){
        
        system.debug(' SOQL --> ' + Limits.getSoslQueries());
        system.debug(' DML --> ' + Limits.getDmlStatements());
        List< Account > listCustomer = [ SELECT Id,PersonEmail FROM Account WHERE RecordType.Name = 'Customer' LIMIT 1 ];
        List< Enrolment__c > listEnrol = [ SELECT Id, Name, Parent__c, Parent__r.Name, Parent__r.Personemail, Parent_Email__c, Student__c,
                                          Student__r.Name,Teacher__c, Teacher__r.Name, Package__c, Package__r.Name, Trial_Date__c, 
                                          Trial_Start_Time__c,Center__c, Center__r.Name  FROM Enrolment__c LIMIT 1 ];
        List< Account > listCentre = [ SELECT Id,PersonEmail FROM Account WHERE RecordType.Name = 'Centre' LIMIT 1 ];
        
        if( listEnrol.size() == 0 ) return; 
        if( listCustomer.size() == 0 ) return;
        if( listCentre.size() == 0 ) return;
        
        SearchInstrumentRental_IpadCntrl srchIns = new SearchInstrumentRental_IpadCntrl();
        
        srchIns.slcdPiano.serialNumber = 'Piano';
        srchIns.slcdPiano.item = 'Piano';
        srchIns.slcdPiano.location = '';
        srchIns.slcdPiano.status = 'Piano';
        srchIns.slcdPiano.inventoryType = 'Piano';
        srchIns.slcdPiano.monthlyRental = '2';
        srchIns.slcdPiano.listPrice = '2';
        srchIns.slcdPiano.model = 'Piano';
        srchIns.slcdPiano.productId = 'Piano';
        srchIns.slcdPiano.brand = 'Piano';
        srchIns.slcdCenter = listCentre[0].Id;
        srchIns.GetToday =date.today();
        srchIns.getCenters();
        srchIns.getPaymentTypePicklist();
        srchIns.getSampleController();
        srchIns.getType();
        srchIns.getEnrolments();
        srchIns.parentAcc =  listCustomer[0];
        SearchInstrumentRental_IpadCntrl.fetchEnrolments('test@xyz.com', 'SG');
        srchIns.slcdEnrolment = listEnrol[0];
        srchIns.isRentalOrSellType = 'Rent';
        srchIns.SaveAndCompleteProcessViaReferenceId();
        SearchInstrumentRental_IpadCntrl.FeeModel fm = new SearchInstrumentRental_IpadCntrl.FeeModel();
        fm.instrumentChrg=4;
        fm.depFee=4;
        fm.deliCharges=5;
        fm.tuningFee=6;
        fm.stairDelCharges=5;
        fm.heatingRodInsFee=5;
        srchIns.fm = fm;
        
        srchIns.slcdEnrId = listEnrol[0].id;
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
        srchIns.parentAcc.id = listCustomer[0].id;
        srchIns.parentAcc.personemail= listCustomer[0].PersonEmail;
        srchIns.createSession();
        srchIns.createSessForAureusGrp();
        string postalCode = Apexpages.currentPage().getParameters().put('postalCode','426731');
        srchIns.fetchFullAddress();
        
        srchIns.isAlreadyStripCstmr = false;
        srchIns.nostairs = 10;
        srchIns.isRentalOrSellType = 'Rent';
        srchIns.nextBtnCmp3(); 
        srchIns.getProducts();
        srchIns.getProducts1();
        srchIns.slctdPianoOpt = 1;
        srchIns.setSlcdPiano();
        srchIns.isAlreadyStripCstmr = true;
        fm.instrumentChrg=4;
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        srchIns.saveAndCompleteProcess();
        
        srchIns.isAlreadyStripCstmr = false;
        srchIns.stripeToken = 'TestToken';
        srchIns.slcdEnrolment = new Enrolment__c();
        srchIns.saveAndCompleteProcess();
        system.debug(' SOQL --> ' + Limits.getSoslQueries());
        system.debug(' DML --> ' + Limits.getDmlStatements());
        SearchInstrumentRental_IpadCntrl.SageProductItems objSage = new SearchInstrumentRental_IpadCntrl.SageProductItems();
        objSage.brand = '';
        objSage.condi = '';
        objSage.location = '';
        objSage.modelNo = '';
        objSage.serNo = '';
        objSage.srNo = 123;
        
        Test.stopTest();
        
    } 
    
}