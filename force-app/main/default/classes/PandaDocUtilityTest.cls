/*
 * Name			:		PandaDocUtilityTest
 * Date			:		30/08/2019
 * Description	:		This Class is to cover the pandadoc Utility Class.
*/ 
@isTest
private class PandaDocUtilityTest {
	@isTest
    static void PandaDocTest(){
        Test.setMock(HttpCalloutMock.class, new PandaDocUtilityTestMocks());
        PandaDocUtility.createDocument('{"id": "001"}');
        PandaDocUtility.sendDocument('{"id": "001"}', '001');
        PandaDocUtility.createSession('001', '{"id": "001"}');
        PandaDocUtility.viewDocument('001');
        
    }
    //Added by jatin: 17-Mar-2020: for test  viewDocumentDetails method for Return stairs data about a document
    @isTest
    static void PandaDocTestviewDocumentDetails(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "R33xS4Ybe3qtBbRyke2p6a", "name": "[DEV] Enr-13456-RentalPolicy", "date_created": "2020-01-22T08:20:58.179132Z", "date_modified": "2020-01-22T08:20:58.652923Z", "template": { "id": "5jfk4yvnNWaqsjmg4tdnbm", "name": "Delivery Order Template" }, "tokens": [{ "name": "Delivery_Person.FirstName" }], "fields": [{ "uuid": "NmobNHTwG6fdu5bVcnAUbZ", "name": "Stairs", "title": "Stairs", "assigned_to": { "id": "QpQRqhYV4k9K95kAqrgaof", "first_name": "Ashish", "last_name": "Bansal", "email": "ashish@outlook.com", "recipient_type": "signer", "has_completed": false, "role": "Delivery_Person", "type": "recipient" }, "value": "0" }] }'));
        PandaDocUtility.viewDocumentDetails('R33xS4Ybe3qtBbRyke2p6a','stairs');
    }
}