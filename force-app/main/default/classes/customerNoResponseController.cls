//not in use
public with sharing class customerNoResponseController {
    
    //to check if the current user is eligible for this operation
    @AuraEnabled
    public static string checkUserEligibility(){

        String message = 'Success';

        List< String > listAllowedUserName = new List< String >();
        set< String > setAllowedUserIds = new set< String > ();
        if( Label.Allowed_Users_For_CustomerNoResponse != Null ){

            if( Label.Allowed_Users_For_CustomerNoResponse.contains(',') ){
                listAllowedUserName = Label.Allowed_Users_For_CustomerNoResponse.split(',');
            }else{
                listAllowedUserName.add( Label.Allowed_Users_For_CustomerNoResponse );
            }

            if( listAllowedUserName.contains( UserInfo.getName() )){
                message =  'Success';
            }else{
                    for ( GroupMember objGroupMembr : [SELECT Id, Group.name, UserOrGroupId FROM 
                                                        GroupMember 
                                                        WHERE Group.name = 'Aureus Finance Team' ] ){
                                                            setAllowedUserIds.add( objGroupMembr.UserOrGroupId );
                    }

                    if( setAllowedUserIds.isEmpty() ){
                        message =  'Allowed Users are not set for this operation.';
                    }else{

                        if( setAllowedUserIds.contains( UserInfo.getUserId())){
                            message =  'Success';
                        }else{
                            message =  'You are not allowed for this action.';
                        }

                    }//end of set contains
                    

            }//end of list contains else
        }else{
            message = 'Allowed Users are not set for this operation.';
        }
        return message;
    }
}
