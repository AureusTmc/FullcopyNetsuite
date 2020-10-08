//Karan Singh Created on 6 Oct 2020
public with sharing class BigEmailMessageController {
    
    //SELECT Id,Subject__c,FromAddress__c,ToAddress__c,MessageDate__c,Related_to_Case__c,Related_to_Case__r.recordtype.name
    //FROM Big_Email_Message__b
    //record type -  Sales Enquiry
@AuraEnabled
public static List< BigEmailMessageWrap > fetchBigEmailMessages( Id recordId,Integer limitRec){

    List< BigEmailMessageWrap > listBigEMailMessageWrap = new List< BigEmailMessageWrap >();
    String queryBigEmail = 'SELECT Id,FirstOpenedDate__c,Headers__c ,LastOpenedDate__c,MessageDate__c,CreatedDate__c,';
    queryBigEmail += 'LastModifiedById__r.Name, IsIncoming_Text__c, FromAddress__c, FromName__c, ToAddress__c,';
    queryBigEmail += 'CC_Address__c, BCC_Address__c, Subject__c, HTML_Body__c, text_Body__c,';
    queryBigEmail += 'Related_to_Account__c,CreatedBy.Name, CreatedDate, LastModifiedDate__c FROM Big_Email_Message_1__b ';
   
    try{
        if( String.isNotBlank( recordId )){

            if( recordId.getSobjectType() == Account.getSObjectType() ){

              queryBigEmail += ' WHERE Related_to_Account__c = \'' + recordId +'\'';
            }else if( recordId.getSobjectType() == Case.getSObjectType() ){
                
                //queryBigEmail += ' WHERE Related_to_Case__c =: ' + recordId;
            }
        }
        //limitRec + 1 is done as to check if the total no of record is more than limitRec(ex 5) .
        // Then in the UI it will show 5+ records
        if ( limitRec != 0 ){ queryBigEmail += ' LIMIT ' + (limitRec + 1); }
        //else{ queryBigEmail += ' LIMIT 100 '; }

        system.debug( queryBigEmail );

        Integer i = 1;
        //listBigEMailMessageWrap = Database.query( queryBigEmail); 
        for( Big_Email_Message_1__b objBigEmail : Database.query( queryBigEmail)){

            BigEmailMessageWrap objBigEmailWrap = new BigEmailMessageWrap();
            
            system.debug(objBigEmail.HTML_Body__c);
            system.debug(objBigEmail.text_Body__c);
            objBigEmailWrap.index = i;
            i++;
            objBigEmailWrap.bccAddress = objBigEmail.BCC_Address__c;
            objBigEmailWrap.ccAddress = objBigEmail.CC_Address__c;
            objBigEmailWrap.emailMessageId = '' ;
            objBigEmailWrap.fromAddress = objBigEmail.FromAddress__c ;
            objBigEmailWrap.fromName = objBigEmail.FromName__c ;
            objBigEmailWrap.Headers = objBigEmail.Headers__c ;
            objBigEmailWrap.htmlBody = objBigEmail.HTML_Body__c ;
            objBigEmailWrap.incomingText = objBigEmail.IsIncoming_Text__c ;
            objBigEmailWrap.LastModifiedByName = objBigEmail.LastModifiedById__r.Name ;
            objBigEmailWrap.relatedTo = '' ;
            objBigEmailWrap.subject = objBigEmail.Subject__c ;
            objBigEmailWrap.textBody = objBigEmail.text_Body__c ;
            objBigEmailWrap.toAddress = objBigEmail.ToAddress__c ;
            objBigEmailWrap.createdByName = objBigEmail.CreatedBy.Name;
            objBigEmailWrap.isError = '' ;

            objBigEmailWrap.createdDate =  formatDateTime(objBigEmail.CreatedDate__c,String.valueOf(UserInfo.getTimeZone()) ) ;
            objBigEmailWrap.MessageDate = formatDateTime(objBigEmail.MessageDate__c,String.valueOf(UserInfo.getTimeZone()) ) ;
            objBigEmailWrap.firstOpenedDate = formatDateTime(objBigEmail.FirstOpenedDate__c,String.valueOf(UserInfo.getTimeZone()) ) ;
            objBigEmailWrap.LastModifiedDate = formatDateTime(objBigEmail.LastModifiedDate__c,String.valueOf(UserInfo.getTimeZone()) ) ;
            objBigEmailWrap.LastOpenedDate = formatDateTime(objBigEmail.LastOpenedDate__c ,String.valueOf(UserInfo.getTimeZone()) );

            listBigEMailMessageWrap.add( objBigEmailWrap );
        }

    }catch( Exception objException ){
        System.debug( 'Error : ' + objException.getMessage() + ' at Line Number : ' + objException.getLineNumber());
        listBigEMailMessageWrap.clear();
        BigEmailMessageWrap objBigEmailWrap = new BigEmailMessageWrap();
        objBigEmailWrap.isError = 'Error : ' + objException.getMessage() + ' at Line Number : ' + objException.getLineNumber();
        listBigEMailMessageWrap.add( objBigEmailWrap );
    }
   return listBigEMailMessageWrap;
}//end of fetchBigEmailMessage()

//this method is used to convert the UTC dateTime to the given time zone
public static string formatDateTime( DateTime objdate, String timeZone ){

    String formatedDate = '';
    if( objdate != Null && String.isNotBlank(timeZone) ){
        formatedDate = objdate.format('MM/dd/yyyy HH:mm:ss a',timeZone );
    }
    return formatedDate;
}

public class BigEmailMessageWrap {
    
    @AuraEnabled
    public Integer index;
    @AuraEnabled
    public String bccAddress;
    @AuraEnabled
    public String ccAddress;
    @AuraEnabled
    public String createdDate;
    @AuraEnabled
    public String createdByName;
    @AuraEnabled
    public String emailMessageId;
    @AuraEnabled
    public String firstOpenedDate;
    @AuraEnabled
    public String fromAddress;
    @AuraEnabled
    public String fromName;
    @AuraEnabled
    public String Headers;
    @AuraEnabled
    public String htmlBody;
    @AuraEnabled
    public String incomingText;
    @AuraEnabled
    public String LastModifiedByName;
    @AuraEnabled
    public String LastModifiedDate;
    @AuraEnabled
    public String LastOpenedDate;
    @AuraEnabled
    public String MessageDate;
    @AuraEnabled
    public String relatedTo;
    @AuraEnabled
    public String subject;
    @AuraEnabled
    public String textBody;
    @AuraEnabled
    public String toAddress;
    @AuraEnabled
    public String isError;

    public BigEmailMessageWrap(){

        bccAddress = '' ;
ccAddress = '' ;
createdDate = '' ;
emailMessageId = '' ;
firstOpenedDate = '' ;
fromAddress = '' ;
fromName = '' ;
Headers = '' ;
htmlBody = '' ;
incomingText = '' ;
LastModifiedByName = '' ;
LastModifiedDate = '' ;
LastOpenedDate = '' ;
MessageDate = '' ;
relatedTo = '' ;
subject = '' ;
textBody = '' ;
toAddress = '' ;
isError = '' ;
    }
}
}

