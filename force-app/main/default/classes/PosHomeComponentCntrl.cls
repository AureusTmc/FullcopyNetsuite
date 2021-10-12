public class PosHomeComponentCntrl {
    public Boolean isAllowedPermissionToThisUser{get;set;}
    public Enrolment__c objEnrolment{get;set;}
    public PosHomeComponentCntrl(Apexpages.StandardController stdController){
        isAllowedPermissionToThisUser = FeatureManagement.checkPermission('Charge_Additional_Services') ? true : false;
        objEnrolment =  new Enrolment__c();
        objEnrolment = (Enrolment__c)stdController.getRecord();
       
    }
    
     @AuraEnabled
	 public static InitWrapper getCenters(){
        InitWrapper initWrap = new InitWrapper();
        
        List<Centre_Users__c> userCenterList = [SELECT Id, Centre_Name__c, Centre_Name__r.Name, Centre_Name__r.Country__c, Centre_Name__r.Country__r.Tax_Rate__c FROM Centre_Users__c WHERE User_Name__c=:UserInfo.getUserId()];
        if(userCenterList.size() > 0){
        	initWrap.slcdCenter			     = userCenterList[0].Centre_Name__c; 
            if(userCenterList[0].Centre_Name__r.Country__r.Tax_Rate__c != null)
            	initWrap.gstPercent 		 = userCenterList[0].Centre_Name__r.Country__r.Tax_Rate__c; 
         
            Map<String,String> accMap = new Map<String,String>();                
            String cenRecId  =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.centerRecTypeName).getRecordTypeId();
         
            for(Account acc: [SELECT Id,Name,CentreName_Cust__c FROM Account 
                              WHERE RecordtypeId =: cenRecId AND Country__c =: userCenterList[0].Centre_Name__r.Country__c AND CentreName_Cust__c != null ORDER BY CentreName_Cust__c]){
                                  system.debug('----'+acc);
                accMap.put(acc.Id, acc.CentreName_Cust__c); 
            }
            initWrap.cntrList = accMap; 
        }
        
        return initWrap;
    }

   //jatin:25-Feb-2020: query for get all Poc Services records according to country or POs_service_id
    Private  static List<Adhoc_POS_Services__c> getPocAdhocServicesList(string countryId,string posAdhocServiceId) {
        List<Adhoc_POS_Services__c> ListOfAdhocPOSService = new List<Adhoc_POS_Services__c>();  
        string  query = 'SELECT Id, Category__c, Status__c, Per_unit_Price__c, Country__c, Name FROM Adhoc_POS_Services__c WHERE Status__c =\'Active\' ';
        if(string.isNotBlank(countryId)){
            query += ' And Country__c =: countryId ';
        }
        if(string.isNotBlank(posAdhocServiceId)){
            query += ' And Id =: posAdhocServiceId ';
        }
    
        if(string.isNotBlank(query)){
            ListOfAdhocPOSService = (List<Adhoc_POS_Services__c>)Database.query(query);
        }
        return ListOfAdhocPOSService;
    }

    //jatin:25-Feb-2020: get Pos service name or details in picklist value 
    @AuraEnabled 
    Public  static Map<String,String> getPocAdhocServicesNames(string centerId) {
        Map<String,String> mapOfAdhocPOSService = new Map<String,String>();  
        if(string.isNotBlank(centerId)){
            List<Account> listOfCenter =  [SELECT Id,Name,Country__c FROM Account 
                                            WHERE  id= :centerId];
             
            if(listOfCenter != null && listOfCenter.size() > 0 ){
                List<Adhoc_POS_Services__c> ListOfAdhocPOSService = getPocAdhocServicesList(listOfCenter[0].Country__c,'');  
                if(ListOfAdhocPOSService != null && ListOfAdhocPOSService.size() >0 ){
                    for(Adhoc_POS_Services__c objAdhocPOSService: ListOfAdhocPOSService){
                                        mapOfAdhocPOSService.put(objAdhocPOSService.Id+'-'+objAdhocPOSService.Name+'-'+
                                                                objAdhocPOSService.Category__c+'-'+
                                                                objAdhocPOSService.Per_unit_Price__c, objAdhocPOSService.Name); 
                    }
                }
            }
        }
        return mapOfAdhocPOSService;
    }
    @AuraEnabled 
    public static List<SageProductItems> getAdhocPOSServicesList(string posAdhocServiceId){
        List<SageProductItems> adhocPOSServicesProductsList = new List<SageProductItems>();
        List<Adhoc_POS_Services__c> ListOfAdhocPOSService = getPocAdhocServicesList('',posAdhocServiceId);  
        if(ListOfAdhocPOSService != null && ListOfAdhocPOSService.size() >0 ){ 
            for(Adhoc_POS_Services__c objAdhocPOSServices : ListOfAdhocPOSService){
                SageProductItems objAdhocPOSServicesProduct = new SageProductItems();
                objAdhocPOSServicesProduct.recNo = objAdhocPOSServices.id;
                objAdhocPOSServicesProduct.item = objAdhocPOSServices.Name;
                objAdhocPOSServicesProduct.category = objAdhocPOSServices.Category__c;
                objAdhocPOSServicesProduct.price =  objAdhocPOSServices.Per_unit_Price__c; 
                adhocPOSServicesProductsList.add(objAdhocPOSServicesProduct);                                                  
            }
        }
        return adhocPOSServicesProductsList;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getRecords(String searchString, String objectApiName, String idFieldApiName, String valueFieldApiName, String extendedWhereClause, Integer maxRecords){
        searchString = String.escapeSingleQuotes(searchString);
        objectApiName = String.escapeSingleQuotes(objectApiName);
        idFieldApiName = String.escapeSingleQuotes(idFieldApiName);
        valueFieldApiName = String.escapeSingleQuotes(valueFieldApiName);
        
        if(extendedWhereClause == null){
            extendedWhereClause = '';
        }
        
        String query = 'SELECT '+idFieldApiName+', '+valueFieldApiName+' FROM '+objectApiName+' WHERE '+valueFieldApiName+' LIKE \'%'+searchString+'%\' '+extendedWhereClause+' LIMIT '+maxRecords;
        if(objectApiName.equalsIgnoreCase('Account')){
             query = 'SELECT '+idFieldApiName+', '+valueFieldApiName+' FROM '+objectApiName+' WHERE Parent__c = null AND ('+valueFieldApiName+' LIKE \'%'+searchString+'%\' OR PersonEmail LIKE \'%'+searchString+'%\' OR Phone LIKE \'%'+searchString+'%\') '+extendedWhereClause+' LIMIT '+maxRecords;
        }
        system.debug('query'+query);
        return Database.query(query);
    }
    
     // Pass in the endpoint to be used using the string url
	@AuraEnabled
	public static List<SageProductItems> getSageProductItems() {
        List<SageProductItems> sageProducts = new List<SageProductItems>();
            
        list<Centre_Users__c> centerNameList= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name, Centre_Name__r.Organisation__r.Sage_Company__c from Centre_Users__c where User_Name__c=:UserInfo.getUserId() AND Centre_Name__r.Organisation__r.Sage_Company__c != null]);
        if(centerNameList.size() > 0){
            String sageCmp =centerNameList[0].Centre_Name__r.Organisation__r.Sage_Company__c;
            
            SageIntacctIntegrationUtility.resultWrapper rw = new SageIntacctIntegrationUtility.resultWrapper();
        
            SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(sageCmp);        
            if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                System.debug('@@@'+sw.sessionId);
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST');
                    req.setEndpoint(sw.endPointUrl);
                    req.setHeader('Content-Type','application/xml');
                
                    string timestamp = String.valueof(DateTime.now().getTime());
                	
                	String wareHouseName = 'AGP-WH';//sageCmp;// 'ACP-WH';
                	//fetching warehouse details
                	String body = '<?xml version="1.0" encoding="UTF-8"?>'+
                                  '<request>'+
                                    '<control>'+
                                        '<senderid>'+sw.senderId+'</senderid>'+
                                        '<password>'+sw.senderPassword+'</password>'+
                                        '<controlid>'+timestamp+'</controlid>'+
                                        '<uniqueid>false</uniqueid>'+
                                        '<dtdversion>3.0</dtdversion>'+
                                        '<includewhitespace>false</includewhitespace>'+
                                     '</control>'+
                                     '<operation>'+
                                        '<authentication>'+
                                          '<sessionid>'+sw.sessionId+'</sessionid>'+
                                        '</authentication>'+
                                        '<content>'+
                                          '<function controlid="'+timestamp+'">'+
                                            '<readByQuery>'+
                                              '<object>ITEMWAREHOUSEINFO</object>'+
                                              '<fields>*</fields>'+
                                              '<query>WAREHOUSEID=\''+wareHouseName+'\'</query>'+
                                              '<pagesize>100</pagesize>'+
                                            '</readByQuery>'+
                                          '</function>'+
                                        '</content>'+
                                      '</operation>'+
                                '</request>';	
                	req.setBody(body);
                    req.setTimeout(120000);
                    
                    String response;
                    If(!Test.isRunningTest()){
                        Http http = new Http();
                        HTTPResponse res = http.send(req);                    
                        response = res.getBody();
                    }else{
                        response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';
                    }
                    
                    system.debug('body==='+body);
                    System.debug('response==='+response);
                	
                	Set<String> whereHouseItems = new Set<String>();
                
                    DOM.Document doc = new DOM.Document();
                    doc.load(response);
                    DOM.XMLNode root = doc.getRootElement();
                	for(DOM.XMLNode child : root.getChildElements()){
                        if(child.getName()=='operation'){
                            for(DOM.XMLNode child1 : child.getChildElements()){                        
                                Boolean isSuccess = false;
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='status'){
                                        if(child2.getText()=='success'){
                                            isSuccess = true;
                                        }
                                    }
                                    
                                    if(isSuccess && child2.getName()=='data'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='itemwarehouseinfo'){
                                                
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='RECORDNO'){
                                                        //System.debug('@@@@-->'+child4.getText());
                                                        //sgPr.recNo = child4.getText();
                                                    }
                                                    else if(child4.getName()=='ITEMID'){
                                                        whereHouseItems.add(child4.getText());
                                                    }else if(child4.getName()=='WONHOLD'){
                                                      // sgPr.category = child4.getText();
                                                    }
                                                }
                                            }                                       
                                        }
                                    }
                                    
                                    if(child2.getName()=='errormessage'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='error'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='description2'){
                                                        rw.errorMsg = child4.getText();
                                                        break;
                                                    }
                                                }
                                                if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if(child.getName()=='errormessage'){
                            for(DOM.XMLNode child1 : child.getChildElements()){
                                if(child1.getName()=='error'){
                                    for(DOM.XMLNode child2 : child1.getChildElements()){
                                        if(child2.getName()=='description2'){
                                            rw.isSuccess = false;
                                            rw.errorMsg = child2.getText();
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }	
                	
                	System.debug('whereHouseItems==='+whereHouseItems);
                	
                
                    //for get items
                    req = new HttpRequest();
                    req.setMethod('POST');
                    req.setEndpoint(sw.endPointUrl);
                    req.setHeader('Content-Type','application/xml');
                
                    timestamp = String.valueof(DateTime.now().getTime());
                    body = '<?xml version="1.0" encoding="UTF-8"?>'+
                                  '<request>'+
                                    '<control>'+
                                        '<senderid>'+sw.senderId+'</senderid>'+
                                        '<password>'+sw.senderPassword+'</password>'+
                                        '<controlid>'+timestamp+'</controlid>'+
                                        '<uniqueid>false</uniqueid>'+
                                        '<dtdversion>3.0</dtdversion>'+
                                        '<includewhitespace>false</includewhitespace>'+
                                     '</control>'+
                                     '<operation>'+
                                        '<authentication>'+
                                          '<sessionid>'+sw.sessionId+'</sessionid>'+
                                        '</authentication>'+
                                        '<content>'+
                                          '<function controlid="'+timestamp+'">'+
                                            '<readByQuery>'+
                                              '<object>ITEM</object>'+
                                              '<fields>*</fields>'+
                                              '<query>ITEMTYPE=\'I\' and STATUS=\'T\' and PRODUCTLINEID!=\'Piano\'</query>'+
                                              '<pagesize>100</pagesize>'+
                                            '</readByQuery>'+
                                          '</function>'+
                                        '</content>'+
                                      '</operation>'+
                                '</request>';
                
                req.setBody(body);
                req.setTimeout(120000);
                
                response = '';
                If(!Test.isRunningTest()){
                    Http http = new Http();
                    HTTPResponse res = http.send(req);                    
                    response = res.getBody();
                }else{
                    response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';
                }
                
                system.debug('body==='+body);
                System.debug('response==='+response);
                
                doc = new DOM.Document();
                doc.load(response);
                root = doc.getRootElement();
                
                for(DOM.XMLNode child : root.getChildElements()){
                    if(child.getName()=='operation'){
                        for(DOM.XMLNode child1 : child.getChildElements()){                        
                            Boolean isSuccess = false;
                            for(DOM.XMLNode child2 : child1.getChildElements()){
                                if(child2.getName()=='status'){
                                    if(child2.getText()=='success'){
                                        isSuccess = true;
                                    }
                                }
                                
                                if(isSuccess && child2.getName()=='data'){
                                    for(DOM.XMLNode child3 : child2.getChildElements()){
                                        if(child3.getName()=='item'){
                                            SageProductItems sgPr = new SageProductItems();
                                            sgPr.wareHouseId = wareHouseName;
                                            
                                            Boolean isWareHouseProduct = false;
                                            for(DOM.XMLNode child4 : child3.getChildElements()){
                                                if(child4.getName()=='RECORDNO'){
                                                    //System.debug('@@@@-->'+child4.getText());
                                                    sgPr.recNo = child4.getText();
                                                }
                                                else if(child4.getName()=='NAME'){
                                                    //System.debug('@@@@-->'+child4.getText());
                                                    sgPr.item = child4.getText();
                                                    if(whereHouseItems.contains(child4.getText()))
                                                        isWareHouseProduct = true;
                                                }else if(child4.getName()=='PRODUCTLINEID'){
                                                   sgPr.category = child4.getText();
                                                /*}else if(child4.getName()=='MODEL' && String.isNotBlank(child4.getText())){
                                                   sgPr.quantity = child4.getText();  */                                                 
                                                }else if(child4.getName()=='SALE_PRICE' && String.isNotBlank(child4.getText())){
                                                   sgPr.price =  Decimal.valueOf(child4.getText());                                                   
                                                }
                                            }
                                            if(isWareHouseProduct)
                                            	sageProducts.add(sgPr);
                                        }                                       
                                    }
                                }
                                
                                if(child2.getName()=='errormessage'){
                                    for(DOM.XMLNode child3 : child2.getChildElements()){
                                        if(child3.getName()=='error'){
                                            for(DOM.XMLNode child4 : child3.getChildElements()){
                                                if(child4.getName()=='description2'){
                                                    rw.errorMsg = child4.getText();
                                                    break;
                                                }
                                            }
                                            if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if(child.getName()=='errormessage'){
                        for(DOM.XMLNode child1 : child.getChildElements()){
                            if(child1.getName()=='error'){
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='description2'){
                                        rw.isSuccess = false;
                                        rw.errorMsg = child2.getText();
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                
            }else If(sw.errorMsg!=null && sw.errorMsg.trim().length()>0){
                rw.isSuccess = false;
                rw.errorMsg = sw.errorMsg;
            }else{
                rw.isSuccess = false;
                rw.errorMsg = 'Unknown error occured. Please contact your admin.';
            }
        }
		//return resultsMap;
		return sageProducts;
	}
    
 	@AuraEnabled
	public static List<SageWarehouseDetails> getSageProductItemWareHouseDetails(SageProductItems slcdItm) {
        List<SageWarehouseDetails> wareHouseDetailList = new List<SageWarehouseDetails>();
            
        list<Centre_Users__c> centerNameList= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name, Centre_Name__r.Organisation__r.Sage_Company__c from Centre_Users__c where User_Name__c=:UserInfo.getUserId() AND Centre_Name__r.Organisation__r.Sage_Company__c != null]);
        if(centerNameList.size() > 0){
            String sageCmp =centerNameList[0].Centre_Name__r.Organisation__r.Sage_Company__c;
            
            SageIntacctIntegrationUtility.resultWrapper rw = new SageIntacctIntegrationUtility.resultWrapper();
        
            SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(sageCmp);        
               System.debug('@@@SageIntacctIntegrationUtility'+sw);
            if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
             
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(sw.endPointUrl);
                req.setHeader('Content-Type','application/xml');
                
                string timestamp = String.valueof(DateTime.now().getTime());
                
                String wareHouseName = 'ACP-WH';
                //fetching warehouse details
                String body = '<?xml version="1.0" encoding="UTF-8"?>'+
                                  '<request>'+
                                    '<control>'+
                                        '<senderid>'+sw.senderId+'</senderid>'+
                                        '<password>'+sw.senderPassword+'</password>'+
                                        '<controlid>'+timestamp+'</controlid>'+
                                        '<uniqueid>false</uniqueid>'+
                                        '<dtdversion>3.0</dtdversion>'+
                                        '<includewhitespace>false</includewhitespace>'+
                                     '</control>'+
                                     '<operation>'+
                                        '<authentication>'+
                                          '<sessionid>'+sw.sessionId+'</sessionid>'+
                                        '</authentication>'+
                                        '<content>'+
                                          '<function controlid="'+timestamp+'">'+
                                            '<readByQuery>'+
                                              '<object>ITEMWAREHOUSEINFO</object>'+
                                              '<fields>*</fields>'+
                                              '<query>ITEMID=\''+slcdItm.item+'\'</query>'+
                                              '<pagesize>100</pagesize>'+
                                            '</readByQuery>'+
                                          '</function>'+
                                        '</content>'+
                                      '</operation>'+
                                '</request>';	
                req.setBody(body);
                req.setTimeout(120000);
                
                String response;
                If(!Test.isRunningTest()){
                    Http http = new Http();
                    HTTPResponse res = http.send(req);                    
                    response = res.getBody();
                }else{
                   // response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';
               		response ='<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout><data><itemwarehouseinfo><RECORDNO>1</RECORDNO><ITEMID>1</ITEMID><WAREHOUSEID>001</WAREHOUSEID><WONHAND>0</WONHAND><STANDARD_COST>10</STANDARD_COST></itemwarehouseinfo></data></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';
               
                }
                    
                system.debug('body==='+body);
                System.debug('response==='+response);
                
                
                DOM.Document doc = new DOM.Document();
                doc.load(response);
                DOM.XMLNode root = doc.getRootElement();
                for(DOM.XMLNode child : root.getChildElements()){
                    if(child.getName()=='operation'){
                        for(DOM.XMLNode child1 : child.getChildElements()){                        
                            Boolean isSuccess = false;
                            for(DOM.XMLNode child2 : child1.getChildElements()){
                                if(child2.getName()=='status'){
                                    if(child2.getText()=='success'){
                                        isSuccess = true;
                                    }
                                }
                                system.debug('!!child2'+ child2.getChildElements());
                                system.debug('!!child2'+ child2.getName());
                                if(isSuccess && child2.getName()=='data'){
                                    system.debug('!!child2'+ child2.getChildElements());
                                    for(DOM.XMLNode child3 : child2.getChildElements()){
                                        if(child3.getName()=='itemwarehouseinfo'){
                                            SageWarehouseDetails whouse = new SageWarehouseDetails();
                                            for(DOM.XMLNode child4 : child3.getChildElements()){
                                                if(child4.getName()=='RECORDNO'){
                                                    //System.debug('@@@@-->'+child4.getText());
                                                    whouse.recNo = child4.getText();
                                                }else if(child4.getName()=='ITEMID'){
                                                    whouse.itemiD = child4.getText();
                                                }else if(child4.getName()=='WAREHOUSEID'){
                                                    whouse.wareHouseId = child4.getText();
                                                }else if(child4.getName()=='WONHAND' && String.isNotBlank(child4.getText())){
                                                    whouse.avlailbleQntity = Integer.valueOf(child4.getText());
                                                }else if(child4.getName()=='STANDARD_COST' && String.isNotBlank(child4.getText())){
                                                    whouse.price = Decimal.valueOf(child4.getText());
                                                }
                                            }
                                            wareHouseDetailList.add(whouse);
                                        }                                       
                                    }
                                }
                                
                                if(child2.getName()=='errormessage'){
                                    for(DOM.XMLNode child3 : child2.getChildElements()){
                                        if(child3.getName()=='error'){
                                            for(DOM.XMLNode child4 : child3.getChildElements()){
                                                if(child4.getName()=='description2'){
                                                    rw.errorMsg = child4.getText();
                                                    break;
                                                }
                                            }
                                            if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if(child.getName()=='errormessage'){
                        for(DOM.XMLNode child1 : child.getChildElements()){
                            if(child1.getName()=='error'){
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='description2'){
                                        rw.isSuccess = false;
                                        rw.errorMsg = child2.getText();
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }	
                
            }else If(sw.errorMsg!=null && sw.errorMsg.trim().length()>0){
                rw.isSuccess = false;
                rw.errorMsg = sw.errorMsg;
            }else{
                rw.isSuccess = false;
                rw.errorMsg = 'Unknown error occured. Please contact your admin.';
            }
        }
		//return resultsMap;
		return wareHouseDetailList;
	}
    
    
    //Insert new customer
    @AuraEnabled
    public static Account insrtCstmr(Account acc, Boolean isLinkDummyCstmr){
       
        try{
            if(isLinkDummyCstmr){
                String recId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
                List<Account> acCstmrList = [SELECT Id, Name, PersonEmail FROM Account WHERE Name =: Label.WalkInCstmr AND RecordTypeId =: recId];
                if(acCstmrList.size() > 0)
                	acc = acCstmrList.get(0);
            }else{            
            	String recId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
            	acc.RecordTypeId = recId;
            	insert acc;
            }
        }catch(Exception e){
           // resMsg = e.getMessage();
        	System.debug('@@@@-->'+e.getMessage());
        }
        return acc;
    }
    
    @AuraEnabled
    public static Account linkDummyCstmr(){
        Account acc = new Account();
        String recId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get(ConstantsClass.customerRecTypeName).getRecordTypeId();
        List<Account> acCstmrList = [SELECT Id, FirstName, LastName, Name, PersonEmail FROM Account WHERE Name =: Label.WalkInCstmr AND RecordTypeId =: recId];
        if(acCstmrList.size() > 0)
            acc = acCstmrList.get(0);
        return acc;
    }
    
    @AuraEnabled
    public static Account checkCstmrCard(String cstmrId){
        List<Account> cstmrAccList = [SELECT Id, Name, PersonEmail, PersonMobilePhone, BillingStreet, BillingCountry, BillingPostalCode, Stripe_Customer_Id__c,Total_Payment_Credit_Available__c FROM Account WHERE Id =: cstmrId];
        if(cstmrAccList.size() > 0){
            return cstmrAccList.get(0);
        }else{
            return null;
        }
    }
    
   /* @AuraEnabled
    public static Decimal paymentCredits(String cstmrId){
        Decimal creditAmount = 0;
        for(Payment__c  pay :[SELECT Id, Name, Payment_Amount__c, Payment_Status__c 
                              FROM Payment__c WHERE Parent_Account__c =: cstmrId AND Payment_Status__c = 'Pending' AND Payment_Amount__c > 0 AND Invoice__c = null]){
        	creditAmount += pay.Payment_Amount__c; 	                          
        }
        return creditAmount;
    }*/
    
    @AuraEnabled
    public static String payAndRedirect(String selectedCenter, String cstmrId, String slcdPayType, List<SageProductItems> sgPrdItms,string enrolmentId){
        String strMsg = '';
        Savepoint sp;
         System.debug('@@@wareHouseId   '+selectedCenter);

        try{
            List<Account> cstmrAccList = [SELECT Id, Name, PersonEmail, PersonContactId, Stripe_Customer_Id__c, Total_Payment_Credit_Available__c, MovedToSage__c, SageCustomerKey__c, 
                                          Sage_Error_Message__c, Centre_Name__r.Organisation__r.Sage_Company__c FROM Account WHERE Id =: cstmrId];
            List<Account> slcdCntryList = [SELECT Id, Name, Country__r.Currency_Code__c, Location__c, Country__r.Stripe_Base_Url__c, Country__r.Stripe_Secret_Key__c, Country__r.Tax_Rate__c 
                                           FROM Account WHERE Id =: selectedCenter];
            if(cstmrAccList.size() > 0 && slcdCntryList.size() > 0){
                Account objAcc = cstmrAccList.get(0);
                Account centreSlcd = slcdCntryList.get(0);
                
                
                String wareHouseId = '';
                Decimal totalAmount = 0;
                List<Invoice_Line_Item__c> listOfLineItems = new List<Invoice_Line_Item__c>();
                
                //Insert Invoice
                Invoice__c objInvoice = new Invoice__c(Status__c=ConstantsClass.paidStatus, 
                                                       Due_Date__c = system.today().AddDays(ConstantsClass.addInvoiceDueDays),
                                                       Invoice_Date__c =system.today(), 
                                                       Parent_Account__c = objAcc.Id, 
                                                       Center__c=selectedCenter, 
                                                       Invoice_Type__c = 'POS');
                if(slcdPayType.equalsIgnoreCase('Online email'))
                    objInvoice.Status__c = 'Due';
                
                for(SageProductItems objItem : sgPrdItms){
                    wareHouseId = objItem.wareHouseId;
                    Invoice_Line_Item__c invItm = new Invoice_Line_Item__c(Amount__c= objItem.price,
                                                                           POS_Item_Type__c = objItem.item,
                                                                           Remarks__c = objItem.item, 
                                                                           month__c = System.today());
                    invItm.Quantity__c = Integer.valueOf(objItem.quantity);
                    if(string.isnotBlank(enrolmentId)){
                        invItm.enrolment__c = enrolmentId;
                    }
                    if(objItem.price > 0 && centreSlcd.Country__r.Tax_Rate__c > 0)
                        invItm.GST_Amount__c = BillingUtility.roundOffAmount(objItem.price) * (BillingUtility.roundOffAmount(centreSlcd.Country__r.Tax_Rate__c) / 100);
                    listOfLineItems.add(invItm);
                    
                    totalAmount+= BillingUtility.roundOffAmount(objItem.price) + BillingUtility.roundOffAmount(invItm.GST_Amount__c);                
                }
                
                System.debug('@@@wareHouseId   '+wareHouseId);
                
                //Utilize avaialble payment credits                
                List<Payment__c> payUpsrtList  = new List<Payment__c>();
                String payCredRecId  =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
                if(objAcc.Total_Payment_Credit_Available__c > 0 && totalAmount > 0){
                    List<Payment__c> payList = [SELECT Id, Name, Parent_Account__c, Payment_Amount__c, Payment_Status__c FROM Payment__c WHERE Parent_Account__c =: objAcc.Id AND 
                                                RecordType.Name = 'Payment As Credit' AND Payment_Status__c = 'Pending' AND Payment_Amount__c > 0 ORDER BY Payment_Amount__c];
                    for(Payment__c pay: payList){
                        if(totalAmount > 0){
                            if(pay.Payment_Amount__c <= totalAmount){
                                pay.Payment_Status__c = 'Success';
                                payUpsrtList.add(pay);
                                totalAmount = totalAmount - pay.Payment_Amount__c;
                            }else{
                                Decimal actualPayCredit = pay.Payment_Amount__c;
                                pay.Payment_Status__c = 'Success';
                                pay.Payment_Amount__c = totalAmount;
                                payUpsrtList.add(pay);     
                                system.debug('!!totalAmount'+totalAmount);
                                totalAmount = totalAmount - pay.Payment_Amount__c;
                                system.debug('!!totalAmount'+totalAmount);
                                system.debug('!!pay.Payment_Amount__'+pay.Payment_Amount__c);
                                
                                //Create new payment credit for remaning amount
                                Payment__c payCrd = new Payment__c();
                                payCrd.RecordTypeId= payCredRecId;
                                payCrd.Payment_Amount__c = (actualPayCredit - pay.Payment_Amount__c);
                                payCrd.Payment_Status__c = 'Pending';
                                payCrd.Parent_Account__c = objAcc.Id;
                                payUpsrtList.add(payCrd);  
                            }
                        }else{
                            break;
                        }
                    }              	
                } 
                
                BillingUtility.StripeCharge objStripeCharge;
                Boolean isStripChardSuccessfully = false;
                if(totalAmount > 0 && slcdPayType.equalsIgnoreCase('Card')){
                    if(String.isNotBlank(objAcc.Stripe_Customer_Id__c) && String.isNotBlank(centreSlcd.Country__r.Currency_Code__c) && String.isNotBlank(centreSlcd.Country__r.Stripe_Base_Url__c) && String.isNotBlank(centreSlcd.Country__r.Stripe_Secret_Key__c)){
                        objStripeCharge = BillingUtility.createChargeForCustomer(objAcc.Stripe_Customer_Id__c, totalAmount, centreSlcd.Country__r.Currency_Code__c, centreSlcd.Country__r.Stripe_Base_Url__c,  centreSlcd.Country__r.Stripe_Secret_Key__c);    
                        if(objStripeCharge.statusCode == 200 && objStripeCharge.paid){
                            isStripChardSuccessfully = true;
                        }else{
                            strMsg = objStripeCharge.error.message;
                        }
                    }else{
                        strMsg = 'Error: Please check card on customer account.';
                    }
                }
                
                sp = Database.setSavepoint();
                System.debug('@@@slcdPayType   '+slcdPayType);
                if(!slcdPayType.equalsIgnoreCase('Card') || totalAmount == 0 || (slcdPayType.equalsIgnoreCase('Card') && isStripChardSuccessfully)){
                    insert objInvoice;
                    
                    for(Invoice_Line_Item__c objItem : listOfLineItems)
                        objItem.Invoice__c = objInvoice.id;
                    insert listOfLineItems;
					
                    if(payUpsrtList.size() > 0){
                        for(Payment__c pay: payUpsrtList){
                        	if(pay.Id != null)  
                                pay.Invoice__c = objInvoice.Id;
                        }
                        upsert payUpsrtList;
                    }
                    
                    if(slcdPayType.equalsIgnoreCase('Online email')){
                        system.debug('!!totalAmount'+totalAmount);
                        if(totalAmount > 0)
                        	sendPaymentCollectionEmail(objAcc.personContactId, objInvoice.Id, centreSlcd.Location__c);
                    }else{
                        if(totalAmount > 0){
                       	    Payment__c objPayment = BillingUtility.fillPayment(objInvoice.Parent_Account__c,objInvoice.Id,totalAmount,ConstantsClass.successStatus);    
                            objPayment.Method_of_Payment__c = slcdPayType;
                            
                            if(objStripeCharge != null){
                                objPayment.Transaction_ID__c = objStripeCharge.Id;
                            }
                            insert objPayment;
                            if(isStripChardSuccessfully){
                                If(!Test.isRunningTest()){
                                    BillingUtility.updateCharge(objStripeCharge.Id,objInvoice.Name, centreSlcd.Country__r.Stripe_Base_Url__c,  centreSlcd.Country__r.Stripe_Secret_Key__c);
                                }
                            }
                        }
                        
                    }                    
                    pushInvoiceToSage(objInvoice.id, objAcc.Id, wareHouseId);
                    
                    strMsg  = objInvoice.Id;     
                }
            }else{
                strMsg = 'Error: Customer not found.';
            }
        }catch(Exception e){
            system.debug('Error:'+e.getMessage()+e.getLineNumber());
            Database.rollback(sp);
            strMsg = 'Error: '+ e.getMessage();
            
        }
        return strMsg;
    }
    
    public static void sendPaymentCollectionEmail(String personContactId,String invId,String centLoc){
        list<EmailTemplate> listOfEmailTemplate = [SELECT Id, Name 
                                                    FROM EmailTemplate 
                                                    WHERE DeveloperName ='POS_Payment_Collection'];
        
        System.debug('@@@listOfEmailTemplate   '+listOfEmailTemplate.size());
        if(listOfEmailTemplate.size() > 0){
        	List<Messaging.SingleEmailMessage> sendSingleEmailMessage = new List<Messaging.SingleEmailMessage>();
            
            sendSingleEmailMessage.add(AureusUtility.getSingleEmailMessage(listOfEmailTemplate[0].Id, personContactId, invId, centLoc));
            Messaging.sendEmail(sendSingleEmailMessage, FALSE); 
        }
    }
    
    
    @future(callout=true) 
    public static void pushInvoiceToSage(String invId, String cstmrId, String wareHouseId){
        Account objAcc;
        List<Account> cstmrAccList = [SELECT Id, Name, PersonEmail, AccountID_Customer__c, Stripe_Customer_Id__c, MovedToSage__c, SageCustomerKey__c, Sage_Error_Message__c, Centre_Name__r.Organisation__r.Sage_Company__c FROM Account WHERE Id =: cstmrId];
        								  
        if(cstmrAccList.size() > 0){
        	objAcc = cstmrAccList[0];
            
            list<Centre_Users__c> centerNameList= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name, Centre_Name__r.Organisation__r.Sage_Company__c 
                                                                             from Centre_Users__c 
                                                                             where User_Name__c=:UserInfo.getUserId() AND Centre_Name__r.Organisation__r.Sage_Company__c != null]);
           
            if(centerNameList.size() > 0){
                String sageCmp =centerNameList[0].Centre_Name__r.Organisation__r.Sage_Company__c;
                SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(sageCmp);  
                
                if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                    Account custToUpdate = new Account();
                    if(!objAcc.MovedToSage__c){
                        objAcc = SageIntacctIntegrationUtility.createCustomer(sw,cstmrAccList[0]);
                        
                        custToUpdate.Id = objAcc.Id;
                        custToUpdate.SageCustomerKey__c = objAcc.SageCustomerKey__c;
                        custToUpdate.MovedToSage__c = objAcc.MovedToSage__c;   
                        custToUpdate.Sage_Error_Message__c = objAcc.Sage_Error_Message__c;   
                    }    
                                        
                    List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,
                                                        Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,
                                                        SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,
                                                        Internal_Ref_No__c,SageOrderEntryKey__c,
                                                        (Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,
                                                                package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,
                                                         		GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) 
                                                from Invoice__c where Id =: invId];
                    Invoice__c invoice = createInvoice(sw,invList[0], wareHouseId);
                    invList[0].MovedToSage__c = invoice.MovedToSage__c;
                    //  invList[0].SageInvoiceKey__c = invoice.SageInvoiceKey__c;
                    invList[0].SageOrderEntryKey__c = invoice.SageOrderEntryKey__c;
                    invList[0].Sage_Error_Message__c = invoice.Sage_Error_Message__c;                                
                    
                    if(String.isNotBlank(custToUpdate.Id))
                    	update custToUpdate;
                    
                    update invList;
                    
                    system.debug('@@@invoice key   '+invoice.SageOrderEntryKey__c);
                }
                                 	
            }
        }
    } 
        
    public static Invoice__c createInvoice(SageIntacctIntegrationUtility.SessionWrapper sw, Invoice__c invoice, String wareHouseId){
        
        System.debug('@@@@-->'+wareHouseId);
        SageIntacctIntegrationUtility.resultWrapper rw = generateInvoiceOnSage(sw, invoice, wareHouseId, 'Sandbox_', '');
        
        if(rw.isSuccess){
            rw = generateInvoiceOnSage(sw, invoice, wareHouseId, 'Sandbox_', rw.sageRecordKey);
            
            if(rw.isSuccess){
            	invoice.MovedToSage__c = true;
            	invoice.SageOrderEntryKey__c = rw.sageRecordKey;
            }else{
                invoice.Sage_Error_Message__c = 'During invoice:  '+rw.errorMsg;
            } 
        }else{
            invoice.Sage_Error_Message__c = 'During activation:  '+rw.errorMsg;
        }           
        return invoice;
    }
    
    
    public static SageIntacctIntegrationUtility.resultWrapper generateInvoiceOnSage(SageIntacctIntegrationUtility.SessionWrapper sw, Invoice__c invoice, String wareHouseId, String invType, String createdFrom){
        string departmentId = 'Aureus Academy'; 
        
        string body='';
        string response='';
        
        System.debug('@@@@-->'+wareHouseId);
        wareHouseId = 'ACP-WH';
        SageIntacctIntegrationUtility.resultWrapper rw = new SageIntacctIntegrationUtility.resultWrapper();
        
            if(invoice!=null && invoice.Id!=null){
                if(invoice.Invoice_Date__c!=null){
                    Date lastMonthDate = date.newInstance(invoice.Invoice_Date__c.year(),invoice.Invoice_Date__c.month(),Date.DaysInMonth(invoice.Invoice_Date__c.year(),invoice.Invoice_Date__c.month()));
                    if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                        sw = SageIntacctIntegrationUtility.getuserSessionID(invoice.center__r.Organisation__r.Sage_Company__c);
                    }
                    if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                        HttpRequest req = new HttpRequest();
                        req.setMethod('POST');
                        req.setEndpoint(sw.endPointUrl);
                        req.setHeader('Content-Type','application/xml');
                        
                        string timestamp = String.valueof(DateTime.now().getTime());
                        String invName = invType+'_'+invoice.Name;
						Body += '<?xml version="1.0" encoding="UTF-8"?>'+
                                '<request>'+
                                   '<control>'+
                                      '<senderid>'+sw.senderId+'</senderid>'+
                                      '<password>'+sw.senderPassword+'</password>'+
                                      '<controlid>'+timestamp+'</controlid>'+
                                      '<uniqueid>true</uniqueid>'+
                                      '<dtdversion>3.0</dtdversion>'+
                                      '<includewhitespace>false</includewhitespace>'+
                                   '</control>'+
                                   '<operation>'+
                                      '<authentication>'+
                                         '<sessionid>'+sw.sessionId+'</sessionid>'+
                                      '</authentication>'+
                                      '<content>'+
                                         '<function controlid="'+invName+'">'+
                                            '<create_sotransaction>'+
                                               '<transactiontype>'+invType+'</transactiontype>'+
                                               '<datecreated>'+
                                                  '<year>'+invoice.Invoice_Date__c.Year()+'</year>'+
                                                  '<month>'+invoice.Invoice_Date__c.Month()+'</month>'+
                                                  '<day>'+invoice.Invoice_Date__c.Day()+'</day>'+
                                               '</datecreated>'+
                                               '<createdfrom>'+createdFrom+'</createdfrom>'+
                                               '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>'+
                                               '<documentno>'+invoice.Name+'</documentno>'+
                                               '<referenceno>'+invoice.Internal_Ref_No__c+'</referenceno>';
                                                if(invoice.Due_Date__c!=null){    
                                                   body += '<datedue><year>'+invoice.Due_Date__c.Year()+'</year><month>'+invoice.Due_Date__c.Month()+'</month><day>'+invoice.Due_Date__c.Day()+'</day></datedue>';
                                                }                        						
                                               
                                                if(invoice.Invoice_Line_Items__r.size()>0){
                                                    body += '<sotransitems>';
                                                       for(Invoice_Line_Item__c invLineItem:invoice.Invoice_Line_Items__r){    
                                                          body +='<sotransitem>'+
                                                                     '<bundlenumber />'+
                                                                     '<itemid>'+'Books'+'</itemid>'+
                                                                     '<itemdesc />'+
                                                                     '<taxable />'+
                                                                     '<warehouseid>'+wareHouseId+'</warehouseid>'+
                                                                     '<quantity>1</quantity>'+
                                                                     '<unit>Each</unit>'+
                                                                     '<discountpercent />'+
                                                                     '<price>'+(invLineItem.Amount__c!=null?invLineItem.Amount__c:0)+'</price>'+
                                                                     '<discsurchargememo />'+
                                                                     '<locationid/>'+
                                                                     '<departmentid>'+departmentId+'</departmentid>';
                                                                     If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){                                                                        
                                                                         decimal gstAmt = invLineItem.GST_Amount__c!=null?invLineItem.GST_Amount__c.setScale(2):0;
                                                                         body += '<customfields>';
                                                                         body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>10018</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>'+(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c/100)+'</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>'+gstAmt+'</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>'+gstAmt+'</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>REVERSE_TXN_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>RECLAIM</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>RECLAIM_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>RECLAIM_VAT_BASE_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>NON_RECLAIM_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>NON_RECLAIM_VAT_BASE_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>NET_OF_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>NET_OF_VAT_BASE_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                                                         body += '<customfield><customfieldname>MANUAL_VAT_AMOUNT</customfieldname><customfieldvalue>true</customfieldvalue></customfield>';
                                                                         body += '</customfields>';
                                                                    }
                                                           			body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>'+
                                                                 '</sotransitem>';                                                  
                                                           }
                                                           body +='</sotransitems>';
                                                      }
                                            body += '</create_sotransaction>'+
                                         '</function>'+
                                      '</content>'+
                                   '</operation>'+
                                '</request>';                        
                        
                        req.setBody(body);
                        system.debug('body'+body);
                        req.setTimeout(120000);
                        
                        If(!Test.isRunningTest()){
                            Http http = new Http();
                            HTTPResponse res = http.send(req);
                            
                            response = res.getBody();
                        }else{
                            response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Intacct_ISB</senderid><controlid>ControlIdHere</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>intacct</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-12-10T00:17:29+00:00</sessiontimestamp><sessiontimeout>2019-12-10T01:55:18+00:00</sessiontimeout></authentication><result><status>success</status><function>create_sotransaction</function><controlid>testControlId</controlid><key>-TEST INTACCT</key></result></operation></response>';
                        }
                        
                        system.debug('body==='+body);
                        System.debug('response==='+response);
                        
                        DOM.Document doc = new DOM.Document();
                        doc.load(response);
                        DOM.XMLNode root = doc.getRootElement();
                        
                        for(DOM.XMLNode child : root.getChildElements()){
                            if(child.getName()=='operation'){
                                for(DOM.XMLNode child1 : child.getChildElements()){
                                    if(child1.getName()=='result'){
                                        for(DOM.XMLNode child2 : child1.getChildElements()){
                                            if(child2.getName()=='status'){
                                                if(child2.getText()=='success'){
                                                    rw.isSuccess = true;
                                                    rw.sfRecordId = invoice.Id;
                                                }
                                            }
                                            
                                            if(child2.getName()=='key'){
                                                rw.sageRecordKey = child2.getText();
                                            }
                                            
                                            if(child2.getName()=='errormessage'){
                                                
                                                for(DOM.XMLNode child3 : child2.getChildElements()){
                                                    if(child3.getName()=='error'){
                                                        for(DOM.XMLNode child4 : child3.getChildElements()){
                                                            if(child4.getName()=='description2'){
                                                                rw.isSuccess = false;
                                                                rw.errorMsg = child4.getText();
                                                                break;
                                                            }
                                                        }
                                                        if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if(child.getName()=='errormessage'){
                                for(DOM.XMLNode child1 : child.getChildElements()){
                                    if(child1.getName()=='error'){
                                        for(DOM.XMLNode child2 : child1.getChildElements()){
                                            if(child2.getName()=='description2'){
                                                rw.isSuccess = false;
                                                rw.errorMsg = child2.getText();
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }else If(sw.errorMsg!=null && sw.errorMsg.trim().length()>0){
                        rw.isSuccess = false;
                        rw.errorMsg = sw.errorMsg;
                    }else{
                        rw.isSuccess = false;
                        rw.errorMsg = 'Unknown error occured. Please contact your admin.';
                    }
                }else{
                    rw.isSuccess = false;
                    rw.errorMsg = 'Invoice Date is missing.';
                }
            }else{
                rw.isSuccess = false;
                rw.errorMsg = 'Invoice not found.';
            }
        /*
        if(rw.isSuccess){
            invoice.MovedToSage__c = true;
            invoice.SageOrderEntryKey__c = rw.sageRecordKey;
        }else{
            invoice.Sage_Error_Message__c = rw.errorMsg;
        } */    
        system.debug('rw'+rw);
        return rw;
    }
    
    /*
    Public class sessionWrapper{
        @AuraEnabled Public string senderId{get;set;}
        @AuraEnabled Public string senderPassword{get;set;}
        @AuraEnabled Public string endPointUrl{get;set;}
        @AuraEnabled Public string sessionId{get;set;}
        @AuraEnabled Public string errorMsg{get;set;}
    }
    
    public class resultWrapper{
        Public Boolean isSuccess{get;set;}
        Public string sfRecordId{get;set;}
        Public string sageRecordKey{get;set;}
        Public string errorMsg{get;set;}
        public resultWrapper(){
            isSuccess = false;
        }
    }
    */
     public class InitWrapper{
        @AuraEnabled public Map<String,String> cntrList;
        @AuraEnabled public String slcdCenter;
        @AuraEnabled public Decimal gstPercent;
        @AuraEnabled public String message;
        @AuraEnabled public Boolean success;
        
        public InitWrapper(){
             gstPercent = 0;
        }
         
    }
    
    public class SageWarehouseDetails{
        @AuraEnabled public String  recNo{get;set;}
        @AuraEnabled public String  wareHouseId{get;set;}
        @AuraEnabled public String  itemiD{get;set;}
        @AuraEnabled public Integer avlailbleQntity{get;set;}
        @AuraEnabled public Decimal price{get;set;}
        
        public SageWarehouseDetails(){
            recNo = itemiD = wareHouseId = '';
            avlailbleQntity = 0;
            price = 0;
        }
    }
    
    public class SageProductItems{
        @AuraEnabled public String  recNo{get;set;}
        @AuraEnabled public String  item{get;set;}
        @AuraEnabled public String  category{get;set;}
        @AuraEnabled public String  quantity{get;set;}
        @AuraEnabled public String  wareHouseId{get;set;}
        @AuraEnabled public Decimal  price{get;set;}
        
        public SageProductItems(){
            recNo = item = category = wareHouseId ='';
            quantity = '1';
            price = 50;
        }
    }
}