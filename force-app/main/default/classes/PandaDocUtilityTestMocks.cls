/*
 * Name			:		PandaDocUtilityTestMocks
 * Date			:		30/08/2019
 * Description	:		This Class is to cover the pandadoc MockTests.
*/ 
@isTest
global class PandaDocUtilityTestMocks implements HttpCalloutMock {
    
    /*
     * This method will cover all callouts from PandadocUtility
     * 
    */
    global HTTPResponse respond(HTTPRequest req) {
     	HttpResponse res = new HttpResponse();
		res.setHeader('Content-Type', 'application/json');
		res.setBody('{"example":"test"}');
		res.setStatusCode(200);
		return res;
    }
}