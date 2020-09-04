@isTest
public class MobileAppTest {
    
    @TestSetup 
    public static void setup(){
        MobileAppUtility.init();
    }
   
    // Start : Cover home api code
    
    // Call Home api with token paramenter
    @isTest
    public static void homeWebServiceWithToken() {
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/home';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"emailId": "user@yahoo.com","password": "Aureus@123","appversion": '+Label.Aureus_Academy_App_Version+', "token":"t"}');
        
        RestContext.request = req;
        RestContext.response= res;
        AureusHomeWebService.getHomeData();
        Test.stopTest();     
        //System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    
     // Call Home api without token paramenter
    @isTest
    public static void homeWebServiceWithoutToken() {
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/home';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"emailId": "user@yahoo.com","password": "Aureus@123","appversion": '+Label.Aureus_Academy_App_Version+'}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        AureusHomeWebService.getHomeData();
        
        Test.stopTest();        
    }
   
    // Call Home api with version  paramenter and check  verison error
    @isTest
    static void getHomeDataGetversionError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/home/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"emailId": "test@gmail.com",'+
            '"password": "test",'+
            '"appversion": "-1"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusHomeWebService.getHomeData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "VERSION_ERROR ","message": "Update is required to login into the app." }'),String.valueOf(RestContext.response.responseBody));
    }
    
    // call home api for check missing parameter error 
    @isTest
    static void getHomeDataPostError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/home/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"emailId": "test@gmail.com",'+
            '"password": "test"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusHomeWebService.getHomeData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    
      // End : Cover home api code
      
     // Start :  Cover Invoice api code 
     
     // Call Invoice api for get all  invoice  record and related payment record
    @isTest
    static void testInvoiceAllDataSucessmsg() {
        // prepare test-data
        List<Account> listOfaccount = [SELECT Id 
                                       FROM Account
                                       WHERE RecordType.name = 'Customer' AND FirstName = 'Sunny'];
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/Invoice/'+listOfAccount[0].id; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusGetInvoiceWebService.getinvoiceData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    // Call Invoice api for get account not found error 
    @isTest
    static void testGetInvoiceAccountErrorMsg() {
        // prepare test-data
        List<Account> listOfaccount = [SELECT Id 
                                       FROM Account
                                       WHERE RecordType.name = 'Teacher'];
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/Invoice/'+listOfAccount[0].id; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusGetInvoiceWebService.getinvoiceData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }    
    // Call Invoice api for check missing parameter error 
    @isTest
    static void testInvoiceErroMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/Invoice/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusGetInvoiceWebService.getinvoiceData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    
    // END :  Cover Invoice api code 
    
     // Start :  Cover signup api code 
     
     // Call signup api for update Custom setting 
    @isTest
    public static void signupWebServiceGetOtp() {
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/signup';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"emailId": "user@yahoo.com","appversion": '+Label.Aureus_Academy_App_Version+', "reset":"true"}');
        
        RestContext.request = req;
        RestContext.response= res;
        AureusSignupWebService.getAccountData();
        Test.stopTest(); 
       // System.assert(RestContext.response.statusCode == 200);
       // System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"OTP sent to user@yahoo.com"}'));
    
    }
    
    // Call signup api for reset password
    @isTest
    public static void signupWebServiceResetPassword() {
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/signup';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"emailId": "user@yahoo.com","password": "Aureus@1234","OTP": 1234}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        AureusSignupWebService.getAccountData();
        
        Test.stopTest(); 
        System.assert(RestContext.response.statusCode == 200);
    }
    
    // Call signup api for checkout not update password
    @isTest
    public static void signupWebServiceResetCheckoutPassword() {
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/signup';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"emailId": "user@yahoo.com","password": "","OTP": 1234}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        AureusSignupWebService.getAccountData();
        
        Test.stopTest(); 
        System.assert(RestContext.response.statusCode == 200);
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errroCode":"SUCCESS","message":"Checked your OTP"}'),String.valueOf(RestContext.response.responseBody));
    }
    
    // Call signup api for invalid otp error
    @isTest
    public static void signupWebServiceinvalidOTPError() {
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/signup';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"emailId": "user@yahoo.com","password": "Aureus@123","OTP": 12341}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        AureusSignupWebService.getAccountData();
        
        Test.stopTest(); 
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"INVALID_OTP","message":"Invalid OTP. Please check OTP again"}'),String.valueOf(RestContext.response.responseBody));
        
    }
    
    // Call signup api for reset password
    @isTest
    public static void signupWebServiceResetPasswordError() {
        Test.startTest();
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/signup';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"emailId": "user@yahoo.com","password": "Aureus@123","OTP": 1234}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        AureusSignupWebService.getAccountData();
        
        Test.stopTest(); 
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"OLD_PASS","message":"You cannot use last password again"}'),String.valueOf(RestContext.response.responseBody));
        
    }
    
    // Call signup api for  check version error
     @isTest
    static void getSignUpGetVersionError() {
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/signup';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"emailId": "user@yahoo.com","appversion": -1, "reset":"true"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
       
        Test.startTest();
        AureusSignupWebService.getAccountData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "VERSION_ERROR ","message": "Update your version." }'),String.valueOf(RestContext.response.responseBody));
    }
    
    // Call signup api for check missing parameter error 
    @isTest
    static void getSignUpGetParameterError() {
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/signup';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof('{"appversion": -1, "reset":"true"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
       
        Test.startTest();
        AureusSignupWebService.getAccountData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'),String.valueOf(RestContext.response.responseBody));
    }
     
    // END :  Cover signup api code 
     
    // Start :  Cover Attachment api code 
    @isTest
    static void updateProfilePOSTSuccess() {
        // prepare test-data
        List<account> listOfAccount = [SELECT Id from account];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/updateProfile/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"parentId": "'+listOfAccount[0].id+'","body": "R0lGODlhDAAMAKIFAF5LAP/zxAAAANyuAP/gaP///wAAAAAAACH5BAEAAAUALAAAAAAMAAwAAAMlWLPcGjDKFYi9lxKBOaGcF35DhWHamZUW0K4mAbiwWtuf0uxFAgA7"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusAttachmentWebService.createAttachmentData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200);
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"Record save sucessfully."}'));
    }
    
    @isTest
    static void updateProfilePOSTError() {
        // prepare test-data
        List<account> listOfAccount = [SELECT Id from account];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site + '/services/apexrest/updateProfile/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"parentId": "'+listOfAccount[0].id+'"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusAttachmentWebService.createAttachmentData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    // END :  Cover Attachment api code 
    
    // Start :  Cover Cancel Booking api code  
    @isTest
    static void updateCancelBookingPost() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Teacher_Account__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c 
                                          from Booking__c
                                          WHERE status__c = 'Pending'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"bookingIds": "'+listOfBooking[0].id+'",'+
            '"cancellationReason": "Exams",'+
            '"makeUpReason": "Teacher MC","makeupRemark": "makeupRemark"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.updateCancelBooking();
        Test.stopTest();
        System.debug(RestContext.response.responseBody);
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"Booking Cancelled Successfully"}'),String.valueOf(RestContext.response.responseBody));
        System.assert([select id 
                       from Booking__c 
                       WHERE status__c = 'Scheduled'
                       And Category__c ='Placeholder'].size() > 0 );
    }
    
    
     @isTest
    static void updateCancelFifthLessonPost() {
        // prepare test-data
        List<Fifth_Lesson__c> listOfBooking = [SELECT Id,Booking_Date__c,Start_Time__c,End_Time__c 
                                          from Fifth_Lesson__c
                                              where Booking__c = null];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"bookingIds": "'+listOfBooking[0].id+'",'+
            '"cancellationReason": "Exams",'+
            '"makeUpReason": "Teacher MC","makeupRemark": "makeupRemark"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.updateCancelBooking();
        Test.stopTest();
        System.debug(RestContext.response.responseBody);
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"Booking Cancelled Successfully"}'),String.valueOf(RestContext.response.responseBody));
        System.assert([select id 
                       from Booking__c 
                       WHERE status__c = 'Scheduled'
                       And Category__c ='Placeholder'].size() > 0 );
    }
    
    
     @isTest
    static void updateCancelMakeupBookingPost() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Teacher_Account__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c 
                                          from Booking__c
                                          WHERE Type__c = 'Make-up' and Status__c = 'Scheduled'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"bookingIds": "'+listOfBooking[0].id+'",'+
            '"cancellationReason": "Exams",'+
            '"makeUpReason": "Teacher MC","makeupRemark": "makeupRemark"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.updateCancelBooking();
        Test.stopTest();
        System.debug(RestContext.response.responseBody);
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"Booking Cancelled Successfully"}'),String.valueOf(RestContext.response.responseBody));
        System.assert([select id 
                       from Booking__c 
                       WHERE status__c = 'Scheduled'
                       And Category__c ='Placeholder'].size() > 0 );
    }
    @isTest
    static void testCancelBookingWithReason() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Teacher_Account__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c 
                                          FROM Booking__c
                                          WHERE status__c = 'Pending'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"bookingIds": "'+listOfBooking[0].id+'",'+
            '"cancellationReason": "Personal Reason",'+
            '"makeUpReason": "Other","makeupRemark": "test"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.updateCancelBooking();
        Test.stopTest();
        System.debug(RestContext.response.responseBody.toString());
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"Booking Cancelled Successfully"}'),String.valueOf(RestContext.response.responseBody));
        System.assert([select id 
                       from Booking__c 
                       WHERE status__c = 'Scheduled'
                       And Category__c ='Placeholder'].size() > 0 );
    }
    
    @isTest
    static void updateCancelBookingPostError() {
        // prepare test-data
        //List<Booking__c> listOfBooking = [SELECT Id,Teacher_Account__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c from Booking__c];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"cancellationReason": "Exams",'+
            '"makeUpReason": "Teacher MC","makeupRemark": "makeupRemark"}';
        req.requestBody = Blob.valueof(JsonMsg);
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.updateCancelBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    
    @isTest
    static void cancelBookingGetSuccess() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Parent__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c 
                                          from Booking__c
                                          WHERE status__c = 'Canceled'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.addParameter('parentId', listOfBooking[0].Parent__c);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.getCancelBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    
    @isTest
    static void testAccountgNotFound() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Parent__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c 
                                          FROM Booking__c
                                          WHERE status__c = 'Pending'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.addParameter('parent', listOfBooking[0].Parent__c);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.getCancelBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode );
    }
    @isTest
    static void testCancelBookingNotFound() {
        // prepare test-data
        List<Account> listOfaccount = [SELECT Id 
                                       FROM Account
                                       WHERE RecordType.name = 'Teacher'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.addParameter('parentId',listOfaccount[0].Id);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.getCancelBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    
    @isTest
    static void cancelBookingGetError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingCancellation/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCancelBookingWebService.getCancelBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    // END :  Cover Cancel Booking api code  
    
    // END :  Cover case  api code  
    @isTest
    static void createCaseDataReferFriendPostSuccess() {
        // prepare test-data
        List<Enrolment__c> listOfEnrolment = [SELECT Id,Center__c, Teacher__c,Package__c,Student__c,Parent__c FROM Enrolment__c];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"parentId":"'+listOfEnrolment[0].Parent__c+'",'+
            ' "studentId":"'+listOfEnrolment[0].Student__c+'",'+
            '"requestType":"Refer a Friend","subject":"Sales Enquirytes ","details":"First Name: Abdul Last Name: Rehman Email: andul@gmail.com Phone: 78945612330 Comment: They are providing free classes for this month!"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCaseWebService.createCaseData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        
        System.assert([select id 
                       from Case].size() > 0 );
    }
     @isTest
    static void createCaseDataRequestTypePostSuccess() {
        // prepare test-data
        List<Enrolment__c> listOfEnrolment = [SELECT Id,Center__c, Teacher__c,Package__c,Student__c,Parent__c FROM Enrolment__c];
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.httpMethod = 'POST';
        
        string JsonMsg=' {"parentId":"'+listOfEnrolment[0].Parent__c+'",'+
            ' "studentId":"'+listOfEnrolment[0].Student__c+'",'+
            '"requestType":"Student Details","subject":"Sales Enquirytes ","details":""}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        
        AureusCaseWebService.createCaseData();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.httpMethod = 'POST';
        
        JsonMsg=' {"parentId":"'+listOfEnrolment[0].Parent__c+'",'+
            ' "studentId":"'+listOfEnrolment[0].Student__c+'",'+
            '"requestType":"Personal Details","subject":"Sales Enquirytes ","details":""}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        
        AureusCaseWebService.createCaseData();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.httpMethod = 'POST';
        
        JsonMsg=' {"parentId":"'+listOfEnrolment[0].Parent__c+'",'+
            ' "studentId":"'+listOfEnrolment[0].Student__c+'",'+
            '"requestType":"Enrolment (Change Enrolment)","subject":"Sales Enquirytes ","details":""}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        
        AureusCaseWebService.createCaseData();
        
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.httpMethod = 'POST';
        JsonMsg=' {"parentId":"'+listOfEnrolment[0].Parent__c+'",'+
            ' "studentId":"'+listOfEnrolment[0].Student__c+'",'+
            '"requestType":"Ticket Tab","subject":"Sales Enquirytes ","details":""}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        
        AureusCaseWebService.createCaseData();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.httpMethod = 'POST';
        JsonMsg=' {"parentId":"'+listOfEnrolment[0].Parent__c+'",'+
            ' "studentId":"'+listOfEnrolment[0].Student__c+'",'+
            '"requestType":"Lesson (Contact Us)","subject":"Sales Enquirytes ","details":""}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        
        AureusCaseWebService.createCaseData();
        
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        
        System.assert([select id 
                       from Case].size() > 0 );
    }
    @isTest
    static void createCaseDataPostError() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"requestType":"Sales Enquiry test","subject":"Sales Enquirytes ","details":""}';
        req.requestBody = Blob.valueof(JsonMsg);
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCaseWebService.createCaseData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    @isTest
    static void testAllCaseGetSucessMsg() {
        // prepare test-data
        List<case> listOfcase = [SELECT Id,AccountId from case];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.addParameter('parent_sf_Id', listOfcase[0].AccountId);
        req.addParameter('type','');
        req.addParameter('limit', '5');
        req.addParameter('offset', '0');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCaseWebService.getCaseData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void testHistoricalCaseGetSucessMsg() {
        // prepare test-data
        List<case> listOfcase = [SELECT Id,AccountId from case];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.addParameter('parent_sf_Id', listOfcase[0].AccountId);
        req.addParameter('type','historical');
        req.addParameter('limit', '1');
        req.addParameter('offset', '1');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCaseWebService.getCaseData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void getCaseDataGetSuccess() {
        // prepare test-data
        List<case> listOfcase = [SELECT Id,AccountId from case];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.addParameter('parent_sf_Id', listOfcase[0].AccountId);
        req.addParameter('type','upcoming');
        req.addParameter('limit', '1');
        req.addParameter('offset', '1');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCaseWebService.getCaseData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void getCaseDataGetError() {
        // prepare test-data
        //List<Booking__c> listOfBooking = [SELECT Id,Teacher_Account__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c from Booking__c];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/case/'; //Request URL
        req.addParameter('type','');
        req.addParameter('limit', '1');
        req.addParameter('offset', '1');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCaseWebService.getCaseData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    // END :  Cover case api code  
    
     // Start :  Cover Update Customer Card api code  
    @isTest
    static void testUpdateCardSucessMsg() {
        // prepare test-data
        List<Account> listOfAccount = [SELECT Id
                                       from Account where PersonEmail = 'user@yahoo.com'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/customerCard/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"parentId": "'+listOfAccount[0].id+'","expMonth": "5","expYear": "2025", "token": "t"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "cus_FV9JjEhEpMdafV", "object": "customer", "account_balance": 0, "address": null, "balance": 0, "created": 1564069045, "currency": null,'+
                                                                          ' "default_source": "card_1F090RJja9IPifcS4jkoWldg", "delinquent": false, "description": "Add customer from update card page", "discount": null, '+
                                                                          '"email": "shahrukhkhan.ibirdscollege@gmail.com", "invoice_prefix": "B9EE59AF", "invoice_settings": { "custom_fields": null, "default_payment_method": null, "footer": null },'+
                                                                          ' "livemode": false, "metadata": { "Name": "Shahrukh Khan" }, "name": null, "phone": null, "preferred_locales": [ ], "shipping": null, "sources": { "object": "list", '+
                                                                          '"data": [ { "id": "card_1F090RJja9IPifcS4jkoWldg", "object": "card", "address_city": null, "address_country": null, "address_line1": null, "address_line1_check": null,'+
                                                                          ' "address_line2": null, "address_state": null, "address_zip": null, "address_zip_check": null, "brand": "Visa", "country": "US", "customer": "cus_FV9JjEhEpMdafV",'+
                                                                          ' "cvc_check": "pass", "dynamic_last4": null, "exp_month": 5, "exp_year": 2025, "fingerprint": "DodUMgRQg0xbj77T", "funding": "credit", "last4": "4242", "metadata": { }, '+
                                                                          '"name": null, "tokenization_method": null } ], "has_more": false, "total_count": 1, "url": "/v1/customers/cus_FV9JjEhEpMdafV/sources" }, "subscriptions": { "object": "list", '+
                                                                          '"data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_FV9JjEhEpMdafV/subscriptions" }, "tax_exempt": "none", "tax_ids": { "object": "list", "data": [ ],'+
                                                                          ' "has_more": false, "total_count": 0, "url": "/v1/customers/cus_FV9JjEhEpMdafV/tax_ids" }, "tax_info": null, "tax_info_verification": null }'));        
        AureusCustomerCardWebService.updateCustomerCard();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void testInsertCardDetailsStripExist() {
        // prepare test-data
        List<Account> listOfAccount = [SELECT Id
                                       from Account where Stripe_Customer_Id__c != null];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/customerCard/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"parentId": "'+listOfAccount[0].id+'",'+
            '"token": "t"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "cus_F77hsHA1L2dKkj", "object": "customer", "account_balance": 0, "address": null, "balance": 0, '+
                                                                          '"created": 1558527712, "currency": null, "default_source": "src_1EzywTJja9IPifcSaz7gZUDB", "delinquent": false, '+
                                                                          '"description": "Parent customer", "discount": null, "email": "abansal.test2@gmail.com", "invoice_prefix": "8D510956",'+
                                                                          ' "invoice_settings": { "custom_fields": null, "default_payment_method": null, "footer": null }, "livemode": false, '+
                                                                          '"metadata": { "Name": "AshishBansal2205_2" }, "name": null, "phone": null, "preferred_locales": [ ], "shipping": null, '+
                                                                          '"sources": { "object": "list", "data": [ { "id": "src_1EzywTJja9IPifcSaz7gZUDB", "object": "source", "amount": null, '+
                                                                          '"card": { "exp_month": 12, "exp_year": 2023, "last4": "5100", "country": "US", "brand": "MasterCard", "cvc_check": "pass",'+
                                                                          ' "funding": "prepaid", "fingerprint": "WukhpWZwEGNuUZyw", "three_d_secure": "optional", "name": null, "address_line1_check": null,'+
                                                                          ' "address_zip_check": null, "tokenization_method": null, "dynamic_last4": null }, "client_secret": "src_client_secret_FUyuAl9DUP1cQ5Kq1HILQxha",'+
                                                                          ' "created": 1564030357, "currency": null, "customer": "cus_F77hsHA1L2dKkj", "flow": "none", "livemode": false, "metadata": { }, '+
                                                                          '"owner": { "address": null, "email": null, "name": null, "phone": null, "verified_address": null, "verified_email": null, "verified_name": null, "verified_phone": null },'+
                                                                          ' "statement_descriptor": null, "status": "chargeable", "type": "card", "usage": "reusable" }, { "id": "src_1Ezh8bJja9IPifcSmfyXKou6", "object": "source", "amount": null, '+
                                                                          '"card": { "exp_month": 12, "exp_year": 2033, "last4": "0005", "country": "US", "brand": "American Express", "cvc_check": "pass", "funding": "credit",'+
                                                                          ' "fingerprint": "0p5GqeuE3rDhu9jv", "three_d_secure": "optional", "name": null, "address_line1_check": null, "address_zip_check": null, "tokenization_method": null,'+
                                                                          ' "dynamic_last4": null }, "client_secret": "src_client_secret_FUgVp2JwihJgT7RiFdtub60b", "created": 1563961917, "currency": null, "customer": "cus_F77hsHA1L2dKkj", "flow": "none",'+
                                                                          ' "livemode": false, "metadata": { }, "owner": { "address": null, "email": null, "name": null, "phone": null, "verified_address": null, "verified_email": null, "verified_name": null, '+
                                                                          '"verified_phone": null }, "statement_descriptor": null, "status": "chargeable", "type": "card", "usage": "reusable" }, { "id": "src_1Ezh6uJja9IPifcSok78xnWj", "object": "source", '+
                                                                          '"amount": null, "card": { "exp_month": 12, "exp_year": 2022, "last4": "8431", "country": "US", "brand": "American Express", "cvc_check": "pass", "funding": "credit", '+
                                                                          '"fingerprint": "h79CyYN7MF3PVNnK", "three_d_secure": "optional", "name": null, "address_line1_check": null, "address_zip_check": null, "tokenization_method": null, "dynamic_last4": null },'+
                                                                          ' "client_secret": "src_client_secret_FUgTJupSVysyadJZgRq6ihYf", "created": 1563961812, "currency": null, "customer": "cus_F77hsHA1L2dKkj", "flow": "none", "livemode": false, "metadata": { },'+
                                                                          ' "owner": { "address": null, "email": null, "name": null, "phone": null, "verified_address": null, "verified_email": null, "verified_name": null, "verified_phone": null }, '+
                                                                          '"statement_descriptor": null, "status": "chargeable", "type": "card", "usage": "reusable" }, { "id": "src_1EzeyNJja9IPifcSzovczX5N", "object": "source", "amount": null,'+
                                                                          ' "card": { "exp_month": 12, "exp_year": 2020, "last4": "4444", "country": "US", "brand": "MasterCard", "cvc_check": "pass", "funding": "credit", '+
                                                                          '"fingerprint": "JeJNtXmDmtX5F6N0", "three_d_secure": "optional", "name": null, "address_line1_check": null, "address_zip_check": null, "tokenization_method": null, "dynamic_last4": null },'+
                                                                          ' "client_secret": "src_client_secret_FUeGVeN57uUtZhjiIZBKFi70", "created": 1563953595, "currency": null, "customer": "cus_F77hsHA1L2dKkj", "flow": "none", "livemode": false, "metadata": { }, '+
                                                                          '"owner": { "address": null, "email": null, "name": null, "phone": null, "verified_address": null, "verified_email": null, "verified_name": null, "verified_phone": null }, '+
                                                                          '"statement_descriptor": null, "status": "chargeable", "type": "card", "usage": "reusable" }, { "id": "card_1EctS7Jja9IPifcSddmSFvZh", "object": "card", "address_city": null, '+
                                                                          '"address_country": null, "address_line1": null, "address_line1_check": null, "address_line2": null, "address_state": null, "address_zip": null, "address_zip_check": null, '+
                                                                          '"brand": "MasterCard", "country": "US", "customer": "cus_F77hsHA1L2dKkj", "cvc_check": "pass", "dynamic_last4": null, "exp_month": 12, "exp_year": 2022, "fingerprint": "JeJNtXmDmtX5F6N0", '+
                                                                          '"funding": "credit", "last4": "4444", "metadata": { }, "name": null, "tokenization_method": null } ], "has_more": false, "total_count": 5, "url": "/v1/customers/cus_F77hsHA1L2dKkj/sources" }, '+
                                                                          '"subscriptions": { "object": "list", "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_F77hsHA1L2dKkj/subscriptions" }, "tax_exempt": "none", "tax_ids": { "object": "list",'+
                                                                          ' "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_F77hsHA1L2dKkj/tax_ids" }, "tax_info": null, "tax_info_verification": null }'));  
        
        AureusCustomerCardWebService.updateCustomerCard();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void testInsertCardDetailsStriptNotExist() {
        // prepare test-data
        List<Account> listOfAccount = [SELECT Id
                                       from Account where Stripe_Customer_Id__c = null];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/customerCard/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"parentId": "'+listOfAccount[0].id+'",'+
            '"token": ""}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
         Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{ "id": "cus_F77hsHA1L2dKkj", "object": "customer", "account_balance": 0, "address": null, "balance": 0, '+
                                                                          '"created": 1558527712, "currency": null, "default_source": "src_1EzywTJja9IPifcSaz7gZUDB", "delinquent": false, '+
                                                                          '"description": "Parent customer", "discount": null, "email": "abansal.test2@gmail.com", "invoice_prefix": "8D510956",'+
                                                                          ' "invoice_settings": { "custom_fields": null, "default_payment_method": null, "footer": null }, "livemode": false, '+
                                                                          '"metadata": { "Name": "AshishBansal2205_2" }, "name": null, "phone": null, "preferred_locales": [ ], "shipping": null, '+
                                                                          '"sources": { "object": "list", "data": [ { "id": "src_1EzywTJja9IPifcSaz7gZUDB", "object": "source", "amount": null, '+
                                                                          '"card": { "exp_month": 12, "exp_year": 2023, "last4": "5100", "country": "US", "brand": "MasterCard", "cvc_check": "pass",'+
                                                                          ' "funding": "prepaid", "fingerprint": "WukhpWZwEGNuUZyw", "three_d_secure": "optional", "name": null, "address_line1_check": null,'+
                                                                          ' "address_zip_check": null, "tokenization_method": null, "dynamic_last4": null }, "client_secret": "src_client_secret_FUyuAl9DUP1cQ5Kq1HILQxha",'+
                                                                          ' "created": 1564030357, "currency": null, "customer": "cus_F77hsHA1L2dKkj", "flow": "none", "livemode": false, "metadata": { }, '+
                                                                          '"owner": { "address": null, "email": null, "name": null, "phone": null, "verified_address": null, "verified_email": null, "verified_name": null, "verified_phone": null },'+
                                                                          ' "statement_descriptor": null, "status": "chargeable", "type": "card", "usage": "reusable" }, { "id": "src_1Ezh8bJja9IPifcSmfyXKou6", "object": "source", "amount": null, '+
                                                                          '"card": { "exp_month": 12, "exp_year": 2033, "last4": "0005", "country": "US", "brand": "American Express", "cvc_check": "pass", "funding": "credit",'+
                                                                          ' "fingerprint": "0p5GqeuE3rDhu9jv", "three_d_secure": "optional", "name": null, "address_line1_check": null, "address_zip_check": null, "tokenization_method": null,'+
                                                                          ' "dynamic_last4": null }, "client_secret": "src_client_secret_FUgVp2JwihJgT7RiFdtub60b", "created": 1563961917, "currency": null, "customer": "cus_F77hsHA1L2dKkj", "flow": "none",'+
                                                                          ' "livemode": false, "metadata": { }, "owner": { "address": null, "email": null, "name": null, "phone": null, "verified_address": null, "verified_email": null, "verified_name": null, '+
                                                                          '"verified_phone": null }, "statement_descriptor": null, "status": "chargeable", "type": "card", "usage": "reusable" }, { "id": "src_1Ezh6uJja9IPifcSok78xnWj", "object": "source", '+
                                                                          '"amount": null, "card": { "exp_month": 12, "exp_year": 2022, "last4": "8431", "country": "US", "brand": "American Express", "cvc_check": "pass", "funding": "credit", '+
                                                                          '"fingerprint": "h79CyYN7MF3PVNnK", "three_d_secure": "optional", "name": null, "address_line1_check": null, "address_zip_check": null, "tokenization_method": null, "dynamic_last4": null },'+
                                                                          ' "client_secret": "src_client_secret_FUgTJupSVysyadJZgRq6ihYf", "created": 1563961812, "currency": null, "customer": "cus_F77hsHA1L2dKkj", "flow": "none", "livemode": false, "metadata": { },'+
                                                                          ' "owner": { "address": null, "email": null, "name": null, "phone": null, "verified_address": null, "verified_email": null, "verified_name": null, "verified_phone": null }, '+
                                                                          '"statement_descriptor": null, "status": "chargeable", "type": "card", "usage": "reusable" }, { "id": "src_1EzeyNJja9IPifcSzovczX5N", "object": "source", "amount": null,'+
                                                                          ' "card": { "exp_month": 12, "exp_year": 2020, "last4": "4444", "country": "US", "brand": "MasterCard", "cvc_check": "pass", "funding": "credit", '+
                                                                          '"fingerprint": "JeJNtXmDmtX5F6N0", "three_d_secure": "optional", "name": null, "address_line1_check": null, "address_zip_check": null, "tokenization_method": null, "dynamic_last4": null },'+
                                                                          ' "client_secret": "src_client_secret_FUeGVeN57uUtZhjiIZBKFi70", "created": 1563953595, "currency": null, "customer": "cus_F77hsHA1L2dKkj", "flow": "none", "livemode": false, "metadata": { }, '+
                                                                          '"owner": { "address": null, "email": null, "name": null, "phone": null, "verified_address": null, "verified_email": null, "verified_name": null, "verified_phone": null }, '+
                                                                          '"statement_descriptor": null, "status": "chargeable", "type": "card", "usage": "reusable" }, { "id": "card_1EctS7Jja9IPifcSddmSFvZh", "object": "card", "address_city": null, '+
                                                                          '"address_country": null, "address_line1": null, "address_line1_check": null, "address_line2": null, "address_state": null, "address_zip": null, "address_zip_check": null, '+
                                                                          '"brand": "MasterCard", "country": "US", "customer": "cus_F77hsHA1L2dKkj", "cvc_check": "pass", "dynamic_last4": null, "exp_month": 12, "exp_year": 2022, "fingerprint": "JeJNtXmDmtX5F6N0", '+
                                                                          '"funding": "credit", "last4": "4444", "metadata": { }, "name": null, "tokenization_method": null } ], "has_more": false, "total_count": 5, "url": "/v1/customers/cus_F77hsHA1L2dKkj/sources" }, '+
                                                                          '"subscriptions": { "object": "list", "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_F77hsHA1L2dKkj/subscriptions" }, "tax_exempt": "none", "tax_ids": { "object": "list",'+
                                                                          ' "data": [ ], "has_more": false, "total_count": 0, "url": "/v1/customers/cus_F77hsHA1L2dKkj/tax_ids" }, "tax_info": null, "tax_info_verification": null }'));  
       
        AureusCustomerCardWebService.updateCustomerCard();
        Test.stopTest();
        // System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void updateCustomerCardPostError() {
        // prepare test-data
        List<Account> listOfAccount = [SELECT Id
                                       from Account];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/customerCard/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"expMonth": "9",'+
            '"expYear": "29"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusCustomerCardWebService.updateCustomerCard();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
     // END :  Cover Update Customer Card api code  
    
     // Start :  Cover get all Lesson api code 
    @isTest
    static void getallLessonGetSuccess() {
        // prepare test-data
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/allLesson/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusGetAllLessonWebService.getallLesson();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
     @isTest
    static void getallLessonBlankGetSuccess() {
        List<Program__c> listOfPackage =[select Id from Program__c];
        delete listOfPackage;
        // prepare test-data
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/allLesson/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusGetAllLessonWebService.getallLesson();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode );
    }
    
    // END :  Cover get all Lesson api code 
    
    // Start :  Cover booking Reschedule api code 
     @isTest
    static void testbookingRescheduleSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Teacher_Account__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c 
                                          from Booking__c
                                         WHERE Type__c='Regular'];
        List<account> listOfAccount = [SELECT Id from account 
                                       where recordType.name='Teacher'
                                       order By createdDate];
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingReschedule/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"time": "'+Time.newInstance(12,0,0,0)+'",'+
            '"teacherId": "'+listOfAccount[1].id+'",'+
            '"oldteacherId": "'+listOfBooking[0].Teacher_Account__c+'",'+
            '"oldtime": "'+listOfBooking[0].Start_Time__c+'",'+
            '"olddate": "'+DateTime.newInstance(
                listOfBooking[0].Booking_Date__c.year(), listOfBooking[0].Booking_Date__c.month(), 
                listOfBooking[0].Booking_Date__c.day()
            ).format('yyyy-MM-dd')+'",'+
            '"duration": 60,'+
            '"date": "'+DateTime.newInstance(
                listOfBooking[0].Booking_Date__c.year(), listOfBooking[0].Booking_Date__c.month(), 
                listOfBooking[0].Booking_Date__c.addDays(3).day()
            ).format('yyyy-MM-dd')+'",'+
            '"bookingId": "'+listOfBooking[0].id+'"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusBookingRescheduleWebService.insertBookingReschedule();
        Test.stopTest();
        System.debug('@@@112'+RestContext.response.responseBody.toString());
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"message":"Booking Reschedule Successfully.","errorCode":"SUCCESS"}'),String.valueOf(RestContext.response.responseBody));
        System.assert([select id 
                       from Booking__c 
                       WHERE status__c = 'Scheduled'
                       And Category__c ='Placeholder'].size() > 0 );
        System.assert([select id 
                       from App_Feeds__c 
                       WHERE Booking_Id__c=:listOfBooking[0].id].size() > 0 );
    }
    @isTest
    static void testBookingRescheduleErroMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Teacher_Account__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c from Booking__c];
        List<account> listOfAccount = [SELECT Id from account order By createdDate];
        //As Per Best Practice it is important to instantiate the Rest Context
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingReschedule/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"time": "'+Time.newInstance(12,0,0,0)+'",'+
            '"teacherId": "'+listOfAccount[0].id+'",'+
            '"oldteacherId": "'+listOfBooking[0].Teacher_Account__c+'",'+
            '"oldtime": "'+listOfBooking[0].Start_Time__c+'",'+
            '"olddate": "'+listOfBooking[0].Booking_Date__c+'",'+
            '"duration": 60,'+
            '"date": "'+listOfBooking[0].Booking_Date__c.addDays(3)+'"}';
        req.requestBody = Blob.valueof(JsonMsg);
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
             AureusBookingRescheduleWebService.insertBookingReschedule();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    // END :  Cover booking Reschedule api code 
    
    // Start :  Cover CaseComment api code 
    @isTest
    static void testCaseCommentSucessMsg() {
        // prepare test-data
        List<Case> listOfcase = [SELECT Id FROM Case];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/caseComment/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"caseId": "'+listOfcase[0].id+'","comment": "testComment"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
            AureusCaseCommentWebService.createCaseCommentData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode": "SUCCESS","message":" Record save sucessfully."}'),String.valueOf(RestContext.response.responseBody));
        System.assert([select id 
                       from CaseComment].size() > 0 );
    }
    @isTest
    static void testCaseCommentErroMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/caseComment/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg=' {"comment": "testComment"}';
        req.requestBody = Blob.valueof(JsonMsg);
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
              AureusCaseCommentWebService.createCaseCommentData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    // END :  Cover CaseComment api code 
    
     // Start :  Cover lesson api code 
     @isTest
    static void getLessonDataGetSuccess() {
        // prepare test-data
        List<Enrolment__c> listOfEnrolment = [SELECT Id,Parent__c from Enrolment__c];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/lesson/'; //Request URL
        req.addParameter('parentId', listOfEnrolment[0].Parent__c);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusLessonWebService.getLessonData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    
     @isTest
    static void getEnrollmentDataGetSuccess() {
        // prepare test-data
        List<Enrolment__c> listOfEnrolment = [SELECT Id,Parent__c from Enrolment__c];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/lesson/'; //Request URL
        req.addParameter('enrollmentId', listOfEnrolment[0].id);
        req.addParameter('type','');
        req.addParameter('Limit', '5');
        req.addParameter('offset', '0');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusLessonWebService.getLessonData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    
    @isTest
    static void getLessonDataGetError() {
        // prepare test-data
        //List<Booking__c> listOfBooking = [SELECT Id,Teacher_Account__c,Booking_Date__c,Start_Time__c,End_Time__c,status__c from Booking__c];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/lesson/'; //Request URL
       
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusLessonWebService.getLessonData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    // Start : Cover MakeupPackage api code
     @isTest
    static void testMakeupPackagePostSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        List<Booking__c> listOfcancelBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Student__c =: listOfBooking[0].Student__c];

       listOfcancelBooking[0].RecordTypeId= Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get(ConstantsClass.recordTypeLesson).getRecordTypeId();
        listOfcancelBooking[0].Status__c =ConstantsClass.statusCanceled;
        listOfcancelBooking[0].Type__c ='Regular';
       listOfcancelBooking[0].Make_up_Utilize_Bookings__c = listOfBooking[1].id+'-30;';
       listOfcancelBooking[0].Available_Make_up_Units__c = 30;
        listOfcancelBooking[0].Make_up_Expiry_Date__c = date.today();
        listOfcancelBooking[0].Parent__c = listOfcancelBooking[0].Student__c;
       update listOfcancelBooking[0];
        system.debug('### test'+ listOfcancelBooking[0].Student__c);
        Set<String> setOfParentStudent = new Set<String>();
        setOfParentStudent.add(listOfcancelBooking[0].Student__c);
        system.debug('### test'+ SOQLQueryHelper.getCancelBooking(setOfParentStudent));
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/package/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='[{"centerId": "'+listOfBooking[0].Center__c+'",'+
            '"teacherId": "'+listOfBooking[0].Teacher_Account__c+'",'+
            '"enrolmentId": "'+listOfBooking[0].Enrolment__c+'",'+
            '"studentId": "'+listOfBooking[0].Student__c+'",'+
            '"packageId": "'+listOfBooking[0].Package__c+'",'+
            '"parentId": "'+listOfBooking[0].Student__c+'",'+
            '"bookingdate": "14/08/2019",'+
            '"startTime": "02:45",'+
            '"duration": "'+listOfBooking[0].Package__r.duration__c+'"}]';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusMakeupPackageWebService.insertMakeUpBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"MakeUp created Successfully"}'),String.valueOf(RestContext.response.responseBody));
        System.assert([select id 
                       from Booking__c 
                       WHERE type__c ='Make-up'].size() > 0 );
    }
    @isTest
    static void testMakeupFifhtbookingPostSucessMsg() {
        // prepare test-data
       List<Fifth_Lesson__c> listOfFifthBooking = [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c 
                FROM Fifth_Lesson__c where Booking__c = null];
        Account parentAccount = new Account(Id = listOfFifthBooking[0].Parent__c,Available_Make_up_Units__c = 120);
        update parentAccount;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/package/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='[{"bookingId":"'+listOfFifthBooking[0].Id+'"}]';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusMakeupPackageWebService.insertMakeUpBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"MakeUp created Successfully"}'),String.valueOf(RestContext.response.responseBody));
        System.assert([select id 
                       from Booking__c 
                       WHERE type__c ='Make-up'].size() > 0 );
    }
    
    @isTest
    static void testMakeupPackagePostErrorMsg() {
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        Test.startTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/package/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='[]';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        AureusMakeupPackageWebService.insertMakeUpBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
        
        
        
    }
    
    @isTest
    static void testMakeupPackagegetGetCenterIdSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/package/'; //Request URL
        req.addParameter('centerId', listOfBooking[0].Center__c);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusMakeupPackageWebService.getPackageData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void testMakeupPackagegetGetlocationIdSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.Location__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/package/'; //Request URL
        req.addParameter('location', listOfBooking[0].Package__r.Location__c);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusMakeupPackageWebService.getPackageData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void testMakeupPackageGetlocationWithProgramIdSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__r.Location__c,Package__r.Program__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/package/'; //Request URL
        req.addParameter('location', listOfBooking[0].Package__r.Location__c);
        req.addParameter('program', listOfBooking[0].Package__r.Program__c);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusMakeupPackageWebService.getPackageData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    
    @isTest
    static void testMakeupPackaGetErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/package/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusMakeupPackageWebService.getPackageData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
