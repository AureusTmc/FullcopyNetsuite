/*

*/
@isTest
public class GenerateInvoiceControllerTest{
    @isTest
    private static void unitTest(){
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        update objCustmr;
        
        Account centreObj = TestUtil.createAccount('Centre',True,True);
        ApexPages.StandardController sc = new ApexPages.StandardController(objCustmr);
        GenerateInvoiceController objController = new GenerateInvoiceController(sc);
        
        objController.addRow();
        for(GenerateInvoiceController.ItemWrapper objItem :  objController.listOfItems){
            objItem.itemName = 'Books';
            objItem.price = 500;
            objItem.selectedStudent = objCustmr.id;
        }
        
        objController.index= '1';
        objController.RemoveRow();
        
        objController.toggaleSummary();
        
        objController.getCampPkgList();
        objController.fetchPkgAmount();
        //objController.selectedCenter = centreObj.Id;
        objController.fetchCentreCountry();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        objController.payAndRedirect();
        test.stopTest();
             
    }
    
    //@jatin : 3-Dec:2019
     @isTest
    private static void unitTest2(){
         //Create Country Records
        Country__c objCountry = AureusCalendarControllerTestHelper.createCountryRecord ('Singapore','SGD',true);
       
        // Create 2 Centre  
        List<Account> ListCentre = new List<Account>();
        ListCentre.add(AureusCalendarControllerTestHelper.createCentre('Aureus AMK Hub', objCountry.Id,FALSE));
        Insert ListCentre; 
        
        
        // Create Customer
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        objCustmr.Centre_Name__c = ListCentre[0].Id;
        objCustmr.personEmail = 'test1@tmc.com';
        update objCustmr;
        
        //Account centreObj = TestUtil.createAccount('Centre',True,True);
        ApexPages.StandardController sc = new ApexPages.StandardController(objCustmr);
        GenerateInvoiceController objController = new GenerateInvoiceController(sc);
        
        objController.addRow();
        for(GenerateInvoiceController.ItemWrapper objItem :  objController.listOfItems){
            objItem.itemName = 'Books';
            objItem.price = 500;
            objItem.selectedStudent = objCustmr.id;
        }
        
        objController.index= '1';
        objController.RemoveRow();
        
        objController.toggaleSummary();
        
        objController.getCampPkgList();
        objController.fetchPkgAmount();
        objController.selectedCenter = ListCentre[0].Id;
        objController.fetchCentreCountry();
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true,"Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        objController.payAndRedirect();
        test.stopTest();
             
    }
}