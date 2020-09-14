public with sharing class AddCreditMemoController {
  @AuraEnabled(cacheable=true)
  public static creditMemoWrap getCreditMemoDetails(Id invId) {
    system.debug('invId --> ' + invId);
    creditMemoWrap objCreditMemoWrap = new creditMemoWrap();

    // prettier-ignore
    if ( String.isBlank(invId) || invId.getSobjectType() != Schema.Invoice__c.SObjectType) {

    objCreditMemoWrap.isError = 'Invalid Invoice Id';
    return objCreditMemoWrap;

  } else {

    // prettier-ignore
    for (Invoice__c objInv : [ SELECT Id,Status__c, 
                    (SELECT ID, Amount__c FROM Invoice_Line_Items__r WHERE Amount__c > 0) 
                    FROM Invoice__c 
                    WHERE ID = :invId ]) {
                      
                      objCreditMemoWrap.invoiceStatus = objInv.Status__c;
                      objCreditMemoWrap.objInvoice = objInv;
                      if( objInv.Invoice_Line_Items__r.size() > 0 ){
                        
                        for( Invoice_Line_Item__c objInvLine : objInv.Invoice_Line_Items__r ){

                          system.debug('objInvLine.Amount__c --> ' + objInvLine.Amount__c);
                          objCreditMemoWrap.invoiceAmount += objInvLine.Amount__c;
                        }
                        
                      }
                    }
                    system.debug('objCreditMemoWrap.invoiceAmount --> ' + objCreditMemoWrap.invoiceAmount );
  }
    return objCreditMemoWrap;
  }

  @AuraEnabled(cacheable=true)
  public static String createCreditMemo(
    String userAmount,
    creditMemoWrap creditWrap,
    String creditMode,
    String remarks
  ) {
    if (creditMode == 'Refund Memo') {
      //will call the stripe after confimation
    } else if (creditMode == 'Credit Memo (Future Adj)') {
      if (creditWrap.invoiceAmount == Decimal.valueOf(userAmount)) {
      } else {
      }
    } else if (creditMode == 'Credit Memo (Invoice Cancellation)') {
      if (creditWrap.invoiceAmount == Decimal.valueOf(userAmount)) {
      } else {
      }
    }

    return 'success';
  }
  public class creditMemoWrap {
    @AuraEnabled
    public Decimal invoiceAmount;
    @AuraEnabled
    public Decimal existCreditAmount;

    @AuraEnabled
    public String invoiceStatus;
    @AuraEnabled
    public Invoice__c objInvoice;
    @AuraEnabled
    public String isError;

    public creditMemoWrap() {
      invoiceAmount = 0;
      existCreditAmount = 0;
      objInvoice = new Invoice__c();
      isError = '';
      invoiceStatus = '';
    }
  }
}
