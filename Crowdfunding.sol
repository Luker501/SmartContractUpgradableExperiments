

pragma solidity ^0.4.21;

//** Creator = Luke Riley
//** This contract is used to check the validity of permissions that are saved in the associated permissions smart contract.
//** To do this, it allows:
//** - A user to confirm that she owns the permissions instance either directly (as the owner) or indirectly (as a member of the share classes)
//** - The ability for a user to validate a permission where she is the owner directly or indirectly

import "browser/PermissionListAbstract.sol";
import "browser/PermissionCheckAbstract.sol";

contract Crowdfunding {
    
    PermissionListAbstract PermListCont;
    PermissionCheckAbstract PermCheckCont;
    int private minRaiseValue;
    int private maxRaiseValue;
    
    /****Modifiers****/
        //** any function containing this modifier, only allows...**//
	modifier PermInstChecksRoughVersion(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont){
	    
		if ((PermListCont.getPermissionInstanceOwner(PermInstId) == msg.sender)==false){
            revert("Not owner of the the permission instance");
        } else if (PermListCont.isPermissionInstanceApproved(PermInstId)){
            revert("The permission instance is not approved");
        }else{
		    _; //means continue on the functions that called it
		}
		
    }
    
    
    /******** Start of blockchain events *********/


    /******** End of blockchain events *********/
    
    
    /******** Start of Functions  *********/
    constructor(address permList) public {
        // initialize contract state variables here
        if (permList!=address(0)) {
            
            PermListCont = PermissionListAbstract(permList);
            address PermCheckAddr = PermListCont.GetPermissionCheckContr();
            if (PermCheckAddr!=address(0)){
                PermCheckCont = PermissionCheckAbstract(PermCheckAddr);
            } else {
                revert("PermCheckAddr variable looked up from permList contract is set to nothing");
            }

        } else {
            revert("datastore or permList input variable set to nothing");
        }
    }
    
    	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
//    function MinMaxRaisePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecksRoughVersion(PermInstId, shareClassUsed, ShareClassIdSRCont) external {
 //NEED TO PUT THE MODIFIER BACK FOR THE FULL DEVELOPMENT!!
    function MinMaxRaisePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  external {
        
            //TEMPORARILY ONLY THERE IS NO EXPIRED CHECK (AS WE CURRENTLY DO NOT HAVE DISAPPROVE PERMIINST IMPLEMENTED)
    	   // if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
                //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
        	        int minRaise = PermListCont.getPermissionInstanceIntAtPosition(PermInstId, 0);
        	        int maxRaise = PermListCont.getPermissionInstanceIntAtPosition(PermInstId, 1);        	        
    	            //record that this permission instance has been used
    	           //TEMPORARILY WE DO NOT RECORD THIS PERMISSION INSTANCE AS BEING USED BUT WE WILL NEED TO!
    	           // PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    //call the function
                    MinMaxRaise(minRaise, maxRaise);
    	       
    	    //} else {
    	    //    revert("Permission instance has expired");
    	    //}
    }
    
    function MinMaxRaise(int minRaise, int maxRaise) private {
        
        minRaiseValue = minRaise;
        maxRaiseValue = maxRaise;
        
    }

    	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function InvestPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecksRoughVersion(PermInstId, shareClassUsed, ShareClassIdSRCont) external {
        
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
                //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
        	        uint value = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
//        	        uint maxRaise = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 1);        	        
    	            //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    //call the function
                    Invest(value);
    	       
    	    }
    }
    
    //IMPORTANT NEEDS TO RETURN TO PRIVATE BEFORE DEPLOYMENT
    function Invest(uint val) private {
        
       // minRaiseValue = minRaise;
    //    maxRaiseValue = maxRaise;
        
    }

    
    /******** End of Functions  *********/
    
    /******** Start of Getters  *********/
    
    function getMinRaise() public view returns (int){
        return minRaiseValue;
    }
    
    function getMaxRaise() public view returns (int){
        return maxRaiseValue;
    }
    
    function getPermListAddr() public view returns (address){
        return address(PermListCont);
    }

    function getPermCheckAddr() public view returns (address){
        return address(PermCheckCont);
    }
    /******** End of Getters  *********/	
    	
    
}
