

pragma solidity ^0.4.21;

//** Creator = Luke Riley
//** This contract is used to check the validity of permissions that are saved in the associated permissions smart contract.
//** To do this, it allows:
//** - A user to confirm that she owns the permissions instance either directly (as the owner) or indirectly (as a member of the share classes)
//** - The ability for a user to validate a permission where she is the owner directly or indirectly


contract PermissionCheckAbstract {
    
    
    /******** Start of blockchain events *********/

	//event fires when a user has proved ownership of a permissionInstance or a user has proved that a permissionInstance is valid
	event PermissionInstanceStateChange(string explanation, uint PermInstId);
	
    /******** End of blockchain events *********/
    
    
    /******** Start of Functions  *********/
    
    //** Checks whether the function user is a owner of a permissionInstance**//
	// @param user - The user the caller is enquiring over (if the user is herself then if this user is the owner of the function, it will be put in her canExecute mapping so she can validate it)
	// @param permInstID - The permissionInstance you are enquirying over
	// @param shareClass - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
	// @returns - if the user has ownership
    function hasOwnershipOfPermissionInstance(address user, uint permInstID, bool shareClass,  uint ShareClassIdSRCont) public returns (bool);
    
    //** This function lets a owner of the permissionInstance check the validity of the next bool value in the permissionInstance**//
	// @param PermInstID - The permissionInstance you are enquirying over
	//IMPORTANT - Note that the bool values need to be checked in order, otherwise the function will revert due to a possible manipulation attempt
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
    function checkBool(uint PermInstId) public;

    //** This function lets a owner of the permissionInstance check the validity of the next bytes32 value in the permissionInstance**//
	// @param PermInstID - The permissionInstance you are enquirying over
	//IMPORTANT - Note that the bytes32 values need to be checked in order, otherwise the function will revert due to a possible manipulation attempt
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
    function checkBytes32(uint PermInstId) public;
    
    
    //** This function lets a owner of the permissionInstance check the validity of the next uint value in the permissionInstance**//
	// @param PermInstID - The permissionInstance you are enquirying over
	//IMPORTANT - Note that the uint values need to be checked in order, otherwise the function will revert due to a possible manipulation attempt
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
    function checkUint(uint PermInstId)public;
    
    //** This function lets a owner of the permissionInstance check the validity of the next int value in the permissionInstance**//
	// @param PermInstID - The permissionInstance you are enquirying over
	//IMPORTANT - Note that the int values need to be checked in order, otherwise the function will revert due to a possible manipulation attempt
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
        function checkInt(uint PermInstId) public;

    //** This function lets the owner validate the permission instance**//
	// @param PermInstID - The permissionInstance you are attempting to validate
    //IMPORTANT - The hasOwnership Modifier requires the function caller to have previously called the hasOwnershipOfPermissionInstance for the same permissionInstance
    function ValidationOfPermissionInstance(uint PermInstId)   public;

    
    //** This function allows a user to attempt to approve another permission, y clearing the data on the previous permission analysed by this user**//
    function ClearAssociatedPermissions() public;
    
    //** This function allows the Permissions.sol contract to inform this contract, of what permission manager it is**//
    function SetPermissionManagerID(address contractAdd, string functionName, uint PermMangPos) public;
    
    //** This function allows a smart contract to say that a permission instance has been used on one of its functions**//
    function PermissionHasBeenUsed(uint PermInstId) public;

    
    /******** End of Functions  *********/
    
    /******** Start of Getters  *********/
 

	//** Returns the owner of the contract**//
	// @returns - the address of the smart contract owner (who is the person who put this contract onto the blockchain)
	function GetOwner() constant public returns(address);
	
	//** Returns the current permissionInstance residing in the  canExecute mapping for this caller**//
	// @returns - the Permission Instance ID
	function GetCanExecute() constant public returns(uint);
	
	//** Returns the current permissionInstance residing in the  vvalidPermission mapping for this caller**//
	// @returns - the Permission Instance ID
	function GetValidPerm() constant public returns(uint);
    
    //** Returns the connected Permission.sol smart contract**//
	// @returns - the associated Permission.sol address
	function GetPermListContractAdd() constant public returns(address);	
	
    //** Returns the connected ShareholderRights.sol smart contract**//
	// @returns - the associated ShareholderRights.sol address
	function GetShareHolderRightsContractAdd() constant public returns(address);
    /******** End of Getters  *********/	
    	
    
}
