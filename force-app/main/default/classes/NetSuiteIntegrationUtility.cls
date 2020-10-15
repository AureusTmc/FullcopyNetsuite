/*
Name        :        NetSuiteIntegrationUtility
Date        :        9 Oct 2020
Author      :        Karan Singh Soni
Test Class  :        SearchInstrumentRental_IpadCntrlTest
Desc        :       This is a helper class for the NetSuite Integration.		 
*/
//Note : This class contains code from the another class SearchInstrumentRental_IpadCntrl.apxc
//CH01 Karan Singh 14 Oct 2020 : added one more parameter from the Netsuite Wrapper class as they will additionally send the aurues student rental fees.
public class NetSuiteIntegrationUtility {
   
    public static HTTPResponse sendNetSuiteRequest( NetSuite_Integration_Creds__c objNetSuiteCred, String jsonRequestBody, String methodName ){
        
        Integer noOfApiCallout = 1;
        HttpRequest req;
        HTTPResponse resp;
         
        //CH04 Start
        Datetime requestDatetime;
        Datetime responseDatetime;
        //CH04 END
        //doing this as there are cases where at first attmpt we get 403 error
        do{
            requestDatetime = DateTime.now();//CH04 
            
            String nonce = String.valueOf(Crypto.getRandomLong());
            String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
            
            String url ='deploy=' +objNetSuiteCred.deploy__c+ '&';
            url += 'oauth_consumer_key='+ objNetSuiteCred.Consumer_Key__c +'&';
            url += 'oauth_nonce=' + nonce + '&';
            url += 'oauth_signature_method=' + objNetSuiteCred.Signature_Method__c + '&';
            url += 'oauth_timestamp=' + timestamp + '&';
            url += 'oauth_token='+ objNetSuiteCred.Access_Token__c +'&';
            url += 'oauth_version='+objNetSuiteCred.Version__c+'&';
            url += 'script=' + objNetSuiteCred.script__c;
            
            String encodeUrl = EncodingUtil.urlEncode( url, 'UTF-8');
            string encodeUrl2 = objNetSuiteCred.Method__c +'&'+EncodingUtil.urlEncode( objNetSuiteCred.Endpoint__c, 'UTF-8') + '&' + encodeUrl;
            Blob blobSignature = Crypto.generateMac(objNetSuiteCred.Crypto_Class_Encrypt_Method__c, Blob.valueOf(encodeUrl2), Blob.valueOf(objNetSuiteCred.Consumer_Secret__c +'&'+ objNetSuiteCred.Token_Secret__c ));
            
            String signature = EncodingUtil.Base64Encode( blobSignature );
            
            String authHeader = 'OAuth realm="' + objNetSuiteCred.Realm__c + '",';
            authHeader += 'oauth_consumer_key="' + objNetSuiteCred.Consumer_Key__c + '",';
            authHeader += 'oauth_token="' + objNetSuiteCred.Access_Token__c + '",';
            authHeader += 'oauth_signature_method="'+ objNetSuiteCred.Signature_Method__c +'",';
            authHeader += 'oauth_timestamp="' + timestamp + '",';
            authHeader += 'oauth_nonce="' + nonce + '",';
            authHeader += 'oauth_version="'+ objNetSuiteCred.Version__c +'",';
            authHeader += 'oauth_signature="' + signature + '"';
            
            req = new HttpRequest();
            req.setEndpoint( objNetSuiteCred.Endpoint__c + '?script='+ objNetSuiteCred.script__c +'&deploy='+objNetSuiteCred.deploy__c );
            req.setMethod( objNetSuiteCred.Method__c );
            req.setHeader('Content-Type', objNetSuiteCred.Content_Type__c );
            req.setHeader('Authorization', authHeader);
            req.setBody( jsonRequestBody );
            req.setTimeout(60000);
            Http h = new Http();
            system.debug(' --> ' + req.getHeader('Authorization'));
            
            resp = new HTTPResponse();
            
            if( !Test.isRunningTest() ){
                resp = h.send(req);
            }
            else{
                resp.setStatusCode( 200 );
                if( methodName == 'pushDataToNetsuite() :  Convert Item to Fixed Asset' ){
                    
                    resp.setBody( '{"error" : {"code" : "INVALID_LOGIN_ATTEMPT", "message" : "Invalid login attempt."}}' );
                }else{
                    resp.setBody( '[{"serialNumber": "123","item": "1234","location": "Test Location","status": "New","inventoryType": "Piano","monthlyRental": "62","listPrice": "66.66","model": "123","productId": "Serialized Item001","brand": "xyz"}]' );
                }
                
            }
            /*system.debug('resp->> ' + resp);system.debug('resp->> ' + resp.getBody());system.debug('resp->> ' + req);system.debug('req.getBody->> ' + req.getBody());system.debug('req.getEndpoint->> ' + req.getEndpoint());system.debug('req.getHeader->> ' + req.getHeader('Authorization'));system.debug('req.getHeader->> ' + req.getHeader('Content-Type'));system.debug('req.getMethod->> ' + req.getMethod());*/
            
            noOfApiCallout++;
        }while( resp.getStatusCode() != 200 && noOfApiCallout <= objNetSuiteCred.Maximum_API_Retry_Count__c );
        
        system.debug('noOfApiCallout --> '+ noOfApiCallout);
        system.debug('resp->> ' + resp);
        system.debug('resp->> ' + resp.getBody());  //resp->> {"error" : {"code" : "INVALID_LOGIN_ATTEMPT", "message" : "Invalid login attempt."}}
        
        //CH04 Start
        responseDatetime = DateTime.now();
        
        if( objNetSuiteCred.Enable_Logging__c){
            
            try{
                NetSuite_API_Logger__c objNetSUiteLogger = new NetSuite_API_Logger__c();
                objNetSUiteLogger.Class_and_Method_Name__c = ' SearchInstrumentRental_IpadCntrl : '+ methodName;
                objNetSUiteLogger.Request__c =  req.getBody().length() > 131070 ? req.getBody().left(131070) : req.getBody();
                objNetSUiteLogger.Request_Header__c = req.getHeader( 'Authorization' ).length() > 131070 ? req.getHeader( 'Authorization' ).left(131070) : req.getHeader( 'Authorization' );
                objNetSUiteLogger.Request_Time__c = requestDatetime;
                objNetSUiteLogger.Response__c = resp.getBody().length() > 131070 ? resp.getBody().left(131070) : resp.getBody();
                objNetSUiteLogger.Response_Time__c = responseDatetime;
                objNetSUiteLogger.Status_Code__c = resp.getStatusCode();
                objNetSUiteLogger.Request_URL__c = req.getEndpoint().length() > 131070 ? req.getEndpoint().left(131070) : req.getEndpoint();
                
                //since we need to call NetSUite API, w/o future dml, it will give You have uncommitted work pending. Please commit or rollback before calling out error 
                if( !Test.isRunningTest() && methodName != 'saveAndCompleteProcess() :Inventory Search')
                    insert objNetSUiteLogger; 
                  system.debug('objNetSUiteLogger Id -> ' + objNetSUiteLogger.id);
                
            }Catch ( Exception objExp ){
                system.debug(' Error -> ' + objExp.getMessage() + ' -> Line Number -> ' + objExp.getLineNumber());
            }
        }
        //Ch04 ENd
        return resp;
    }

    
    public class NetSuiteProducts{
        
        public Integer srNo{get;set;}
        public String serialNumber {get;set;}
        public String item {get;set;}
        public String location {get;set;}
        public String status {get;set;}
        public String inventoryType {get;set;}
        public String monthlyRental {get;set;}
        public String listPrice {get;set;}
        public String studentPrice {get;set;} //CH01 Added
        public String model {get;set;}
        public String productId {get;set;}
        public String brand {get;set;}
        
        public NetSuiteProducts(){
            serialNumber = '';
            item = '';
            location = '';
            status = '';
            inventoryType = '';
            monthlyRental = '';
            listPrice = '';
            studentPrice = ''; //CH01 added
            model = '';
            productId = '';
            brand = '';
            
        }
    }
    public class NetSuiteError{
        
        public NetSuiteErrorCode error {get;set;}
    }
    public class NetSuiteErrorCode{
        public String code{get;set;}
        public String message{get;set;}
        public String request_datetime{get;set;}
    }
}