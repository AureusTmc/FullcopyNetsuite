@isTest
public class SchedulablarToUpdateCaseWidAccTest {
 private static testMethod void ScheduleRefreshGrade_test()
    {
        Test.startTest();
        
        // Schedule the test job
        String jobId = System.schedule('ScheduleProgressChecktest','0 0 0 3 9 ? 2022', new SchedulablarToUpdateCaseWidAcc());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same
        System.assertEquals('0 0 0 3 9 ? 2022', ct.CronExpression);
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        // Verify the next time the job will run
        System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        
        Test.stopTest();
    }
}