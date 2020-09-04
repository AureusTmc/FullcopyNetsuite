public class GetVideoRecordingController {
    public String username = 'SKee8fb3d0f04c7ecfbbc55a688e74ce89';
    public String password = 'eHzeoDwfeL5YedKysCv1YKbP9qDLHujl';
    public String RoomSid = 'RM9d53e64d174a424f32704793cb77eb82';
    public String clientId = 'SKee8fb3d0f04c7ecfbbc55a688e74ce89';
    public String clientSecret = 'eHzeoDwfeL5YedKysCv1YKbP9qDLHujl';
    public String roomId {get;set;}
    public String bookingId {get;set;}
    public String compURL {get;set;}
    public Boolean compURLALready {get;set;}
    public Boolean downloadActive {get;set;}
    public Boolean compLink {get;set;}
    public Boolean roomIdNotFound {get;set;}
    public Boolean recordingNotFound {get;set;}
    public Boolean checkLater {get;set;}
    
    public GetVideoRecordingController(){
        bookingId  = ApexPages.CurrentPage().getparameters().get('id');
        roomId  = ApexPages.CurrentPage().getparameters().get('room_id');
        
        Booking__c bObj = [Select Id,Composition_URL__c from Booking__c where Id=:bookingId];
        compURL = bObj.Composition_URL__c;
        if(compURL!=null){
            compURLALready=true;
            downloadActive=false;
            compLink=true;
        }else{
            compURLALready=false;
            downloadActive=true;
            compLink=false;
        }
    }
    
    public void generateComposition(){
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' +EncodingUtil.base64Encode(headerValue);
        
        String jsonBody = 'RoomSid='+roomId+'&AudioSources=*&StatusCallback=http://my.server.org/callbacks&'+
            'Format=mp4&VideoLayout={'+
            '"grid":{'+
            '"video_sources":["*"]'+
            '}'+
            '}';
        if(String.isNotBlank(roomId)){
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setHeader('Accept-Encoding', 'gzip,deflate');
            req.setHeader('Authorization',authorizationHeader);
            req.setHeader('Content-Length', String.valueOf(jsonBody.length()));
            req.setEndpoint('https://video.twilio.com/v1/Compositions');
            req.setBody(jsonBody);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            system.debug('res.getBody()--'+res.getBody());
            Map<String,Object> jsonParsed =(Map<String,Object> ) JSON.deserializeUntyped(res.getBody());
            Map<String,Object> newMap2 = (Map<String,Object>)jsonParsed;
            if(newMap2.containsKey('links')){
                Map<String,Object> newMap3 = (Map<String,Object>)newMap2.get('links');
                String compositionURL ='';
                compositionURL= (string)newMap3.get('media');
                system.debug('compositionURL--'+compositionURL);
                
                
                if(compositionURL != null){
                    Booking__c bObj = [Select Id from Booking__c where Id=:bookingId];
                    bObj.Composition_URL__c=compositionURL;
                    Update bObj;
                    compURLALready=true;
                    downloadActive=false;
                    compLink=false;
                }
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Recording Not Found.'));
                recordingNotFound=true;
            }
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please pass room id to get recording.'));
            roomIdNotFound=true;
        }
        
        
    }
    public PageReference downloadRecording(){
        
        Booking__c bObj = [Select Id,Composition_URL__c from Booking__c where Id=:bookingId];
        String compositionURL = bObj.Composition_URL__c;
        
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' +EncodingUtil.base64Encode(headerValue);
        
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setTimeout(60000);
        request.setHeader('Accept-Encoding', 'gzip,deflate');
        
        //request.setHeader('Authorization','Basic U0tlZThmYjNkMGYwNGM3ZWNmYmJjNTVhNjg4ZTc0Y2U4OTplSHplb0R3ZmVMNVllZEt5c0N2MVlLYlA5cURMSHVqbA==');
        request.setHeader('Authorization',authorizationHeader);
        //system.debug(str);
        request.setEndpoint(compositionURL+'?username='+username+'&password='+password);
        system.debug('request'+request);
        Http http1 = new Http();
        HTTPResponse response = http1.send(request);
        system.debug('response'+response.getBody());
        Map<String,Object> jsonParsed =(Map<String,Object> ) JSON.deserializeUntyped(response.getBody());
        // Map<String,Object> newMap2 = (Map<String,Object>)jsonParsedget('redirect_to');
        if(jsonParsed.containsKey('redirect_to')){
            String downloadURL = (string)jsonParsed.get('redirect_to');
            //Map<String,Object> newMap3 = (Map<String,Object>)newMap2.
            system.debug('downloadURL--'+downloadURL);
            PageReference retURL = new PageReference(downloadURL);
            retURL.setRedirect(true);
            return retURL;
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, 'Check after sometime to download it.'));
            checkLater=true;
            return null;
        }
    }
}