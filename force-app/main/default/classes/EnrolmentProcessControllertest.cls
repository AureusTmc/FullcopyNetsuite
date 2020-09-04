/*
Name        :        EnrolmentProcessControllertest
Date        :        21,22 April 2019,18 july 2019
Author      :        Karan Singh Soni
Description :        It is the test class of EnrolmentProcessController.
*/

@isTest
public class EnrolmentProcessControllertest {
    public static testMethod void invokeEnrolmentProcessController(){
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
        
        Map<string,string> entrdDataMap=TestUtil.createData(); 
        // ################################ Added By Karan Singh Soni on 26 June 2019 ###########################
        Account objCentr=new Account();
        objCentr.id=entrdDataMap.get('objCentr');
        objCentr.Name='Aureus 112 Katong'; // satisfying condition on LOC 294
        objCentr.CentreName_Cust__c='Aureus Academy - 112 Katong';
        objCentr.Country__c = cntry.Id;
        update objcentr;
        // ################################  END Added By Karan Singh Soni on 26 June 2019 ######################
        Account objCustmr=new Account();
        objCustmr.id=entrdDataMap.get('objCustmr');
        objCustmr.Stripe_Customer_Id__c='cus_EtBijt8zP1mTdc';
        objCustmr.Card_Number__c='4242';
        objCustmr.Card_Type__c='Visa';
        update objCustmr;
        
        School__c objSchool= new School__C();
        objschool.Name='Rosyth School';
        insert objSchool;
        
        Program__C objProgram= new Program__C();
        objProgram.Id=entrdDataMap.get('objProg');
        objProgram.Billing__c='Monthly';
        update objProgram; 
        
        
        Package__c objPack= new Package__c();
        objPack.Id=entrdDataMap.get('objPack');
        objPack.Duration__c='30';
        objpack.Type__c='Individual';
        objpack.Type_of_package__c = 'Normal';
        objPack.RecordTypeId=Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        update objpack;
        
        
        ApexPages.currentPage().getParameters().put('Id',entrdDataMap.get('objEnrol'));
        
        EnrolmentProcessController objEPC=new EnrolmentProcessController();
        objEPC.getAccoungGenderPicklist();
        objEPC.getAccoungNationalityPicklist();
        objEPC.getAccoungBillCntryPicklist();
        objEPC.getSchoolPicklist(); 
        objEPC.saveStuAndLessonOnGrid();
        objEPC.thirdScreenFeeCalculation();
		
        test.startTest();
            objEpc.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer","paid": true, "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
            
            objEpc.base64SignImg='TestEnrolmentImage';
            objEpc.completeEnrolment();
            
            objEpc.selectedStudentIndex = 0;
            objEpc.selectedLessonIndex  = 0;
            objEpc.buttonType  = 'EditRowBtn';
            objEpc.editLesson();
            
            objEpc.refreshSlots();
        objEPC.addMoreLessons();
        objEPC.addMoreStudentsAndLessons();
        test.stopTest();
        
        /*
        //objEpc.lessonWrap.selectedPlan=entrdDataMap.get('objPack');
        
       objEPC.getAccoungGenderPicklist();
        objEPC.getAccoungNationalityPicklist();
        objEPC.getAccoungBillCntryPicklist();
        objEPC.getSchoolPicklist();
        objEPC.checkTrialAvl();
        objEPC.lessonWrap.selectedCenter=entrdDataMap.get('objCentr');
        objEPC.fetchPlans();  
        
        objEpc.fetchTeachers();
        
        
        objEpc.lessonWrap.selectedTeacher=entrdDataMap.get('objTchr');
        objEpc.lessonWrap.lessonSlctSlot='11:00';
        objEpc.fetchTimeSlot();  
        objEpc.saveStuAndLessonOnGrid();
        objEpc.thirdScreenFeeCalculation(); 
        test.startTest();
        objEpc.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
        objEpc.parentAccWrap.Email='testEmail@gmail.com';
        objEpc.parentAccWrap.lastname='ParentWrapperLastName';
        
        objEpc.isParAlsoAStudent=true;
        objEpc.base64SignImg='TestEnrolmentImage';
        objEpc.completeEnrolment();
        test.stopTest();
        
        */
    }
    public static testMethod void invokeEnrolmentProcessController2(){
        /*EnrolmentProcessController objEPC=new EnrolmentProcessController();
        objEPC.checkTrialAvl();
        objEPC.selectedStudentIndex =1;
        objEPC.deleteLesson();
        objEPC.addMoreStudentsAndLessons();
        objEPC.completeEnrolment();
        School__c objSchool= new School__C();
        objschool.Name='Other';
        insert objSchool;
        objEPC.getSchoolPicklist();
        objEPC.isFreeTrialOpp = true;
        objEPC.checkTrialAvl();
        objEPC.isAlreadyStripCstmr =False;
       objEPC.stripeToken = 'Token';
        test.startTest();
                    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
        objEPC.completeEnrolment();
        test.stopTest();
        //objEPC.addMoreLessons();
        //
        */
        
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
        
        
        Map<string,string> entrdDataMap=TestUtil.createData(); 
        // ################################ Added By Karan Singh Soni on 26 June 2019 ###########################
        Account objCentr=new Account();
        objCentr.Country__c = cntry.Id;
        objCentr.id=entrdDataMap.get('objCentr');
        objCentr.Name='Aureus 112 Katong'; // satisfying condition on LOC 294
        objCentr.CentreName_Cust__c='Aureus Academy - 112 Katong';
        update objcentr;
        // ################################  END Added By Karan Singh Soni on 26 June 2019 ######################
        Account objCustmr=new Account();
        objCustmr.id=entrdDataMap.get('objCustmr');
        objCustmr.Stripe_Customer_Id__c='cus_EtBijt8zP1mTdc';
        objCustmr.Card_Number__c='4242';
        objCustmr.Card_Type__c='Visa';
        update objCustmr;
        
        School__c objSchool= new School__C();
        objschool.Name='Rosyth School';
        insert objSchool;
        
        Program__C objProgram= new Program__C();
        objProgram.Id=entrdDataMap.get('objProg');
        objProgram.Billing__c='Monthly';
        update objProgram; 
        
        Package__c objPacktemp =testutil.createPackage(objProgram.id, objcentr.id, '30', true);
        
        
        Package__c objPack= new Package__c();
        objPack.Id=entrdDataMap.get('objPack');
        objPack.Duration__c='30';
        objpack.Type__c='Individual';
        objpack.Type_of_package__c = 'Promo';
        objpack.Promotion_Discount__c = 99;
        objpack.Promotion_period_In_months__c = '2';
        objpack.Package_after_Promotion__c = objPacktemp.id;
        objpack.of_Units__c = 8;
        objPack.RecordTypeId=Schema.SObjectType.Package__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        update objpack;
        
        
        ApexPages.currentPage().getParameters().put('Id',entrdDataMap.get('objEnrol'));
        
        EnrolmentProcessController objEPC=new EnrolmentProcessController();
        objEPC.getAccoungGenderPicklist();
        objEPC.getAccoungNationalityPicklist();
        objEPC.getAccoungBillCntryPicklist();
        objEPC.getSchoolPicklist(); 
         objEPC.lessonWrap.selectedPlan = objPack.id;
        objepc.fetchTimeSlot();
        objEPC.saveStuAndLessonOnGrid();
        objEPC.thirdScreenFeeCalculation();
		
        test.startTest();
       
        
            objEpc.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer", "paid": true, "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
            
            objEpc.base64SignImg='TestEnrolmentImage';
            objEpc.completeEnrolment();
            
            objEpc.selectedStudentIndex = 0;
            objEpc.selectedLessonIndex  = 0;
            objEpc.buttonType  = 'EditRowBtn';
            objEpc.editLesson();
            
            objEpc.refreshSlots();
        objEPC.addMoreLessons();
        objEPC.addMoreStudentsAndLessons();
        test.stopTest();
        
        /*
        //objEpc.lessonWrap.selectedPlan=entrdDataMap.get('objPack');
        
       objEPC.getAccoungGenderPicklist();
        objEPC.getAccoungNationalityPicklist();
        objEPC.getAccoungBillCntryPicklist();
        objEPC.getSchoolPicklist();
        objEPC.checkTrialAvl();
        objEPC.lessonWrap.selectedCenter=entrdDataMap.get('objCentr');
        objEPC.fetchPlans();  
        
        objEpc.fetchTeachers();
        
        
        objEpc.lessonWrap.selectedTeacher=entrdDataMap.get('objTchr');
        objEpc.lessonWrap.lessonSlctSlot='11:00';
        objEpc.fetchTimeSlot();  
        objEpc.saveStuAndLessonOnGrid();
        objEpc.thirdScreenFeeCalculation(); 
        test.startTest();
        objEpc.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
        objEpc.parentAccWrap.Email='testEmail@gmail.com';
        objEpc.parentAccWrap.lastname='ParentWrapperLastName';
        
        objEpc.isParAlsoAStudent=true;
        objEpc.base64SignImg='TestEnrolmentImage';
        objEpc.completeEnrolment();
        test.stopTest();
        
        */

    }
    
}