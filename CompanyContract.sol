

pragma solidity ^0.4.21;

import "browser/ShareholderRights.sol";
import "browser/Permissions.sol";
import "browser/PermissionCheck.sol";

//** Creator = Luke Riley
//** This contract is used to check to test the permission smart contract and the associated permission check smart contract
//** To do this, it allows:
//** - The user to call a function with two int values that requires a permission 
//** - The ability for a user to validate a permission where she is the owner directly or indirectly

contract CompanyContract {
    
	address public Owner;						//holds the address of the contract creator
    ShareholderRights RightsCont;					//holds the address of the associated ShareholderRights.sol contract
	PermissionList PermListCont;						
	PermissionCheck PermCheckCont;

    //variables relating to the functions protected by Permissions
    uint minRaiseAmount;
    uint maxRaiseAmount;    //normally this would be private information (i.e. it is not displayed on CrowdCube's website)

    /******** Start of modifiers *********/

	//** any function containing this modifier, only allows the contract owner to call it**//
	modifier ifOwner(){
		if(Owner != msg.sender){
		    revert();
		}else{
		    _; //means continue on the functions that called it
		}
    }
    
    
    /******** End of Modifiers  *********/
    	
    	
	constructor(address PermList, address PermCheck) public{
        Owner = msg.sender;
        if ((PermList!=address(0))&&((PermCheck!=address(0)))){
            
            Owner = msg.sender;
            PermListCont = PermissionList(PermList);
            PermCheckCont = PermissionCheck(PermCheck);
        }
    }
    
    /******** Start of Functions  *********/
    

	//** Allows a user to call the private minMaxRaise function - if the user has the correct permissions**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function minMaxRaisePermission(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) public {
    	    
    	    //check the permission instance, to make sure that the caller can use it and if the permission instance has been approved
            if ((PermCheckCont.hasOwnershipOfPermissionInstance(msg.sender, PermInstId, shareClassUsed,  ShareClassIdSRCont) == false)||(PermListCont.isPermissionInstanceApproved(PermInstId))){
                revert();
            }

            //get the associated permission template
            uint PermId = PermListCont.getPermissionInstanceRelatedID(PermInstId);
    	    if ((block.number >  PermListCont.getPermissionTemplateStartTime(PermId))&&(block.number <  PermListCont.getPermissionTemplateEndTime(PermId))) {
                //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function
    	            uint min = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
    	            uint max = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 1);
    	            //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
    	            //call the function
    	            minMaxRaise(min,max);
    	       
    	    }
    	  
    }

	//** Allows a user to call the private invest function - if the user has the correct permissions**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function investPermission(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) public {
    	    
    	    //check the permission instance, to make sure that the caller can use it and if the permission instance has been approved
            if ((PermCheckCont.hasOwnershipOfPermissionInstance(msg.sender, PermInstId, shareClassUsed,  ShareClassIdSRCont) == false)||(PermListCont.isPermissionInstanceApproved(PermInstId))){
                revert();
            }

            //get the associated permission template
            uint PermId = PermListCont.getPermissionInstanceRelatedID(PermInstId);
            
    	    if ((block.number >  PermListCont.getPermissionTemplateStartTime(PermId))&&(block.number <  PermListCont.getPermissionTemplateEndTime(PermId))) {
                //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function
        	        uint shares = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
                    bytes32 shareClassB = PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 0);
                    bytes32 sellerB = PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 1);
                    bytes32 buyerB = PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 2);
                    //convert the bytes32 objects into their original form
                    string memory shareClass = bytes32ToString(shareClassB);
                    address seller = bytes32ToAddress(sellerB);
                    address buyer = bytes32ToAddress(buyerB);
    	            //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    //call the function
                    invest(shares,shareClass,seller,buyer);
    	       
    	       
    	    }
    	    
    	  
    }

    //** Allows a user to set the minimum and maximum raise amount**//
	// @param minRaise - the minimum amount of money to raise
	// @param maxRaise - the maximum amount of money to raise
    function minMaxRaise (uint minRaise, uint maxRaise) private {
    	    
    	if (minRaise >= maxRaise){
    	    revert();
    	}   
    	//share price fixed by standard formula (but it uses pre-money valuation which is estimate)
    	    
    	    
        //we will temporarily set the variables in this contract, even though it is not exactly a crowdfunding smart contract. (normally the max raise number is not public)
    	minRaiseAmount = minRaise;
    	maxRaiseAmount = maxRaise;
    	    
    }

    //** Allows a user buy shares from somebody else**//
	// @param shareNum - the number of shares bought
	// @param shareClass - the class fo the shares
	// @param seller - the address of the seller of the shares
	// @param buyer - the address of the buyer of the shares
    function invest (uint shareNum, string shareClass, address seller, address buyer) private {
    	    
    	    //make sure that the seller has the shares recorded in the platform before moving them! and make sure we minus them vbefore plus
    	    //send an event to show that this has occurred!!!
    	    
    	   // cannot have fractional share price
    	    //params: 
    	    // - investor (address)
    	    // - number of shares (uint)
    	    // - share price (uint)
    	    
    	    
    }
    
    /**GET FUNCTIONS******/
    //** Returns the minimum raise amount**//
	// @returns - the raise amount
    function getMinRaiseRequired() public constant returns(uint){
        return minRaiseAmount;
    }

    //** Returns the maximum raise amount**//
	// @returns - the raise amount    
    function getMaxRaiseRequired() public constant returns(uint){
        return maxRaiseAmount;
    }
    
    /**HELPER FUNCTIONS******/
    
    function bytes32ToString(bytes32 x) internal pure returns (string) {
        
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
        
    }

    //address use 20 bytes
   function bytes32ToAddress(bytes32 _address) private pure returns (address) {
    uint160 m = 0;
    uint160 b = 0;

    for (uint8 i = 0; i < 20; i++) {
      m *= 256;
      b = uint160(_address[i]);
      m += (b);
    }

    return address(m);
  } 
  
    function AddresstoBytes32(address addr) private pure returns (bytes32 c) {

        return bytes32(uint256(addr) << 96);
    }

    /**HELPER FUNCTIONS******/


}
		