// END: Cover MakeupPackage api code
    

    // Start : Cover Payment api code
    @isTest
    static void testPaymentGetSucessMsg() {
        // prepare test-data
        List<Invoice__c> listOfInvoice = [SELECT Id
                                          FROM Invoice__c];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/Payment/'; //Request URL
        req.addParameter('invoiceId', listOfInvoice[0].Id);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusPaymentWebService.getinvoiceData();
        Test.stopTest();
    }
     @isTest
    static void testPaymentGetPaidErrorMsg() {
        // prepare test-data
        List<Invoice__c> listOfInvoice = [SELECT Id
                                          FROM Invoice__c
                                         WHERE Status__c = 'Paid'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/Payment/'; //Request URL
        req.addParameter('invoiceId', listOfInvoice[0].Id);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusPaymentWebService.getinvoiceData();
        Test.stopTest();
         System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"DATA_NOT_FOUND","message":"This Invoice is already Paid"}'));
    }
    
    @isTest
    static void testPaymentGetErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/Payment/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusPaymentWebService.getinvoiceData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    // END : Cover Payment api code
    
    
    // Start : Cover picklist api code
    @isTest
    static void testPicklistGetSucessMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/picklist/'; //Request URL
        req.addParameter('objName', 'Booking__c');
         req.addParameter('fieldApiName', 'Cancellation_Reason__c');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusPickListValueWebService.fetchPickListValues();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
     @isTest
    static void testPicklistGetObjectErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/picklist/'; //Request URL
        req.addParameter('objName', 'Booking__r');
        req.addParameter('fieldApiName', 'Cancellation_Reason__c');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusPickListValueWebService.fetchPickListValues();
        Test.stopTest();
         System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode": "INCORRECT_API","message":"Please Insert Correct Object API Name!"}'));
    }
    
    @isTest
    static void testPicklistGetErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/picklist/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusPickListValueWebService.fetchPickListValues();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    // END : Cover picklist api code
    
    // START:Cover TeachersInstrument api code 
    @isTest
    static void testTeachersInstrumentGetBookingIdSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/TeachersInstrument/'; //Request URL
        req.addParameter('bookingId', listOfBooking[0].id);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusTeacherWebService.getTeachersData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void testTeachersInstrumentGetCenterIdWithInstrumentSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c ,Instrument__c
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/TeachersInstrument/'; //Request URL
        req.addParameter('centerId', listOfBooking[0].Center__c);
        req.addParameter('instrument', listOfBooking[0].Instrument__c);
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusTeacherWebService.getTeachersData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    @isTest
    static void testTeachersInstrumentGetErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/TeachersInstrument/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        AureusTeacherWebService.getTeachersData();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
