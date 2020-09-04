@isTest
public class EnrolmentThankyouIpadCntrlTest {

    testMethod static void invokeEnrolmentThankyouIpadMethod(){
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
        
        Account objCustmr=TestUtil.createAccount('Customer',True,True);
        Account objCentr=TestUtil.createAccount('Centre',False,False);
        objCentr.Country__c = cntry.Id;
        Insert objCentr;
        
        Account objtechr=TestUtil.createAccount('Teacher',False,true);
        Program__C objProg=TestUtil.createProgram('Active','Piano',true);
        Package__c objPack=testUtil.createPackage(objProg.id,objCentr.id,'60',true);             
        Enrolment__c objENrol=TestUtil.createEnrolment(objCentr.Id,objTechr.Id,objCustmr.Id,objPack.id,False);
        objENrol.Type__c='Trial';
        objEnrol.Stage__c='Requested';
        
        insert objENrol;
        
        Booking__c objBook = TestUtil.createBooking(objtechr.id, 'Lesson','Trial',False);
        ObjBook.Enrolment__c=objEnrol.id;
        objBook.Center__c=objCentr.Id;
        objBook.Booking_Date__c=System.today();
        
        insert objBook;
        
        Invoice__c objINV=new Invoice__c();
        objINV.Parent_Account__c=objCustmr.Id;
        objINV.Invoice_Date__c=system.today();
        objINV.Due_Date__c=system.today().addDays(30);
        
        
        insert objINV;
        set<String> idsObj = new set<String>();
        idsObj.add(objINV.Id);
       
        ApexPages.currentPage().getParameters().put('inv','inv');
        ApexPages.currentPage().getParameters().put('bookId',objBook.id);
        EnrolmentThankyouIpadCntrl enrolObj = new EnrolmentThankyouIpadCntrl();
        enrolObj.generateInvPdf();
        enrolObj.sendEmailWithPdfOnStudio(objBook.Id);
         //ApexPages.currentPage().getParameters().put('Studio','Studio');
        //enrolObj.generateInvPdf();
        ApexPages.currentPage().getParameters().put('scId',objINV.Id);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id":"cus_EmndZcxxpUhDzD", "object": "customer", "account_balance": 0, "created": 1553840254, "currency": "usd", "default_source": null, "delinquent": false, "description": null, "discount": null, "email": null, "invoice_prefix": "98B2456", "invoice_settings": { "custom_fields": null, "footer": null }, "livemode": false, "metadata": {}, "shipping": null, "sources": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/sources" }, "subscriptions": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_EmndZcxxpUhDzD/subscriptions" }, "tax_info": null, "tax_info_verification": null }'));
        enrolObj.updateInvoiceNumOnStripe(idsObj);
        enrolObj.sendEmailWithPdf(new set<String> {objINV.Id});
        EnrolmentThankyouIpadCntrl.fillAtt(Blob.valueOf('Test'),objCustmr.Id,'Test');
    } 
}