/*
Name        :        StudioRentalControllerTest
Date        :        21 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of StudioRentalController.
*/

@isTest
public class StudioRentalControllerTest {
    public static testMethod void createStudioRentalController(){
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
        
        Account objCust=TestUtil.createAccount('Customer',false, True);
        Account objCenter=TestUtil.createAccount('Centre',false,false);
        objCenter.Country__c = cntry.Id;
        insert objCenter;
        Program__C objProg=TestUtil.createProgram('Active','',True);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCenter.id,'60',true);
        Resource__c objRes=TestUtil.createResource(objCenter.id,'tstID',objPack.id,true);
        list<Resource_Working_Hour__c>  objRWh=TestUtil.createResource_Working_Hour(objCenter.id,objRes.id, true, true, 7);
        Booking__C objBook=TestUtil.createStudioBooking(objRes.id,objCenter.Id,'Standard',true);
        StudioRentalController objSrc= new StudioRentalController();
        objSrc.getCenters();
        objSrc.slcdCenter=objCenter.id;
        objSrc.getResourceType();
        objSrc.slcdResType='ABRSM';
        objSrc.fetchStudios();
        objSrc.slcdStudio=ObjRes.id;
        objSrc.getAddr();
        objSrc.getDuration();
        objSrc.slcdDuration='60';
        objSrc.fetchTimeSlot();
        objSrc.fetchTimeSlotBasesOfDuration();
        objSrc.slcdSlot='11:00';
        objSrc.cacluateTotal();
        objSrc.stripeToken='sk_test_BQokikJOvBiI2HlWgH4olfQ2';
        objSrc.parentAcc.PersonEmail='testEmail@gmail.com';
        //objSrc.base64SignImg='TestImg';
        objSrc.iWantReceivedLatestNew=true;
        
        test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        objSrc.saveData();
        test.stopTest();
    }
}