// END: Cover MakeupPackage api code
    
    
   
    // Start : Cover update Fields Records api code
     @isTest
    static void testUpdateFieldsRecordsPostSucessMsg() {
        // prepare test-data
         List<Account> listOfaccount = [SELECT Id 
                                       FROM Account
                                       WHERE RecordType.name = 'Customer'];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/updateFieldsRecords/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"recordId": "'+listOfaccount[0].Id+'","fieldApi":"Invoice_Paid_Notification__c","newValue" : true}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusUpdateFieldsRecordsWebService.updateRecords();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"Record update sucessfully."}'),String.valueOf(RestContext.response.responseBody));
    }
     @isTest
    static void testUpdateFieldsRecordsIdPostErrorMsg() {
        // prepare test-data
         List<Account> listOfaccount = [SELECT Id 
                                       FROM Account
                                       WHERE RecordType.name = 'Customer'];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/updateFieldsRecords/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"recordId": "","fieldApi":"Invoice_Paid_Notification__c","newValue" : true}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusUpdateFieldsRecordsWebService.updateRecords();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "DATA_NOT_FOUND","message": "Record Id Not Found" }'),String.valueOf(RestContext.response.responseBody));
    }
    
     @isTest
    static void testUpdateFieldsRecordsPostFieldapiErrorMsg() {
        // prepare test-data
         List<Account> listOfaccount = [SELECT Id 
                                       FROM Account
                                       WHERE RecordType.name = 'Customer'];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/updateFieldsRecords/'; //Request URL
        req.httpMethod = 'POST';
         String JsonMsg='{"recordId": "'+listOfaccount[0].Id+'","fieldApi":"Invoice_Paid_Notifications__c","newValue" : true}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusUpdateFieldsRecordsWebService.updateRecords();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"INCORRECT_API", "message":"Please Correct the Object Field API Name!"}'),String.valueOf(RestContext.response.responseBody));
    }
    
    @isTest
    static void testUpdateFieldsRecordsPostErrorMsg() {
         List<Account> listOfaccount = [SELECT Id 
                                       FROM Account
                                       WHERE RecordType.name = 'Customer'];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/updateFieldsRecords/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"recordId": "'+listOfaccount[0].Id+'","fieldApi":"Invoice_Paid_Notification__c"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
       Test.startTest();
        AureusUpdateFieldsRecordsWebService.updateRecords();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    
   // END : Cover update Fields Records api code 
   
    
    
    // Start : Cover Mobile notifications api code
     @isTest
    static void testMobileNotificationsPostSucessMsg() {
        // prepare test-data
         List<Mobile_Notification__c> listOfMobileNotification = [SELECT Id 
                                       FROM Mobile_Notification__c
                                      ];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/notifications/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{"notificationId": "'+listOfMobileNotification[0].Id+'"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusMobileNotificationWebService.updateMobileNotifications();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"Mobile Notifications is Deleted Successfully"}'),String.valueOf(RestContext.response.responseBody));
    }
        
     @isTest
    static void testMobileNotificationsPostFieldapiParentIdSucessMsg() {
        // prepare test-data
           List<Mobile_Notification__c> listOfMobileNotification = [SELECT Id,Customer_Name__c 
                                       FROM Mobile_Notification__c
                                      ];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/notifications/'; //Request URL
        req.httpMethod = 'POST';
         String JsonMsg='{"parentId": "'+listOfMobileNotification[0].Customer_Name__c+'"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusMobileNotificationWebService.updateMobileNotifications();
        Test.stopTest();
          System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
        System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"All Mobile Notifications are  Deleted Successfully"}'),String.valueOf(RestContext.response.responseBody));
    }
    
    @isTest
    static void testMobileNotificationsPostErrorMsg() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/notifications/'; //Request URL
        req.httpMethod = 'POST';
        String JsonMsg='{}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
       Test.startTest();
       AureusMobileNotificationWebService.updateMobileNotifications();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
  @isTest
    static void testMobileNotificationsGetSucessMsg() {
        // prepare test-data
         List<Mobile_Notification__c> listOfMobileNotification = [SELECT Id ,Customer_Name__c
                                       FROM Mobile_Notification__c
                                      ];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/notifications/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('parentId', listOfMobileNotification[0].Customer_Name__c);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
           AureusMobileNotificationWebService.getMobileNotfication();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
        
    
    @isTest
    static void testMobileNotificationsGetErrorMsg() {
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/notifications/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
       Test.startTest();
       AureusMobileNotificationWebService.getMobileNotfication();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400,RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }    
   // END : Cover Mobile notifications api code 
    
    // Start: Cover SingleWorkingHours api code
     @isTest
    static void testSingleWorkingHoursGetAllHoursSlotsSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/singleWorkingHours/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('centre', listOfBooking[0].Center__c);
        req.addParameter('teacher', listOfBooking[0].Teacher_Account__c);
        req.addParameter('duration', '30');
        req.addParameter('date', DateTime.newInstance(
                listOfBooking[0].Booking_Date__c.year(), listOfBooking[0].Booking_Date__c.month(), 
                listOfBooking[0].Booking_Date__c.day()
            ).format('yyyy-MM-dd'));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
          AureusSingleWorkingHoursWebService.fetchSingleWorkingHours();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
      @isTest
    static void testSingleWorkingHoursGetAllDateSlotsCenterIdSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/singleWorkingHours/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('centre', listOfBooking[0].Center__c);
        req.addParameter('teacher', listOfBooking[0].Teacher_Account__c);
        req.addParameter('duration', '30');
        req.addParameter('date', '');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
          AureusSingleWorkingHoursWebService.fetchSingleWorkingHours();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
    
     @isTest
    static void testMultipleWorkingHoursGetAllHoursSlotsSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher'];  
        List<Account> listOfcenter = [select id  from Account Where recordType.name='Centre'];  
                 list<Teacher_Working_Hour__c> listTwh2=new List<Teacher_Working_Hour__c>();
        
        for(integer i=1;i<=10;i++){
            Teacher_Working_Hour__c tw = new Teacher_Working_Hour__c();
            tw.Active__c = true;
            tw.Break_Time__c= False;
            tw.Teacher_Name__c=listOfTeacher[1].Id;
            tw.Center_Name__c=listOfcenter[0].Id;
            tw.Working_Day__c=i==1?'mon':i==2?'tue':i==3?'wed':i==4?'thu':i==5?'fri':i==6?'sat':'sun';
            tw.Start_Time__c=Time.newInstance(7,0,0,0);
            tw.End_Time__c=Time.newInstance(23,0,0,0);
            
            listTwh2.add(tw);
        }
        insert listTwh2; 
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/singleWorkingHours/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('centre', listOfBooking[0].Center__c);
        req.addParameter('teacher', listOfTeacher[0].id+','+listOfTeacher[1].id);
        req.addParameter('duration', '30,30');
        req.addParameter('date', DateTime.newInstance(
                system.today().addDays(1).year(), system.today().addDays(1).month(), 
                system.today().addDays(1).day()
            ).format('yyyy-MM-dd'));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
         AureusSingleWorkingHoursWebService.fetchSingleWorkingHours();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
      @isTest
    static void testMultipleWorkingHoursGetAllDateSlotsCenterIdSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        List<Account> listOfTeacher = [select id  from Account Where recordType.name='Teacher'];  
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/singleWorkingHours/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('centre', listOfBooking[0].Center__c);
        req.addParameter('teacher', listOfTeacher[0].id+','+listOfTeacher[1].id);
        req.addParameter('duration', '30,30');
        req.addParameter('date', '');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
          AureusSingleWorkingHoursWebService.fetchSingleWorkingHours();
        
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
     @isTest
    static void testSingleWorkingHoursGetCenterIdBlankErrorMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/singleWorkingHours/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('centre', listOfBooking[0].Center__c);
        req.addParameter('teacher', listOfBooking[0].Teacher_Account__c);
        req.addParameter('duration', '');
        req.addParameter('date', DateTime.newInstance(
                listOfBooking[0].Booking_Date__c.year(), listOfBooking[0].Booking_Date__c.month(), 
                listOfBooking[0].Booking_Date__c.day()
            ).format('yyyy-MM-dd'));
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
           AureusSingleWorkingHoursWebService.fetchSingleWorkingHours();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    
    @isTest
    static void testSingleWorkingHoursGetErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/singleWorkingHours/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
         AureusSingleWorkingHoursWebService.fetchSingleWorkingHours();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
// END: Cover singleWorkingHours api code

 // Start: Cover teachersWorkingHour api code
     @isTest
    static void testTeachersWorkingHourSucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/teachersWorkingHour/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('centre', listOfBooking[0].Center__c);
        req.addParameter('teachers', listOfBooking[0].Teacher_Account__c +','+listOfBooking[0].Teacher_Account__c);
        req.addParameter('weekday', 'mon');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
          AureusTeachersWorkingHoursWebService.fetchWorkingHours();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
     @isTest
    static void testTeachersWorkingHourIdBlankErrorMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/teachersWorkingHour/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('centre', listOfBooking[0].Center__c);
        req.addParameter('teachers', listOfBooking[0].Teacher_Account__c +','+listOfBooking[0].Teacher_Account__c);
        req.addParameter('weekday', '');
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
            AureusTeachersWorkingHoursWebService.fetchWorkingHours();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
    
    @isTest
    static void testTeachersWorkingHourGetErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/teachersWorkingHour/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
         AureusTeachersWorkingHoursWebService.fetchWorkingHours();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
// END: Cover teachersWorkingHour api code
  
    
     // Start: Cover bookingHistory api code
     @isTest
    static void testbookingHistorySucessMsg() {
        // prepare test-data
        List<Booking__c> listOfBooking = [SELECT Id,Package__c,Package__r.duration__c,Enrolment__c,Center__c,Parent__c,Booking_Date__c,
                                         Student__c,Start_Time__c,Teacher_Account__c 
                                          FROM Booking__c
                                          WHERE Type__c = 'Regular'];
        listOfBooking[0].status__c = 'Scheduled';
        update listOfBooking[0];
        listOfBooking[0].Booking_Date__c = listOfBooking[0].Booking_Date__c.addDays(1);
        update listOfBooking[0];
        listOfBooking[0].Available_Make_up_Units__c = 20;
        update listOfBooking[0];
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingHistory/'; //Request URL
        req.httpMethod = 'GET';
        req.addParameter('bookingId', listOfBooking[0].id);
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
          AureusBookingHistoryWebService.getBookingHistory();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    }
   
    @isTest
    static void testbookingHistoryGetErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/bookingHistory/'; //Request URL
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
         AureusBookingHistoryWebService.getBookingHistory();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }
