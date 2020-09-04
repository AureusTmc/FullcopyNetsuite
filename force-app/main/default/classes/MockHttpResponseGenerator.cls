@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    protected integer statuscode;
    protected String Body;
    public MockHttpResponseGenerator(integer status,String Body){
        this.statuscode=status;
        this.Body=body;
    }
    global HTTPResponse respond(HTTPRequest req) {
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');     
        res.setBody(Body);
        res.setStatusCode(statuscode);
        return res;
    }
}