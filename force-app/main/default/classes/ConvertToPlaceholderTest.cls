/*
    Name            :   ConvertToPlaceholderTest;
    Date            :   9/30/2019;
    Author          :
    Description     :   This Test Class Covered To ConvertToPlaceholder Class;
*/



@isTest
Private class ConvertToPlaceholderTest {
    
    /*---------This Is a DataSetup Method Fill The Data----------*/
    @TestSetup
    Private static void dataSetup(){
        /*--------Create CountryList -------------*/
        List<Country__c> countryList = new List<Country__c>();
        /*---------Fill The CountryList------------*/     
        countryList.add(new Country__c(Name = 'SGD',Country_Name__c = 'India',Tax_Rate__c = 7.0,Currency_Code__c = 'SGD',
                                      Student_Policies_Template_Id__c = 'test',Stripe_Base_Url__c = 'www.test.com',Stripe_Publishable_Key__c = 'ABC',
                                      Stripe_Secret_Key__c = 'deede'));
        
        
         /*----------Check The CountryList-------*/
        if(countryList.size()>0){
            /*------------Insert The CountryList-----------*/
               insert countryList;                         
         }

        /*------create a customerAccount  ------------*/
        Account objCustmr=TestUtil.createAccount('Customer',true,true);
        /*------create a centerAccount  ------------*/
        Account objCentr=TestUtil.createAccount('Centre',false,false);
        objCentr.Country__c=countryList[0].Id;
        /*--------insert Center---------*/
        insert objCentr;
         /*------create a TeacherAccount-------------*/
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        
        
        /*--------Create a Program Object----------*/
        Program__C objProg = TestUtil.createProgram('Active','Piano',true);
        /*--------create a Package Object-----------*/
        Package__c objPack = TestUtil.createPackage(objProg.id,objCentr.id,'45',true);
        /*--------Create a Enrolment Object -----------*/
        Enrolment__c objENrol = TestUtil.createEnrolment(objCentr.Id,objTchr.Id,objCustmr.Id,objPack.id,true);
        
        /*--------create a fifthLessonList-------------*/
        List<Fifth_Lesson__c>   fifthLessonList=new List<Fifth_Lesson__c>();
        /*---------Fill The fifthLessonList ------------*/
        fifthLessonList.add(new Fifth_Lesson__c(Teacher_Account__c=objTchr.Id,Center__c=objCentr.Id,
                                                Student__c=objCustmr.Id,Start_Time__c=TIME.newInstance(2, 40, 60,160),End_Time__c=TIME.newInstance(6, 40, 60,180),
                                                Package__c=objPack.Id,Parent__c=objCustmr.Id,Remarks__c='40',IsActive__c=true,
                                                Enrolment__c=objENrol.Id,Booking_Date__c=Date.newInstance(2019,9,30)));
        /*--------check The fifthLessonList---------*/
        if(fifthLessonList.size()>0){
            /*-----Insert fifthLessonList------*/
            insert fifthLessonList;
        }
        
    }
  
    /*------create testMethod testConvertFifthLessonProcess  ---------*/
    Private static testMethod void testConvertFifthLessonProcess(){
        /*-------create a fifthLessaonList----------*/
        List<Fifth_Lesson__c>   fifthLessonList=new List<Fifth_Lesson__c>([SELECT Id FROM Fifth_Lesson__c]);
        /*-------Create a ConvertToPlaceholder Class Object-------*/
        ConvertToPlaceholder    convertToPlaceholderObj=new ConvertToPlaceholder(fifthLessonList[0].Id,''); 
        /*-----start The Test startTest Method---*/
        Test.startTest();
        /*-----Call To convertFifthLesson Method In ConvertToPlaceholder Class-----*/
        convertToPlaceholderObj.convertFifthLesson();
        /*-----end The Test endTest Method---*/
        Test.stopTest();
        
        /*-------create fifthLessson Object Check Updation------------*/
        Fifth_Lesson__c fifthLessonObj=[SELECT Id,isActive__c,Booking__c FROM Fifth_Lesson__c LIMIT 1]; 
        /*-------Create First System assert And Check The isActive Field----*/
        System.assertEquals(fifthLessonObj.isActive__c,false);
        List<Booking__c>    bookingList=new List<Booking__c>([SELECT Id FROM Booking__c]);
        /*------Create Second System Assert And Check Booking Size-----*/
        System.assertEquals(bookingList.size(),1);
        
    } 

}