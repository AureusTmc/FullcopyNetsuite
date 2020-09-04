Public without sharing class SageIntacctIntegrationUtility{
    
    public static sessionWrapper getuserSessionID(string locationId){
        sessionWrapper sw = new sessionWrapper();
        
        string body;
        string response;
        
        List<Sage_Intacct_Credentials__c> sageIntacctCredList = [Select Id,Name,Endpoint__c,Sender_ID__c,Sender_Password__c,Webservice_User_ID__c,Webservice_User_Password__c from Sage_Intacct_Credentials__c limit 1];
        if(sageIntacctCredList.size()>0){                
            try{
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(sageIntacctCredList[0].Endpoint__c);
                req.setHeader('Content-Type','application/xml');
                
                body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                body += '<senderid>'+sageIntacctCredList[0].Sender_ID__c+'</senderid>';
                body += '<password>'+sageIntacctCredList[0].Sender_Password__c+'</password>';
                body += '<controlid>'+sageIntacctCredList[0].Id+'</controlid>';
                body += '<uniqueid>false</uniqueid>';
                body += '<dtdversion>3.0</dtdversion>';
                body += '<includewhitespace>false</includewhitespace>';
                body += '</control>';
                body += '<operation>';
                body += '<authentication>';
                body += '<login>';
                body += '<userid>'+sageIntacctCredList[0].Webservice_User_ID__c+'</userid>';
                body += '<companyid>'+sageIntacctCredList[0].Name+'</companyid>';
                body += '<password>'+sageIntacctCredList[0].Webservice_User_Password__c+'</password>';
                if(locationId!=null && locationId.trim().length()>0){
                    body += '<locationid>'+locationId+'</locationid>';
                }
                body += '</login>';
                body += '</authentication>';
                body += '<content>';
                body += '<function controlid="'+sageIntacctCredList[0].Id+'">';
                body += '<getAPISession/>';
                body += '</function>';
                body += '</content></operation></request>';
                
                req.setBody(body);
                req.setTimeout(120000);
                
                If(!Test.isRunningTest()){
                    Http http = new Http();
                    HTTPResponse res = http.send(req);
                    response = res.getBody();
                }else{
                    response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>a0P0p000000AKnAEAW</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-08-28T03:47:39-07:00</sessiontimestamp><sessiontimeout>2019-08-28T09:47:39-07:00</sessiontimeout></authentication><result><status>success</status><function>getAPISession</function><controlid>a0P0p000000AKnAEAW</controlid><data><api><sessionid>oSHwMnFypzWA7wmIPlLj332aNYHvCQ..</sessionid><endpoint>https://api.intacct.com/ia/xml/xmlgw.phtml</endpoint><locationid>AGP</locationid></api></data></result></operation></response>';
                }
                System.debug('response==='+response);
                
                DOM.Document doc = new DOM.Document();
                doc.load(response);
                DOM.XMLNode root = doc.getRootElement();
                
                string sessionID;
                Boolean isError = false;
                string errorMsg;
                If(response!=null && response.trim().length()>0){
                    for(DOM.XMLNode child : root.getChildElements()){
                        if(child.getName()=='operation'){
                            for(DOM.XMLNode child1 : child.getChildElements()){
                                if(child1.getName()=='result'){
                                    for(DOM.XMLNode child2 : child1.getChildElements()){
                                        if(child2.getName()=='errormessage'){
                                            isError = true;
                                            for(DOM.XMLNode child3 : child2.getChildElements()){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='description' || child4.getName()=='description2'){
                                                        string childVal = child4.getText();
                                                        if(childVal!=null && childVal.trim().length()>0){
                                                            errorMsg = childVal;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        if(child2.getName()=='data'){
                                            for(DOM.XMLNode child3 : child2.getChildElements()){
                                                if(child3.getName()=='api'){
                                                    for(DOM.XMLNode child4 : child3.getChildElements()){
                                                        if(child4.getName()=='sessionid'){
                                                            system.debug(child4.getName()+' : '+child4.getText());
                                                            sessionID = child4.getText();
                                                            break;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }else if(child.getName()=='errormessage'){
                            isError = true;
                            for(DOM.XMLNode child1 : child.getChildElements()){
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='description' || child2.getName()=='description2'){
                                        string childVal = child2.getText();
                                        if(childVal!=null && childVal.trim().length()>0){
                                            errorMsg = childVal;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                sw.senderId = sageIntacctCredList[0].Sender_ID__c;
                sw.senderPassword = sageIntacctCredList[0].Sender_Password__c;
                sw.endPointUrl = sageIntacctCredList[0].Endpoint__c;
                
                if(isError){
                    sw.errorMsg = errorMsg;
                }else{
                    sw.sessionId = sessionID;
                }
            }catch(exception e){
                sw.errorMsg = e.getMessage();
            }
        }else{
            sw.errorMsg = 'Blank response from Sage.';
        }
        
        return sw;
    }
    
    public static void getGlAccountCodes(){
        
        /*SessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(null);
        
        if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(sw.endPointUrl);
            req.setHeader('Content-Type','application/xml');
            
            string timestamp = String.valueof(DateTime.now().getTime());
            
            string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
            body += '<senderid>'+sw.senderId+'</senderid>';
            body += '<password>'+sw.senderPassword+'</password>';
            body += '<controlid>'+timestamp+'</controlid>';
            body += '<uniqueid>false</uniqueid>';
            body += '<dtdversion>3.0</dtdversion>';
            body += '<includewhitespace>false</includewhitespace>';
            body += '</control>';
            body += '<operation>';
            body += '<authentication>';
            body += '<sessionid>'+sw.sessionId+'</sessionid>';
            body += '</authentication>';
            body += '<content>';
            body += '<function controlid="'+timestamp+'">';
            body += '<readByQuery>';
            body += '<object>GLACCOUNT</object>';
            body += '<fields>*</fields>';
            body += '<query></query>';
            body += '<pagesize>1000</pagesize>';
            body += '</readByQuery>';
            body += '</function></content></operation></request>';
            
            req.setBody(body);
            req.setTimeout(120000);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            string response = res.getBody();
            
            system.debug(response);
            
            Map<string,string> resultMap = new Map<string,string>();
            
            DOM.Document doc = new DOM.Document();
            doc.load(response);
            DOM.XMLNode root = doc.getRootElement();
            
            for(DOM.XMLNode child : root.getChildElements()){
                if(child.getName()=='operation'){
                    for(DOM.XMLNode child1 : child.getChildElements()){
                        if(child1.getName()=='result'){
                            Boolean isSuccess = false;
                            for(DOM.XMLNode child2 : child1.getChildElements()){
                                if(child2.getName()=='status'){
                                    if(child2.getText()=='success'){
                                        isSuccess = true;
                                    }
                                }
                                if(isSuccess && child2.getName()=='data'){
                                    for(DOM.XMLNode child3 : child2.getChildElements()){
                                        string glAccNo = null;
                                        string glTitle = null;
                                        for(DOM.XMLNode child4 : child3.getChildElements()){
                                            system.debug('child4.getName()====='+child4.getName());
                                            if(child4.getName()=='ACCOUNTNO'){
                                                glAccNo = child4.getText();
                                                system.debug(glAccNo);
                                            }else if(child4.getName()=='TITLE'){
                                                glTitle = child4.getText();
                                                system.debug(glTitle);
                                            }
                                        }
                                        if(glAccNo!=null && glTitle!=null){
                                            resultMap.put(glAccNo,glTitle);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if(resultMap!=null && resultMap.size()>0){
                Savepoint sp = Database.setSavePoint();
                try{
                    List<Sage_GL_Account__c> sageGLAccList = [Select id,Name,GL_Account_No__c from Sage_GL_Account__c];
                    if(sageGLAccList.size()>0){
                        delete sageGLAccList;
                    }
                    List<Sage_GL_Account__c> sageGLAccounts = new List<Sage_GL_Account__c>();
                    for(string str:resultMap.keyset()){
                        Sage_GL_Account__c sga = new Sage_GL_Account__c();
                        sga.Name = resultMap.get(str);
                        sga.GL_Account_No__c = str;
                        sageGLAccounts.add(sga);
                    }
                    insert sageGLAccounts;
                }catch(exception e){
                    Database.rollback(sp);
                }
            }
        }*/
    }
    
    public static  Account createCustomer(SessionWrapper sw, Account customer){
        /*resultWrapper crw = new resultWrapper();
        string body;
        string response;
        if(customer!=null && customer.Id!=null){
            if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                sw = SageIntacctIntegrationUtility.getuserSessionID(customer.Centre_Name__r.Organisation__r.Sage_Company__c);
            }
            
            if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(sw.endPointUrl);
                req.setHeader('Content-Type','application/xml');
                
                string timestamp = String.valueof(DateTime.now().getTime());
                
                string name = customer.Name;
                if(name.contains('&')){
                    name = name.replaceAll('&','&amp;');
                }
                
                body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                body += '<senderid>'+sw.senderId+'</senderid>';
                body += '<password>'+sw.senderPassword+'</password>';
                body += '<controlid>'+timestamp+'</controlid>';
                body += '<uniqueid>false</uniqueid>';
                body += '<dtdversion>3.0</dtdversion>';
                body += '<includewhitespace>false</includewhitespace>';
                body += '</control>';
                body += '<operation>';
                body += '<authentication>';
                body += '<sessionid>'+sw.sessionId+'</sessionid>';
                body += '</authentication>';
                body += '<content>';
                body += '<function controlid="'+timestamp+'">';
                body += '<create>';
                body += '<CUSTOMER>';
                body += '<customerid>'+customer.AccountID_Customer__c+'</customerid>';
                body += '<name>'+name+'</name>';
                body += '<DISPLAYCONTACT>';
                body += '<contactname>'+name+'-'+customer.AccountID_Customer__c+'</contactname>';
                body += '<printas>'+name+'</printas>';
                body += '<email1>'+customer.personEmail+'</email1>';
                body += '</DISPLAYCONTACT>';
                body += '</CUSTOMER>';
                body += '</create></function></content></operation></request>';
                
                system.debug('Body===='+body);
                
                req.setBody(body);
                req.setTimeout(120000);
                
                If(!Test.isRunningTest()){
                    Http http = new Http();
                    HTTPResponse res = http.send(req);
                    
                    response = res.getBody();
                }else{
                    response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561703547692</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid></locationid><sessiontimestamp>2019-06-27T23:32:27-07:00</sessiontimestamp><sessiontimeout>2019-06-28T05:32:27-07:00</sessiontimeout></authentication><result><status>success</status><function>create</function><controlid>1561703547692</controlid><data listtype="objects" count="1"><customer><RECORDNO>30</RECORDNO><CUSTOMERID>0010p00000DUwJfAAL</CUSTOMERID></customer></data></result></operation></response>';
                }
                
                
                System.debug('response===='+response);
                
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
                                            crw.isSuccess = true;
                                            crw.sfRecordId = customer.Id;
                                        }
                                    }
                                    
                                    if(crw.isSuccess && child2.getName()=='data'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='customer'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='RECORDNO'){
                                                        crw.sageRecordKey = child4.getText();
                                                        break;
                                                    }
                                                }
                                            }
                                            if(crw.sageRecordKey!=null && crw.sageRecordKey.trim().length()>0){
                                                break;
                                            }                                       
                                        }
                                    }
                                    
                                    if(child2.getName()=='errormessage'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='error'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='description2'){
                                                        crw.isSuccess = false;
                                                        crw.errorMsg = child4.getText();
                                                        break;
                                                    }
                                                }
                                                if(crw.errorMsg!=null && crw.errorMsg.trim().length()>0){
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
                                        crw.isSuccess = false;
                                        crw.errorMsg = child2.getText();
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
                
            }else If(sw.errorMsg!=null && sw.errorMsg.trim().length()>0){
                crw.isSuccess = false;
                crw.errorMsg = sw.errorMsg;
                
            }else{
                crw.isSuccess = false;
                crw.errorMsg = 'Unknown error occured. Please contact your admin.';
            }
        }
        
        system.debug('crw.sageRecordKey=='+crw.sageRecordKey);
        
        if(crw.isSuccess){
            customer.MovedToSage__c = true;
            customer.SageCustomerKey__c = crw.sageRecordKey;
            customer.Sage_Error_Message__c = '';
        }else{
            customer.Sage_Error_Message__c = crw.errorMsg; 
        }*/           
        return customer;
        
    }
    
    public static Payment__c createPayment(sessionWrapper sw, Payment__c payment, string invoiceKey){
        /*resultWrapper rw = new resultWrapper();
        
        string body;
        string response;
        
        Map<string,string> glCodeMap = new Map<string,string>();
        List<Sage_GL_Account__c> glList = [Select id,Name,GL_Account_No__c from Sage_GL_Account__c];
        for(Sage_GL_Account__c gl: glList){
            glCodeMap.put(gl.Name,gl.GL_Account_No__c);
        }
        
        If(glCodeMap.size()>0){    
            if(payment!=null && payment.Id!=null){
                if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                    sw = SageIntacctIntegrationUtility.getuserSessionID(payment.Invoice__r.Center__r.Organisation__r.Sage_Company__c);
                }
                if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST');
                    req.setEndpoint(sw.endPointUrl);
                    req.setHeader('Content-Type','application/xml');
                    
                    string timestamp = String.valueof(DateTime.now().getTime());
                    
                    body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                    body += '<senderid>'+sw.senderId+'</senderid>';
                    body += '<password>'+sw.senderPassword+'</password>';
                    body += '<controlid>'+timestamp+'</controlid>';
                    body += '<uniqueid>false</uniqueid>';
                    body += '<dtdversion>3.0</dtdversion>';
                    body += '<includewhitespace>false</includewhitespace>';
                    body += '</control>';
                    body += '<operation>';
                    body += '<authentication>';
                    body += '<sessionid>'+sw.sessionId+'</sessionid>';
                    body += '</authentication>';
                    body += '<content>';
                    body += '<function controlid="'+timestamp+'">';
                    body += '<create_arpayment>';
                    body += '<customerid>'+payment.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                    
                    body += '<paymentamount>'+payment.Payment_Amount__c.setScale(2)+'</paymentamount>';
                    
                    If(payment.recordType.Name=='Payment As Deposit'){
                        body += '<undepfundsacct>'+glCodeMap.get('Customer Deposits')+'</undepfundsacct>';
                    }else If(payment.recordType.Name=='Payment As Credit'){
                        body += '<undepfundsacct>'+glCodeMap.get('Accounts Receivable')+'</undepfundsacct>';
                    }else{
                        If(payment.Method_of_Payment__c=='Card' || payment.Method_of_Payment__c=='Offline Card'){                        
                            body += '<undepfundsacct>'+glCodeMap.get('Merchandise Card Receivable')+'</undepfundsacct>';
                        }else if(payment.Method_of_Payment__c=='Cash' || payment.Method_of_Payment__c=='NETS' || payment.Method_of_Payment__c=='Cheque'){
                            If(payment.Invoice__r.Center__r.Organisation__r.Sage_Company__c=='AGP'){
                                body += '<bankaccountid>OCBC-AGP</bankaccountid>';
                            }else if(payment.Invoice__r.Center__r.Organisation__r.Sage_Company__c=='AGH'){
                                body += '<bankaccountid>OCBC1-AGH</bankaccountid>';
                            }
                        }else{
                            body += '<undepfundsacct>'+glCodeMap.get('Accounts Receivable')+'</undepfundsacct>';
                        }
                    }
                    
                    If(payment.Payment_Date__c!=null){
                        body += '<datereceived><year>'+payment.Payment_Date__c.year()+'</year><month>'+payment.Payment_Date__c.month()+'</month><day>'+payment.Payment_Date__c.day()+'</day></datereceived>';
                    }
                    
                    body += '<paymentmethod>EFT</paymentmethod>';
                    
                    If(payment.Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c!=null){
                        body += '<basecurr>'+payment.Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c+'</basecurr>';
                        body += '<currency>'+payment.Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c+'</currency>';
                        body += '<exchrate>1</exchrate>';
                    }
                    
                    Decimal invAmount = 0;
                    If(payment.Payment_Amount__c > payment.Invoice__r.Total_Amount__c){
                        invAmount = payment.Invoice__r.Total_Amount__c;
                    }else{
                        invAmount = payment.Payment_Amount__c;
                    }
                    
                    body += '<arpaymentitem>';
                    body += '<invoicekey>'+((invoiceKey!=null && invoiceKey.trim().length()>0)?invoiceKey:payment.Invoice__r.SageInvoiceKey__c)+'</invoicekey>';
                    body += '<amount>'+invAmount.setscale(2)+'</amount>';
                    body += '</arpaymentitem>';                    
                    
                    body += '</create_arpayment></function></content></operation></request>';
                    
                    req.setBody(body);
                    req.setTimeout(120000);
                    
                    If(!Test.isRunningTest()){
                        Http http = new Http();
                        HTTPResponse res = http.send(req);                    
                        response = res.getBody();
                    }else{
                        response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561088787741</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid /><sessiontimestamp>2019-06-20T20:46:28-07:00</sessiontimestamp><sessiontimeout>2019-06-21T02:46:28-07:00</sessiontimeout></authentication><result><status>success</status><function>create_arpayment</function><controlid>1561088787741</controlid><key>9</key></result></operation></response>';
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
                                                rw.sfRecordId = payment.Id;
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
                rw.errorMsg = 'Payment record not found.';
            }
        }else{
            rw.isSuccess = false;
            rw.errorMsg = 'GL code not found.';
        }
        
        system.debug('payment rw ==='+rw);
        
        if(rw.isSuccess){
            payment.MovedToSage__c = true;
            payment.SagePaymentKey__c = rw.sageRecordKey;
            payment.Sage_Error_Message__c = '';
        }else{
            payment.Sage_Error_Message__c = rw.errorMsg;
        }*/           
        return payment;
    }
    
    Public static Invoice__c reverseInvoice(SessionWrapper sw, Invoice__c invoice){
        /*string body;
        string response;
        if(invoice!=null && invoice.Id!=null){
            List<Invoice__c> invList = [Select id,SageInvoiceKey__c,Voided_on_Sage__c,Sage_Error_Message__c,Invoice_Date__c,Remarks__c,Center__r.Organisation__r.Sage_Company__c from Invoice__c where Id=:invoice.Id and SageInvoiceKey__c!=null and Voided_on_Sage__c=false limit 1];
            
            if(invList.size()>0){
                invoice = invList[0];
                
                Date reverseDate = system.today();
                if(invoice.Invoice_Date__c!=null && invoice.Invoice_Date__c>reverseDate){
                    reverseDate = invoice.Invoice_Date__c;
                }
                
                if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                    sw = SageIntacctIntegrationUtility.getuserSessionID(invoice.Center__r.Organisation__r.Sage_Company__c);
                }
                if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST');
                    req.setEndpoint(sw.endPointUrl);
                    req.setHeader('Content-Type','application/xml');
                    
                    string timestamp = String.valueof(DateTime.now().getTime());
                    
                    body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                    body += '<senderid>'+sw.senderId+'</senderid>';
                    body += '<password>'+sw.senderPassword+'</password>';
                    body += '<controlid>'+timestamp+'</controlid>';
                    body += '<uniqueid>false</uniqueid>';
                    body += '<dtdversion>3.0</dtdversion>';
                    body += '<includewhitespace>false</includewhitespace>';
                    body += '</control>';
                    body += '<operation>';
                    body += '<authentication>';
                    body += '<sessionid>'+sw.sessionId+'</sessionid>';
                    body += '</authentication>';
                    body += '<content>';
                    body += '<function controlid="'+timestamp+'">';
                    body += '<reverse_invoice key="'+invoice.SageInvoiceKey__c+'">';
                    body += '<datereversed><year>'+reverseDate.year()+'</year><month>'+reverseDate.month()+'</month><day>'+reverseDate.day()+'</day></datereversed>';
                    body += '<description>'+invoice.Remarks__c+'</description>';
                    body += '</reverse_invoice></function></content></operation></request>';
                    
                    req.setBody(body);
                    req.setTimeout(120000);
                    
                    If(!Test.isRunningTest()){
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        
                        response = res.getBody();
                    }else{
                        response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1561954211557</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid></locationid><sessiontimestamp>2019-06-30T21:10:11-07:00</sessiontimestamp><sessiontimeout>2019-07-01T03:10:11-07:00</sessiontimeout></authentication><result><status>success</status><function>reverse_invoice</function><controlid>1561954211557</controlid></result></operation></response>';
                    }    
                    
                    system.debug('body==='+body);
                    System.debug('response==='+response);
                    
                    DOM.Document doc = new DOM.Document();
                    doc.load(response);
                    DOM.XMLNode root = doc.getRootElement();
                    Boolean isSuccess = false;
                    string errorMsg;
                    for(DOM.XMLNode child : root.getChildElements()){
                        if(child.getName()=='operation'){
                            for(DOM.XMLNode child1 : child.getChildElements()){
                                if(child1.getName()=='result'){
                                    for(DOM.XMLNode child2 : child1.getChildElements()){
                                        if(child2.getName()=='status'){
                                            if(child2.getText()=='success'){
                                                isSuccess = true;
                                            }
                                        }
                                        
                                        if(child2.getName()=='errormessage'){                                                
                                            for(DOM.XMLNode child3 : child2.getChildElements()){
                                                if(child3.getName()=='error'){
                                                    for(DOM.XMLNode child4 : child3.getChildElements()){
                                                        if(child4.getName()=='description2'){
                                                            isSuccess = false;
                                                            errorMsg = child4.getText();
                                                            break;
                                                        }
                                                    }
                                                    if(errorMsg!=null && errorMsg.trim().length()>0){
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                        
                                        
                                    }
                                }
                            }
                        }
                    }
                    
                    If(isSuccess){
                        Invoice.Voided_on_Sage__c = true;
                        Invoice.Sage_Error_Message__c = '';
                    }else If(errorMsg!=null && errorMsg.trim().length()>0){
                        Invoice.Sage_Error_Message__c = errorMsg;
                    }
                }
            }
        }*/
        return Invoice;
    }
    
    Public static Payment__c reversePayment(SessionWrapper sw, Payment__c payment){
        /*if(payment!=null && payment.Id!=null){
            
            Date reverseDate = system.today();
            
            if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                sw = SageIntacctIntegrationUtility.getuserSessionID(payment.Invoice__r.Center__r.Organisation__r.Sage_Company__c);
            }
            if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(sw.endPointUrl);
                req.setHeader('Content-Type','application/xml');
                
                string timestamp = String.valueof(DateTime.now().getTime());
                
                string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                body += '<senderid>'+sw.senderId+'</senderid>';
                body += '<password>'+sw.senderPassword+'</password>';
                body += '<controlid>'+timestamp+'</controlid>';
                body += '<uniqueid>false</uniqueid>';
                body += '<dtdversion>3.0</dtdversion>';
                body += '<includewhitespace>false</includewhitespace>';
                body += '</control>';
                body += '<operation>';
                body += '<authentication>';
                body += '<sessionid>'+sw.sessionId+'</sessionid>';
                body += '</authentication>';
                body += '<content>';
                body += '<function controlid="'+timestamp+'">';
                body += '<reverse_arpayment key="'+payment.Parent_Payment__r.SagePaymentKey__c+'">';
                body += '<datereversed><year>'+reverseDate.year()+'</year><month>'+reverseDate.month()+'</month><day>'+reverseDate.day()+'</day></datereversed>';
                body += '<description>'+payment.Remarks__c+'</description>';
                body += '</reverse_arpayment></function></content></operation></request>';
                
                req.setBody(body);
                req.setTimeout(120000);
                
                string response;
                If(!Test.isRunningTest()){
                    Http http = new Http();
                    HTTPResponse res = http.send(req);
                    
                    response = res.getBody();
                }else{
                    response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1562747764</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid></locationid><sessiontimestamp>2019-07-10T01:36:03-07:00</sessiontimestamp><sessiontimeout>2019-07-10T07:36:03-07:00</sessiontimeout></authentication><result><status>success</status><function>reverse_arpayment</function><controlid>aff15573-a1b6-4a71-90af-7c527ce66b62</controlid></result></operation></response>';
                }
                
                
                system.debug('body==='+body);
                System.debug('response==='+response);
                
                DOM.Document doc = new DOM.Document();
                doc.load(response);
                DOM.XMLNode root = doc.getRootElement();
                Boolean isSuccess = false;
                string errorMsg;
                for(DOM.XMLNode child : root.getChildElements()){
                    if(child.getName()=='operation'){
                        for(DOM.XMLNode child1 : child.getChildElements()){
                            if(child1.getName()=='result'){
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='status'){
                                        if(child2.getText()=='success'){
                                            isSuccess = true;
                                            payment.MovedToSage__c = true;
                                            payment.SagePaymentKey__c = payment.Parent_Payment__r.SagePaymentKey__c;
                                        }
                                    }
                                    
                                    if(child2.getName()=='errormessage'){                                                
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='error'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='description2'){
                                                        isSuccess = false;
                                                        errorMsg = child4.getText();
                                                        payment.Sage_Error_Message__c = errorMsg;
                                                        break;
                                                    }
                                                }
                                                if(errorMsg!=null && errorMsg.trim().length()>0){
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }else{
                payment.Sage_Error_Message__c = sw.errorMsg;
            }   
        }*/
        
        return payment;
    }
    
    @future(Callout=true)
    Public static void newEnrolment(string customerId,Set<string> invoiceIds){
        /*If(CustomerId!=null && customerId.trim().length()>0){
            Account custToUpdate = new Account();
            List<Account> customers = [Select id,Name,AccountID_Customer__c,PersonEmail,MovedToSage__c,SageCustomerKey__c,Sage_Error_Message__c,Centre_Name__r.Organisation__r.Sage_Company__c from Account where Id=:CustomerId and MovedToSage__c=False and Parent__c=null limit 1];
            if(customers.size()>0){
                customers[0] = SageIntacctIntegrationUtility.createCustomer(null,customers[0]);
                
                custToUpdate.Id = customers[0].Id;
                custToUpdate.MovedToSage__c = customers[0].MovedToSage__c;
                custToUpdate.SageCustomerKey__c = customers[0].SageCustomerKey__c;
                custToUpdate.Sage_Error_Message__c = customers[0].Sage_Error_Message__c;
                
            }
            
            If(Test.isRunningTest()){
                Invoice__c invMovedToSageUpd = [select id,MovedToSage__c from invoice__c where Id in:invoiceIds limit 1];
                invMovedToSageUpd.MovedToSage__c=false;
                update invMovedToSageUpd;
            }
            
            if(invoiceIds!=null && invoiceIds.size()>0){
                List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Id in:invoiceIds and MovedToSage__c=False];
                if(invList.size()>0){
                    for(Invoice__c inv :invList){
                        Invoice__c invoice = SageIntacctIntegrationUtility.createInvoice(null,inv);
                        inv.MovedToSage__c = invoice.MovedToSage__c;
                        inv.SageOrderEntryKey__c = invoice.SageOrderEntryKey__c;
                        inv.Sage_Error_Message__c = invoice.Sage_Error_Message__c;
                    }
                    update invList;
                }   
            }
            if(customers.size()>0){
                update custToUpdate;
            }
        }*/
    }
    
    @future(Callout=true)
    Public static void newStudioRental(string customerId,string invoiceId,string paymentId){
        /*If(Test.isRunningTest()){
            Account accMovedToSageUpd = [select id,MovedToSage__c from Account where Id=:CustomerId and Parent__c=null limit 1];
            accMovedToSageUpd.MovedToSage__c=false;
            update accMovedToSageUpd;
            
            Invoice__c invMovedToSageUpd = [select id,MovedToSage__c from invoice__c where Id=:invoiceId limit 1];
            invMovedToSageUpd.MovedToSage__c=false;
            update invMovedToSageUpd;
            
            Payment__c payMovedToSageUpd = [select id,MovedToSage__c from Payment__c where Id=:paymentId limit 1];
            payMovedToSageUpd.MovedToSage__c=false;
            update payMovedToSageUpd;
        }
        
        If(CustomerId!=null && customerId.trim().length()>0){
            Account custToUpdate = new Account();
            List<Account> customers = [Select id,Name,AccountID_Customer__c,PersonEmail,MovedToSage__c,SageCustomerKey__c,Sage_Error_Message__c,Centre_Name__r.Organisation__r.Sage_Company__c from Account where Id=:CustomerId and MovedToSage__c=False and Parent__c=null limit 1];
            if(customers.size()>0){
                customers[0] = SageIntacctIntegrationUtility.createCustomer(null,customers[0]);
                
                custToUpdate.Id = customers[0].Id;
                custToUpdate.MovedToSage__c = customers[0].MovedToSage__c;
                custToUpdate.SageCustomerKey__c = customers[0].SageCustomerKey__c;
                custToUpdate.Sage_Error_Message__c = customers[0].Sage_Error_Message__c;
                
            }
            
            
            if(invoiceId!=null && invoiceId.trim().length()>0){
                List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Id=:invoiceId and MovedToSage__c=False limit 1];
                if(invList.size()>0){
                    Invoice__c invoice = SageIntacctIntegrationUtility.createInvoice(null,invList[0]);
                    invList[0].MovedToSage__c = invoice.MovedToSage__c;
                    invList[0].SageOrderEntryKey__c = invoice.SageOrderEntryKey__c;
                    invList[0].Sage_Error_Message__c = invoice.Sage_Error_Message__c;
                    system.debug('invList===='+invList);
                    update invList[0];
                }
                
                If(Test.isRunningTest()){
                    Payment__c payMovedToSageUpd = [select id,MovedToSage__c from Payment__c where Id=:paymentId limit 1];
                    payMovedToSageUpd.MovedToSage__c=false;
                    update payMovedToSageUpd;
                }
            }
            if(customers.size()>0){
                update custToUpdate;
            }
        }*/
    }
    
    @future(Callout=true)
    Public static void packageUpgrade(string invoiceId,string paymentId){
        /*List<Invoice__c> invList;
        
        If(Test.isRunningTest()){
            invList = [select id,MovedToSage__c from invoice__c  where Id=:invoiceId limit 1];
            invList[0].MovedToSage__c=false;
            update invList;
            
            Payment__c payMovedToSageUpd = [select id,MovedToSage__c from Payment__c where Id=:paymentId limit 1];
            payMovedToSageUpd.MovedToSage__c=false;
            update payMovedToSageUpd;
        }
        if(invoiceId!=null && invoiceId.trim().length()>0){
            invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Id=:invoiceId and MovedToSage__c=False limit 1];
            if(invList.size()>0){
                Invoice__c invoice = SageIntacctIntegrationUtility.createInvoice(null,invList[0]);
                invList[0].MovedToSage__c = invoice.MovedToSage__c;
                invList[0].SageOrderEntryKey__c = invoice.SageOrderEntryKey__c;
                invList[0].Sage_Error_Message__c = invoice.Sage_Error_Message__c;
                update invList[0];
            }
        }*/
    }
    
    @future(Callout=true)
    Public static void changeEnrolment(string invoiceId){
        /*If(Test.isRunningTest()){
            Invoice__c invMovedToSageUpd = [select id,MovedToSage__c from invoice__c where Id=:invoiceId limit 1];
            invMovedToSageUpd.MovedToSage__c=false;
            update invMovedToSageUpd;
        }
        
        if(invoiceId!=null && invoiceId.trim().length()>0){
            List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Id=:invoiceId and MovedToSage__c=False limit 1];
            if(invList.size()>0){
                Invoice__c invoice = SageIntacctIntegrationUtility.createInvoice(null,invList[0]);
                invList[0].MovedToSage__c = invoice.MovedToSage__c;
                invList[0].SageOrderEntryKey__c = invoice.SageOrderEntryKey__c;
                invList[0].Sage_Error_Message__c = invoice.Sage_Error_Message__c;
                update invList[0];
            }
        }*/
    }
    
    @future(Callout=true)
    Public static void existingCustomerPrepayment(string invoiceId,string paymentId){
        /*If(Test.isRunningTest()){
            Invoice__c invMovedToSageUpd = [select id,MovedToSage__c from invoice__c where Id=:invoiceId limit 1];
            invMovedToSageUpd.MovedToSage__c=false;
            update invMovedToSageUpd;
            
            Payment__c payMovedToSageUpd = [select id,MovedToSage__c from Payment__c where Id=:paymentId limit 1];
            payMovedToSageUpd.MovedToSage__c=false;
            update payMovedToSageUpd;
            
            
        }
        
        
        List<Invoice__c> invList = new List<Invoice__c>();
        if(invoiceId!=null && invoiceId.trim().length()>0){
            invList = [Select Id,Name,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Id=:invoiceId and MovedToSage__c=False limit 1];
            if(invList.size()>0){
                Invoice__c invoice = SageIntacctIntegrationUtility.createInvoice(null,invList[0]);
                invList[0].MovedToSage__c = invoice.MovedToSage__c;
                invList[0].SageOrderEntryKey__c = invoice.SageOrderEntryKey__c;
                invList[0].Sage_Error_Message__c = invoice.Sage_Error_Message__c;
                update invList[0];  
            }
        }*/
    }
    
    @future(Callout=true)
    Public static void voidInvoice(string invoiceId){
        /*If(invoiceId!=null && invoiceId.trim().length()>0){
            SageIntacctIntegrationUtility.sessionWrapper sw = null;
            SageIntacctIntegrationUtility.invoiceVoid(sw,invoiceId, true);
        }*/
    }
    
    public static Invoice__c invoiceVoid(SessionWrapper sw, string invoiceId, Boolean isUpdateInvoice){
        Invoice__c invToUpdate = new Invoice__c();
        invToUpdate.Id = invoiceId;
        /*If(invoiceId!=null && invoiceId.trim().length()>0){
            List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Total_Amount__c,Voided_on_Sage__c,
                                                Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,
                                                center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,SageCreditMemoOrderEntryKey__c,Invoice_Void_Date__c,
                                                (Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,
                                                 Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) 
                                        from Invoice__c where Id=:invoiceId and Voided_on_Sage__c=false limit 1];
            if(invList.size() > 0){
                Invoice__c invoice = invList.get(0);
                invToUpdate.Id = invoice.Id;
                
                if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                    sw = SageIntacctIntegrationUtility.getuserSessionID(invoice.center__r.Organisation__r.Sage_Company__c);
                }
                
                if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                    resultWrapper rw = new resultWrapper();
                    if(invoice.SageCreditMemoOrderEntryKey__c!=null){
                        rw.isSuccess = true;
                        rw.sageRecordKey = invoice.SageCreditMemoOrderEntryKey__c;
                    }else{
                        if(invoice.Invoice_Void_Date__c!=null){
                            rw = SageIntacctIntegrationUtility.createCreditMemoForVoidInvoice(sw, invoice);
                        }else{
                            invoice.Sage_Error_Message__c = 'Invoice void date is missing.';
                        }
                    }
                    if(rw.isSuccess){
                        invoice.SageCreditMemoOrderEntryKey__c = rw.sageRecordKey;
                        
                        resultWrapper fetchArOfCreditMemo = SageIntacctIntegrationUtility.fetchARInvoiceKey(sw, invoice.SageCreditMemoOrderEntryKey__c);
                        if(fetchArOfCreditMemo.isSuccess){
                            String creditMemoOrderKey = fetchArOfCreditMemo.sageRecordKey;
                            
                            resultWrapper applyCreditRW = SageIntacctIntegrationUtility.applyCreditToInvoice(sw, invoice, creditMemoOrderKey);
                            if(applyCreditRW.isSuccess){
                                invoice.Voided_on_Sage__c = true;
                                invoice.Sage_Error_Message__c = '';
                            }else{
                                invoice.Sage_Error_Message__c = applyCreditRW.errorMsg;
                            }
                        }else{
                            invoice.Sage_Error_Message__c = fetchArOfCreditMemo.errorMsg;
                        }
                    }else{
                        invoice.Sage_Error_Message__c = rw.errorMsg;
                    }
                    
                   // invToUpdate.Id = invoice.Id;
                    invToUpdate.SageCreditMemoOrderEntryKey__c = invoice.SageCreditMemoOrderEntryKey__c;
                    invToUpdate.Voided_on_Sage__c = invoice.Voided_on_Sage__c;
                    invToUpdate.Sage_Error_Message__c = invoice.Sage_Error_Message__c;
                    if(isUpdateInvoice)
                        update invToUpdate;
                }
            }
        }*/
        return invToUpdate;
    }    
    
    @future(Callout=true)
    Public static void refundPayment(string paymentId){
        /*If(Test.isRunningTest()){
            Payment__c payMovedToSageUpd = [select id,MovedToSage__c from Payment__c where Id=:paymentId limit 1];
            payMovedToSageUpd.MovedToSage__c=false;
            update payMovedToSageUpd;
        }
        
        if(paymentId!=null && paymentId.trim().length()>0){
            List<Payment__c> payments = [Select Id,Name,Payment_Date__c,Parent_Account__c,Parent_Account__r.Name,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.SageCustomerKey__c,Payment_Amount__c,Invoice__c,Invoice__r.Name,Invoice__r.Total_Amount__c,Invoice__r.SageInvoiceKey__c,MovedToSage__c,Sage_Error_Message__c,SagePaymentKey__c,Method_of_Payment__c,Parent_Payment__c,Parent_Payment__r.Payment_Amount__c,Parent_Payment__r.SagePaymentKey__c,Remarks__c,Invoice__r.Center__r.Organisation__r.Sage_Company__c,Parent_Account__r.Centre_Name__r.Name,Parent_Account__r.Centre_Name__r.Organisation__r.Sage_Company__c,Refund_Id__c,Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c,Parent_Account__r.Centre_Name__r.Organisation__r.Country__r.Currency_Code_PI__c,recordType.Name from Payment__c where Id=:paymentId and MovedToSage__c=false and Payment_Amount__c<0 limit 1];
            if(payments.size()>0){
                Payment__c payment = new Payment__c();
                if(payments[0].Parent_Payment__r.SagePaymentKey__c!=null && ((payments[0].Parent_Payment__r.Payment_Amount__c+payments[0].Payment_Amount__c)==0)){
                    payment = SageIntacctIntegrationUtility.reversePayment(null,payments[0]);    
                }else{
                    payment = SageIntacctIntegrationUtility.createAdjustmentJournalEntries(null,payments[0]);
                }
                payments[0].MovedToSage__c = payment.MovedToSage__c;
                payments[0].SagePaymentKey__c = payment.SagePaymentKey__c;
                payments[0].Sage_Error_Message__c = payment.Sage_Error_Message__c;
                update payments[0];
            }
        }*/
    }
    
    @future(Callout=true)
    Public static void paynowInvoice(string paymentId){
        /*If(Test.isRunningTest()){
            Payment__c payMovedToSageUpd = [select id,MovedToSage__c from Payment__c where Id=:paymentId limit 1];
            payMovedToSageUpd.MovedToSage__c=false;
            update payMovedToSageUpd;
        }
        
        if(paymentId!=null && paymentId.trim().length()>0){
            List<Payment__c> payments = [Select Id,Payment_Date__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Payment_Amount__c,Invoice__c,Invoice__r.Name,Invoice__r.Total_Amount__c,Invoice__r.SageInvoiceKey__c,MovedToSage__c,Sage_Error_Message__c,SagePaymentKey__c,Method_of_Payment__c,Invoice__r.Center__r.Organisation__r.Sage_Company__c,recordType.Name,Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c from Payment__c where Id=:paymentId and MovedToSage__c=false limit 1];
            if(payments.size()>0){
                Payment__c payment = SageIntacctIntegrationUtility.createPayment(null,payments[0],'');
                payments[0].MovedToSage__c = payment.MovedToSage__c;
                payments[0].SagePaymentKey__c = payment.SagePaymentKey__c;
                payments[0].Sage_Error_Message__c = payment.Sage_Error_Message__c;
                update payments[0];
            }
        }*/
    }
    
    Public static void americanClubInvoice(string invoiceId){
        /*if(invoiceId!=null && invoiceId.trim().length()>0){
            List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c, Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Id=:invoiceId and MovedToSage__c=False limit 1];
            if(invList.size()>0){
                Invoice__c invoice = SageIntacctIntegrationUtility.createInvoice(null,invList[0]);
                invList[0].MovedToSage__c = invoice.MovedToSage__c;
                invList[0].SageOrderEntryKey__c = invoice.SageOrderEntryKey__c;
                invList[0].Sage_Error_Message__c = invoice.Sage_Error_Message__c;
                update invList[0];
            }
        }*/
    }
    
    @future(Callout=true)
    Public static void adhocInvoice(string invoiceId){
        /*List<Invoice__c> invList = new List<Invoice__c>();
        if(invoiceId!=null && invoiceId.trim().length()>0){
            invList = [Select Id,Name,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,(Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c from Invoice_Line_Items__r) from Invoice__c where Id=:invoiceId and MovedToSage__c=False limit 1];
            if(invList.size()>0){
                Invoice__c invoice = SageIntacctIntegrationUtility.createInvoice(null,invList[0]);
                invList[0].MovedToSage__c = invoice.MovedToSage__c;
                invList[0].SageOrderEntryKey__c = invoice.SageOrderEntryKey__c;
                invList[0].Sage_Error_Message__c = invoice.Sage_Error_Message__c;
                update invList[0];
            }
        }*/
    }
    
    Public class sessionWrapper{
        Public string senderId{get;set;}
        Public string senderPassword{get;set;}
        Public string endPointUrl{get;set;}
        Public string sessionId{get;set;}
        Public string errorMsg{get;set;}
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
    
    Public class revenueRecogWrapper{
        /*public string glCode{get;set;}
        public string locationId{get;set;}
        public string projectId{get;set;}
        public string classId{get;set;}
        public decimal amount{get;set;}
        public decimal gstAmount{get;set;}
        public decimal discountAmount{get;set;}
        public decimal discountGstAmount{get;set;}
        public date fromDate{get;set;}
        public date toDate{get;set;}
        public string revenueTemplate{get;set;}*/
    }
    
    Public class exchangeRateWrapper{
        public decimal exchangeRate{get;set;}
        public string targetCurrency{get;set;}
    }
    
    Public static revRecWrapper getRevRecognitionSchedule(SessionWrapper sw, string orderEntryKey){
        revRecWrapper rrw = new revRecWrapper();
        /*If(orderEntryKey!=null && orderEntryKey.trim().length()>0){
            
            if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(sw.endPointUrl);
                req.setHeader('Content-Type','application/xml');
                
                string timestamp = String.valueof(DateTime.now().getTime());
                
                string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                body += '<senderid>'+sw.senderId+'</senderid>';
                body += '<password>'+sw.senderPassword+'</password>';
                body += '<controlid>'+timestamp+'</controlid>';
                body += '<uniqueid>false</uniqueid>';
                body += '<dtdversion>3.0</dtdversion>';
                body += '<includewhitespace>false</includewhitespace>';
                body += '</control>';
                body += '<operation>';
                body += '<authentication>';
                body += '<sessionid>'+sw.sessionId+'</sessionid>';
                body += '</authentication>';
                body += '<content>';
                body += '<function controlid="'+timestamp+'">';
                body += '<readByQuery>';
                body += '<object>REVRECSCHEDULE</object>';
                body += '<fields>RECORDNO</fields>';
                body += '<query>DOCID = \''+orderEntryKey+'\'</query>';
                body += '<returnFormat>xml</returnFormat>';
                body += '<pagesize>100</pagesize>';
                body += '</readByQuery>';
                body += '</function></content></operation></request>';
                
                system.debug('Body===='+body);
                
                req.setBody(body);
                req.setTimeout(120000);
                
                string response;
                If(!Test.isRunningTest()){
                    Http http = new Http();
                    HTTPResponse res = http.send(req);
                    
                    response = res.getBody();
                }else{
                    response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>ControlIdHere</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>intacct</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-09-05T11:57:09-07:00</sessiontimestamp><sessiontimeout>2019-09-05T13:01:47-07:00</sessiontimeout></authentication><result><status>success</status><function>readByQuery</function><controlid>testControlId</controlid><data listtype="revrecschedule" count="2" totalcount="2" numremaining="0" resultId=""><revrecschedule><RECORDNO>73</RECORDNO></revrecschedule><revrecschedule><RECORDNO>74</RECORDNO></revrecschedule></data></result></operation></response>';
                }
                
                system.debug('response==='+response);
                
                If(response!=null && response.trim().length()>0){
                    DOM.Document doc = new DOM.Document();
                    doc.load(response);
                    DOM.XMLNode root = doc.getRootElement();
                    
                    for(DOM.XMLNode child : root.getChildElements()){
                        if(child.getName()=='operation'){
                            for(DOM.XMLNode child1 : child.getChildElements()){
                                if(child1.getName()=='result'){
                                    Boolean isSuccess = false;
                                    for(DOM.XMLNode child2 : child1.getChildElements()){
                                        if(child2.getName()=='status'){
                                            if(child2.getText()=='success'){
                                                isSuccess = true;
                                            }
                                        }
                                        
                                        if(isSuccess && child2.getName()=='data'){
                                            for(DOM.XMLNode child3 : child2.getChildElements()){
                                                if(child3.getName()=='revrecschedule'){
                                                    for(DOM.XMLNode child4 : child3.getChildElements()){
                                                        if(child4.getName()=='RECORDNO'){
                                                            rrw.revRecList.add(child4.getText());
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
                                                            rrw.errorMsg = child4.getText();
                                                            break;
                                                        }
                                                    }
                                                    if(rrw.errorMsg!=null && rrw.errorMsg.trim().length()>0){
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
                                            rrw.errorMsg = child2.getText();
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }*/
        return rrw;
    }
    
    Public static RevRecEntryWrapper getRevRecognitionEntries(SessionWrapper sw, Set<string> revRecSet){
        RevRecEntryWrapper rrw = new RevRecEntryWrapper();
        /*If(revRecSet!=null && revRecSet.size()>0){
            string revRecKeys = '(';
            for(string str:revRecSet){
                revRecKeys += str+',';
            }
            If(revRecKeys.endsWith(',')){
                revRecKeys = revRecKeys.substring(0,revRecKeys.length()-1);
            }
            revRecKeys += ')';
            
            if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(sw.endPointUrl);
                req.setHeader('Content-Type','application/xml');
                
                string timestamp = String.valueof(DateTime.now().getTime());
                
                string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                body += '<senderid>'+sw.senderId+'</senderid>';
                body += '<password>'+sw.senderPassword+'</password>';
                body += '<controlid>'+timestamp+'</controlid>';
                body += '<uniqueid>false</uniqueid>';
                body += '<dtdversion>3.0</dtdversion>';
                body += '<includewhitespace>false</includewhitespace>';
                body += '</control>';
                body += '<operation>';
                body += '<authentication>';
                body += '<sessionid>'+sw.sessionId+'</sessionid>';
                body += '</authentication>';
                body += '<content>';
                body += '<function controlid="'+timestamp+'">';
                body += '<readByQuery>';
                body += '<object>REVRECSCHEDULEENTRY</object>';
                body += '<fields>RECORDNO,AMOUNT,POSTINGDATE,ACCOUNTNO,REVRECSCHEDULEKEY</fields>';
                body += '<query>REVRECSCHEDULEKEY in '+revRecKeys+'</query>';
                body += '<returnFormat>xml</returnFormat>';
                body += '<pagesize>100</pagesize>';
                body += '</readByQuery>';
                body += '</function></content></operation></request>';
                
                system.debug('Body===='+body);
                
                req.setBody(body);
                req.setTimeout(120000);
                
                string response;
                If(!Test.isRunningTest()){
                    Http http = new Http();
                    HTTPResponse res = http.send(req);
                    
                    response = res.getBody();
                }else{
                    response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Intacct_ISB</senderid><controlid>ControlIdHere</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>intacct</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-09-05T11:57:09-07:00</sessiontimestamp><sessiontimeout>2019-09-05T13:04:24-07:00</sessiontimeout></authentication><result><status>success</status><function>readByQuery</function><controlid>testControlId</controlid><data listtype="revrecscheduleentry" count="3" totalcount="3" numremaining="0" resultId=""><revrecscheduleentry><RECORDNO>656</RECORDNO><AMOUNT>199.08</AMOUNT><POSTINGDATE>10/01/2019</POSTINGDATE><ACCOUNTNO>2551</ACCOUNTNO></revrecscheduleentry><revrecscheduleentry><RECORDNO>657</RECORDNO><AMOUNT>199.07</AMOUNT><POSTINGDATE>11/01/2019</POSTINGDATE><ACCOUNTNO>2551</ACCOUNTNO></revrecscheduleentry><revrecscheduleentry><RECORDNO>658</RECORDNO><AMOUNT>199.07</AMOUNT><POSTINGDATE>12/01/2019</POSTINGDATE><ACCOUNTNO>2551</ACCOUNTNO></revrecscheduleentry></data></result></operation></response>';
                }
                
                system.debug('response===='+response);
                
                If(response!=null && response.trim().length()>0){
                    DOM.Document doc = new DOM.Document();
                    doc.load(response);
                    DOM.XMLNode root = doc.getRootElement();
                    
                    for(DOM.XMLNode child : root.getChildElements()){
                        if(child.getName()=='operation'){
                            for(DOM.XMLNode child1 : child.getChildElements()){
                                if(child1.getName()=='result'){
                                    Boolean isSuccess = false;
                                    for(DOM.XMLNode child2 : child1.getChildElements()){
                                        if(child2.getName()=='status'){
                                            if(child2.getText()=='success'){
                                                isSuccess = true;
                                            }
                                        }
                                        
                                        if(isSuccess && child2.getName()=='data'){
                                            for(DOM.XMLNode child3 : child2.getChildElements()){
                                                if(child3.getName()=='revrecscheduleentry'){
                                                    revRecEntry rre = new revRecEntry();
                                                    for(DOM.XMLNode child4 : child3.getChildElements()){
                                                        if(child4.getName()=='RECORDNO'){
                                                            rre.recordNo = child4.getText();
                                                        }
                                                        if(child4.getName()=='AMOUNT'){
                                                            rre.amount = decimal.valueOf(child4.getText());
                                                        }
                                                        if(child4.getName()=='POSTINGDATE'){
                                                            List<string> tempList = child4.getText().split('/'); 
                                                            //rre.postingDate = Date.parse(child4.getText());
                                                            rre.postingDate = Date.newInstance(Integer.valueOf(tempList[2]),Integer.valueOf(tempList[0]),Integer.valueOf(tempList[1]));
                                                        }
                                                        if(child4.getName()=='ACCOUNTNO'){
                                                            rre.accountNo = child4.getText();
                                                        }
                                                        if(child4.getName()=='REVRECSCHEDULEKEY'){
                                                            rre.revAccKey = child4.getText();
                                                        }
                                                    }
                                                    if(rre.amount!=null){
                                                        List<revRecEntry> tempList = new List<revRecEntry>();
                                                        if(rrw.revRecEntryListMap.containsKey(rre.revAccKey)){
                                                            tempList.addAll(rrw.revRecEntryListMap.get(rre.revAccKey));
                                                        }
                                                        tempList.add(rre);
                                                        rrw.revRecEntryListMap.put(rre.revAccKey,tempList);
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if(child2.getName()=='errormessage'){
                                            for(DOM.XMLNode child3 : child2.getChildElements()){
                                                if(child3.getName()=='error'){
                                                    for(DOM.XMLNode child4 : child3.getChildElements()){
                                                        if(child4.getName()=='description2'){
                                                            rrw.errorMsg = child4.getText();
                                                            break;
                                                        }
                                                    }
                                                    if(rrw.errorMsg!=null && rrw.errorMsg.trim().length()>0){
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
                                            rrw.errorMsg = child2.getText();
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }*/
        return rrw;
    }
    
    Public static void updateRevRecEntries(SessionWrapper sw, Map<string,string> updRevRecEntryMap, Map<string,string> newRevRecEntryMap){
        /*HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(sw.endPointUrl);
        req.setHeader('Content-Type','application/xml');
        
        string timestamp = String.valueof(DateTime.now().getTime());
        
        string revEntryBody = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
        revEntryBody += '<senderid>'+sw.senderId+'</senderid>';
        revEntryBody += '<password>'+sw.senderPassword+'</password>';
        revEntryBody += '<controlid>'+timestamp+'</controlid>';
        revEntryBody += '<uniqueid>false</uniqueid>';
        revEntryBody += '<dtdversion>3.0</dtdversion>';
        revEntryBody += '<includewhitespace>false</includewhitespace>';
        revEntryBody += '</control>';
        revEntryBody += '<operation>';
        revEntryBody += '<authentication>';
        revEntryBody += '<sessionid>'+sw.sessionId+'</sessionid>';
        revEntryBody += '</authentication>';
        revEntryBody += '<content>';
        
        for(string strRevRec: updRevRecEntryMap.keyset()){
            revEntryBody += '<function controlid="'+timestamp+'">';
            revEntryBody += '<update_revrecschedule>';
            revEntryBody += '<recordno>'+strRevRec+'</recordno>';
            revEntryBody += '<revrecentries>';
            revEntryBody += updRevRecEntryMap.get(strRevRec);
            
            If(newRevRecEntryMap.containsKey(strRevRec)){
                revEntryBody += newRevRecEntryMap.get(strRevRec);    
            }
            
            revEntryBody += '</revrecentries>';
            revEntryBody += '</update_revrecschedule>';
            revEntryBody += '</function>';
        }
        
        
        revEntryBody += '</content></operation></request>';
        
        system.debug('revEntryBody==='+revEntryBody);
        
        req.setBody(revEntryBody);
        req.setTimeout(120000);
        
        string response;
        If(!Test.isRunningTest()){
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            response = res.getBody();
        }else{
            response ='';
        }
        
        system.debug('response=='+response);
        */
    }
    
    public class revRecWrapper{
        public Set<string> revRecList{get;set;}
        public string errorMsg{get;set;}
        public revRecWrapper(){
            revRecList = new Set<string>();
        }
    }
    
    public class RevRecEntryWrapper{
        public Map<string, List<revRecEntry>> revRecEntryListMap{get;set;}
        public string errorMsg{get;set;}
        
        Public RevRecEntryWrapper(){
            revRecEntryListMap = new Map<string, List<revRecEntry>>();
        }
    }
    
    Public class revRecEntry{
        /*public string recordNo{get;set;}
        public decimal amount{get;set;}
        public date postingDate{get;set;}
        public string accountNo{get;set;}
        public string revAccKey{get;set;}*/
    }
    
    public static Stripe_Payout_Log__c createStripeJournalEntries(Stripe_Payout_Log__c stripePayLog,List<Payment__c> paymentList){//update GLCodes
        /*stripePayLog.Sage_Error_Message__c = '';
        Map<string,string> glCodeMap = new Map<string,string>();
        List<Sage_GL_Account__c> glList = [Select id,Name,GL_Account_No__c from Sage_GL_Account__c];
        for(Sage_GL_Account__c gl: glList){
            glCodeMap.put(gl.Name,gl.GL_Account_No__c);
        }
        
        If(glCodeMap.size()>0){
            SessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(stripePayLog.Organisation__r.Sage_Company__c);//Change
            
            if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(sw.endPointUrl);
                req.setHeader('Content-Type','application/xml');
                
                string timestamp = String.valueof(DateTime.now().getTime());
                
                string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                body += '<senderid>'+sw.senderId+'</senderid>';
                body += '<password>'+sw.senderPassword+'</password>';
                body += '<controlid>'+timestamp+'</controlid>';
                body += '<uniqueid>false</uniqueid>';
                body += '<dtdversion>3.0</dtdversion>';
                body += '<includewhitespace>false</includewhitespace>';
                body += '</control>';
                body += '<operation>';
                body += '<authentication>';
                body += '<sessionid>'+sw.sessionId+'</sessionid>';
                body += '</authentication>';
                body += '<content>';
                body += '<function controlid="'+timestamp+'">';
                
                body += '<create>';
                body += '<GLBATCH>';
                body += '<JOURNAL>CRJ</JOURNAL>';
                body += '<BATCH_DATE>'+(stripePayLog.Stripe_Payout_Date__c!=null?stripePayLog.Stripe_Payout_Date__c.format('MM/dd/yyyy'):system.now().format('MM/dd/yyyy'))+'</BATCH_DATE>';
                body += '<BATCH_TITLE>Stripe Payout - '+stripePayLog.Stripe_Payout_Id__c+'('+stripePayLog.Name+')'+'</BATCH_TITLE>';
                body += '<ENTRIES>';
                
                Decimal stripePaymentAmount = 0;
                Decimal stripeFeeCharged = 0;
                
                If(glCodeMap.containsKey('Merchandise Card Receivable') && paymentList!=null && paymentList.size()>0){
                    for(Payment__c pay: paymentList){
                        stripePaymentAmount += pay.Payment_Amount__c!=null?pay.Payment_Amount__c.setScale(2):0;
                        stripeFeeCharged +=  pay.Stripe_fees__c!=null?pay.Stripe_fees__c.setScale(2):0;
                        If(pay.Payment_Amount__c!=null){
                            if(pay.Payment_Amount__c<0){
                                body += '<GLENTRY>';
                                body += '<ACCOUNTNO>'+glCodeMap.get('Merchandise Card Receivable')+'</ACCOUNTNO>';
                                body += '<CURRENCY>'+stripePayLog.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                                body += '<TR_TYPE>1</TR_TYPE>';
                                body += '<AMOUNT>'+(-1*pay.Payment_Amount__c.setScale(2))+'</AMOUNT>';
                                body += '<EXCHANGE_RATE>1</EXCHANGE_RATE>';
                                body += '<DESCRIPTION>'+pay.Invoice__r.Name+'</DESCRIPTION>';
                                body += '</GLENTRY>';
                            }else{
                                body += '<GLENTRY>';
                                body += '<ACCOUNTNO>'+glCodeMap.get('Merchandise Card Receivable')+'</ACCOUNTNO>';
                                body += '<CURRENCY>'+stripePayLog.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                                body += '<TR_TYPE>-1</TR_TYPE>';
                                body += '<AMOUNT>'+pay.Payment_Amount__c.setScale(2)+'</AMOUNT>';
                                body += '<EXCHANGE_RATE>1</EXCHANGE_RATE>';
                                body += '<DESCRIPTION>'+pay.Invoice__r.Name+'</DESCRIPTION>';
                                body += '</GLENTRY>';
                            }
                        }
                    }
                }
                
                If(stripePayLog.Organisation__r.Sage_Company__c=='AGP' && glCodeMap.containsKey('AGP Cash at Bank - OCBC') && stripePaymentAmount!=null){
                    stripePaymentAmount = stripePaymentAmount + stripeFeeCharged;
                    //Bank debit entry
                    body += '<GLENTRY>';
                    body += '<ACCOUNTNO>'+glCodeMap.get('AGP Cash at Bank - OCBC')+'</ACCOUNTNO>';
                    body += '<CURRENCY>'+stripePayLog.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                    body += '<TR_TYPE>1</TR_TYPE>';
                    body += '<AMOUNT>'+stripePaymentAmount.setScale(2)+'</AMOUNT>';
                    body += '<EXCHANGE_RATE>1</EXCHANGE_RATE>';
                    body += '<DESCRIPTION>'+stripePayLog.Stripe_Payout_Id__c+'</DESCRIPTION>';
                    body += '</GLENTRY>';
                }else If(stripePayLog.Organisation__r.Sage_Company__c=='AGH' && glCodeMap.containsKey('AGH Cash at Bank-OCBC WH (Main account)') && stripePaymentAmount!=null){
                    stripePaymentAmount = stripePaymentAmount + stripeFeeCharged;
                    //Bank debit entry
                    body += '<GLENTRY>';
                    body += '<ACCOUNTNO>'+glCodeMap.get('AGH Cash at Bank-OCBC WH (Main account)')+'</ACCOUNTNO>';
                    body += '<CURRENCY>'+stripePayLog.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                    body += '<TR_TYPE>1</TR_TYPE>';
                    body += '<AMOUNT>'+stripePaymentAmount.setScale(2)+'</AMOUNT>';
                    body += '<EXCHANGE_RATE>1</EXCHANGE_RATE>';
                    body += '<DESCRIPTION>'+stripePayLog.Stripe_Payout_Id__c+'</DESCRIPTION>';
                    body += '</GLENTRY>';
                }
                
                If(glCodeMap.containsKey('Merchant Account Fees') && stripeFeeCharged!=null){
                    //Stripe fee entry
                    body += '<GLENTRY>';
                    body += '<ACCOUNTNO>'+glCodeMap.get('Merchant Account Fees')+'</ACCOUNTNO>';
                    body += '<CURRENCY>'+stripePayLog.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                    body += '<TR_TYPE>1</TR_TYPE>';
                    body += '<AMOUNT>'+(stripeFeeCharged<0?-1*stripeFeeCharged.setScale(2):stripeFeeCharged.setScale(2))+'</AMOUNT>';
                    body += '<EXCHANGE_RATE>1</EXCHANGE_RATE>';
                    body += '<DESCRIPTION>'+stripePayLog.Stripe_Payout_Id__c+'</DESCRIPTION>';
                    body += '</GLENTRY>';
                }
                
                body += '</ENTRIES></GLBATCH></create></function></content></operation></request>';
                
                req.setBody(body);
                req.setTimeout(120000);
                string response;
                If(!Test.isRunningTest()){
                    Http http = new Http();
                    HTTPResponse res = http.send(req);                    
                    response = res.getBody();
                }else{
                    response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1567082989116</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-10-16T05:00:12-07:00</sessiontimestamp><sessiontimeout>2019-10-16T11:00:12-07:00</sessiontimeout></authentication><result><status>success</status><function>create</function><controlid>1567082989116</controlid><data listtype="objects" count="1"><glbatch><RECORDNO>13760</RECORDNO></glbatch></data></result></operation></response>';
                }
                
                system.debug('Body==='+body);
                system.debug('response==='+response);
                
                DOM.Document doc = new DOM.Document();
                doc.load(response);
                DOM.XMLNode root = doc.getRootElement();
                Boolean isSuccess = false;
                for(DOM.XMLNode child : root.getChildElements()){
                    if(child.getName()=='operation'){
                        for(DOM.XMLNode child1 : child.getChildElements()){
                            if(child1.getName()=='result'){
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='status'){
                                        if(child2.getText()=='success'){
                                            isSuccess = true;
                                        }
                                    }
                                    
                                    if(isSuccess && child2.getName()=='data'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='glbatch'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='RECORDNO'){
                                                        stripePayLog.Status__c = 'Posted in Sage';
                                                        stripePayLog.SageJournalEntryKey__c = child4.getText();
                                                        break;
                                                    }
                                                }
                                            }
                                            if(stripePayLog.SageJournalEntryKey__c!=null && stripePayLog.SageJournalEntryKey__c.trim().length()>0){
                                                break;
                                            }                                       
                                        }
                                    }
                                    
                                    if(child2.getName()=='errormessage'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='error'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='description2'){
                                                        stripePayLog.Sage_Error_Message__c = child4.getText();
                                                        break;
                                                    }
                                                }
                                                if(stripePayLog.Sage_Error_Message__c!=null && stripePayLog.Sage_Error_Message__c.trim().length()>0){
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
                                        stripePayLog.Sage_Error_Message__c = child2.getText();
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }else If(sw.errorMsg!=null && sw.errorMsg.trim().length()>0){
                stripePayLog.Sage_Error_Message__c = sw.errorMsg;
            }else{
                stripePayLog.Sage_Error_Message__c = 'Unknown error occured. Please try again.';
            }
        }else{
            stripePayLog.Sage_Error_Message__c = 'GL code not found.';
        }*/
        return stripePayLog;
    }
    
    Public static Payment__c createAdjustmentJournalEntries(SessionWrapper sw, Payment__c payment){
        /*string departmentId = 'Aureus Academy';
        if(payment!=null && payment.Id!=null){
            If(payment.Payment_Date__c!=null){
                if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                    If(payment.Invoice__r.Center__r.Organisation__r.Sage_Company__c!=null){
                        sw = SageIntacctIntegrationUtility.getuserSessionID(payment.Invoice__r.Center__r.Organisation__r.Sage_Company__c);
                    }else{
                        sw = SageIntacctIntegrationUtility.getuserSessionID(payment.Parent_Account__r.Centre_Name__r.Organisation__r.Sage_Company__c);
                    }
                }
                if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                    Map<string,string> glCodeMap = new Map<string,string>();
                    List<Sage_GL_Account__c> glList = [Select id,Name,GL_Account_No__c from Sage_GL_Account__c];
                    for(Sage_GL_Account__c gl: glList){
                        glCodeMap.put(gl.Name,gl.GL_Account_No__c);
                    }
                    
                    If(glCodeMap.size()>0){
                        
                        HttpRequest req = new HttpRequest();
                        req.setMethod('POST');
                        req.setEndpoint(sw.endPointUrl);
                        req.setHeader('Content-Type','application/xml');
                        
                        string timestamp = String.valueof(DateTime.now().getTime());
                        
                        string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                        body += '<senderid>'+sw.senderId+'</senderid>';
                        body += '<password>'+sw.senderPassword+'</password>';
                        body += '<controlid>'+timestamp+'</controlid>';
                        body += '<uniqueid>false</uniqueid>';
                        body += '<dtdversion>3.0</dtdversion>';
                        body += '<includewhitespace>false</includewhitespace>';
                        body += '</control>';
                        body += '<operation>';
                        body += '<authentication>';
                        body += '<sessionid>'+sw.sessionId+'</sessionid>';
                        body += '</authentication>';
                        body += '<content>';
                        body += '<function controlid="'+timestamp+'">';
                        
                        body += '<create>';
                        body += '<GLBATCH>';
                        body += '<JOURNAL>ARJ</JOURNAL>';
                        
                        DateTime DT = DateTime.newInstance(payment.Payment_Date__c.year(), payment.Payment_Date__c.month(), payment.Payment_Date__c.day());
                        body += '<BATCH_DATE>'+DT.format('MM/dd/yyyy')+'</BATCH_DATE>';
                        body += '<BATCH_TITLE>Adjustment for '+(payment.invoice__r.Name!=null?payment.invoice__r.Name:payment.Parent_Account__r.Name)+'</BATCH_TITLE>';
                        body += '<ENTRIES>';
                        
                        body += '<GLENTRY>';
                        if(payment.recordType.Name=='Payment Transaction'){
                            body += '<ACCOUNTNO>'+glCodeMap.get('Accounts Receivable')+'</ACCOUNTNO>';
                        }else{
                            body += '<ACCOUNTNO>'+glCodeMap.get('Customer Deposits')+'</ACCOUNTNO>';
                        }
                        If(payment.Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c!=null){
                            body += '<CURRENCY>'+payment.Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                        }else{
                            body += '<CURRENCY>'+payment.Parent_Account__r.Centre_Name__r.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                        }
                        body += '<TR_TYPE>1</TR_TYPE>';
                        body += '<AMOUNT>'+(-1*payment.Payment_Amount__c.setScale(2))+'</AMOUNT>';
                        body += '<EXCHANGE_RATE>1</EXCHANGE_RATE>';
                        body += '<DESCRIPTION>'+payment.Name+'</DESCRIPTION>';
                        
                        If(payment.Parent_Account__r.Centre_Name__r.Name!=null){
                            body += '<LOCATION>'+payment.Parent_Account__r.Centre_Name__r.Name+'</LOCATION>';
                        }
                        body += '<DEPARTMENT>'+departmentId+'</DEPARTMENT>';
                        body += '<CUSTOMERID>'+payment.Parent_Account__r.AccountID_Customer__c+'</CUSTOMERID>'; 
                        
                        body += '</GLENTRY>';
                        
                        body += '<GLENTRY>';
                        body += '<ACCOUNTNO>'+glCodeMap.get('Merchandise Card Receivable')+'</ACCOUNTNO>';
                        If(payment.Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c!=null){
                            body += '<CURRENCY>'+payment.Invoice__r.Center__r.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                        }else{
                            body += '<CURRENCY>'+payment.Parent_Account__r.Centre_Name__r.Organisation__r.Country__r.Currency_Code_PI__c+'</CURRENCY>';
                        }
                        body += '<TR_TYPE>-1</TR_TYPE>';
                        body += '<AMOUNT>'+(-1*payment.Payment_Amount__c.setScale(2))+'</AMOUNT>';
                        body += '<EXCHANGE_RATE>1</EXCHANGE_RATE>';
                        body += '<DESCRIPTION>'+payment.Name+'</DESCRIPTION>';
                        If(payment.Parent_Account__r.Centre_Name__r.Name!=null){
                            body += '<LOCATION>'+payment.Parent_Account__r.Centre_Name__r.Name+'</LOCATION>';
                        }
                        body += '<DEPARTMENT>'+departmentId+'</DEPARTMENT>';
                        body += '<CUSTOMERID>'+payment.Parent_Account__r.AccountID_Customer__c+'</CUSTOMERID>';
                        body += '</GLENTRY>';
                        
                        body += '</ENTRIES>';
                        body += '</GLBATCH>';
                        body += '</create>';
                        
                        body += '</function></content></operation></request>';
                        
                        req.setBody(body);
                        req.setTimeout(120000);
                        string response;
                        If(!Test.isRunningTest()){
                            Http http = new Http();
                            HTTPResponse res = http.send(req);                    
                            response = res.getBody();
                        }else{
                            response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1567082989116</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-10-16T05:00:12-07:00</sessiontimestamp><sessiontimeout>2019-10-16T11:00:12-07:00</sessiontimeout></authentication><result><status>success</status><function>create</function><controlid>1567082989116</controlid><data listtype="objects" count="1"><glbatch><RECORDNO>13760</RECORDNO></glbatch></data></result></operation></response>';
                        }
                        
                        system.debug('Body==='+body);
                        system.debug('response==='+response);
                        
                        DOM.Document doc = new DOM.Document();
                        doc.load(response);
                        DOM.XMLNode root = doc.getRootElement();
                        Boolean isSuccess = false;
                        for(DOM.XMLNode child : root.getChildElements()){
                            if(child.getName()=='operation'){
                                for(DOM.XMLNode child1 : child.getChildElements()){
                                    if(child1.getName()=='result'){
                                        for(DOM.XMLNode child2 : child1.getChildElements()){
                                            if(child2.getName()=='status'){
                                                if(child2.getText()=='success'){
                                                    payment.MovedToSage__c = true;
                                                }
                                            }
                                            
                                            if(payment.MovedToSage__c && child2.getName()=='data'){
                                                for(DOM.XMLNode child3 : child2.getChildElements()){
                                                    if(child3.getName()=='glbatch'){
                                                        for(DOM.XMLNode child4 : child3.getChildElements()){
                                                            if(child4.getName()=='RECORDNO'){
                                                                payment.SagePaymentKey__c = child4.getText();
                                                                break;
                                                            }
                                                        }
                                                    }
                                                    if(payment.SagePaymentKey__c!=null && payment.SagePaymentKey__c.trim().length()>0){
                                                        break;
                                                    }
                                                }
                                            }
                                            
                                            if(child2.getName()=='errormessage'){
                                                for(DOM.XMLNode child3 : child2.getChildElements()){
                                                    if(child3.getName()=='error'){
                                                        for(DOM.XMLNode child4 : child3.getChildElements()){
                                                            if(child4.getName()=='description2'){
                                                                payment.MovedToSage__c = false;
                                                                payment.Sage_Error_Message__c = child4.getText();
                                                                break;
                                                            }
                                                        }
                                                    }
                                                    If(payment.Sage_Error_Message__c!=null && payment.Sage_Error_Message__c.trim().length()>0){
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
                                                payment.MovedToSage__c = false;
                                                payment.Sage_Error_Message__c = child2.getText();
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }else{
                        payment.Sage_Error_Message__c = 'GL account not found.';
                    }
                }else{
                    payment.Sage_Error_Message__c = sw.errorMsg;
                }
            }
        }else{
            payment.Sage_Error_Message__c = 'Payment date is blank.';
        }*/   
        return payment;
    }
    
    public static Invoice__c createInvoice(SessionWrapper sw, Invoice__c invoice){
        /*string departmentId = 'Aureus Academy'; 
        
        string body;
        string response;
        
        resultWrapper rw = new resultWrapper();
        
        Map<Id,revenueRecogWrapper> revrecWrapMap = new Map<Id,revenueRecogWrapper>();
        
        Map<string,List<Invoice_Line_Item__c>> enrToLineItemMap = new Map<string,List<Invoice_Line_Item__c>>();
        Map<string,decimal> enrToMaxAmountMap = new Map<string,decimal>();
        Map<string,decimal> enrToMaxDiscountAmountMap = new Map<string,decimal>();
        
        List<Sage_GL_Account__c> sageGlAccList = [Select id,Name,GL_Account_No__c from Sage_GL_Account__c];
        Map<string,string> glCodeMap = new Map<string,string>();
        if(sageGlAccList.size()>0){
            for(Sage_GL_Account__c sga:sageGlAccList){
                glCodeMap.put(sga.Name,sga.GL_Account_No__c);
            }
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
                        
                        body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                        body += '<senderid>'+sw.senderId+'</senderid>';
                        body += '<password>'+sw.senderPassword+'</password>';
                        body += '<controlid>'+timestamp+'</controlid>';
                        body += '<uniqueid>true</uniqueid>';
                        body += '<dtdversion>3.0</dtdversion>';
                        body += '<includewhitespace>false</includewhitespace>';
                        body += '</control>';
                        body += '<operation>';
                        body += '<authentication>';
                        body += '<sessionid>'+sw.sessionId+'</sessionid>';
                        body += '</authentication>';
                        body += '<content>';
                        body += '<function controlid="Activation-'+invoice.Name+'">';
                        
                        body += '<create_sotransaction>';
                        body += '<transactiontype>Activation</transactiontype>';
                        body += '<datecreated><year>'+invoice.Invoice_Date__c.Year()+'</year><month>'+invoice.Invoice_Date__c.Month()+'</month><day>'+invoice.Invoice_Date__c.Day()+'</day></datecreated>';
                        body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                        body += '<documentno>'+invoice.Name+'</documentno>';
                        body += '<referenceno>'+invoice.Internal_Ref_No__c+'</referenceno>';
                        if(invoice.Due_Date__c!=null){    
                            body += '<datedue><year>'+invoice.Due_Date__c.Year()+'</year><month>'+invoice.Due_Date__c.Month()+'</month><day>'+invoice.Due_Date__c.Day()+'</day></datedue>';
                        }
                        
                        if(invoice.Invoice_Line_Items__r.size()>0){
                            body += '<sotransitems>';
                            
                            for(Invoice_Line_Item__c invLineItem:invoice.Invoice_Line_Items__r){
                                if(invLineItem.Remarks__c!='Registration Fees' && !invLineItem.Is_Deposit__c && (invLineItem.Package__r.Type_of_package__c=='Promo' || invLineItem.Package__r.Type_of_package__c=='Prepayment')){
                                    revenueRecogWrapper rwrap = new revenueRecogWrapper();
                                    rwrap.amount = 0;
                                    rwrap.discountAmount = 0;
                                    rwrap.gstAmount = 0;
                                    
                                    if(revrecWrapMap.containsKey(invLineItem.Enrolment__c)){
                                        rwrap = revrecWrapMap.get(invLineItem.Enrolment__c);
                                    }
                                    
                                    List<Invoice_Line_Item__c> tempList = new List<Invoice_Line_Item__c>();
                                    If(enrToLineItemMap.containsKey(invLineItem.Enrolment__c)){
                                        tempList.addAll(enrToLineItemMap.get(invLineItem.Enrolment__c));
                                    }
                                    tempList.add(invLineItem);
                                    enrToLineItemMap.put(invLineItem.Enrolment__c,tempList);
                                    
                                    decimal tempAmount = 0;
                                    if(enrToMaxAmountMap.containsKey(invLineItem.Enrolment__c)){
                                        tempAmount = enrToMaxAmountMap.get(invLineItem.Enrolment__c);
                                    }
                                    
                                    if(invLineItem.Amount__c > tempAmount){
                                        tempAmount = invLineItem.Amount__c;
                                    }
                                    If(tempAmount>0){
                                        enrToMaxAmountMap.put(invLineItem.Enrolment__c,tempAmount);
                                    }
                                    
                                    decimal tempDiscountAmount = 0;
                                    if(enrToMaxDiscountAmountMap.containsKey(invLineItem.Enrolment__c)){
                                        tempDiscountAmount = enrToMaxDiscountAmountMap.get(invLineItem.Enrolment__c);
                                    }
                                    
                                    if(invLineItem.Discount_Amount__c > tempDiscountAmount){
                                        tempDiscountAmount = invLineItem.Discount_Amount__c;
                                    }
                                    If(tempDiscountAmount>0){
                                        enrToMaxDiscountAmountMap.put(invLineItem.Enrolment__c,tempDiscountAmount);
                                    }
                                    
                                    if(rwrap.glCode==null){
                                        if(invLineItem.Package__r.Type__c=='Individual' || invLineItem.Package__r.Type__c=='Home' || invLineItem.Package__r.Type__c=='Adhoc' || invLineItem.Package__r.Type__c=='American Club'){
                                            rwrap.glCode = 'Individual Lessons';                                    
                                        }else if(invLineItem.Package__r.Type__c=='Group'){
                                            rwrap.glCode = 'Group Lessons';
                                        }else if(invLineItem.Package__r.Type__c=='Camp'){
                                            rwrap.glCode = 'Camp &amp; Event Revenue';
                                        }
                                    }
                                    
                                    if(rwrap.locationId==null && invLineItem.Package__r.Location__r.Name!=null){
                                        rwrap.locationId = invLineItem.Package__r.Location__r.Name;
                                    }
                                    
                                    if(rwrap.projectId==null && invLineItem.Package__r.Program__r.Name!=null){
                                        rwrap.projectId = invLineItem.Package__r.Program__r.Name;
                                    }
                                    
                                    if(rwrap.classId==null && invLineItem.Package__r.Duration__c!=null){
                                        rwrap.classId = invLineItem.Package__r.Duration__c;
                                    }
                                    
                                    if(invLineItem.Amount__c!=null){
                                        if(rwrap.amount!=null){
                                            rwrap.amount += invLineItem.Amount__c;
                                        }else{
                                            rwrap.amount = invLineItem.Amount__c;
                                        }
                                    }else{
                                        rwrap.amount = 0;
                                    }
                                    
                                    if(invLineItem.Discount_Amount__c>0){
                                        if(rwrap.discountAmount>0){
                                            rwrap.discountAmount += invLineItem.Discount_Amount__c;
                                        }else{
                                            rwrap.discountAmount = invLineItem.Discount_Amount__c;
                                        }
                                    }else{
                                        rwrap.discountAmount = 0;
                                    }
                                    
                                    if(invLineItem.Gst_Amount__c!=null && invLineItem.Gst_Amount__c!=0){
                                        rwrap.gstAmount += invLineItem.Gst_Amount__c;
                                    }else{
                                        rwrap.gstAmount = 0;
                                    }
                                    
                                    if(rwrap.fromDate!=null){
                                        if(rwrap.fromDate>invLineItem.Month__c){
                                            rwrap.fromDate = invLineItem.Month__c;
                                        }
                                    }else{
                                        rwrap.fromDate = invLineItem.Month__c;
                                    }
                                    if(rwrap.toDate!=null){
                                        if(rwrap.toDate<invLineItem.month__c){
                                            rwrap.toDate = invLineItem.Month__c;
                                        }
                                    }else{
                                        rwrap.toDate = invLineItem.Month__c;
                                    }
                                    
                                    If(rwrap.revenueTemplate==null){
                                        rwrap.revenueTemplate = invLineItem.Package__r.Sage_Revenue_Template__c;
                                    }
                                    
                                    revrecWrapMap.put(invLineItem.Enrolment__c,rwrap);
                                    
                                    continue;
                                }
                                body += '<sotransitem>';
                                if(invLineItem.Is_Deposit__c){
                                    body += '<itemid>Customer Deposit</itemid>';
                                }else{
                                    if(invLineItem.Remarks__c=='Registration Fees'){
                                        body += '<itemid>Registration Fees</itemid>';
                                    }else if(invLineItem.Remarks__c!=null && invLineItem.Remarks__c.contains('Studio')){
                                        body += '<itemid>Studio Rental</itemid>';
                                    }else if(invLineItem.Remarks__c!=null && invLineItem.Remarks__c.contains('Referral')){
                                            body += '<itemid>Discount Given</itemid>';
                                    }else if(invLineItem.Remarks__c=='Credit Note Adjustment'){
                                            body += '<itemid>Credit Note</itemid>';
                                    }else if(invLineItem.Remarks__c=='Rounding Adjustment'){
                                            body += '<itemid>Other Income</itemid>';
                                    }else{
                                        if(invLineItem.Package__r.Type__c=='Individual' || invLineItem.Package__r.Type__c=='Home' || invLineItem.Package__r.Type__c=='Adhoc' || invLineItem.Package__r.Type__c=='American Club'){
                                            body += '<itemid>Individual Lessons</itemid>';
                                        }else if(invLineItem.Package__r.Type__c=='Group'){
                                                body += '<itemid>Group Lessons</itemid>';
                                        }else if(invLineItem.Package__r.Type__c=='Camp'){
                                                body += '<itemid>Camp &amp; Event Revenue</itemid>';
                                        }else if(invLineItem.GL_Code__c!=null){
                                            body += '<itemid>'+invLineItem.GL_Code__c+'</itemid>';
                                        }else{
                                            body += '<itemid>Retail Sales</itemid>';
                                        }
                                    }
                                }
                                body += '<quantity>1</quantity>';
                                body += '<unit>Each</unit>';
                                body += '<price>'+(invLineItem.Amount__c!=null?invLineItem.Amount__c:0)+'</price>';
                                if(invLineItem.Package__r.Location__r.Name!=null){
                                    body += '<locationid>'+invLineItem.Package__r.Location__r.Name+'</locationid>';
                                }else if(invoice.center__r.Name!=null){
                                    body += '<locationid>'+invoice.center__r.Name+'</locationid>';
                                }else If(invLineItem.POS_Item_Type__c!=null && invLineItem.POS_Item_Type__c.contains('Camp')){
                                    body += '<locationid>'+invLineItem.POS_Item_Type__c+'</locationid>';
                                }
                                
                                body += '<departmentid>'+departmentId+'</departmentid>';
                                
                                If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                    If(!invLineItem.Is_Deposit__c){
                                        decimal gstAmt = invLineItem.GST_Amount__c!=null?invLineItem.GST_Amount__c.setScale(2):0;
                                        body += '<customfields>';
                                        body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
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
                                    }else{
                                        body += '<customfields>';
                                        body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageNoGSTCode+'</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
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
                                }
                                
                                If(!invLineItem.Is_Deposit__c && invLineItem.Month__c!=null && invLineItem.Package__r.Sage_Revenue_Template__c!=null && invLineItem.Month__c>lastMonthDate){
                                    body += '<revrectemplate>'+invLineItem.Package__r.Sage_Revenue_Template__c+'</revrectemplate>';
                                    body += '<revrecstartdate><year>'+invLineItem.Month__c.year()+'</year><month>'+invLineItem.Month__c.month()+'</month><day>'+invLineItem.Month__c.day()+'</day></revrecstartdate>';
                                    body += '<revrecenddate><year>'+invLineItem.Month__c.year()+'</year><month>'+invLineItem.Month__c.month()+'</month><day>'+invLineItem.Month__c.day()+'</day></revrecenddate>'; 
                                }
                                
                                if(invLineItem.Package__r.Program__r.Name!=null){
                                    body += '<projectid>'+invLineItem.Package__r.Program__r.Name+'</projectid>';
                                }
                                body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                
                                if(invLineItem.Remarks__c==null || !invLineItem.Remarks__c.contains('Studio')){
                                    if(invLineItem.Package__r.Duration__c!=null){
                                        body += '<classid>'+invLineItem.Package__r.Duration__c+' Min</classid>';
                                    }
                                }
                                
                                body += '</sotransitem>';
                                
                                If(invLineItem.Discount_Amount__c>0){
                                    body += '<sotransitem>';
                                    
                                    body += '<itemid>Discount Given</itemid>';
                                    
                                    body += '<quantity>1</quantity>';
                                    body += '<unit>Each</unit>';
                                    body += '<price>'+(-invLineItem.Discount_Amount__c)+'</price>';
                                    if(invLineItem.Package__r.Location__r.Name!=null){
                                        body += '<locationid>'+invLineItem.Package__r.Location__r.Name+'</locationid>';
                                    }                        
                                    body += '<departmentid>'+departmentId+'</departmentid>';
                                    
                                    If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                        body += '<customfields>';
                                        body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
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
                                    
                                    If(invLineItem.Month__c!=null && invLineItem.Package__r.Sage_Revenue_Template__c!=null && invLineItem.Month__c>lastMonthDate){
                                        body += '<revrectemplate>'+invLineItem.Package__r.Sage_Revenue_Template__c+'</revrectemplate>';
                                        body += '<revrecstartdate><year>'+invLineItem.Month__c.year()+'</year><month>'+invLineItem.Month__c.month()+'</month><day>'+invLineItem.Month__c.day()+'</day></revrecstartdate>';
                                        body += '<revrecenddate><year>'+invLineItem.Month__c.year()+'</year><month>'+invLineItem.Month__c.month()+'</month><day>'+invLineItem.Month__c.day()+'</day></revrecenddate>'; 
                                    }
                                    
                                    if(invLineItem.Package__r.Program__r.Name!=null){
                                        body += '<projectid>'+invLineItem.Package__r.Program__r.Name+'</projectid>';
                                    }
                                    body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                    
                                    if(invLineItem.Remarks__c==null || !invLineItem.Remarks__c.contains('Studio')){
                                        if(invLineItem.Package__r.Duration__c!=null){
                                            body += '<classid>'+invLineItem.Package__r.Duration__c+' Min</classid>';
                                        }
                                    }
                                    body += '</sotransitem>';
                                }
                            }
                            
                            If(revrecWrapMap!=null && revrecWrapMap.size()>0){
                                for(Id eid:revrecWrapMap.keyset()){
                                    revenueRecogWrapper rWrap = new revenueRecogWrapper();
                                    rwrap = revrecWrapMap.get(eid);
                                    body += '<sotransitem>';
                                    body += '<itemid>'+rwrap.glcode+'</itemid>';
                                    body += '<quantity>1</quantity>';
                                    body += '<unit>Each</unit>';
                                    body += '<price>'+rwrap.amount+'</price>';
                                    
                                    if(rwrap.locationId!=null){
                                        body += '<locationid>'+rwrap.locationId+'</locationid>';
                                    }                        
                                    body += '<departmentid>'+departmentId+'</departmentid>';
                                    
                                    If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                        If(rwrap.gstAmount!=null && rwrap.gstAmount!=0){
                                            body += '<customfields>';
                                            body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>'+(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c/100)+'</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>'+rwrap.gstAmount.setScale(2)+'</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>'+rwrap.gstAmount.setScale(2)+'</customfieldvalue></customfield>';
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
                                        }else{
                                            body += '<customfields>';
                                            body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
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
                                    }
                                    
                                    system.debug('rwrap.revenueTemplate==='+rwrap.revenueTemplate);
                                    system.debug('rwrap.fromDate==='+rwrap.fromDate);
                                    system.debug('rwrap.toDate==='+rwrap.toDate);
                                    
                                    if(rwrap.fromDate!=null && rwrap.toDate!=null && rwrap.revenueTemplate!=null && rwrap.toDate>lastMonthDate){
                                        body += '<revrectemplate>'+rwrap.revenueTemplate+'</revrectemplate>';
                                        body += '<revrecstartdate><year>'+rwrap.fromDate.year()+'</year><month>'+rwrap.fromDate.month()+'</month><day>'+rwrap.fromDate.day()+'</day></revrecstartdate>';
                                        body += '<revrecenddate><year>'+rwrap.toDate.year()+'</year><month>'+rwrap.toDate.month()+'</month><day>'+rwrap.toDate.day()+'</day></revrecenddate>';                                         
                                    }
                                    
                                    if(rwrap.projectId!=null){
                                        body += '<projectid>'+rwrap.projectId+'</projectid>';
                                    }
                                    body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                    
                                    if(rwrap.classId!=null){
                                        body += '<classid>'+rwrap.classId+' Min</classid>';
                                    }
                                    
                                    body += '</sotransitem>';
                                    
                                    if(rwrap.discountAmount>0){
                                        body += '<sotransitem>';
                                        body += '<itemid>Discount Given</itemid>';
                                        body += '<quantity>1</quantity>';
                                        body += '<unit>Each</unit>';
                                        body += '<price>'+(-rwrap.discountAmount)+'</price>';
                                        
                                        if(rwrap.locationId!=null){
                                            body += '<locationid>'+rwrap.locationId+'</locationid>';
                                        }                        
                                        body += '<departmentid>'+departmentId+'</departmentid>';
                                        
                                        If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                            body += '<customfields>';
                                            body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                            body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
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
                                        
                                        if(rwrap.fromDate!=null && rwrap.toDate!=null && rwrap.revenueTemplate!=null && rwrap.toDate>lastMonthDate){
                                            body += '<revrectemplate>'+rwrap.revenueTemplate+'</revrectemplate>';
                                            body += '<revrecstartdate><year>'+rwrap.fromDate.year()+'</year><month>'+rwrap.fromDate.month()+'</month><day>'+rwrap.fromDate.day()+'</day></revrecstartdate>';
                                            body += '<revrecenddate><year>'+rwrap.toDate.year()+'</year><month>'+rwrap.toDate.month()+'</month><day>'+rwrap.toDate.day()+'</day></revrecenddate>';                                         
                                        }
                                        
                                        if(rwrap.projectId!=null){
                                            body += '<projectid>'+rwrap.projectId+'</projectid>';
                                        }
                                        body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                        
                                        
                                        if(rwrap.classId!=null){
                                            body += '<classid>'+rwrap.classId+' Min</classid>';
                                        }
                                        
                                        body += '</sotransitem>';
                                    }
                                }
                            }
                            
                            if(invoice.Admin_Fees__c>0){
                                body += '<sotransitem>';
                                
                                body += '<itemid>Admin Fee</itemid>';
                                
                                body += '<quantity>1</quantity>';
                                body += '<unit>Each</unit>';
                                body += '<price>'+invoice.Admin_Fees__c+'</price>';
                                body += '<locationid>'+invoice.Center__r.Name+'</locationid>';
                                body += '<departmentid>'+departmentId+'</departmentid>';
                                
                                If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                    decimal AdminTax = invoice.New_GST_Amount_Admin_Fee__c - invoice.New_GST_Amount__c;
                                    adminTax = AdminTax.setScale(2);
                                            
                                    body += '<customfields>';
                                    body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>'+invoice.center__r.Organisation__r.Country__r.Tax_Rate__c+'</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>'+adminTax+'</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>'+adminTax+'</customfieldvalue></customfield>';
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
                                        
                                body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                body += '</sotransitem>';
                            }
                            
                            body += '</sotransitems>';
                        }
                        
                        body += '</create_sotransaction></function></content></operation></request>';
                        
                        req.setBody(body);
                        
                        req.setTimeout(120000);
                        
                        If(!Test.isRunningTest()){
                            Http http = new Http();
                            HTTPResponse res = http.send(req);
                            
                            response = res.getBody();
                        }else{
                            response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Intacct_ISB</senderid><controlid>ControlIdHere</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>intacct</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-12-10T00:17:29+00:00</sessiontimestamp><sessiontimeout>2019-12-10T01:55:18+00:00</sessiontimeout></authentication><result><status>success</status><function>create_sotransaction</function><controlid>testControlId</controlid><key>Activation-TEST INTACCT</key></result></operation></response>';
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
                                                                rw.errorMsg = child4.getText(); break;
                                                            }
                                                        }
                                                        if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){break;}
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
                                                rw.errorMsg = child2.getText(); break;
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
        }else{
            rw.isSuccess = false;
            rw.errorMsg = 'GL Account codes not found.';
        }
        
        if(rw.isSuccess){
            
            if(enrToLineItemMap.size()>0){
                SageIntacctIntegrationUtility.revRecWrapper rrw = SageIntacctIntegrationUtility.getRevRecognitionSchedule(sw,rw.sageRecordKey);
                if(rrw.revRecList!=null && rrw.revRecList.size()>0){
                    SageIntacctIntegrationUtility.RevRecEntryWrapper rrew = SageIntacctIntegrationUtility.getRevRecognitionEntries(sw,rrw.revRecList);
                    If(rrew.revRecEntryListMap!=null && rrew.revRecEntryListMap.size()>0){
                        system.debug('Check1=='+enrToMaxAmountMap);
                        Map<string,string> amountEnrToRevRecMap = new Map<string,string>();
                        Map<string,string> discountEnrToRevRecMap = new Map<string,string>(); 
                        for(string str: rrew.revRecEntryListMap.keyset()){
                            system.debug('Check2');
                            decimal maxAmount = 0;
                            decimal minAmount = 0;
                            for(revRecEntry rrEntry:rrew.revRecEntryListMap.get(str)){
                                If(rrEntry.amount>0){
                                    if(rrEntry.amount > maxAmount){
                                        maxAmount = rrEntry.amount;
                                    }
                                }else{
                                    if(rrEntry.amount < minAmount){
                                        minAmount = rrEntry.amount;
                                    }
                                }
                            }
                            If(maxAmount>0){
                                for(string enr: enrToMaxAmountMap.keyset()){
                                    system.debug('check2.1=='+enrToMaxAmountMap.get(enr)+'----'+maxAmount);
                                    if(Integer.valueOf(enrToMaxAmountMap.get(enr))==Integer.valueOf(maxAmount) && !amountEnrToRevRecMap.containsKey(enr)){
                                        system.debug('check2.2');
                                        amountEnrToRevRecMap.put(enr,str);
                                        break;
                                    }
                                }
                            }
                            
                            If(minAmount<0){
                                for(string enr: enrToMaxDiscountAmountMap.keyset()){
                                    system.debug('check2.3=='+enrToMaxDiscountAmountMap.get(enr)+'----'+minAmount);
                                    system.debug('discountEnrToRevRecMap.containsKey(enr)===='+discountEnrToRevRecMap.containsKey(enr)+'-----'+enr);
                                    if(Integer.valueOf(enrToMaxDiscountAmountMap.get(enr))==(-1*Integer.valueOf(minAmount)) && !discountEnrToRevRecMap.containsKey(enr)){
                                        system.debug('check2.4');
                                        discountEnrToRevRecMap.put(enr,str);
                                        break;
                                    }
                                }
                            }
                        }
                        
                        system.debug('amountEnrToRevRecMap=='+amountEnrToRevRecMap);
                        
                        Map<string,string> UpdRevRecEntryMap = new Map<string,string>();
                        Map<string,string> newRevRecEntryMap = new Map<string,string>();
                        
                        for(string enr:enrToLineItemMap.keyset()){
                            system.debug('Check3=='+discountEnrToRevRecMap);
                            string amountRevRecKey = '';
                            string discountRevRecKey = '';
                            If(amountEnrToRevRecMap.containsKey(enr)){
                                amountRevRecKey = amountEnrToRevRecMap.get(enr);
                            }
                            If(discountEnrToRevRecMap.containsKey(enr)){
                                discountRevRecKey = discountEnrToRevRecMap.get(enr);
                            }
                            
                            for(Invoice_Line_Item__c ili:enrToLineItemMap.get(enr)){
                                system.debug('Check4==='+amountRevRecKey+'---'+discountRevRecKey);
                                if(rrew.revRecEntryListMap.containsKey(amountRevRecKey)){
                                    system.debug('Check5');
                                    Boolean lineItemMatched = false;
                                    for(revRecEntry rre: rrew.revRecEntryListMap.get(amountRevRecKey)){
                                        system.debug('Check5.1==='+rre.postingDate.month()+'--'+ili.Month__c.Month()+'---'+rre.postingDate.Year()+'---'+ili.Month__c.year());
                                        if(rre.postingDate.month()==ili.Month__c.Month() && rre.postingDate.Year()==ili.Month__c.year()){
                                            lineItemMatched = true;
                                            string bdy = '';
                                            
                                            If(UpdRevRecEntryMap.containsKey(amountRevRecKey)){
                                                bdy = UpdRevRecEntryMap.get(amountRevRecKey);
                                            }
                                            
                                            bdy += '<revrecentry><recordno>'+rre.recordNo+'</recordno><trx_amount>'+ili.amount__c+'</trx_amount></revrecentry>';
                                            
                                            UpdRevRecEntryMap.put(amountRevRecKey,bdy);
                                        }
                                    }
                                    If(!lineItemMatched){
                                        string bdy = '';
                                        If(newRevRecEntryMap.containsKey(amountRevRecKey)){
                                            bdy = newRevRecEntryMap.get(amountRevRecKey);
                                        }
                                        string glCode='';
                                        if(ili.Package__r.Type__c=='Individual' || ili.Package__r.Type__c=='Home' || ili.Package__r.Type__c=='American Club'){
                                            if(glCodeMap.containsKey('Individual Lessons')){
                                                glCode = glCodeMap.get('Individual Lessons');
                                            }                                    
                                        }else if(ili.Package__r.Type__c=='Group'){
                                            if(glCodeMap.containsKey('Group Lessons')){
                                                glCode += glCodeMap.get('Group Lessons');
                                            }
                                        }
                                        If(glCode!=null && glCode.trim().length()>0){
                                            bdy += '<revrecentry><postingdate><year>'+ili.Month__c.year()+'</year><month>'+ili.Month__c.month()+'</month><day>'+ili.Month__c.day()+'</day></postingdate><accountno>'+glCode+'</accountno><trx_amount>'+ili.amount__c+'</trx_amount></revrecentry>';
                                        }
                                        newRevRecEntryMap.put(amountRevRecKey,bdy);
                                    }
                                }
                                if(rrew.revRecEntryListMap.containsKey(discountRevRecKey)){
                                    system.debug('Check6');
                                    Boolean lineItemMatched = false;
                                    for(revRecEntry rre: rrew.revRecEntryListMap.get(discountRevRecKey)){
                                        if(rre.postingDate.month()==ili.Month__c.Month() && rre.postingDate.Year()==ili.Month__c.year()){
                                            lineItemMatched = true;
                                            string bdy = '';
                                            
                                            If(UpdRevRecEntryMap.containsKey(discountRevRecKey)){
                                                bdy = UpdRevRecEntryMap.get(discountRevRecKey);
                                            }
                                            
                                            bdy += '<revrecentry><recordno>'+rre.recordNo+'</recordno><trx_amount>'+(-1*ili.Discount_amount__c)+'</trx_amount></revrecentry>';
                                            
                                            UpdRevRecEntryMap.put(discountRevRecKey,bdy);
                                        }
                                    }
                                    If(!lineItemMatched){
                                        string bdy = '';
                                        If(newRevRecEntryMap.containsKey(discountRevRecKey)){
                                            bdy = newRevRecEntryMap.get(discountRevRecKey);
                                        }
                                        If(glCodeMap.containsKey('Discount Given')){
                                            bdy += '<revrecentry><postingdate><year>'+ili.Month__c.year()+'</year><month>'+ili.Month__c.month()+'</month><day>'+ili.Month__c.day()+'</day></postingdate><accountno>'+glCodeMap.get('Discount Given')+'</accountno><trx_amount>'+(-1*ili.Discount_amount__c)+'</trx_amount></revrecentry>';
                                        }
                                        newRevRecEntryMap.put(discountRevRecKey,bdy);
                                    }
                                }
                            }
                        }
                        
                        system.debug('check7==='+updRevRecEntryMap);
                        
                        If(updRevRecEntryMap.size()>0){
                            SageIntacctIntegrationUtility.updateRevRecEntries(sw,UpdRevRecEntryMap, newRevRecEntryMap);
                        }
                    }
                }
            }
            
            resultWrapper rw1 = SageIntacctIntegrationUtility.activateOrderEntry(sw,invoice,rw.sageRecordKey);
            
            if(rw1.isSuccess){
                invoice.SageOrderEntryKey__c = rw1.sageRecordKey;
                invoice.MovedToSage__c = true;
                invoice.Sage_Error_Message__c = '';
            }else{
                invoice.Sage_Error_Message__c = rw1.errorMsg;
            }
        }else{
            invoice.Sage_Error_Message__c = rw.errorMsg;
        }*/           
        return invoice;
    }
    
    public static resultWrapper activateOrderEntry(SessionWrapper sw, Invoice__c invoice, string orderEntryKey){
        
        resultWrapper rw = new resultWrapper();
        
        /*string departmentId = 'Aureus Academy'; 
        
        string body;
        string response;
        
        Map<Id,revenueRecogWrapper> revrecWrapMap = new Map<Id,revenueRecogWrapper>();
        
        Map<string,List<Invoice_Line_Item__c>> enrToLineItemMap = new Map<string,List<Invoice_Line_Item__c>>();
        Map<string,decimal> enrToMaxAmountMap = new Map<string,decimal>();
        Map<string,decimal> enrToMaxDiscountAmountMap = new Map<string,decimal>();
        
        if(invoice!=null && invoice.Id!=null){
            if(invoice.Invoice_Date__c!=null){
                if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                    sw = SageIntacctIntegrationUtility.getuserSessionID(invoice.center__r.Organisation__r.Sage_Company__c);
                }
                if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST');
                    req.setEndpoint(sw.endPointUrl);
                    req.setHeader('Content-Type','application/xml');
                    
                    string timestamp = String.valueof(DateTime.now().getTime());
                    
                    body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                    body += '<senderid>'+sw.senderId+'</senderid>';
                    body += '<password>'+sw.senderPassword+'</password>';
                    body += '<controlid>'+timestamp+'</controlid>';
                    body += '<uniqueid>true</uniqueid>';
                    body += '<dtdversion>3.0</dtdversion>';
                    body += '<includewhitespace>false</includewhitespace>';
                    body += '</control>';
                    body += '<operation>';
                    body += '<authentication>';
                    body += '<sessionid>'+sw.sessionId+'</sessionid>';
                    body += '</authentication>';
                    body += '<content>';
                    body += '<function controlid="Invoice-'+invoice.Name+'">';
                    
                    body += '<create_sotransaction>';
                    body += '<transactiontype>Invoice</transactiontype>';
                    body += '<datecreated><year>'+invoice.Invoice_Date__c.Year()+'</year><month>'+invoice.Invoice_Date__c.Month()+'</month><day>'+invoice.Invoice_Date__c.Day()+'</day></datecreated>';
                    body += '<createdfrom>'+orderEntryKey+'</createdfrom>';
                    body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                    body += '<documentno>'+invoice.Name+'</documentno>';
                    body += '<referenceno>'+invoice.Internal_Ref_No__c+'</referenceno>';
                    if(invoice.Due_Date__c!=null){    
                        body += '<datedue><year>'+invoice.Due_Date__c.Year()+'</year><month>'+invoice.Due_Date__c.Month()+'</month><day>'+invoice.Due_Date__c.Day()+'</day></datedue>';
                    }
                    
                    if(invoice.Invoice_Line_Items__r.size()>0){
                        body += '<sotransitems>';
                        
                        for(Invoice_Line_Item__c invLineItem:invoice.Invoice_Line_Items__r){
                            if(invLineItem.Remarks__c!='Registration Fees' && !invLineItem.Is_Deposit__c && (invLineItem.Package__r.Type_of_package__c=='Promo' || invLineItem.Package__r.Type_of_package__c=='Prepayment')){
                                revenueRecogWrapper rwrap = new revenueRecogWrapper();
                                rwrap.amount = 0;
                                rwrap.discountAmount = 0;
                                rwrap.gstAmount = 0;
                                
                                if(revrecWrapMap.containsKey(invLineItem.Enrolment__c)){
                                    rwrap = revrecWrapMap.get(invLineItem.Enrolment__c);
                                }
                                
                                List<Invoice_Line_Item__c> tempList = new List<Invoice_Line_Item__c>();
                                If(enrToLineItemMap.containsKey(invLineItem.Enrolment__c)){
                                    tempList.addAll(enrToLineItemMap.get(invLineItem.Enrolment__c));
                                }
                                tempList.add(invLineItem);
                                enrToLineItemMap.put(invLineItem.Enrolment__c,tempList);
                                
                                decimal tempAmount = 0;
                                if(enrToMaxAmountMap.containsKey(invLineItem.Enrolment__c)){
                                    tempAmount = enrToMaxAmountMap.get(invLineItem.Enrolment__c);
                                }
                                
                                if(invLineItem.Amount__c > tempAmount){
                                    tempAmount = invLineItem.Amount__c;
                                }
                                If(tempAmount>0){
                                    enrToMaxAmountMap.put(invLineItem.Enrolment__c,tempAmount);
                                }
                                
                                decimal tempDiscountAmount = 0;
                                if(enrToMaxDiscountAmountMap.containsKey(invLineItem.Enrolment__c)){
                                    tempDiscountAmount = enrToMaxDiscountAmountMap.get(invLineItem.Enrolment__c);
                                }
                                
                                if(invLineItem.Discount_Amount__c > tempDiscountAmount){
                                    tempDiscountAmount = invLineItem.Discount_Amount__c;
                                }
                                If(tempDiscountAmount>0){
                                    enrToMaxDiscountAmountMap.put(invLineItem.Enrolment__c,tempDiscountAmount);
                                }
                                
                                if(rwrap.glCode==null){
                                    if(invLineItem.Package__r.Type__c=='Individual' || invLineItem.Package__r.Type__c=='Home' || invLineItem.Package__r.Type__c=='Adhoc' || invLineItem.Package__r.Type__c=='American Club'){
                                        rwrap.glCode = 'Individual Lessons';
                                    }else if(invLineItem.Package__r.Type__c=='Group'){
                                        rwrap.glCode = 'Group Lessons';
                                    }else if(invLineItem.Package__r.Type__c=='Camp'){
                                        rwrap.glCode = 'Camp &amp; Event Revenue';
                                    }
                                }
                                
                                if(rwrap.locationId==null && invLineItem.Package__r.Location__r.Name!=null){
                                    rwrap.locationId = invLineItem.Package__r.Location__r.Name;
                                }
                                
                                if(rwrap.projectId==null && invLineItem.Package__r.Program__r.Name!=null){
                                    rwrap.projectId = invLineItem.Package__r.Program__r.Name;
                                }
                                
                                if(rwrap.classId==null && invLineItem.Package__r.Duration__c!=null){
                                    rwrap.classId = invLineItem.Package__r.Duration__c;
                                }
                                
                                if(invLineItem.Amount__c!=null){
                                    if(rwrap.amount!=null){
                                        rwrap.amount += invLineItem.Amount__c;
                                    }else{
                                        rwrap.amount = invLineItem.Amount__c;
                                    }
                                }else{
                                    rwrap.amount = 0;
                                }
                                
                                if(invLineItem.Discount_Amount__c>0){
                                    if(rwrap.discountAmount>0){
                                        rwrap.discountAmount += invLineItem.Discount_Amount__c;
                                    }else{
                                        rwrap.discountAmount = invLineItem.Discount_Amount__c;
                                    }
                                }else{
                                    rwrap.discountAmount = 0;
                                }
                                
                                if(invLineItem.Gst_Amount__c!=null && invLineItem.Gst_Amount__c!=0){
                                    rwrap.gstAmount += invLineItem.Gst_Amount__c;
                                }else{
                                    rwrap.gstAmount = 0;
                                }
                                
                                if(rwrap.fromDate!=null){
                                    if(rwrap.fromDate>invLineItem.Month__c){
                                        rwrap.fromDate = invLineItem.Month__c;
                                    }
                                }else{
                                    rwrap.fromDate = invLineItem.Month__c;
                                }
                                if(rwrap.toDate!=null){
                                    if(rwrap.toDate<invLineItem.month__c){
                                        rwrap.toDate = invLineItem.Month__c;
                                    }
                                }else{
                                    rwrap.toDate = invLineItem.Month__c;
                                }
                                
                                If(rwrap.revenueTemplate==null){
                                    rwrap.revenueTemplate = invLineItem.Package__r.Sage_Revenue_Template__c;
                                }
                                
                                revrecWrapMap.put(invLineItem.Enrolment__c,rwrap);
                                continue;
                            }
                            body += '<sotransitem>';
                            if(invLineItem.Is_Deposit__c){
                                body += '<itemid>Customer Deposit</itemid>';
                            }else{
                                if(invLineItem.Remarks__c=='Registration Fees'){
                                    body += '<itemid>Registration Fees</itemid>';
                                }else if(invLineItem.Remarks__c!=null && invLineItem.Remarks__c.contains('Studio')){
                                    body += '<itemid>Studio Rental</itemid>';
                                }else if(invLineItem.Remarks__c!=null && invLineItem.Remarks__c.contains('Referral')){
                                    body += '<itemid>Discount Given</itemid>';
                                }else if(invLineItem.Remarks__c=='Credit Note Adjustment'){
                                    body += '<itemid>Credit Note</itemid>';
                                }else if(invLineItem.Remarks__c=='Rounding Adjustment'){
                                    body += '<itemid>Other Income</itemid>';
                                }else{
                                    if(invLineItem.Package__r.Type__c=='Individual' || invLineItem.Package__r.Type__c=='Home' || invLineItem.Package__r.Type__c=='Adhoc' || invLineItem.Package__r.Type__c=='American Club'){
                                        body += '<itemid>Individual Lessons</itemid>';
                                    }else if(invLineItem.Package__r.Type__c=='Group'){
                                        body += '<itemid>Group Lessons</itemid>';
                                    }else if(invLineItem.Package__r.Type__c=='Camp'){
                                        body += '<itemid>Camp &amp; Event Revenue</itemid>';
                                    }else if(invLineItem.GL_Code__c!=null){
                                        body += '<itemid>'+invLineItem.GL_Code__c+'</itemid>';
                                    }else{
                                        body += '<itemid>Retail Sales</itemid>';
                                    }
                                }
                            }
                            body += '<quantity>1</quantity>';
                            body += '<unit>Each</unit>';
                            body += '<price>'+(invLineItem.Amount__c!=null?invLineItem.Amount__c:0)+'</price>';
                            if(invLineItem.Package__r.Location__r.Name!=null){
                                body += '<locationid>'+invLineItem.Package__r.Location__r.Name+'</locationid>';
                            }else if(invoice.center__r.Name!=null){
                                body += '<locationid>'+invoice.center__r.Name+'</locationid>';
                            }else If(invLineItem.POS_Item_Type__c!=null && invLineItem.POS_Item_Type__c.contains('Camp')){
                                body += '<locationid>'+invLineItem.POS_Item_Type__c+'</locationid>';
                            }
                            
                            body += '<departmentid>'+departmentId+'</departmentid>';
                            
                            If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                If(!invLineItem.Is_Deposit__c){
                                    decimal gstAmt = invLineItem.GST_Amount__c!=null?invLineItem.GST_Amount__c.setScale(2):0;
                                    body += '<customfields>';
                                    body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
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
                                }else{
                                    body += '<customfields>';
                                    body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageNoGSTCode+'</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
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
                            }
                            
                            Date lastMonthDate = date.newInstance(invoice.Invoice_Date__c.year(),invoice.Invoice_Date__c.month(),Date.DaysInMonth(invoice.Invoice_Date__c.year(),invoice.Invoice_Date__c.month()));
                            
                            if(invLineItem.Package__r.Program__r.Name!=null){
                                body += '<projectid>'+invLineItem.Package__r.Program__r.Name+'</projectid>';
                            }
                            body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                            
                            if(invLineItem.Remarks__c==null || !invLineItem.Remarks__c.contains('Studio')){
                                if(invLineItem.Package__r.Duration__c!=null){
                                    body += '<classid>'+invLineItem.Package__r.Duration__c+' Min</classid>';
                                }
                            }
                            
                            body += '</sotransitem>';
                            
                            If(invLineItem.Discount_Amount__c>0){
                                body += '<sotransitem>';
                                
                                body += '<itemid>Discount Given</itemid>';
                                
                                body += '<quantity>1</quantity>';
                                body += '<unit>Each</unit>';
                                body += '<price>'+(-invLineItem.Discount_Amount__c)+'</price>';
                                if(invLineItem.Package__r.Location__r.Name!=null){
                                    body += '<locationid>'+invLineItem.Package__r.Location__r.Name+'</locationid>';
                                }                        
                                body += '<departmentid>'+departmentId+'</departmentid>';
                                
                                If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                    body += '<customfields>';
                                    body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                    body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
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
                                
                                if(invLineItem.Package__r.Program__r.Name!=null){
                                    body += '<projectid>'+invLineItem.Package__r.Program__r.Name+'</projectid>';
                                }
                                body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                
                                if(invLineItem.Remarks__c==null || !invLineItem.Remarks__c.contains('Studio')){
                                    if(invLineItem.Package__r.Duration__c!=null){
                                        body += '<classid>'+invLineItem.Package__r.Duration__c+' Min</classid>';
                                    }
                                }
                                body += '</sotransitem>';
                            }
                        }
                        
                        If(revrecWrapMap!=null && revrecWrapMap.size()>0){
                            for(Id eid:revrecWrapMap.keyset()){
                                revenueRecogWrapper rWrap = new revenueRecogWrapper();
                                rwrap = revrecWrapMap.get(eid);
                                body += '<sotransitem>';
                                body += '<itemid>'+rwrap.glcode+'</itemid>';
                                body += '<quantity>1</quantity>';
                                body += '<unit>Each</unit>';
                                body += '<price>'+rwrap.amount+'</price>';
                                
                                if(rwrap.locationId!=null){
                                    body += '<locationid>'+rwrap.locationId+'</locationid>';
                                }                        
                                body += '<departmentid>'+departmentId+'</departmentid>';
                                
                                If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                    If(rwrap.gstAmount!=null && rwrap.gstAmount!=0){
                                        body += '<customfields>';
                                        body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>'+(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c/100)+'</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>'+rwrap.gstAmount.setScale(2)+'</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>'+rwrap.gstAmount.setScale(2)+'</customfieldvalue></customfield>';
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
                                    }else{
                                        body += '<customfields>';
                                        body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
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
                                }
                                
                                if(rwrap.projectId!=null){
                                    body += '<projectid>'+rwrap.projectId+'</projectid>';
                                }
                                body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                
                                if(rwrap.classId!=null){
                                    body += '<classid>'+rwrap.classId+' Min</classid>';
                                }
                                
                                body += '</sotransitem>';
                                
                                if(rwrap.discountAmount>0){
                                    body += '<sotransitem>';
                                    body += '<itemid>Discount Given</itemid>';
                                    body += '<quantity>1</quantity>';
                                    body += '<unit>Each</unit>';
                                    body += '<price>'+(-rwrap.discountAmount)+'</price>';
                                    
                                    if(rwrap.locationId!=null){
                                        body += '<locationid>'+rwrap.locationId+'</locationid>';
                                    }                        
                                    body += '<departmentid>'+departmentId+'</departmentid>';
                                    
                                    If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                        body += '<customfields>';
                                        body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
                                        body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>0</customfieldvalue></customfield>';
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
                                    
                                    if(rwrap.projectId!=null){
                                        body += '<projectid>'+rwrap.projectId+'</projectid>';
                                    }
                                    body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                    
                                    
                                    if(rwrap.classId!=null){
                                        body += '<classid>'+rwrap.classId+' Min</classid>';
                                    }
                                    
                                    body += '</sotransitem>';
                                }
                            }
                        }
                        
                        if(invoice.Admin_Fees__c>0){
                            body += '<sotransitem>';
                            body += '<itemid>Admin Fee</itemid>';
                            body += '<quantity>1</quantity>';
                            body += '<unit>Each</unit>';
                            body += '<price>'+invoice.Admin_Fees__c+'</price>';
                            body += '<locationid>'+invoice.Center__r.Name+'</locationid>';
                            body += '<departmentid>'+departmentId+'</departmentid>';
                            
                            If(invoice.center__r.Organisation__r.Country__r.Tax_Rate__c>0){
                                decimal AdminTax = invoice.New_GST_Amount_Admin_Fee__c - invoice.New_GST_Amount__c;
                                adminTax = AdminTax.setScale(2);
                                        
                                body += '<customfields>';
                                body += '<customfield><customfieldname>GLDIMVAT_CODE</customfieldname><customfieldvalue>'+label.SageGSTCode+'</customfieldvalue></customfield>';
                                body += '<customfield><customfieldname>VAT_RATE</customfieldname><customfieldvalue>'+invoice.center__r.Organisation__r.Country__r.Tax_Rate__c+'</customfieldvalue></customfield>';
                                body += '<customfield><customfieldname>VAT_AMOUNT</customfieldname><customfieldvalue>'+adminTax+'</customfieldvalue></customfield>';
                                body += '<customfield><customfieldname>BASE_VAT_AMOUNT</customfieldname><customfieldvalue>'+adminTax+'</customfieldvalue></customfield>';
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
                                    
                            body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                            body += '</sotransitem>';
                        }
                        
                        body += '</sotransitems>';
                    }
                    
                    body += '</create_sotransaction></function></content></operation></request>';
                    
                    req.setBody(body);
                    
                    req.setTimeout(120000);
                    
                    If(!Test.isRunningTest()){
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        
                        response = res.getBody();
                    }else{
                        response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Intacct_ISB</senderid><controlid>ControlIdHere</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>intacct</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-12-10T00:17:29+00:00</sessiontimestamp><sessiontimeout>2019-12-10T02:04:27+00:00</sessiontimeout></authentication><result><status>success</status><function>create_sotransaction</function><controlid>testControlId</controlid><key>Invoice-TEST INTACCT2</key></result></operation></response>';
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
                                                            rw.errorMsg = child4.getText(); break;
                                                        }
                                                    }
                                                    if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){break;}
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
                                            rw.errorMsg = child2.getText(); break;
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
        }*/
                 
        return rw;
    }
    
    public static resultWrapper createCreditMemoForVoidInvoice(SessionWrapper sw, Invoice__c invoice){
        
        resultWrapper rw = new resultWrapper();
        
        /*string departmentId = 'Aureus Academy'; 
        
        string body;
        string response;
        
        Map<Id,revenueRecogWrapper> revrecWrapMap = new Map<Id,revenueRecogWrapper>();
        
        Map<string,List<Invoice_Line_Item__c>> enrToLineItemMap = new Map<string,List<Invoice_Line_Item__c>>();
        Map<string,decimal> enrToMaxAmountMap = new Map<string,decimal>();
        Map<string,decimal> enrToMaxDiscountAmountMap = new Map<string,decimal>();
        
        if(invoice!=null && invoice.Id!=null){
            if(invoice.Invoice_Date__c!=null){
                if(sw==null || sw.sessionId==null || sw.sessionId.trim().length()==0){
                    sw = SageIntacctIntegrationUtility.getuserSessionID(invoice.center__r.Organisation__r.Sage_Company__c);
                }
                if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                    HttpRequest req = new HttpRequest();
                    req.setMethod('POST');
                    req.setEndpoint(sw.endPointUrl);
                    req.setHeader('Content-Type','application/xml');
                    
                    string timestamp = String.valueof(DateTime.now().getTime());
                    
                    body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                    body += '<senderid>'+sw.senderId+'</senderid>';
                    body += '<password>'+sw.senderPassword+'</password>';
                    body += '<controlid>'+timestamp+'</controlid>';
                    body += '<uniqueid>true</uniqueid>';
                    body += '<dtdversion>3.0</dtdversion>';
                    body += '<includewhitespace>false</includewhitespace>';
                    body += '</control>';
                    body += '<operation>';
                    body += '<authentication>';
                    body += '<sessionid>'+sw.sessionId+'</sessionid>';
                    body += '</authentication>';
                    body += '<content>';
                    body += '<function controlid="CreditMemo-'+invoice.Name+'">';
                    
                    body += '<create_sotransaction>';
                    body += '<transactiontype>Credit Memo</transactiontype>';
                    If(invoice.Invoice_Void_Date__c!=null){
                        body += '<datecreated><year>'+invoice.Invoice_Void_Date__c.Year()+'</year><month>'+invoice.Invoice_Void_Date__c.Month()+'</month><day>'+invoice.Invoice_Void_Date__c.Day()+'</day></datecreated>';
                    }
                    body += '<createdfrom>'+invoice.SageOrderEntryKey__c+'</createdfrom>';
                    body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                    body += '<documentno>'+invoice.Name+'-voided'+'</documentno>';
                    body += '<referenceno>'+invoice.Internal_Ref_No__c+'</referenceno>';
                    if(invoice.Invoice_Void_Date__c!=null){    
                        body += '<datedue><year>'+invoice.Invoice_Void_Date__c.Year()+'</year><month>'+invoice.Invoice_Void_Date__c.Month()+'</month><day>'+invoice.Invoice_Void_Date__c.Day()+'</day></datedue>';
                    }
                    
                    if(invoice.Invoice_Line_Items__r.size()>0){
                        body += '<sotransitems>';
                        
                        for(Invoice_Line_Item__c invLineItem:invoice.Invoice_Line_Items__r){
                            if(invLineItem.Remarks__c!='Registration Fees' && !invLineItem.Is_Deposit__c && (invLineItem.Package__r.Type_of_package__c=='Promo' || invLineItem.Package__r.Type_of_package__c=='Prepayment')){
                                revenueRecogWrapper rwrap = new revenueRecogWrapper();
                                rwrap.amount = 0;
                                rwrap.discountAmount = 0;
                                rwrap.gstAmount = 0;
                                
                                if(revrecWrapMap.containsKey(invLineItem.Enrolment__c)){
                                    rwrap = revrecWrapMap.get(invLineItem.Enrolment__c);
                                }
                                
                                List<Invoice_Line_Item__c> tempList = new List<Invoice_Line_Item__c>();
                                If(enrToLineItemMap.containsKey(invLineItem.Enrolment__c)){
                                    tempList.addAll(enrToLineItemMap.get(invLineItem.Enrolment__c));
                                }
                                tempList.add(invLineItem);
                                enrToLineItemMap.put(invLineItem.Enrolment__c,tempList);
                                
                                decimal tempAmount = 0;
                                if(enrToMaxAmountMap.containsKey(invLineItem.Enrolment__c)){
                                    tempAmount = enrToMaxAmountMap.get(invLineItem.Enrolment__c);
                                }
                                
                                if(invLineItem.Amount__c > tempAmount){
                                    tempAmount = invLineItem.Amount__c;
                                }
                                If(tempAmount>0){
                                    enrToMaxAmountMap.put(invLineItem.Enrolment__c,tempAmount);
                                }
                                
                                decimal tempDiscountAmount = 0;
                                if(enrToMaxDiscountAmountMap.containsKey(invLineItem.Enrolment__c)){
                                    tempDiscountAmount = enrToMaxDiscountAmountMap.get(invLineItem.Enrolment__c);
                                }
                                
                                if(invLineItem.Discount_Amount__c > tempDiscountAmount){
                                    tempDiscountAmount = invLineItem.Discount_Amount__c;
                                }
                                If(tempDiscountAmount>0){
                                    enrToMaxDiscountAmountMap.put(invLineItem.Enrolment__c,tempDiscountAmount);
                                }
                                
                                if(rwrap.glCode==null){
                                    if(invLineItem.Package__r.Type__c=='Individual' || invLineItem.Package__r.Type__c=='Home' || invLineItem.Package__r.Type__c=='Adhoc' || invLineItem.Package__r.Type__c=='American Club'){
                                        rwrap.glCode = 'Individual Lessons';
                                    }else if(invLineItem.Package__r.Type__c=='Group'){
                                        rwrap.glCode = 'Group Lessons';
                                    }else if(invLineItem.Package__r.Type__c=='Camp'){
                                        rwrap.glCode = 'Camp &amp; Event Revenue';
                                    }
                                }
                                
                                if(rwrap.locationId==null && invLineItem.Package__r.Location__r.Name!=null){
                                    rwrap.locationId = invLineItem.Package__r.Location__r.Name;
                                }
                                
                                if(rwrap.projectId==null && invLineItem.Package__r.Program__r.Name!=null){
                                    rwrap.projectId = invLineItem.Package__r.Program__r.Name;
                                }
                                
                                if(rwrap.classId==null && invLineItem.Package__r.Duration__c!=null){
                                    rwrap.classId = invLineItem.Package__r.Duration__c;
                                }
                                
                                if(invLineItem.Amount__c!=null){
                                    if(rwrap.amount!=null){
                                        rwrap.amount += invLineItem.Amount__c;
                                    }else{
                                        rwrap.amount = invLineItem.Amount__c;
                                    }
                                }else{
                                    rwrap.amount = 0;
                                }
                                
                                if(invLineItem.Discount_Amount__c>0){
                                    if(rwrap.discountAmount>0){
                                        rwrap.discountAmount += invLineItem.Discount_Amount__c;
                                    }else{
                                        rwrap.discountAmount = invLineItem.Discount_Amount__c;
                                    }
                                }else{
                                    rwrap.discountAmount = 0;
                                }
                                
                                if(invLineItem.Gst_Amount__c!=null && invLineItem.Gst_Amount__c!=0){
                                    rwrap.gstAmount += invLineItem.Gst_Amount__c;
                                }else{
                                    rwrap.gstAmount = 0;
                                }
                                
                                if(rwrap.fromDate!=null){
                                    if(rwrap.fromDate>invLineItem.Month__c){
                                        rwrap.fromDate = invLineItem.Month__c;
                                    }
                                }else{
                                    rwrap.fromDate = invLineItem.Month__c;
                                }
                                if(rwrap.toDate!=null){
                                    if(rwrap.toDate<invLineItem.month__c){
                                        rwrap.toDate = invLineItem.Month__c;
                                    }
                                }else{
                                    rwrap.toDate = invLineItem.Month__c;
                                }
                                
                                If(rwrap.revenueTemplate==null){
                                    rwrap.revenueTemplate = invLineItem.Package__r.Sage_Revenue_Template__c;
                                }
                                
                                revrecWrapMap.put(invLineItem.Enrolment__c,rwrap);
                                continue;
                            }
                            body += '<sotransitem>';
                            if(invLineItem.Is_Deposit__c){
                                body += '<itemid>Customer Deposit</itemid>';
                            }else{
                                if(invLineItem.Remarks__c=='Registration Fees'){
                                    body += '<itemid>Registration Fees</itemid>';
                                }else if(invLineItem.Remarks__c!=null && invLineItem.Remarks__c.contains('Studio')){
                                    body += '<itemid>Studio Rental</itemid>';
                                }else if(invLineItem.Remarks__c!=null && invLineItem.Remarks__c.contains('Referral')){
                                    body += '<itemid>Discount Given</itemid>';
                                }else if(invLineItem.Remarks__c=='Credit Note Adjustment'){
                                    body += '<itemid>Credit Note</itemid>';
                                }else if(invLineItem.Remarks__c=='Rounding Adjustment'){
                                    body += '<itemid>Other Income</itemid>';
                                }else{
                                    if(invLineItem.Package__r.Type__c=='Individual' || invLineItem.Package__r.Type__c=='Home' || invLineItem.Package__r.Type__c=='Adhoc' || invLineItem.Package__r.Type__c=='American Club'){
                                        body += '<itemid>Individual Lessons</itemid>';
                                    }else if(invLineItem.Package__r.Type__c=='Group'){
                                        body += '<itemid>Group Lessons</itemid>';
                                    }else if(invLineItem.Package__r.Type__c=='Camp'){
                                        body += '<itemid>Camp &amp; Event Revenue</itemid>';
                                    }else if(invLineItem.GL_Code__c!=null){
                                        body += '<itemid>'+invLineItem.GL_Code__c+'</itemid>';
                                    }else{
                                        body += '<itemid>Retail Sales</itemid>';
                                    }
                                }
                            }
                            body += '<quantity>1</quantity>';
                            body += '<unit>Each</unit>';
                            body += '<price>'+(invLineItem.Amount__c!=null?invLineItem.Amount__c:0)+'</price>';
                            if(invLineItem.Package__r.Location__r.Name!=null){
                                body += '<locationid>'+invLineItem.Package__r.Location__r.Name+'</locationid>';
                            }else if(invoice.center__r.Name!=null){
                                body += '<locationid>'+invoice.center__r.Name+'</locationid>';
                            }else If(invLineItem.POS_Item_Type__c!=null && invLineItem.POS_Item_Type__c.contains('Camp')){
                                body += '<locationid>'+invLineItem.POS_Item_Type__c+'</locationid>';
                            }
                            
                            body += '<departmentid>'+departmentId+'</departmentid>';
                            
                            
                            //Date lastMonthDate = date.newInstance(invoice.Invoice_Date__c.year(),invoice.Invoice_Date__c.month(),Date.DaysInMonth(invoice.Invoice_Date__c.year(),invoice.Invoice_Date__c.month()));
                            
                            if(invLineItem.Package__r.Program__r.Name!=null){
                                body += '<projectid>'+invLineItem.Package__r.Program__r.Name+'</projectid>';
                            }
                            body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                            
                            if(invLineItem.Remarks__c==null || !invLineItem.Remarks__c.contains('Studio')){
                                if(invLineItem.Package__r.Duration__c!=null){
                                    body += '<classid>'+invLineItem.Package__r.Duration__c+' Min</classid>';
                                }
                            }
                            
                            body += '</sotransitem>';
                            
                            If(invLineItem.Discount_Amount__c>0){
                                body += '<sotransitem>';
                                
                                body += '<itemid>Discount Given</itemid>';
                                
                                body += '<quantity>1</quantity>';
                                body += '<unit>Each</unit>';
                                body += '<price>'+(-invLineItem.Discount_Amount__c)+'</price>';
                                if(invLineItem.Package__r.Location__r.Name!=null){
                                    body += '<locationid>'+invLineItem.Package__r.Location__r.Name+'</locationid>';
                                }                        
                                body += '<departmentid>'+departmentId+'</departmentid>';
                                
                                if(invLineItem.Package__r.Program__r.Name!=null){
                                    body += '<projectid>'+invLineItem.Package__r.Program__r.Name+'</projectid>';
                                }
                                body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                
                                if(invLineItem.Remarks__c==null || !invLineItem.Remarks__c.contains('Studio')){
                                    if(invLineItem.Package__r.Duration__c!=null){
                                        body += '<classid>'+invLineItem.Package__r.Duration__c+' Min</classid>';
                                    }
                                }
                                body += '</sotransitem>';
                            }
                        }
                        
                        If(revrecWrapMap!=null && revrecWrapMap.size()>0){
                            for(Id eid:revrecWrapMap.keyset()){
                                revenueRecogWrapper rWrap = new revenueRecogWrapper();
                                rwrap = revrecWrapMap.get(eid);
                                body += '<sotransitem>';
                                body += '<itemid>'+rwrap.glcode+'</itemid>';
                                body += '<quantity>1</quantity>';
                                body += '<unit>Each</unit>';
                                body += '<price>'+rwrap.amount+'</price>';
                                
                                if(rwrap.locationId!=null){
                                    body += '<locationid>'+rwrap.locationId+'</locationid>';
                                }                        
                                body += '<departmentid>'+departmentId+'</departmentid>';
                                
                                if(rwrap.projectId!=null){
                                    body += '<projectid>'+rwrap.projectId+'</projectid>';
                                }
                                body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                
                                if(rwrap.classId!=null){
                                    body += '<classid>'+rwrap.classId+' Min</classid>';
                                }
                                
                                body += '</sotransitem>';
                                
                                if(rwrap.discountAmount>0){
                                    body += '<sotransitem>';
                                    body += '<itemid>Discount Given</itemid>';
                                    body += '<quantity>1</quantity>';
                                    body += '<unit>Each</unit>';
                                    body += '<price>'+(-rwrap.discountAmount)+'</price>';
                                    
                                    if(rwrap.locationId!=null){
                                        body += '<locationid>'+rwrap.locationId+'</locationid>';
                                    }                        
                                    body += '<departmentid>'+departmentId+'</departmentid>';
                                    
                                    if(rwrap.projectId!=null){
                                        body += '<projectid>'+rwrap.projectId+'</projectid>';
                                    }
                                    body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                                    
                                    
                                    if(rwrap.classId!=null){
                                        body += '<classid>'+rwrap.classId+' Min</classid>';
                                    }
                                    
                                    body += '</sotransitem>';
                                }
                            }
                        }
                        
                        if(invoice.Admin_Fees__c>0){
                            body += '<sotransitem>';
                            body += '<itemid>Admin Fee</itemid>';
                            body += '<quantity>1</quantity>';
                            body += '<unit>Each</unit>';
                            body += '<price>'+invoice.Admin_Fees__c+'</price>';
                            body += '<locationid>'+invoice.Center__r.Name+'</locationid>';
                            body += '<departmentid>'+departmentId+'</departmentid>';
                                    
                            body += '<customerid>'+invoice.Parent_Account__r.AccountID_Customer__c+'</customerid>';
                            body += '</sotransitem>';
                        }
                        
                        body += '</sotransitems>';
                    }
                    
                    body += '<subtotals><subtotal><description>VAT</description><total/><absval>'+invoice.New_GST_Amount_Admin_Fee__c+'</absval></subtotal></subtotals>';

                    body += '</create_sotransaction></function></content></operation></request>';
                    
                    req.setBody(body);
                    
                    req.setTimeout(120000);
                    
                    If(!Test.isRunningTest()){
                        Http http = new Http();
                        HTTPResponse res = http.send(req);
                        
                        response = res.getBody();
                    }else{
                        response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Intacct_ISB</senderid><controlid>ControlIdHere</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>intacct</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-12-10T00:17:29+00:00</sessiontimestamp><sessiontimeout>2019-12-10T02:04:27+00:00</sessiontimeout></authentication><result><status>success</status><function>create_sotransaction</function><controlid>testControlId</controlid><key>Invoice-TEST INTACCT2</key></result></operation></response>';
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
                                                            rw.errorMsg = child4.getText(); break;
                                                        }
                                                    }
                                                    if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){break;}
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
                                            rw.errorMsg = child2.getText(); break;
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
        }*/
                 
        return rw;
    }
    
    //This function is used to apply credits for voided invoices
    public static resultWrapper applyCreditToInvoice(SessionWrapper sw, Invoice__c invoice, String creditMemoKey){
        resultWrapper rrw = new resultWrapper();    
        /*if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(sw.endPointUrl);
            req.setHeader('Content-Type','application/xml');
            
            string timestamp = String.valueof(DateTime.now().getTime());
            
            string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
            body += '<senderid>'+sw.senderId+'</senderid>';
            body += '<password>'+sw.senderPassword+'</password>';
            body += '<controlid>'+timestamp+'</controlid>';
            body += '<uniqueid>false</uniqueid>';
            body += '<dtdversion>3.0</dtdversion>';
            body += '<includewhitespace>false</includewhitespace>';
            body += '</control>';
            body += '<operation>';
            body += '<authentication>';
            body += '<sessionid>'+sw.sessionId+'</sessionid>';
            body += '</authentication>';
            body += '<content>';
            body += '<function controlid="'+timestamp+'">';
            body +=     '<apply_arpayment>';
            body +=         '<arpaymentkey>'+creditMemoKey+'</arpaymentkey>';
            body +=         '<paymentdate>';
            body +=             '<year>'+invoice.Invoice_Date__c.year()+'</year>';
            body +=             '<month>'+invoice.Invoice_Date__c.month()+'</month>';
            body +=             '<day>'+invoice.Invoice_Date__c.day()+'</day>';
            body +=         '</paymentdate>';
            body +=         '<memo>Apply AR Payment from API : '+invoice.Name+'</memo>';
            body +=         '<arpaymentitems>';
            body +=             '<arpaymentitem>';
            body +=                 '<invoicekey>'+invoice.SageInvoiceKey__c+'</invoicekey>';
            body +=                 '<amount>'+invoice.Total_Amount__c+'</amount>';
            body +=             '</arpaymentitem>';
            body +=         '</arpaymentitems>';
            body +=     '</apply_arpayment>';
            body += '</function></content></operation></request>';
            
            system.debug('Body===='+body);
            
            req.setBody(body);
            req.setTimeout(120000);
            
            string response;
            If(!Test.isRunningTest()){
                Http http = new Http();
                HTTPResponse res = http.send(req);
                
                response = res.getBody();
            }else{
                response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1580971347153</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2020-02-06T06:42:27+00:00</sessiontimestamp><sessiontimeout>2020-02-06T12:42:27+00:00</sessiontimeout></authentication><result><status>success</status><function>apply_arpayment</function><controlid>1580971347153</controlid></result></operation></response>';
            }
            
            system.debug('response==='+response);
            
            If(response!=null && response.trim().length()>0){
                DOM.Document doc = new DOM.Document();
                doc.load(response);
                DOM.XMLNode root = doc.getRootElement();
                
                for(DOM.XMLNode child : root.getChildElements()){
                    if(child.getName()=='operation'){
                        for(DOM.XMLNode child1 : child.getChildElements()){
                            if(child1.getName()=='result'){
                                Boolean isSuccess = false;
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='status'){
                                        if(child2.getText()=='success'){
                                            isSuccess = true;
                                            rrw.isSuccess = true;
                                        }
                                    }
                                    
                                    if(child2.getName()=='errormessage'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='error'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='description2'){
                                                        rrw.errorMsg = child4.getText(); break;
                                                    }
                                                }
                                                if(rrw.errorMsg!=null && rrw.errorMsg.trim().length()>0){break;}
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
                                        rrw.errorMsg = child2.getText(); break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }*/
        return rrw;
    }
    
    public static resultWrapper fetchARInvoiceKey(SessionWrapper sw, string orderEntryKey){
        resultWrapper rrw = new resultWrapper();    
        /*if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(sw.endPointUrl);
            req.setHeader('Content-Type','application/xml');
            
            string timestamp = String.valueof(DateTime.now().getTime());
            
            string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
            body += '<senderid>'+sw.senderId+'</senderid>';
            body += '<password>'+sw.senderPassword+'</password>';
            body += '<controlid>'+timestamp+'</controlid>';
            body += '<uniqueid>false</uniqueid>';
            body += '<dtdversion>3.0</dtdversion>';
            body += '<includewhitespace>false</includewhitespace>';
            body += '</control>';
            body += '<operation>';
            body += '<authentication>';
            body += '<sessionid>'+sw.sessionId+'</sessionid>';
            body += '</authentication>';
            body += '<content>';
            body += '<function controlid="'+timestamp+'">';
            body += '<readByQuery>';
            body += '<object>SODOCUMENT</object>';
            body += '<fields>PRRECORDKEY</fields>';
            body += '<query>DOCID = \''+orderEntryKey+'\'</query>';
            body += '<returnFormat>xml</returnFormat>';
            body += '<pagesize>100</pagesize>';
            body += '</readByQuery>';
            body += '</function></content></operation></request>';
            
            system.debug('Body===='+body);
            
            req.setBody(body);
            req.setTimeout(120000);
            
            string response;
            If(!Test.isRunningTest()){
                Http http = new Http();
                HTTPResponse res = http.send(req);
                response = res.getBody();
            }else{
                response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Intacct_ISB</senderid><controlid>ControlIdHere</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>intacct</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-12-10T03:30:01+00:00</sessiontimestamp><sessiontimeout>2019-12-10T04:30:14+00:00</sessiontimeout></authentication><result><status>success</status><function>readByQuery</function><controlid>testControlId</controlid><data listtype="sodocument" count="1" totalcount="1" numremaining="0" resultId=""><sodocument><PRRECORDKEY>45841</PRRECORDKEY></sodocument></data></result></operation></response>';
            }
            system.debug('response==='+response);
            
            If(response!=null && response.trim().length()>0){
                DOM.Document doc = new DOM.Document();
                doc.load(response);
                DOM.XMLNode root = doc.getRootElement();
                
                for(DOM.XMLNode child : root.getChildElements()){
                    if(child.getName()=='operation'){
                        for(DOM.XMLNode child1 : child.getChildElements()){
                            if(child1.getName()=='result'){
                                Boolean isSuccess = false;
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='status'){
                                        if(child2.getText()=='success'){
                                            isSuccess = true;
                                            rrw.isSuccess = true;
                                        }
                                    }
                                    
                                    if(isSuccess && child2.getName()=='data'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='sodocument'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='PRRECORDKEY'){
                                                        rrw.sageRecordKey =child4.getText(); break;
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
                                                        rrw.errorMsg = child4.getText(); break;
                                                    }
                                                }
                                                if(rrw.errorMsg!=null && rrw.errorMsg.trim().length()>0){break;}
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
                                        rrw.errorMsg = child2.getText(); break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }*/  
        return rrw;
    }
    
    public static string fetchVATprocessStatus(SessionWrapper sw, string invoiceNumber){
        string status = '';
        /*if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(sw.endPointUrl);
            req.setHeader('Content-Type','application/xml');
            
            string timestamp = String.valueof(DateTime.now().getTime());
            
            string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
            body += '<senderid>'+sw.senderId+'</senderid>';
            body += '<password>'+sw.senderPassword+'</password>';
            body += '<controlid>'+timestamp+'</controlid>';
            body += '<uniqueid>false</uniqueid>';
            body += '<dtdversion>3.0</dtdversion>';
            body += '<includewhitespace>false</includewhitespace>';
            body += '</control>';
            body += '<operation>';
            body += '<authentication>';
            body += '<sessionid>'+sw.sessionId+'</sessionid>';
            body += '</authentication>';
            body += '<content>';
            body += '<function controlid="'+timestamp+'">';
            body += '<readByQuery>';
            body += '<object>vat_process_and_error_log</object>';
            body += '<fields>status</fields>';
            body += '<query>docid LIKE \'%'+invoiceNumber+'\'</query>';
            body += '<returnFormat>xml</returnFormat>';
            body += '<pagesize>100</pagesize>';
            body += '</readByQuery>';
            body += '</function></content></operation></request>';
            
            system.debug('Body===='+body);
            
            req.setBody(body);
            req.setTimeout(120000);
            
            string response;
            If(!Test.isRunningTest()){
                Http http = new Http();
                HTTPResponse res = http.send(req);
                
                response = res.getBody();
            }else{
                response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1576640476544</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2019-12-23T02:42:26+00:00</sessiontimestamp><sessiontimeout>2019-12-23T08:42:26+00:00</sessiontimeout></authentication><result><status>success</status><function>readByQuery</function><controlid>testControlId</controlid><data listtype="vat_process_and_error_log" count="1" totalcount="1" numremaining="0" resultId=""><vat_process_and_error_log><status>Complete</status></vat_process_and_error_log></data></result></operation></response>';
            }
            
            system.debug('response==='+response);
            
            If(response!=null && response.trim().length()>0){
                DOM.Document doc = new DOM.Document();
                doc.load(response);
                DOM.XMLNode root = doc.getRootElement();
                
                for(DOM.XMLNode child : root.getChildElements()){
                    if(child.getName()=='operation'){
                        for(DOM.XMLNode child1 : child.getChildElements()){
                            if(child1.getName()=='result'){
                                Boolean isSuccess = false;
                                for(DOM.XMLNode child2 : child1.getChildElements()){
                                    if(child2.getName()=='status'){
                                        if(child2.getText()=='success'){
                                            isSuccess = true;
                                        }
                                    }
                                    
                                    if(isSuccess && child2.getName()=='data'){
                                        for(DOM.XMLNode child3 : child2.getChildElements()){
                                            if(child3.getName()=='vat_process_and_error_log'){
                                                for(DOM.XMLNode child4 : child3.getChildElements()){
                                                    if(child4.getName()=='status'){
                                                        status = child4.getText(); break;
                                                    }
                                                }
                                            }                                       
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }*/
        return status;
    }
    
    public static resultWrapper applyARPayment(SessionWrapper sw,Invoice__c invoice){
        resultWrapper rw = new resultWrapper();
        /*if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
            if(invoice!=null && invoice.Id!=null){
                if(invoice.Invoice_Date__c!=null){
                    if(invoice.Discount_Amount__c>0){
                        HttpRequest req = new HttpRequest();
                        req.setMethod('POST');
                        req.setEndpoint(sw.endPointUrl);
                        req.setHeader('Content-Type','application/xml');
                        
                        string timestamp = String.valueof(DateTime.now().getTime());
                        
                        string body = '<?xml version="1.0" encoding="UTF-8"?><request><control>';
                        body += '<senderid>'+sw.senderId+'</senderid>';
                        body += '<password>'+sw.senderPassword+'</password>';
                        body += '<controlid>'+timestamp+'</controlid>';
                        body += '<uniqueid>false</uniqueid>';
                        body += '<dtdversion>3.0</dtdversion>';
                        body += '<includewhitespace>false</includewhitespace>';
                        body += '</control>';
                        body += '<operation>';
                        body += '<authentication>';
                        body += '<sessionid>'+sw.sessionId+'</sessionid>';
                        body += '</authentication>';
                        body += '<content>';
                        body += '<function controlid="'+timestamp+'">';
                        body += '<apply_arpayment>';
                        body += '<arpaymentkey>'+invoice.SageInvoiceKey__c+'</arpaymentkey>';
                        body += '<paymentdate>';
                        body += '<year>'+invoice.Invoice_Date__c.year()+'</year>';
                        body += '<month>'+invoice.Invoice_Date__c.month()+'</month>';
                        body += '<day>'+invoice.Invoice_Date__c.day()+'</day>';
                        body += '</paymentdate>';
                        body += '<memo>Apply AR Payment for invoice : '+invoice.Name+'</memo>';
                        body += '<arpaymentitems>';
                        body += '<arpaymentitem>';
                        body += '<invoicekey>'+invoice.SageInvoiceKey__c+'</invoicekey>';
                        body += '<amount>'+invoice.Discount_Amount__c.setScale(2)+'</amount>';
                        body += '</arpaymentitem>';
                        body += '</arpaymentitems>';
                        body += '</apply_arpayment>';
                        body += '</function></content></operation></request>';
            
                        system.debug('Body===='+body);
                        
                        req.setBody(body);
                        req.setTimeout(120000);
                        
                        string response;
                        If(!Test.isRunningTest()){
                            Http http = new Http();
                            HTTPResponse res = http.send(req);
                            
                            response = res.getBody();
                        }else{
                            response = '<?xml version="1.0" encoding="UTF-8"?><response><control><status>success</status><senderid>Aureus Group</senderid><controlid>1578034940385</controlid><uniqueid>false</uniqueid><dtdversion>3.0</dtdversion></control><operation><authentication><status>success</status><userid>ws_tek</userid><companyid>Aureus Group-imp</companyid><locationid>AGP</locationid><sessiontimestamp>2020-01-06T06:14:00+00:00</sessiontimestamp><sessiontimeout>2020-01-06T12:14:00+00:00</sessiontimeout></authentication><result><status>success</status><function>apply_arpayment</function><controlid>testControlId</controlid></result></operation></response>';
                        }
                        
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
                                                }
                                            }
                                            
                                            if(child2.getName()=='errormessage'){
                                                for(DOM.XMLNode child3 : child2.getChildElements()){
                                                    if(child3.getName()=='error'){
                                                        for(DOM.XMLNode child4 : child3.getChildElements()){
                                                            if(child4.getName()=='description2'){
                                                                rw.isSuccess = false;
                                                                rw.errorMsg = child4.getText(); break;
                                                            }
                                                        }
                                                        if(rw.errorMsg!=null && rw.errorMsg.trim().length()>0){break;}
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
                                                rw.errorMsg = child2.getText();break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }*/
        return rw;
    }
}