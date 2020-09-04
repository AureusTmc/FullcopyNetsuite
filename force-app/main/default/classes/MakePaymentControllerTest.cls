/*
Name        :        MakePaymentControllerTest
Date        :        2 April 2019
Author      :        Karan Singh Soni
Description :        It is the test class of MakePaymentController.
*/
@isTest
public class MakePaymentControllerTest {
    public static testmethod void invokeMakePaymentControllerTest(){
        Account objCustmr=TestUtil.createAccount('Customer',false,False);
        objCustmr.Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X';
        insert objCustmr;
        
        Invoice__C objInv=TestUtil.createInvoice(objCustmr.id,False);
        objInv.Status__c='Due';
        objInv.Parent_Account__c=objCustmr.id;
        insert objInv;
        
        Invoice_Line_Item__c objInvLneItm=TestUtil.createInvLineItem(objInv.id,false);
        objInvLneItm.Amount__c=80.00;
        
        insert objInvLneItm;
        
        apexpages.currentpage().getparameters().put('id',objInv.Id);
        MakePaymentController objMPC=new MakePaymentController();
        MakePaymentController.getInvoice(objInv.id);
        MakePaymentController.sendInvoiceMail(objInv.id);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "ch_1AxWbTFytruJp2FXW6iuRd1X", "object": "charge", "amount": 100, "amount_refunded": 0, "application": null, "application_fee": null, "balance_transaction": "txn_17JOXKFytruJp2FXS4XNisQd", "captured": false, "created": 1504339423, "currency": "usd", "customer": null, "description": "My First Test Charge (created for API docs)", "destination": null, "dispute": null, "failure_code": null, "failure_message": null, "fraud_details": { }, "invoice": null, "livemode": false, "metadata": { }, "on_behalf_of": null, "order": null, "outcome": null, "paid": true, "receipt_email": null, "receipt_number": null, "refunded": false, "refunds": { "object": "list", "data": [], "has_more": false, "total_count": 0, "url": "/v1/charges/ch_1AxWbTFytruJp2FXW6iuRd1X/refunds" }, "review": null, "shipping": null, "source": { "id": "card_1AxWPmFytruJp2FXw4m0V0fN", "object": "card", "address_city": null, "address_country": null, "address_line1": null, "address_line1_check": null, "address_line2": null, "address_state": null, "address_zip": "10001", "address_zip_check": "unchecked", "brand": "Visa", "country": "US", "customer": null, "cvc_check": "unchecked", "dynamic_last4": null, "exp_month": 4, "exp_year": 2024, "fingerprint": "sNtyd9sZ2vA6o4IM", "funding": "credit", "last4": "4242", "metadata": { }, "name": "Mandeep", "tokenization_method": null }, "source_transfer": null, "statement_descriptor": null, "status": "succeeded", "transfer_group": null }'));
        MakePaymentController.createCharge('sk_test_BQokikJOvBiI2HlWgH4olfQ2',objInv.id);
        Test.stopTest();
    }
}