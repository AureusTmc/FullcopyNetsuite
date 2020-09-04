// Added By Ravi (6th Jan 2020).... this basically the class for exchange pos
public class ExchangeInstrumntCLass {
    
    //this method fetches the record of Invoice and Invoice Line items
    @AuraEnabled
    public static list<Invoice__c> getInvoiceData(string invoiceID){
        
        return [select Id,Parent_Account__c,Parent_Account__r.Name,Customer_Name__c,Center__r.Name,Name,Invoice_Type__c,Total_Invoice_Amount__c,Parent_Account__r.Stripe_Customer_Id__c,
                Invoice_Date__c,(select Id,Name,Remarks__c,Quantity__c,Amount__c,GST_Amount__c,Teacher__c,Student__c,Invoice_Date__c from Invoice_Line_Items__r) 
                from Invoice__c where Id=:invoiceID AND Invoice_Type__c = 'POS' AND Status__c = 'Paid'];
    }
    
    //This function is used for the refund process
    @AuraEnabled
    public static string peformActionInvoice(string invoiceID){
        string returnmsg='SUCCESS';
        try{
           
            List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,
                                       Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,
                                       center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,
                                       (Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,
                                                Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c 
                                        from Invoice_Line_Items__r), (SELECT Id, Payment_Status__c, Parent_Account__c, Payment_Amount__c, Method_of_Payment__c FROM Payments__r WHERE Payment_Status__c = 'Success' AND RecordType.Name = 'Payment Transaction')
                                   from Invoice__c where Id =: invoiceID];
            
          
            if(invList.size() > 0){
                Invoice__c inv = new Invoice__c();
                inv.Id=invList.get(0).Id;
                inv.Status__c='Void';
                update inv;
                
                /*Payment__c pay = new Payment__c();
                if(invList.get(0).Payments__r.size() > 0){
                    pay = invList.get(0).Payments__r.get(0);
                    pay.Payment_Status__c = 'Void';
                    update pay;
                }*/
                List<Payment__c> payList = new List<Payment__c>();
                if(invList.get(0).Payments__r.size() > 0){
                    Payment__c pay = invList.get(0).Payments__r.get(0);
                    
                    //Negative payment
                    String payRecId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment Transaction').getRecordTypeId();
                    Payment__c negativPay = new Payment__c();
                    negativPay.RecordTypeId = payRecId;
                    negativPay.Invoice__c = inv.Id;
                    negativPay.Parent_Account__c = pay.Parent_Account__c;
                    negativPay.Payment_Amount__c = -(pay.Payment_Amount__c);
                    negativPay.Payment_Date__c = system.today();
                    negativPay.Parent_Payment__c = pay.Id;
                    negativPay.Method_of_Payment__c = pay.Method_of_Payment__c;
                    negativPay.Payment_Status__c = 'Success';
					payList.add(negativPay);					
                    
                    payRecId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
                    Payment__c payAsCredit = new Payment__c();
                    payAsCredit.RecordTypeId = payRecId;
                    payAsCredit.Parent_Account__c = pay.Parent_Account__c;
                    payAsCredit.Payment_Amount__c = pay.Payment_Amount__c;
                    payAsCredit.Payment_Date__c = system.today();
                    payAsCredit.Payment_Status__c = 'Pending';
                    payList.add(payAsCredit);
                    
                    insert payList;
                    
                    reverseInvOrPayment(inv.Id, negativPay.Id);
                   /*
                    list<Centre_Users__c> centerNameList= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name, Centre_Name__r.Organisation__r.Sage_Company__c 
                                                                                         from Centre_Users__c 
                                                                                         where User_Name__c=:UserInfo.getUserId() AND Centre_Name__r.Organisation__r.Sage_Company__c != null]);
                    if(centerNameList.size() > 0){
                        String sageCmp =centerNameList[0].Centre_Name__r.Organisation__r.Sage_Company__c;
                        SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(sageCmp);  
                        
                        if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                            inv = SageIntacctIntegrationUtility.reverseInvoice(sw, inv);
                            update inv;
                            
                            if(pay.Id != null){
                                SageIntacctIntegrationUtility.reversePayment(sw, pay);
                            }
                        }
                    }*/
                }
            }
        }catch(Exception ex){
            returnmsg = ex.getMessage();
        }
        return returnmsg;
        
    }
    
     @future(Callout=true)
    Public static void reverseInvOrPayment(String invoiceId, String payId){
        list<Centre_Users__c> centerNameList= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name, Centre_Name__r.Organisation__r.Sage_Company__c 
                                                                         from Centre_Users__c 
                                                                         where User_Name__c=:UserInfo.getUserId() AND Centre_Name__r.Organisation__r.Sage_Company__c != null]);
        if(centerNameList.size() > 0){
            String sageCmp =centerNameList[0].Centre_Name__r.Organisation__r.Sage_Company__c;
            SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(sageCmp);  
            
            if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                Payment__c pay = new Payment__c(Id=payId);
                pay = SageIntacctIntegrationUtility.reversePayment(sw, pay);
               
                
                Invoice__c inv = new Invoice__c(Id=invoiceId);
                inv = SageIntacctIntegrationUtility.reverseInvoice(sw, inv);
                
                update pay;
                update inv;
            }
        }
    }
    
    
    @AuraEnabled
    public static list<wrpClass> getInvoiceRefundData(string invoiceID){
        
        List<wrpClass> wrpList = new List<wrpClass>();
        for(Invoice__c invObj:[select Id,Parent_Account__c,Parent_Account__r.Name,Customer_Name__c,Center__r.Name,Name,Invoice_Type__c,Total_Invoice_Amount__c,Customer_Name__r.Stripe_Customer_Id__c from Invoice__c where Id =:invoiceID ]){
            wrpClass wrpObj = new wrpClass();
            wrpObj.IdInvoice=invObj.Id;
            wrpObj.Center=invObj.Center__r.Name;
            wrpObj.CustomerName=invObj.Parent_Account__r.Name;
            wrpObj.InvoiceType=invObj.Invoice_Type__c;
            wrpObj.TotalInvoiceAmount=invObj.Total_Invoice_Amount__c;
            if(invObj.Customer_Name__r.Stripe_Customer_Id__c != null){
              wrpObj.StripeCustomerId=invObj.Customer_Name__r.Stripe_Customer_Id__c;  
            }else{
              wrpObj.StripeCustomerId='';   
            }
            wrpObj.Name=invObj.Name;
            wrpList.add(wrpObj);
        }
        
        return wrpList;
    }
    public class wrpClass{
        @AuraEnabled
        public string IdInvoice{get;set;}
        @AuraEnabled
        public string Center{get;set;}
        @AuraEnabled
        public string CustomerName{get;set;}
        @AuraEnabled
        public string InvoiceType{get;set;}       
        @AuraEnabled
        public Decimal TotalInvoiceAmount{get;set;}
        @AuraEnabled
        public string StripeCustomerId{get;set;}
        @AuraEnabled
        public string Name{get;set;}
        
    }
    
     @AuraEnabled
    public static string performBankTrnsfrAct(string invoiceID){
        //Savepoint sp = Database.setSavepoint();
        string returnmsg='SUCCESS';
        try{
            List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,
                                       Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,
                                       center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,
                                        (SELECT Id,Parent_Account__c,Payment_Amount__c,Transaction_Id__c,Payment_Status__c,Invoice__c,Method_of_Payment__c  FROM Payments__r 
                                         			WHERE Payment_Status__c = 'Success' AND RecordType.Name = 'Payment Transaction')
                                   from Invoice__c where Id =: invoiceID];
            
          
            if(invList.size() > 0 && invList.get(0).Payments__r.size() > 0){
                Invoice__c inv = new Invoice__c();
                inv.Id=invList.get(0).Id;
                inv.Status__c='Void';
                update inv;
                
                Payment__c objPay = new Payment__c();
                objPay = invList.get(0).Payments__r.get(0);
                
                String payRecId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment Transaction').getRecordTypeId();
                Payment__c negativPay = new Payment__c();
                negativPay.RecordTypeId = payRecId;
                negativPay.Invoice__c = inv.Id;
                negativPay.Parent_Account__c = objPay.Parent_Account__c;
                negativPay.Payment_Amount__c = -(objPay.Payment_Amount__c);
                negativPay.Parent_Payment__c = objpay.Id;
                negativPay.Payment_Date__c = system.today();
                negativPay.Method_of_Payment__c = objpay.Method_of_Payment__c;
                negativPay.Payment_Status__c = 'Success';
                insert negativPay;
                
                
                reverseInvOrPayment(inv.Id, negativPay.Id);
            }
           /* List<Task> tskList = new List<Task>();
            List<Invoice__c> invList = new List<Invoice__c>();
            for(Invoice__c invObj:[select Id,Status__c,Parent_Account__r.PersonContactId from Invoice__c where Id=:invoiceID]){
                Invoice__c inv = new Invoice__c();
                inv.Id=invObj.Id;
                inv.Status__c='Void';
                invList.add(inv);
            }
            if(invList.size()>0){
                update invList;
                sendCaseEmail(invList);
                for(Invoice__c inv:invList){
                    Task tsk = new Task(WhatId=inv.Id,Subject='Create Refund');
                    tskList.add(tsk);
                }
            }
            if(tskList.size()>0){
                insert tskList;
            }*/
            
        }catch(Exception ex){
            returnmsg = ex.getMessage();
            system.debug('returnmsg'+returnmsg + '--->'+ ex.getLineNumber() );
           // Database.rollback(sp);
        }
        return returnmsg;
    }
	
    /*
    private static void sendCaseEmail(list<Invoice__c> Ids){
        // Savepoint sp = Database.setSavepoint();
        string templateId ='';
        list<EmailTemplate> templateList= new list<EmailTemplate>();
        templateList = [Select Id,DeveloperName  from EmailTemplate where DeveloperName  = 'Bank_Details_Refund' limit 1];  
        if(templateList[0].Id != null){
            templateId = templateList[0].Id;  
        }
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(Invoice__c inv:[select Id,Status__c,Customer_Name__r.PersonContactId,Parent_Account__r.PersonContactId,Parent_Account__r.PersonEmail,Center__r.Location__c from Invoice__c where Id=:Ids]){
            
            if(String.isNotBlank(templateId) && String.isNotBlank(inv.Parent_Account__r.PersonEmail) ){
                system.debug('inv.Customer_Name__r.PersonEmail'+inv.Parent_Account__r.PersonEmail + 'templateId ' + templateId + '---' +inv.Parent_Account__r.PersonContactId + '====' +inv.Center__r.Location__c + '=---'+inv.Id);
                Messaging.SingleEmailMessage mail = AureusUtility.getSingleEmailMessage(templateId, inv.Parent_Account__r.PersonContactId, inv.Id, inv.Center__r.Location__c);
                //mail.setToAddresses(personEmailList);
                emailList.add(mail);
                system.debug('emailList'+emailList);
            }
        }
        system.debug('emailList'+emailList);
        if(!test.isRunningTest())
            for(Messaging.SendEmailResult results :Messaging.sendEmail(emailList,false)){
                if(!results.isSuccess())
                    system.debug(results.getErrors());
            }    
    }*/
    
    @AuraEnabled
    public static string perfrmCardAction(string invoiceID){
        string returnmsg='SUCCESS';
        try{
            
            List<Invoice__c> invList = [Select Id,New_GST_Amount_Admin_Fee__c,New_GST_Amount__c,Name,Parent_Account__c,Parent_Account__r.AccountID_Customer__c,Parent_Account__r.Name,Center__c,Due_Date__c,Invoice_Date__c,
                                       Status__c,GST_Tax_Amount__c,Discount_Amount__c,Admin_Fees__c,Center__r.Name,MovedToSage__c,Sage_Error_Message__c,SageInvoiceKey__c,Center__r.Organisation__r.Sage_Company__c,
                                       center__r.Organisation__r.Country__r.Currency_Code_PI__c,center__r.Organisation__r.Country__r.Tax_Rate__c,Internal_Ref_No__c,SageOrderEntryKey__c,
                                       (Select Id,Amount__c,Center__c,Package__c,Package__r.Duration__c,Package__r.Type_of_package__c,Package__r.Program__r.Name,package__r.Sage_Revenue_Template__c,
                                                Package__r.Location__r.Name,Is_Deposit__c,Remarks__c,Package__r.Type__c,Discount_Amount__c,Enrolment__c,Month__c,GST_Amount__c,GL_Code__c,POS_Item_Type__c 
                                        from Invoice_Line_Items__r), 
                                        (SELECT Id, Payment_Amount__c,Transaction_Id__c,Payment_Status__c,Parent_Account__r.Country_PI__pc,
                                                     Invoice__r.Center__r.Country__r.Stripe_Base_Url__c, Invoice__r.Center__r.Country__r.Id, 
                                                     Invoice__r.Center__r.Country__r.Stripe_Secret_Key__c, Invoice__c  FROM Payments__r 
                                         			WHERE Payment_Status__c = 'Success' AND RecordType.Name = 'Payment Transaction')
                                   from Invoice__c where Id =: invoiceID];
            
          
            if(invList.size() > 0){
                Invoice__c inv = new Invoice__c();
                inv.Id=invList.get(0).Id;
                inv.Status__c='Void';
               // update inv;
                
                Payment__c objPay = new Payment__c();
                if(invList.get(0).Payments__r.size() > 0){
                    objPay = invList.get(0).Payments__r.get(0);
                  	
                    String payRecId = Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Refund').getRecordTypeId();
                    Payment__c negativPay = new Payment__c();
                    negativPay.RecordTypeId = payRecId;
                    negativPay.Invoice__c = inv.Id;
                    negativPay.Parent_Account__c = objPay.Parent_Account__c;
                    negativPay.Payment_Amount__c = -(objPay.Payment_Amount__c);
                    negativPay.Payment_Date__c = system.today();
                    negativPay.Method_of_Payment__c = 'Card';
                	negativPay.Payment_Status__c = 'Success';
                    //insert negativPay;
                	
                    
                    if(objPay.Payment_Amount__c >= 0 && String.isNotBlank(objPay.Transaction_Id__c)){
                        String stripe_Base_Url  = objPay.Invoice__r.Center__r.Country__r.Stripe_Base_Url__c;
                        String stripe_Secret_Key = objPay.Invoice__r.Center__r.Country__r.Stripe_Secret_Key__c;
                        BillingUtility.StripeRefund  refundObj = BillingUtility.createRefundForCharge(objPay.Transaction_Id__c,
                                                                                                      (BillingUtility.roundOffAmount(objPay.Payment_Amount__c)),
                                                                                                      stripe_Base_Url, 
                                                                                                      stripe_Secret_Key
                                                                                                     );
                        System.debug('@@@@refundObj'+refundObj);
                        if(refundObj.statusCode == 200 && refundObj.status == 'succeeded'){
                            inv.Status__c='Void';
                            update inv;
                            
                            negativPay.Refund_Id__c = refundObj.id;
                            negativPay.Payment_Status__c = ConstantsClass.paymentSuccessStatus;
                            insert negativPay;
                            
                            system.debug('@@@objPay'+objPay);
                           // SageIntacctIntegrationUtility.refundPayment(objPay.id);	 
                           /* if(String.isNotBlank(objPay.Invoice__c)){
                               // Invoice__c invoice = new Invoice__c(Id=objPay.Invoice__c);
                                inv.Status__c = ConstantsClass.dueStatus;
                                update inv;
                                system.debug('@@@invoice'+invoice);
                            }*/
                            
                            reverseInvOrPayment(inv.Id, negativPay.Id);
                        }else{
                            //throw new AuraHandledException('Refund Failed');
                            returnmsg = 'Refund Failed';
                        }
                    }
                    
                    
                    list<Centre_Users__c> centerNameList= new List<Centre_Users__c>([select Id,Centre_Name__c,Centre_Name__r.Name, Centre_Name__r.Organisation__r.Sage_Company__c 
                                                                                         from Centre_Users__c 
                                                                                         where User_Name__c=:UserInfo.getUserId() AND Centre_Name__r.Organisation__r.Sage_Company__c != null]);
                    if(centerNameList.size() > 0){
                        String sageCmp =centerNameList[0].Centre_Name__r.Organisation__r.Sage_Company__c;
                       // SageIntacctIntegrationUtility.sessionWrapper sw = SageIntacctIntegrationUtility.getuserSessionID(sageCmp);  
                        
                        //if(sw.sessionId!=null && sw.sessionId.trim().length()>0){
                           // inv = SageIntacctIntegrationUtility.reverseInvoice(sw, inv);
                           // update inv;
                           /*
                            if(pay.Id != null){
                                SageIntacctIntegrationUtility.reversePayment(sw, pay);
                                
                                
                                String payCrditRecId   =  Schema.SObjectType.Payment__c.getRecordTypeInfosByName().get('Payment As Credit').getRecordTypeId();
                                Payment__c creditPay   = BillingUtility.fillPayment(pay.Parent_Account__c, inv.Id, pay.Payment_Amount__c, ConstantsClass.successStatus);
                                creditPay.RecordTypeId = payCrditRecId;
                                insert creditPay;
                                
                                //For credit memo
                                Invoice__c tempInv = createInvoice(sw, inv);
                                creditPay.SagePaymentKey__c =  tempInv.SageOrderEntryKey__c;
                                update tempInv;
                            }*/
                       // }
                    }
                }
            }
            
        }catch(Exception ex){
            returnmsg = ex.getMessage();
        }
        return returnmsg;
    }
    
    //Create invoice order on sage for Credit Memo
    public static Invoice__c createInvoice(SageIntacctIntegrationUtility.SessionWrapper sw, Invoice__c invoice){
        string departmentId = 'Aureus Academy'; 
        
        string body;
        string response;
        
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
                                         '<function controlid="'+invoice.Name+'">'+
                                            '<create_sotransaction>'+
                                               '<transactiontype>Credit Memo</transactiontype>'+
                                               '<datecreated>'+
                                                  '<year>'+invoice.Invoice_Date__c.Year()+'</year>'+
                                                  '<month>'+invoice.Invoice_Date__c.Month()+'</month>'+
                                                  '<day>'+invoice.Invoice_Date__c.Day()+'</day>'+
                                               '</datecreated>'+
                                               '<createdfrom></createdfrom>'+
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
                                                                     '<itemid>POS</itemid>'+
                                                                     '<itemdesc />'+
                                                                     '<taxable />'+
                                                                     '<warehouseid />'+
                                                                     '<quantity>1</quantity>'+
                                                                     '<unit>Each</unit>'+
                                                                     '<discountpercent />'+
                                                                     '<price>'+(invLineItem.Amount__c!=null?invLineItem.Amount__c:0)+'</price>'+
                                                                     '<discsurchargememo />'+
                                                                     '<locationid>'+invLineItem.POS_Item_Type__c+'</locationid>'+
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
                                                         /*  '<subtotals>'+
                                                              '<subtotal>'+
                                                                 '<description>Shipping</description>'+
                                                                 '<total>20</total>'+
                                                                 '<absval />'+
                                                                 '<percentval />'+
                                                                 '<locationid>ARL-VA-US</locationid>'+
                                                                 '<departmentid>ADM</departmentid>'+
                                                                 '<projectid />'+
                                                                 '<customerid />'+
                                                                 '<vendorid />'+
                                                                 '<employeeid />'+
                                                                 '<classid />'+
                                                                 '<itemid />'+
                                                              '</subtotal>'+
                                                           '</subtotals>'*/
                                                      }
                                            body += '</create_sotransaction>'+
                                         '</function>'+
                                      '</content>'+
                                   '</operation>'+
                                '</request>';                        
                        
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
        /*}else{
            rw.isSuccess = false;
            rw.errorMsg = 'GL Account codes not found.';
        }*/
        
        if(rw.isSuccess){
            invoice.SageInvoiceKey__c = rw.sageRecordKey;
            
            SageIntacctIntegrationUtility.resultWrapper rw1 = SageIntacctIntegrationUtility.activateOrderEntry(sw,invoice,rw.sageRecordKey);
            if(rw1.isSuccess){
                invoice.SageOrderEntryKey__c = rw1.sageRecordKey;
                invoice.MovedToSage__c = true;
                invoice.Sage_Error_Message__c = '';
            }else{
                invoice.Sage_Error_Message__c = rw1.errorMsg;
            }
        }else{
            invoice.Sage_Error_Message__c = rw.errorMsg;
        }           
        return invoice;
    }
    
}