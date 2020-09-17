public class OAuth {
    
    public static void callRequest2(){
        
        String nonce ='';
        //nonce = 'n7HzhmWJbn7ulPiYqO6UrvegXEX6gyvt';
        nonce = String.valueOf(Crypto.getRandomLong());
        
        //incase if you got 403 error then use this js code to create the nonce -> https://gist.github.com/smaeda-ks/dc5cdd50956e63bdae11314612389a07
        //the whole code is from -> https://stackoverflow.com/questions/15271508/netsuite-oauth-implemenation
        //https://github.com/metadaddy/sfdc-oauth-playground/blob/master/OAuth/src/classes/OAuth.cls

        String timestamp = String.valueOf(DateTime.now().getTime() / 1000);
        String base_URL ='https://5458485.restlets.api.netsuite.com/app/site/hosting/restlet.nl';
        String consume_secret = '28bcb56dc46c4a824c3e7b40e6d13daa9dd9a6f1444f56dbf83429673356b4b6';
        String tok_secret = '14ac546c1d8f92ebda2281f28cc0fb9e2095952872f1896e3505736d78e14ee0';
        
        String s1 ='deploy=' + 'customdeploy_serialize_inventory_search' + '&';    
        s1 +='oauth_consumer_key=fde0410a786eef835c92a8bec32d744385c01bbe983951d8e40fcb974d0011d4&';
        s1 += 'oauth_nonce=' + nonce + '&';
        s1 += 'oauth_signature_method=' + 'HMAC-SHA256' + '&';
        s1 += 'oauth_timestamp=' + timestamp + '&';
        s1 += 'oauth_token=01987317686d31609d34540c38d835a801077f3bb5285a1d8beff12c43465138&';
        s1 += 'oauth_version=1.0&';
        s1 += 'script=' + 'customscript_serialize_inventory_search';
        string s11 = EncodingUtil.urlEncode(s1, 'UTF-8');
        string s2 = 'POST&'+EncodingUtil.urlEncode(base_URL, 'UTF-8') + '&' + s11;
        Blob sig = Crypto.generateMac('HmacSHA256', Blob.valueOf(s2), Blob.valueOf(consume_secret +'&'+ tok_secret ));
        
        String auth_Sign = EncodingUtil.Base64Encode( sig );
        system.debug(' --> ' + auth_Sign);
        
        String authHeader = 'OAuth realm="' + '5458485' + '",';
        authHeader += 'oauth_consumer_key="' + 'fde0410a786eef835c92a8bec32d744385c01bbe983951d8e40fcb974d0011d4' + '",';
        authHeader += 'oauth_token="' + '01987317686d31609d34540c38d835a801077f3bb5285a1d8beff12c43465138' + '",';
        authHeader += 'oauth_signature_method="HMAC-SHA256",';
        authHeader += 'oauth_timestamp="' + timestamp + '",';
        authHeader += 'oauth_nonce="' + nonce + '",';
        authHeader += 'oauth_version="1.0",';
        authHeader += 'oauth_signature="' + auth_Sign + '"';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(base_URL + '?script=customscript_serialize_inventory_search&deploy=customdeploy_serialize_inventory_search');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', authHeader);
        req.setBody('{"location": "test location","brand" : "xyz"}');
        Http h = new Http();
        system.debug(' --> ' + req.getHeader('Authorization'));
        HTTPResponse resp = h.send(req);
        system.debug('resp->> ' + resp);
        system.debug('resp->> ' + resp.getBody());  //resp->> {"error" : {"code" : "INVALID_LOGIN_ATTEMPT", "message" : "Invalid login attempt."}}
    }
    
     public static void getProducts1(){
        
        NetSuite_Integration_Creds__c objNetSuiteCred = NetSuite_Integration_Creds__c.getValues('NetSuiteCreds');
        
        if( objNetSuiteCred == null ){
            return;
        }
        Integer noOfApiCallout = 1;
        HttpRequest req;
        HTTPResponse resp;
        
        do{
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
            req.setBody('{"location": "test location","brand" : "xyz"}');
            Http h = new Http();
            system.debug(' --> ' + req.getHeader('Authorization'));
            
            resp = new HTTPResponse();
            
            if( !Test.isRunningTest() ){
                resp = h.send(req);
            }
            else{
                resp.setStatusCode( 200 );
                resp.setBody( '[{"serialNumber": "123","item": "1234","location": "Test Location","status": "New","inventoryType": "Piano","monthlyRental": "62","listPrice": "66.66","model": "123","productId": "Serialized Item001","brand": "xyz"},' );
            }
            
            noOfApiCallout++;
        }while( resp.getStatusCode() != 200 && noOfApiCallout <= 5 );
        
         system.debug('noOfApiCallout --> '+ noOfApiCallout);
        system.debug('resp->> ' + resp);
        system.debug('resp->> ' + resp.getBody());  //resp->> {"error" : {"code" : "INVALID_LOGIN_ATTEMPT", "message" : "Invalid login attempt."}}
    }
 
}