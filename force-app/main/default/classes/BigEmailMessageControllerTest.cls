/*
Name        :        BigEmailMessageControllerTest
Date        :        9 Oct 2020
Author      :        Karan Singh Soni
Apex Class  :       BigEmailMessageController 
*/
@isTest
public class BigEmailMessageControllerTest {
    
    public static testmethod void testMethod1(){
        
        Account objCustmr=TestUtil.createAccount('Customer',true,true);
        
        BigEmailMessageController.fetchBigEmailMessages( objCustmr.Id, 0 );
        
        BigEmailMessageController.formatDateTime( DateTime.now() , String.valueOf(userInfo.getTimeZone()));
        
		BigEmailMessageController.mapBigEmailMessageWrapValues( new BigEmailMessageController.BigEmailMessageWrap(), new Big_Email_Message_1__b(), 0 );
		BigEmailMessageController.fetchBigEMailMessageRecord( objCustmr.Id , objCustmr.Id );        
    }

    //SELECT id,RelatedTo.Name,(SELECT id FROm Attachments) FROM EmailMessage Id = '02s2s000000Y39dAAC'
}