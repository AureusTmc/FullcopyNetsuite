@isTest
    public class EnrolmentProcessForClassCtrlTest {
    
    testMethod static void invokeEnrolmentProcessClassMethod(){
        
        try{
            Country__c cntry = new Country__c();
            cntry.Name = 'SG';
            cntry.Country_Name__c ='Singapore';
            cntry.Currency_Code__c ='SGD';
            cntry.Tax_Rate__c = 7;
            cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
            cntry.Stripe_Base_Url__c ='https://api.stripe.com';
            cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
            cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
            insert cntry;
            Account objTeachr=testUtil.createAccount('Teacher',false,False);
            objTeachr.Minor_Instruments_Disciplines__c='Piano';
            insert objTeachr;
            Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
            objCentr.Country__c = cntry.Id;
            Insert objCentr;
            //Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
            List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
            list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
            //  list<Resource_Working_Hour__c> listRwh=TestUtil.createResource_Working_Hour(objCentr.id,objRes.Id,true,7);
            
            
            // Account objCentr=TestUtil.createAccount('Centre',False,false);
            // objCentr.Country__c = cntry.Id;
            // insert objCentr;
            
            Account objCustmr=TestUtil.createAccount('Customer',True,true);
            //Account objCustmer=TestUtil.createAccount('Customer',True,true);
            Account objtechr=TestUtil.createAccount('Teacher',False,true);
            Leave_Request__c leavObj = new Leave_Request__c();
            leavObj.Leave_Start_Date__c=System.today().addDays(17);
            leavObj.Leave_End_Date__c=system.today().addDays(27);
            leavObj.Employee__c=objtechr.Id;        
            leavObj.Status__c = 'Approved';
            insert leavObj;
            Program__C objProg=TestUtil.createProgram('Active','Piano',true);
            Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);  
            Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
            objENrol.Type__c='Trial';
            objEnrol.Stage__c='Pending Enrolment';
            objEnrol.Lessons_Start_Date__c = System.today().addDays(10);
            insert objENrol;
            
            Postal_Code__c posObj= new Postal_Code__c();
            posObj.Name='18906';
            posObj.Country__c=cntry.Id;        
            insert posObj;
            
            ApexPages.currentPage().getParameters().put('postalCode','18906');
            ApexPages.currentPage().getParameters().put('id',objENrol.id);
            EnrolmentProcessForClassCtrl enrolProObj = new EnrolmentProcessForClassCtrl();
            //enrolProObj.fetchFullAddress();
            enrolProObj.isAmcClubMember= true;
            // enrolProObj.isAlreadyStripCstmr= true;
            //  enrolProObj.isAlreadyStripCstmr= 'test';
            //set<String> setOfEnrolments = new set<String>();
            //PageReference.getParameters().put('id',objENrol.Id);
            //ApexPages.currentPage().getParameters().put('Id',objENrol.Id);
            enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();
            enrolProObj.isAmcClubMember= false;
           
            enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();
            
            enrolProObj.enrolDetails.parent.country = 'SG';
          
            enrolProObj.enrolDetails.parent.id = objCustmr.id;
            enrolProObj.fetchFullAddress();
            // enrolProObj.signAgreement();
            //enrolProObj.fetchEnrolmentDetails();
            ApexPages.currentPage().getParameters().put('id',objEnrol.id);
         
            enrolProObj.isAmcClubMember= true;
            test.startTest();
            enrolProObj.sendEmailToParent();
            enrolProObj.redirectToenrollmentprocessPage();
           // test.startTest();
            enrolProObj.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
            enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();  
            test.stopTest();
        }Catch( Exception e ){
            
        }
    }
    testMethod static void invokeEnrolmentProcessClassMethodTwo(){
        
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = cntry.Id;
        Insert objCentr;
        //Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        //  list<Resource_Working_Hour__c> listRwh=TestUtil.createResource_Working_Hour(objCentr.id,objRes.Id,true,7);
        
        
        //  Account objCentr=TestUtil.createAccount('Centre',False,false); 
        // objCentr.Country__c = cntry.Id;
        // insert objCentr;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);  
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Pending Enrolment';
        objEnrol.Lessons_Start_Date__c = System.today().addDays(10);
        insert objENrol;
        ApexPages.currentPage().getParameters().put('id',objENrol.id);
        EnrolmentProcessForClassCtrl enrolProObj = new EnrolmentProcessForClassCtrl();
        enrolProObj.isAmcClubMember= true;
        //enrolProObj.isAmcClubMember= false;
        // enrolProObj.stripeCstmrId= 'test';
        
        enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();
        enrolProObj.isAmcClubMember= false;
      
        enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();
        // enrolProObj.signAgreement();
        //enrolProObj.fetchEnrolmentDetails();
        ApexPages.currentPage().getParameters().put('id','id');
        enrolProObj.isAmcClubMember= true;
        /* test.startTest();
enrolProObj.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(201,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
enrolProObj.signAgreement();  
test.stopTest();*/
        EnrolmentProcessForClassCtrl.enrolDetails objEnrolWrapper = new EnrolmentProcessForClassCtrl.enrolDetails( new Map<String, Enrolment__c>(),new Map<String, EnrolmentProcessForClassCtrl.AccountDetails>()
                                                                                                                  ,new EnrolmentProcessForClassCtrl.AccountDetails(),
                                                                                                                  new Map<String, EnrolmentProcessForClassCtrl.FeeModel>());
        enrolProObj.EnrolDetails.parent.id ='css';
        //enrolProObj.documentDetails.id = 'csdcds';
        try{
            enrolProObj.createSession();
            
        }catch(Exception e){
        }
        try{
            test.startTest();
            enrolProObj.signAgreement();
            test.stopTest();
        }catch(Exception e){
            
        }
        try{
            enrolProObj.sendAgreement();
        }catch(Exception e){}
        
        
    }
    
    testMethod static void invokeEnrolmentProcessClassMethodThree(){
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = cntry.Id;
        Insert objCentr;
       
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
       
        
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        
        Package__c objPacktemp =testutil.createPackage(objProg.id, objcentr.id, '30', true); 
        
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',false);  
        objPack.Duration__c='30';
        objpack.Type__c='Individual';
        objpack.Type_of_package__c = 'Promo';
        objpack.Promotion_Discount__c = 99;
        objpack.Promotion_period_In_months__c = '2';
        objpack.Package_after_Promotion__c = objPacktemp.id;
        objpack.of_Units__c = 8;  
        insert objpack;
        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Pending Enrolment';
        objEnrol.Lessons_Start_Date__c = System.today().addDays(10);
        insert objENrol;
        objENrol.Center__c=Label.Aureus_at_Home_Id;
        update objENrol;
        
        try{
            
            ApexPages.currentPage().getParameters().put('id',objENrol.id);
            EnrolmentProcessForClassCtrl enrolProObj = new EnrolmentProcessForClassCtrl();
            enrolProObj.isAmcClubMember= true;
           
            test.startTest();
            enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();
            enrolProObj.isAmcClubMember= false;
            enrolProObj.isAlreadyStripCstmr= false;
          
            enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();
           
            ApexPages.currentPage().getParameters().put('id','id');
            enrolProObj.isAmcClubMember= true;
            List<Booking__c> bookList = new List<Booking__c>();
            Booking__c bkgObj = TestUtil.createBooking(objtechr.Id,'Lesson','Regular',false);
            bkgObj.Student__c=objCustmr.Id;
            insert bkgObj;
            bookList.add(bkgObj);
            AureusUtility.createCase(bookList);
            enrolProObj.updateCstmrDetail();
            objENrol.Center__c = Label.Aureus_at_Home_Id;
            update objENrol;
            ApexPages.currentPage().getParameters().put('id',objENrol.id);
            EnrolmentProcessForClassCtrl enrolProObj1 = new EnrolmentProcessForClassCtrl();
            enrolProObj1.saveAccountForEnrolmentAndGenerateInvoice();
            test.stopTest();
            
        }Catch( Exception e ){
            
        }
    }
    
    testMethod static void invokeEnrolmentProcessClassMethodFour(){
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = cntry.Id;
        Insert objCentr;
        //Resource__c objRes=TestUtil.createResource(objCentr.Id,'TstId',objPack.id,true);
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        //  list<Resource_Working_Hour__c> listRwh=TestUtil.createResource_Working_Hour(objCentr.id,objRes.Id,true,7);
        
        
        //Account objCentr=TestUtil.createAccount('Centre',False,false); 
        //objCentr.Country__c = cntry.Id;
        //insert objCentr;
        
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        
        Package__c objPacktemp =testutil.createPackage(objProg.id, objcentr.id, '30', true); 
        
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',false);  
        objPack.Duration__c='30';
        objpack.Type__c='Individual';
        objpack.Type_of_package__c = 'Promo';
        objpack.Promotion_Discount__c = 99;
        objpack.Promotion_period_In_months__c = '2';
        objpack.Package_after_Promotion__c = objPacktemp.id;
        objpack.of_Units__c = 8;  
        insert objpack;
        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Pending Enrolment';
        objEnrol.Lessons_Start_Date__c = System.today().addDays(10);
        
        insert objENrol;
        objENrol.Center__c=Label.Aureus_at_Home_Id;
        update objENrol;
        
        List<Booking__c> bookList = new List<Booking__c>();
        Booking__c bkgObj = TestUtil.createBooking(objtechr.Id,'Lesson','Regular',false);
        bkgObj.Student__c=objCustmr.Id;
        bkgObj.Cancellation_Reason__c = 'Holidays';
        insert bkgObj;
        bookList.add(bkgObj);
        try{
            EnrolmentProcessForClassCtrl objEnrolProcess = new EnrolmentProcessForClassCtrl();
            objEnrolProcess.getFillInstrumentAtHome();
            objEnrolProcess.waitAgreement();
            EnrolmentProcessForClassCtrl.campBookingsCancellationProcess( bookList);
            EnrolmentProcessForClassCtrl.createPlaceholderForCampFifthLsn(new List< Fifth_Lesson__c  > {new Fifth_Lesson__c () });
        }Catch(Exception e){
            
        }
    }
    testMethod static void forferel(){
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        
       School__c schl =  TestUtil.createSchool(false);
        schl.Country__c = cntry.Id;
        INSERT schl;
        
        Organisation__c organisation = new Organisation__c(
            Name = 'Aureus Academy Singapore',
            Bank_Account_Number__c = '647743343001',
            Bank_Name__c = 'OVERSEA-CHINESE BANKING CORP GROUP',
            Branch_Code__c = '001',
            CPF_Advice_Code__c = '01',
            CPF_Payment_Type__c = 'PTE',
            Country__c =cntry.Id,
            Sage_Company__c = 'AGP');
        insert organisation;
        
        Referral_Discount__c referral_discount = new Referral_Discount__c(
            Name = 'Std. Referral (SG)',
            Discount_Amount_Referrer__c = 70.09,
            Discount_Amount_Referee__c = 70.09,
            Country__c = cntry.Id,
            Default__c = 'Yes',
            Active__c = 'Yes');
        insert referral_discount;

        
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = cntry.Id;
        objCentr.Organisation__c = organisation.Id;
        Insert objCentr;
        
        
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        
        
        Account refrelCustomer=TestUtil.createAccount('Customer',True,false);
        refrelCustomer.FirstName ='test';
        refrelCustomer.LastName = 'Class';
        refrelCustomer.PersonEmail = 'Aureas@Gmail.test'; 
        insert refrelCustomer;
       
        account refrelAccount = [SELECT id,name,Unique_Referral_Code__c from account where id =:refrelCustomer.id];
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.Referred_by__c = refrelAccount.Id;
        insert objCustmr;
      
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        
        Package__c objPacktemp =testutil.createPackage(objProg.id, objcentr.id, '30', true); 
        
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',false);  
        objPack.Duration__c='30';
        objpack.Type__c='Individual';
        objpack.Type_of_package__c = 'Normal';
        objpack.Promotion_Discount__c = 99;
        objpack.Promotion_period_In_months__c = '2';
        objpack.Package_after_Promotion__c = objPacktemp.id;
        objpack.of_Units__c = 8;  
        insert objpack;
        
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Pending Enrolment';
        objEnrol.Lessons_Start_Date__c = System.today().addDays(10);
        objEnrol.Referral_code_used__c = refrelAccount.Unique_Referral_Code__c;
        objEnrol.Referred_by__c = refrelAccount.Id;
        insert objENrol;
     
        ApexPages.currentPage().getParameters().put('id',objENrol.id);
        EnrolmentProcessForClassCtrl enrolProObj = new EnrolmentProcessForClassCtrl();
        enrolProObj.getFillInstrumentAtHome();
        enrolProObj.isAmcClubMember = true;
        ApexPages.currentPage().getParameters().put('postalCode','18906');
        enrolProObj.fetchFullAddress();     
        enrolProObj.updateCstmrDetail();
        enrolProObj.createSession();
      
        try{
            enrolProObj.waitAgreement();
            enrolProObj.signAgreement();
            enrolProObj.sendAgreement();
          
        }catch(exception e){
            
        }
        Test.startTest();
        enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();
        enrolProObj.sendEmailToParent();
        Test.stopTest();
    }
   testMethod static void forferel2(){
        Country__c cntry = new Country__c();
        cntry.Name = 'SG';
        cntry.Country_Name__c ='Singapore';
        cntry.Currency_Code__c ='SGD';
        cntry.Tax_Rate__c = 7;
        cntry.Student_Policies_Template_Id__c= 'DLe9tWht6W9PNHEabs2ruT';
        cntry.Stripe_Base_Url__c ='https://api.stripe.com';
        cntry.Stripe_Publishable_Key__c ='pk_test_eGeu4Z0mLSfXmekcJcLt7TVH';
        cntry.Stripe_Secret_Key__c ='sk_test_M3pk8qvbMs03SWjDuf6m1bss';
        insert cntry;
        
       School__c schl =  TestUtil.createSchool(false);
        schl.Country__c = cntry.Id;
        INSERT schl;
        
        Organisation__c organisation = new Organisation__c(
            Name = 'Aureus Academy Singapore',
            Bank_Account_Number__c = '647743343001',
            Bank_Name__c = 'OVERSEA-CHINESE BANKING CORP GROUP',
            Branch_Code__c = '001',
            CPF_Advice_Code__c = '01',
            CPF_Payment_Type__c = 'PTE',
            Country__c =cntry.Id,
            Sage_Company__c = 'AGP');
        insert organisation;
        
        Referral_Discount__c referral_discount = new Referral_Discount__c(
            Name = 'Std. Referral (SG)',
            Discount_Amount_Referrer__c = 70.09,
            Discount_Amount_Referee__c = 70.09,
            Country__c = cntry.Id,
            Default__c = 'Yes',
            Active__c = 'Yes');
        insert referral_discount;

        
        Account objTeachr=testUtil.createAccount('Teacher',false,False);
        objTeachr.Minor_Instruments_Disciplines__c='Piano';
        insert objTeachr;
        
        Account objCentr=TestUtil.createAccount('Centre',false,FALSE);
        objCentr.Country__c = cntry.Id;
        objCentr.Organisation__c = organisation.Id;
        Insert objCentr;
        
        
        List <Teacher_Working_Hour__c> listTWH=TestUtil.createTeacher_Working_Hour(objTeachr.id,objCentr.Id,True,False,7);
        list<Center_Working_Hours__c> listCwh=TestUtil.createCenter_Working_Hours(objCentr.id, True,7);
        
        
        Account refrelCustomer=TestUtil.createAccount('Customer',True,false);
        refrelCustomer.FirstName ='test';
        refrelCustomer.LastName = 'Class';
        refrelCustomer.PersonEmail = 'Aureas@Gmail.test'; 
        insert refrelCustomer;
       
        account refrelAccount = [SELECT id,name,Unique_Referral_Code__c from account where id =:refrelCustomer.id];
        Account objCustmr=TestUtil.createAccount('Customer',True,false);
        objCustmr.Referred_by__c = refrelAccount.Id;
        insert objCustmr;
     
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        
        Package__c objPacktemp =testutil.createPackage(objProg.id, objcentr.id, '30', true); 
        
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',false);  
        objPack.Duration__c='30';
        objpack.Type__c='Individual';
        objpack.Type_of_package__c = 'Normal';
        objpack.Promotion_Discount__c = 99;
        objpack.Promotion_period_In_months__c = '2';
        objpack.Package_after_Promotion__c = objPacktemp.id;
        objpack.of_Units__c = 8;  
        insert objpack;
        
        Enrolment__c objENrol=TestUtil.createEnrolment(null,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Pending Enrolment';
        objEnrol.Lessons_Start_Date__c = System.today().addDays(10);
        objEnrol.Referral_code_used__c = refrelAccount.Unique_Referral_Code__c;
        objEnrol.Referred_by__c = refrelAccount.Id;
       objEnrol.Center__c = Label.Aureus_at_Home_Id;
        insert objENrol;
        
        ApexPages.currentPage().getParameters().put('id',objENrol.id);
        EnrolmentProcessForClassCtrl enrolProObj = new EnrolmentProcessForClassCtrl();
       enrolProObj.cardNumber = '4242424242424242';
       enrolProObj.cardType = 'Visa';
       enrolProObj.cardImage = 'abc';
        enrolProObj.getFillInstrumentAtHome();
        enrolProObj.isAmcClubMember = false;
       enrolProObj.isAlreadyStripCstmr = false;
        ApexPages.currentPage().getParameters().put('postalCode','18906');
        enrolProObj.fetchFullAddress();     
        enrolProObj.updateCstmrDetail();
        enrolProObj.createSession();
      
        try{
            enrolProObj.waitAgreement();
            enrolProObj.signAgreement();
            enrolProObj.sendAgreement();
          
        }catch(exception e){
            
        }
        Test.startTest();
       enrolProObj.sendEmailToParent();
        enrolProObj.saveAccountForEnrolmentAndGenerateInvoice();
        Test.stopTest();
    }
  
    
    
    
}