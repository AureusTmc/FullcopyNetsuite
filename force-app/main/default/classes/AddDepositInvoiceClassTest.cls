@isTest
public class AddDepositInvoiceClassTest {
	@isTest
    private static void unitTest(){
        Account cstmr = TestUtil.createAccount('Customer', TRUE, TRUE);
        Account center = TestUtil.createAccount('Centre',FALSE,True);
        Account teacher = TestUtil.createAccount('Teacher',False, TRUE);
        Enrolment__c enrol = TestUtil.createEnrolment(False);
        enrol.student__c = cstmr.id;
        enrol.Center__c = center.id;
        enrol.Teacher__c = teacher.Id;
        insert enrol;
        Subscription__c subs = TestUtil.createSubscription(cstmr.id,true);
        Subscription_line_item__c item = TestUtil.createSubscriptionLineItem(subs.id, true);
        
        List<Enrolment__c> listOfEnrol  = AddDepositInvoiceClass.getType(enrol.id);
        List<AddDepositInvoiceClass.Wrapperclass> listOfWrap = new List<AddDepositInvoiceClass.Wrapperclass>();
        AddDepositInvoiceClass.Wrapperclass objWrap = new AddDepositInvoiceClass.Wrapperclass();
        objWrap.Center = center.id;
        objWrap.Student = cstmr.id;
        objWrap.Parent = cstmr.id;
        objWrap.Invoice_Date = '2019-05-01';
        objWrap.DepositAmt = '50';
        objWrap.Packages = NULL;
        objWrap.Stripe = '';
        objWrap.CoInv = '123';
        objWrap.PaymentMethod = 'Card';
        listOfWrap.add(objWrap);
            
        AddDepositInvoiceClass.SaveInvoice(JSON.serialize(listOfWrap),subs.id,enrol.id,null,teacher.id,item.id);
    }
}