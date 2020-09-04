@isTest
public class SageStripePayoutPushBatchTest {

    @isTest
      public static void test1(){

  
        Test.startTest();
        SageStripePayoutPushBatch obj = new SageStripePayoutPushBatch();
        ID batchprocessid = Database.executeBatch(obj);
        test.stopTest();
    }
    
     @isTest
    public static void test2(){
		Sage_Intacct_Credentials__c sic = new Sage_Intacct_Credentials__c();
        sic.Name='test';
        sic.Endpoint__c='https://api.intacct.com/ia/xml/xmlgw.phtml';
        insert sic;
        
        List<Sage_GL_Account__c> sgaList = new List<Sage_GL_Account__c>();
        for(integer i=0;i<=3;i++){
            Sage_GL_Account__c sga = new Sage_GL_Account__c();
            if(i==0){
                sga.Name='Merchandise Card Receivable';
            }
            else if(i==1){
                sga.Name='Accounts Payable'; 
                sga.GL_Account_No__c='qwerty';
            }
            else if(i==2){
                sga.Name='AGP Cash at Bank - OCBC';
            }
            else{
                sga.Name='Merchant Account Fees';
            }
            sga.GL_Account_No__c=''+i;
            sgaList.add(sga) ;
        }
        insert sgaList;
       
        Organisation__c org = new Organisation__c();
        org.Sage_Company__c = 'AGP';
        insert org;
        Stripe_Payout_Log__c spl = new Stripe_Payout_Log__c();
        spl.Status__c = 'Processed in SF';
        spl.Organisation__c= org.id;
        insert spl;
        Account cust = TestUtil.createAccount('Customer',TRUE,TRUE);
        Payment__c pay = new Payment__c();
        pay.Parent_Account__c = cust.id;
        pay.Payment_Status__c ='Success';
        pay.Payment_Amount__c = 105;
        pay.Stripe_Payout_Id__c = spl.Id;
        insert pay;
        
        set<Id> invidSet=new Set<Id>();
        invidSet.add(spl.id);
  
        Test.startTest();
        SageStripePayoutPushBatch obj = new SageStripePayoutPushBatch(invidSet);
        ID batchprocessid = Database.executeBatch(obj);
  
         Database.executeBatch(new SageStripePayoutPushBatch());
        test.stopTest();
    }
  
}