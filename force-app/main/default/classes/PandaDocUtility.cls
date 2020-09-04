/*
	Name		:	PandaDocUtility
	Date		:	08/28/2019
	Author		:	
	Description	:	This is utility class for pandadoc integration.
*/
public  class PandaDocUtility {
	private static String apiKey;
    private static String baseURL;
    
    Static{
    	List<Pandadoc_Setting__mdt> pandaDocSettings = [SELECT Api_Key__c, Base_URL__c, DeveloperName FROM Pandadoc_Setting__mdt];    
        if(pandaDocSettings.size() > 0){
            apiKey = pandaDocSettings[0].Api_Key__c;
            baseURL = pandaDocSettings[0].Base_URL__c;
        }
    }
    
    
    
    public static CreateDocument createDocument(String body){
        CreateDocument documentDetails = new CreateDocument();
        if(String.isNotBlank(body)){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(baseURL+'/public/v1/documents');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;');
            request.setHeader('Authorization', 'API-Key '+apiKey);
            request.setBody(body);
            request.setTimeout(20000);
           
            HttpResponse response = http.send(request);
             System.debug('@@@response '+response.getBody());
            if(response.getStatusCode() == 201){
                documentDetails = (CreateDocument)Json.deserialize(response.getBody(), CreateDocument.class);
            }
        } 
        return documentDetails;
    }
    
    public static CreateDocument sendDocument(String body, String documentId){
        CreateDocument documentDetails = new CreateDocument();
        if(String.isNotBlank(body) && String.isNotBlank(documentId)){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(baseURL+'/public/v1/documents/'+documentId+'/send');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;');
            request.setHeader('Authorization', 'API-Key '+apiKey);
            request.setBody(body);
            request.setTimeout(20000);
            HttpResponse response = http.send(request);
            System.debug('@@@response'+response.getBody());
            if(response.getStatusCode() == 200){
                documentDetails = (CreateDocument)Json.deserialize(response.getBody(), CreateDocument.class);
            }
        } 
        return documentDetails;
    }
    
    Public Static SessionDocument createSession(String documentId, String body){
        SessionDocument sessionDetails = new SessionDocument();
        if(String.isNotBlank(body) && String.isNotBlank(documentId)){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(baseURL+'/public/v1/documents/'+documentId+'/session');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json;');
            request.setHeader('Authorization', 'API-Key '+apiKey);
            request.setBody(body);
            request.setTimeout(20000);
            HttpResponse response = http.send(request);
            System.debug('@@@response Session'+ response.getBody()+response.getStatusCode());
            if(response.getStatusCode() == 201){
                sessionDetails = (SessionDocument)Json.deserialize(response.getBody(), SessionDocument.class);
            }
        }
        return sessionDetails;
    }

    Public Static Document viewDocument(String documentId){
        
        Document documentDetails = new Document();
        
        if(String.isNotBlank(documentId)){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(baseURL+'/public/v1/documents/'+documentId+'');
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json;');
            request.setHeader('Authorization', 'API-Key '+apiKey);
            request.setTimeout(20000);
            HttpResponse response = http.send(request);
            System.debug('@@@response Session'+ response.getBody()+response.getStatusCode());
            if(response.getStatusCode() == 200){
                documentDetails = (Document)Json.deserialize(response.getBody(), Document.class);
            }
        }
        
        System.debug('####documentDetails'+documentDetails);   
        return documentDetails;
    }
    
    //jatin: 12-Jan:2020 for Return detailed data about a document
    Public Static Fields viewDocumentDetails(String documentId,string customFieldName){
        // ViewDocumentDetails documentDetails = new ViewDocumentDetails();
        Fields objFields;
        if(String.isNotBlank(documentId)){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(baseURL+'/public/v1/documents/'+documentId+'/details');
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json;');
            request.setHeader('Authorization', 'API-Key '+apiKey);
            request.setTimeout(20000);
            HttpResponse response = http.send(request);
            string responseBody = response.getBody();
            System.debug('@@@response Session'+ responseBody);
            responseBody =  responseBody.replaceAll('type','type_Z').replaceAll('salesforce.account_id','salesforce_account_id').replaceAll('currency','currency_c').replaceAll('document__created_via_public_api','document_created');
            System.debug('@@@response Session'+ responseBody);
           
            if(response.getStatusCode() == 200){
                Map<String,Object> lst_JsonParse = (Map<String,Object>)Json.deserializeUntyped(responseBody);
                //10-feb-2020: convert to json and get stairs 
                for(string  obj : lst_JsonParse.keyset()){
                    system.debug('obj'+obj);
                    if(obj == 'fields'){
                        system.debug('lst_JsonParse.get(obj)'+lst_JsonParse.get(obj));  
                        for(Object fields_StrObj : (list<Object>)lst_JsonParse.get(obj)){
                            Map<String, Object> fieldObject = (Map<String, Object>)fields_StrObj;
                            if(fieldObject.get('name') ==customFieldName){
                                objFields = new Fields(fieldObject.get('uuid'),fieldObject.get('name'), fieldObject.get('title'),fieldObject.get('value'));
                            }
                        }
                    }
                }
            }
        }
        
        System.debug('####objFields'+objFields);   
        return objFields;
    }

    /*
    {
    "id": "msFYActMfJHqNTKH8YSvF1",
    "name": "API Sample Document from PandaDoc Template",
    "status": "document.viewed",
    "date_created": "2017-07-06T08:42:13.836022Z",
    "date_modified": "2017-08-04T02:21:13.963750Z",
    }
     */
    Public Class Document{
        Public String id;
        Public String name;
        Public String status;
        Public String date_created;
		Public String date_modified;
    }
    
    
    Public Class CreateDocument{
        Public String id;
		Public String status;
		Public String name;
		Public String date_created;
		Public String date_modified;
        Public String expiration_date;
        Public String uuid;
    }
    
    Public Class SessionDocument{
		Public String id;
		Public String expires_at;        
    }

    
	
	Public Class Fields {
		public String uuid {get;set;} 
		public String name {get;set;} 
		public String title {get;set;} 
	    public string value {get;set;} 
        public Fields(object uuid,object name, object title,object value){
            this.uuid =(string)uuid;
            this.name = (string)name;
            this.title =(string)title;
            this.value = (string)value; 
        }
        public Fields(){
            this.uuid = '';
            this.name = '';
            this.title = '';
            this.value = '';
        }
	}
	
	
}