

pragma solidity ^0.4.21;

import "browser/ShareholderRights.sol";
import "browser/Permissions.sol";

//** Creator = Luke Riley
//** This contract is used to check the validity of permissions that are saved in the associated permissions smart contract.
//** To do this, it allows:
//** - A user to confirm that she owns the permissions instance either directly (as the owner) or indirectly (as a member of the share classes)
//** - The ability for a user to validate a permission where she is the owner directly or indirectly


contract PermissionCheck {
    
        //holds the address of the contract creator
    	address public Owner;
    	   //keeps track of the next permissionInstance that each address can execute (if this permissionInstance is valid)
	    mapping (address => uint) canExecute; 
    	//keeps track of the next permissionInstance that each address can exeute whenever that address is ready (as this permissionInstance has been checked for validity)
    	mapping (address => uint) validPermission;	
        //holds the address of the associated ShareholderRights.sol contract that details the list of what share classes are assigned to each shareholder
	    ShareholderRights RightsCont;
	    //holds the address of the associated PermissionList.sol contract that details the current function permissions
	    PermissionList PermListCont;
	    //records what PermissionManager position this smart contract is listed for a smart contract address and a function name in the PermissionList contract
	    mapping (address => mapping (string  => uint)) PermissionManagerList;
    
    /******** Start of blockchain events *********/

	//event fires when a user has proved ownership of a permissionInstance or a user has proved that a permissionInstance is valid
	event PermissionInstanceStateChange(string explanation, uint PermInstId);
	
    /******** End of blockchain events *********/
    
    
        /******** Start of modifiers *********/

	//** any function containing this modifier, only allows the contract owner to call it**//
	modifier ifOwner(){
		if(Owner != msg.sender){
		    revert();
		}else{
		    _; //means continue on the functions that called it
		}
    }
    
    	//** any function containing this modifier, only allows the owner of the given permissionInstance to call it**//
	modifier HasOwnership(uint PermId){
		if(canExecute[msg.sender] != PermId){
		    revert();
		}else{
		    _; //means continue on the functions that called it
		}
    }
    
        /******** End of Modifiers  *********/
        
    //constructs the class - sets the owner as the address that put the contract on the blockchain
    //Also links to the PermissionList contract (that holds the current function permissions) and the ShareholderRights contract (that holds the list of what share classes are assigned to each shareholder)
    constructor(address PermList, address ShareRights) public{
        Owner = msg.sender;
        if ((PermList!=address(0)) &&((ShareRights!=address(0)))){
            
            Owner = msg.sender;
            PermListCont = PermissionList(PermList);
            RightsCont = ShareholderRights(ShareRights);
         //   Initialised("The ShareholderRights contract has been initialised:", msg.sender, Owner, ComDefAdd);	//***EVENT: Owner
            
        }
    }
    
    /******** Start of Functions  *********/
    
    //** Checks whether the function user is a owner of a permissionInstance**//
	// @param user - The user the caller is enquiring over (if the user is herself then if this user is the owner of the function, it will be put in her canExecute mapping so she can validate it)
	// @param permInstID - The permissionInstance you are enquirying over
	// @param shareClass - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
	// @returns - if the user has ownership
    function hasOwnershipOfPermissionInstance(address user, uint permInstID, bool shareClass,  uint ShareClassIdSRCont) public returns (bool){
        
    	    //Is this permissionInstance owned by a share class or an individual
    	    if (shareClass == true){

                //get the id of the shareClass that is assigned to this user at position ShareClassIdSRCont in the ShareholderRights smart contract
    	        uint  fromRights = RightsCont.GetShareClass(user, ShareClassIdSRCont);
    	        //Now get the id of the shareClass assigned ownership to this permissionInstance
    	        uint fromPermList = PermListCont.getPermissionInstanceShareClass(permInstID);
    	        if ((fromRights == 0)||(fromRights != fromPermList)){
    	            //A zero is only returned from the GetShareClass function, if there is an error
    	            //if the two IDs do not match then return false
  	                return false;
    	        }
    	    } else {
        	    if (PermListCont.getPermissionInstanceOwner(permInstID)!=msg.sender) {
        	        //If an individual owns this permissionInstance and it is not the sender then return false
        	        return false;
        	    }    
    	    }
    	    
    	   //we now know that this address can execute this permission, so we will set this information in the mapping
    	   if (msg.sender == user){
    	        canExecute[msg.sender] = permInstID;  
    	        emit PermissionInstanceStateChange("A user has proved that she has direct or indirect ownership of the permissionInstance", permInstID);
    	   }
    	    return true;

    }
    
    //** This function lets a owner of the permissionInstance check the validity of the next bool value in the permissionInstance**//
	// @param PermInstID - The permissionInstance you are enquirying over
	//IMPORTANT - Note that the bool values need to be checked in order, otherwise the function will revert due to a possible manipulation attempt
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
    function checkBool(uint PermInstId) HasOwnership(PermInstId) public  {

            //get the next bool to check
            uint boolPosCheck = PermListCont.getPermissionInstanceBoolAnalysed(PermInstId);
            if (boolPosCheck >= 2){
                revert(); //as there can only be two bool values (and array starts at 0)
            }
            //Get the ID of the related PermissionTemplate
            uint PermId;
            uint pointer;
            //get the bool from the permissionInstance
            bool boolToUse = PermListCont.getPermissionInstanceBoolAtPosition(PermInstId, boolPosCheck);
            //get the related PermissionTemplate ID and the position of the bool in the PermissionTemplate's boolVariables array
            (PermId,pointer) = PermListCont.getPermissionInstanceBoolPointer(PermInstId, boolPosCheck);
            //get the bool in that position of the PermissionTemplate's boolVariables array
            bool boolToCompare = PermListCont.getPermissionTemplateBooleans(PermId, boolPosCheck)[pointer];
            //check if the value in the permissionInstance and the value in the PermissionTemplate match
            if (boolToUse != boolToCompare){
                revert();   //if they do not then this permissionInstance cannot be valid
            } else {

                //get the address and the name of the function so that this contract can find at what position it is the PermissionManager
                address functionLocation = PermListCont.getPermissionTemplateFunctionLocation(PermId);
                string memory functionName = bytes32ToString(PermListCont.getPermissionTemplateFunctionName(PermId));
                
                //now set this variable as analysed
                PermListCont.setPermissionInstanceBoolAnalysed(PermInstId, boolPosCheck, PermissionManagerList[functionLocation][functionName]);

            }
            
    } 

    //** This function lets a owner of the permissionInstance check the validity of the next bytes32 value in the permissionInstance**//
	// @param PermInstID - The permissionInstance you are enquirying over
	//IMPORTANT - Note that the bytes32 values need to be checked in order, otherwise the function will revert due to a possible manipulation attempt
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
    function checkBytes32(uint PermInstId) HasOwnership(PermInstId) public {


           //get the next bytes32 to check
            uint bytes32PosCheck = PermListCont.getPermissionInstanceBytes32Analysed(PermInstId);

            //Get the ID of the related PermissionTemplate
            uint PermId;
            uint pointer;
            //get the bool from the permissionInstance
            bytes32 bytes32ToUse = PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, bytes32PosCheck);
            //get the related PermissionTemplate ID and the position of the bool in the PermissionTemplate's boolVariables array
            (PermId,pointer) = PermListCont.getPermissionInstanceBytes32Pointer(PermInstId, bytes32PosCheck);
            //get the bool in that position of the PermissionTemplate's boolVariables array
            bytes32 bytes32ToCompare = PermListCont.getPermissionTemplateBytes32(PermId, bytes32PosCheck, pointer);
            //does the pointer indicate any variable is allowed?
            bytes32 emptyToCompare;
            if ((pointer == 0)&&(bytes32ToCompare == emptyToCompare)){
                //then any bytes32 variable will be valid
            }
            else if (bytes32ToUse != bytes32ToCompare){             //check if the value in the permissionInstance and the value in the PermissionTemplate match
                revert();   //if they do not then this permissionInstance cannot be valid
            }

                //get the address and the name of the function so that this contract can find at what position it is the PermissionManager
                address functionLocation = PermListCont.getPermissionTemplateFunctionLocation(PermId);
                string memory functionName = bytes32ToString(PermListCont.getPermissionTemplateFunctionName(PermId));
                //now set this variable as analysed
                PermListCont.setPermissionInstanceBytes32Analysed(PermInstId, bytes32PosCheck, PermissionManagerList[functionLocation][functionName]);

            
            
    }
    
    
    //** This function lets a owner of the permissionInstance check the validity of the next uint value in the permissionInstance**//
	// @param PermInstID - The permissionInstance you are enquirying over
	//IMPORTANT - Note that the uint values need to be checked in order, otherwise the function will revert due to a possible manipulation attempt
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
    function checkUint(uint PermInstId) HasOwnership(PermInstId) public {


           //get the next uint to check
            uint uintPosCheck = PermListCont.getPermissionInstanceUintAnalysed(PermInstId);

            //Get the ID of the related PermissionTemplate
            uint PermId;
            uint pointer;
            uint lowRange;
            uint highRange;
            //get the bool from the permissionInstance
            uint uintToUse = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, uintPosCheck);
            //get the related PermissionTemplate ID and the position of the bool in the PermissionTemplate's boolVariables array
            (PermId,pointer, lowRange, highRange) = PermListCont.getPermissionInstanceUintPointer(PermInstId, uintPosCheck);
            //get the bool in that position of the PermissionTemplate's boolVariables array
            uint uintToCompare = PermListCont.getPermissionTemplateUints(PermId, uintPosCheck, pointer);
            //does pointer and uintToCompare indicate that a range has been set? (the pointer does this by pointing at position 0, therefore if [uintPosCheck][0] == 1, then a range has been set)
            if ((pointer == 0)&&(uintToCompare == 1)){
                //then either any uint is allowed or we have a range
                //so see if any uint is allowed. We know this is true when the next two positions of the array are set to the default value 0
                if ((lowRange == 0)&&(highRange == 0)){
                    //any uint is allowed
                }else if ((uintToUse <lowRange)||(uintToUse > highRange)){  //otherwise check ranges
                    revert();   //as not in range.
                }
            } else if (pointer == 0){
                //if pointer == 0 and uintToCompare != 1, then a range has not been set so this is a possible manipulation, therefore revert
                revert();
            }
            else if (uintToUse != uintToCompare){   //check if the value in the permissionInstance and the value in the PermissionTemplate match (note if we get here then pointer != 0)
                revert();   //if they do not then this permissionInstance cannot be valid
            }

            //if we are here then the uint is valid (because we have not been reverted)
            //get the address and the name of the function so that this contract can find at what position it is the PermissionManager
            address functionLocation = PermListCont.getPermissionTemplateFunctionLocation(PermId);
            string memory functionName = bytes32ToString(PermListCont.getPermissionTemplateFunctionName(PermId));
            //now set this variable as analysed
            PermListCont.setPermissionInstanceUintAnalysed(PermInstId, uintPosCheck, PermissionManagerList[functionLocation][functionName]);

            
    }
    
    //** This function lets a owner of the permissionInstance check the validity of the next int value in the permissionInstance**//
	// @param PermInstID - The permissionInstance you are enquirying over
	//IMPORTANT - Note that the int values need to be checked in order, otherwise the function will revert due to a possible manipulation attempt
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
        function checkInt(uint PermInstId) HasOwnership(PermInstId) public {


           //get the next uint to check
            uint intPosCheck = PermListCont.getPermissionInstanceIntAnalysed(PermInstId);

            //Get the ID of the related PermissionTemplate
            uint PermId;
            uint pointer;
            int lowRange;
            int highRange;
            //get the bool from the permissionInstance
            int intToUse = PermListCont.getPermissionInstanceIntAtPosition(PermInstId, intPosCheck);
            //get the related PermissionTemplate ID and the position of the bool in the PermissionTemplate's boolVariables array
            (PermId,pointer, lowRange, highRange) = PermListCont.getPermissionInstanceIntPointer(PermInstId, intPosCheck);
            //get the bool in that position of the PermissionTemplate's boolVariables array
            int intToCompare = PermListCont.getPermissionTemplateInts(PermId, intPosCheck, pointer);
            //does pointer and intToCompare indicate that a range has been set? (the pointer does this by pointing at position 0, therefore if [intPosCheck][0] == 1, then a range has been set)
            if ((pointer == 0)&&(intToCompare == 1)){
                //then either any int is allowed or we have a range
                //so see if any int is allowed. We know this is true when the next two positions of the array are set to the default value 0
                if ((lowRange == 0)&&(highRange == 0)){
                    //any int is allowed
                }else if ((intToUse <lowRange)||(intToUse > highRange)){  //otherwise check ranges
                    revert();   //as not in range.
                }
            } else if (pointer == 0){
                //if pointer == 0 and intToCompare != 1, then a range has not been set so this is a possible manipulation, therefore revert
                revert();
            }
            else if (intToUse != intToCompare){   //check if the value in the permissionInstance and the value in the PermissionTemplate match
                revert();   //if they do not then this permissionInstance cannot be valid
            }

            //if we are here then the int is valid (because we have not been reverted)
            //get the address and the name of the function so that this contract can find at what position it is the PermissionManager
            address functionLocation = PermListCont.getPermissionTemplateFunctionLocation(PermId);
            string memory functionName = bytes32ToString(PermListCont.getPermissionTemplateFunctionName(PermId));
            //now set this variable as analysed
            PermListCont.setPermissionInstanceIntAnalysed(PermInstId, intPosCheck, PermissionManagerList[functionLocation][functionName]);

            
    }

    //** This function lets the owner validate the permission instance**//
	// @param PermInstID - The permissionInstance you are attempting to validate
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
    function ValidationOfPermissionInstance(uint PermInstId)  HasOwnership(PermInstId)  public {

        if (PermListCont.IsPermissionInstanceValid(PermInstId)){
              validPermission[msg.sender] = PermInstId;  //valid so ready to be executed
              emit PermissionInstanceStateChange("A user has proved that the permissionInstance is valid, thereore it has been approved for us", PermInstId);
        }else{
            revert();
        }
        
    }    

    
    //** This function allows a user to attempt to approve another permission, y clearing the data on the previous permission analysed by this user**//
    function ClearAssociatedPermissions() public {
        
        canExecute[msg.sender] = 0;
        validPermission[msg.sender] = 0;

    }
    
    //** This function allows the Permissions.sol contract to inform this contract, of what permission manager it is**//
    function SetPermissionManagerID(address contractAdd, string functionName, uint PermMangPos) public {
        
        if (msg.sender == address(PermListCont)){
            PermissionManagerList[contractAdd][functionName] = PermMangPos;    
        } else {
            revert();
        }

    }
    
    //** This function allows a smart contract to say that a permission instance has been used on one of its functions**//
    function PermissionHasBeenUsed(uint PermInstId) public {
        
        uint PermId = PermListCont.getPermissionInstanceRelatedID(PermInstId);
        //get the address and the name of the function so that this contract can find at what position it is the PermissionManager
        address functionLocation = PermListCont.getPermissionTemplateFunctionLocation(PermId);
        string memory functionName = bytes32ToString(PermListCont.getPermissionTemplateFunctionName(PermId));
        
        if (functionLocation != msg.sender){
            revert();
        }
        
        PermListCont.PermissionInstanceHasBeenUsed(PermInstId, PermissionManagerList[functionLocation][functionName]);

    }

    
    /******** End of Functions  *********/
    
    /******** Start of Getters  *********/
 

	//** Returns the owner of the contract**//
	// @returns - the address of the smart contract owner (who is the person who put this contract onto the blockchain)
	function GetOwner() constant public returns(address) {
		return Owner; 
	}	
	
	//** Returns the current permissionInstance residing in the  canExecute mapping for this caller**//
	// @returns - the Permission Instance ID
	function GetCanExecute() constant public returns(uint) {
		return canExecute[msg.sender]; 
	}	
	
	//** Returns the current permissionInstance residing in the  vvalidPermission mapping for this caller**//
	// @returns - the Permission Instance ID
	function GetValidPerm() constant public returns(uint) {
		return validPermission[msg.sender]; 
	}	
    
    //** Returns the connected Permission.sol smart contract**//
	// @returns - the associated Permission.sol address
	function GetPermListContractAdd() constant public returns(address) {
		return PermListCont; 
	}	
	
    //** Returns the connected ShareholderRights.sol smart contract**//
	// @returns - the associated ShareholderRights.sol address
	function GetShareHolderRightsContractAdd() constant public returns(address) {
		return RightsCont; 
	}	
    /******** End of Getters  *********/	
    	
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
    
}
