@isTest
public class MockHttpResponseGeneratorTest {
    public Static testMethod Void invokeMockHttpResponseGenerator(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
    }
}