// END: Cover bookingHistory api code
     @isTest
    static void coverOtpEmail() {
        Account aaObj = [Select Id from Account limit 1];
        WebServiceDataFactoryHelper objWebServiceDataFactoryHelper = new WebServiceDataFactoryHelper();
        objWebServiceDataFactoryHelper.accountobj =  [Select Id from Account limit 1];
        objWebServiceDataFactoryHelper.getobjAccount();
        objWebServiceDataFactoryHelper.getAutoGeneratedCode();
        SOQLQueryHelper.getContentDocumentLink(objWebServiceDataFactoryHelper.accountobj.id);
        SOQLQueryHelper.getContentDistribution(objWebServiceDataFactoryHelper.accountobj.id);
        SOQLQueryHelper.getEnrolment(objWebServiceDataFactoryHelper.accountobj.id);
        SOQLQueryHelper.getBookingsOnSelectedDates('',new List<String>(),new Set<Date>());
        
    }
     
     // Start: Cover Adhoc Booking api code
     @isTest
    static void testAdhocbookingSucessMsg() {
        // prepare test-data
        List<Fifth_Lesson__c> listOfFifthBooking = [SELECT Booking__c, Booking_Date__c, Booking_Day__c, Center__c, Start_Time__c, End_Time__c, Duration__c, Enrolment__c, Event_Color__c, 
                IsActive__c, Package__c, Parent__c, Remarks__c, Student__c, Teacher_Account__c, Id, Name,Package__r.Package_Fee_with_GST__c,
                Student__r.Name,Package__r.type__c,Package__r.Name,Center__r.Name,Teacher_Account__r.Name,Package__r.Unit_Fee__c 
                FROM Fifth_Lesson__c where Booking__c = null];
        List<Package__c> listOfPackage = [Select Id from Package__c where type__c = 'Adhoc'];
        Fifth_Lesson__c objFifth_Lesson = new Fifth_Lesson__c(Id = listOfFifthBooking[0].id, Package__c = listOfPackage[0].id );
        update objFifth_Lesson; 
        Account objCustmr=New Account(id =listOfFifthBooking[0].Parent__c, Stripe_Customer_Id__c='ch_1AxWbTFytruJp2FXW6iuRd1X');
        update objCustmr;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/adhocbooking/'; //Request URL
         req.httpMethod = 'POST';
         String JsonMsg='{"fifthBookingId": "'+listOfFifthBooking[0].id+'"}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'{"paid": true}'));
        AureusAdHocBookingWebService.updateAdHocBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 200,RestContext.response.statusCode );
    	System.assert(RestContext.response.responseBody == Blob.valueof('{"errorCode":"SUCCESS","message":"Ad-Hoc Booking is created Successfully"}'));
    }
   
    @isTest
    static void testAdhocbookingGetErrorMsg() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = System.Label.Aureus_Site+'/services/apexrest/adhocbooking/'; //Request URL
         req.httpMethod = 'POST';
         String JsonMsg='{}';
        req.requestBody = Blob.valueof(JsonMsg);
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
         AureusAdHocBookingWebService.updateAdHocBooking();
        Test.stopTest();
        System.assert(RestContext.response.statusCode == 400);
        System.assert(RestContext.response.responseBody == Blob.valueof('{ "errorCode": "INVALID_PARM","message": "Some Parameters are Missing" }'));
    }

}