//Data insert query from email message to big object
/*
EmailMessage objEMail = [SELECT Id,HtmlBody,LastModifiedDate,LastModifiedById,ParentId, CreatedById, CreatedDate, TextBody, Headers, Subject, FromName, FromAddress, ToAddress, CcAddress, BccAddress, Incoming, MessageDate, FirstOpenedDate, LastOpenedDate, IsIncoming_Text__c FROM EmailMessage WHERE Id = '02s1m0000001NEgAAM'];
Big_Email_Message_1__b objBigEMail = new Big_Email_Message_1__b();
objBigEMail.Email_Message_Id__c = objEMail.Id;
objBigEMail.Related_To_Account__c = '0011m00000EWlQ0AAL';
objBigEMail.BCC_Address__c = objEMail.BccAddress;
objBigEMail.CC_Address__c = objEMail.CcAddress;
objBigEMail.CreatedDate__c = objEMail.CreatedDate;
objBigEMail.FirstOpenedDate__c = objEMail.FirstOpenedDate;
objBigEMail.FromAddress__c = objEMail.FromAddress;
objBigEMail.FromName__c = objEMail.FromName;
objBigEMail.Headers__c = objEMail.Headers;
objBigEMail.HTML_Body__c = objEMail.HtmlBody;
objBigEMail.IsIncoming_Text__c = objEMail.IsIncoming_Text__c ;
objBigEMail.LastModifiedById__c = objEMail.LastModifiedById;
objBigEMail.LastModifiedDate__c = objEMail.LastModifiedDate;
objBigEMail.Subject__c = objEMail.Subject;
objBigEMail.Text_Body__c = objEMail.TextBody;
objBigEMail.ToAddress__c = objEMail.ToAddress;
objBigEMail.MessageDate__c = objEMail.MessageDate;
Database.insertImmediate(objBigEMail);

*/