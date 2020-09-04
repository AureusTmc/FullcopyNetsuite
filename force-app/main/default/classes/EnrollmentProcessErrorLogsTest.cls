@isTest
public class EnrollmentProcessErrorLogsTest {
	@isTest
    private static void unitTest(){
        Test.startTest();
        Account customer = TestUtil.createAccount('Customer',TRUE,TRUE);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"status": "succeeded","Id":"ch_1AxWbTFytruJp2FXW6iuRd1X"}'));
        EnrollmentProcessErrorLogs.errorLogObj logObj = new EnrollmentProcessErrorLogs.errorLogObj();
        logObj.customerSalesforceId= customer.id;
    	logObj.customerStripeId = 'cus_123';
    	logObj.stripeTransactionId='xyz';
    	logObj.stripeChargeAmount=10.50;
    	logObj.exceptionMessage='test error';
        EnrollmentProcessErrorLogs.generateErrorLogsAndRefundAmount(JSON.serialize(logObj));
        Test.stopTest();
    }
}