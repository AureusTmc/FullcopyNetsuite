/*
Name        :        RentalPurchaseSummaryControllerTest
Date        :        17 March 2020
Author      :        Jatin
Description :        It is the test class of RentalPurchaseSummaryController.
*/
@isTest
public class RentalPurchaseSummaryControllerTest {
    @testSetup
    private static  void createData(){
        PianoRentalTestHelper.createPianoRentalData();
    }
    private static testMethod void testRentalSummary(){
        List<Enrolment__c> lstEnrolments = [SELECT Id FROM Enrolment__c limit 1];
        RentalPurchaseSummaryController objController = new RentalPurchaseSummaryController();
        lstEnrolments[0].Selling_price__c = 5000;
        lstEnrolments[0].Delivery_Charges__c = 10;
        lstEnrolments[0].Stair_Charges__c = 10;
        
        update lstEnrolments[0];
        objController.enrolId = lstEnrolments[0].id;
        objController.getPurchaseBillingSummary();
     
    }
}