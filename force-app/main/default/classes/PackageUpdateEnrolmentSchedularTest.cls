/*
        Name        :    PackageUpdateEnrolmentSchedularTest
        Date        :   
		Remodified	:	 06/30/2019
        Author      :    Karan Singh Soni
        Description :    This test class is used for PackageUpdateEnrolmentSchedular class
*/
@isTest
public class PackageUpdateEnrolmentSchedularTest {
    public Static testMethod void invokePackageUpdateEnrolmentSchedular(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',false,true);
        Account objTchr=TestUtil.createAccount('Teacher',false,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=TestUtil.createPackage(objProg.id,objCentr.id,'30',false);
        Package__c objPack2=TestUtil.createPackage(objProg.id,objCentr.id,'45',true);
        objPack2.Promotion_period_In_months__c='1';
        objPack2.Promotion_Discount__c=30;
        objPack2.Package_after_Promotion__c=objPack.Id;
        objPack2.Type_Of_Package__c = 'Promo';
        update objPack2;
        Package__c objNewPack=TestUtil.createPackage(objProg.id,objCentr.id,'60',true);
        Enrolment__c objEnrol=TestUtil.createEnrolment(objCentr.id,objTchr.id,objCustmr.id,objPack2.id,False);
        objEnrol.Lesson_Day__c='Friday';
        objEnrol.Stage__c='Enrolled';
        objEnrol.Package_Process_Type__c='Upgrade';
        objEnrol.Package_Process_Status__c='Pending';
        objEnrol.Effective_Date__c=Date.newInstance(System.today().year(),System.today().month(), 05);
        objenrol.New_Package_Id__c=objNewPack.id;
        objenrol.Package_To_Be_Change__c=objNewPack.id;
        objenrol.Promotional_Period_End_Date__c=System.today();
        insert objEnrol;
        //##################### added on  06/30/2019 By Karan Singh Soni #################################################
        Booking__c objBooking=new Booking__c();
        objBooking.Enrolment__c=objEnrol.Id;
        objBooking.RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Lesson').getRecordTypeId();
        objBooking.Booking_Date__c=Date.Today()+84;
        objBooking.Is_fifth_booking__c=True;
        //objBooking.Status__c='Completed';
        insert objBooking;
        //############################### end  06/30/2019 #######################################################
        
        Subscription__C objSubs=TestUtil.createSubscription(objCustmr.Id,False);
        objSubs.Status__c='Active';
        objSubs.Subscription_Start_Date__c=date.today().adddays(-5);
        objSubs.Next_Bill_Date__c=date.today().adddays(-5);
        insert objSubs;
        
        Subscription_Line_Item__c objSubsLine=TestUtil.createSubscriptionLineItem(objSubs.Id,False);
        objSubsLine.Enrolment__c=objEnrol.id;
        objSubsLine.Plan_Package__c=objPack2.id;
        objSubsLine.Status__c='Active';
        objSubsLine.Next_Bill_Date__c=date.today().addMonths( 1 );
        
        insert objSubsLine;
        
        PackageUpdateEnrolmentSchedular objPackUpdate=new PackageUpdateEnrolmentSchedular();
        objPackUpdate.execute(Null);
        
    }
}