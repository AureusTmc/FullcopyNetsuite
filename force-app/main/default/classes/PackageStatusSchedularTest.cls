/*
Name        :        PackageStatusSchedularTest
Date        :        23 July 2019
Description :        It is the test class of PackageStatusScheduler.
*/
@isTest
public class PackageStatusSchedularTest {
    @isTest
    public static void testExecuteBatch(){
        
        String CRON_EXP = '0 0 0 15 3 ? *';
        //Create Centre
        Account objCentr=TestUtil.createAccount('Centre',false,true);
        //Create Program
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
   		//Create Package     
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'45',false);
        objPack.offer_start_date__c = System.today();
        objPack.offer_end_Date__c = System.today().addDays(25);
        insert objPack;
        
        Test.startTest();
        	String jobId = System.schedule('PackageStatusSchedularTest',  CRON_EXP, new PackageStatusScheduler());
        Test.stopTest();
    }
}