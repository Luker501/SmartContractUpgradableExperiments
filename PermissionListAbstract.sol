//Solidity online complier: https://remix.ethereum.org/

pragma solidity ^0.4.20;


//** Creator = Luke Riley
//** This contract can be used as a permission based system for smart contract functions.
//** To do this, it details:
//**    - which functions have permissions (detailed through the FunctionList mapping of FunctionPermission classes). These are created by the contract owner (who is the contract creator)
//**    - who controls the permissions of each function (detailed through the PermissionManagers mapping in the FunctionPermission class). These are created by the contract owner or other PermissionManagers.
//**    - what can be a valid permission for each function (detailed through the PermissionTemplate class of the PermissionsAvailable mapping). These are created by the PermissionManagers.
//**    - Who can use a permission (detailed by the PermissionInstance class of the PermissionInstances mapping). These can be created by anyone but must be approved by a permission manager.

contract PermissionListAbstract {

 
	//Notes the status of a permission to prevent manipulations
	enum PermissionStatus {None,Created,Ongoing,Revoked}
	//Notes the class type encoded by the bytes32
	enum Bytes32Type {Bytes32, String, Address, Other} //NOTE - ALLOW THIS TO BE EXTENDABLE IN THE FUTURE?

    /******** Start of blockchain events *********/
	
	//event fires when the contract has been added to the blockchain
	
	//needs events for:

	//event fires when there have been major changes to a FunctionPermission
	event FunctionPermissionEvent(string explanation, address functionAddress, string functionName);
	
    //event fires when there has been major changes to a permissionTemplate
	event PermissionTemplateStatusEvent(address functionAddress, string functionLocation, uint PermTemplateID);
	
	//NOTE - I would of had more events but solidity was complaining if I had more than 6 parameters in all of my events! Strange!

    /******** End of blockchain events *********/
    

	/******** Start of Functions  *********/
	
	//** This function allows the contract owner to set the smart contract responsible for checking the permissioned saved in this contract **//
	//IMPORTANT - note that if this is changed, the old PermCheckCont smart contract will still be set as a permission manager of FunctionPermissions previously initialised
	function connectAPermissionCheckCont(address PermCheckAdd) public;

	//** Allows the smart contract owner to create details on a new function that will be protected by permissions described in this contract **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param permissionManager - an address that will be able to create Permissiontemplates for this function
	function createFunctionPermission (address functionLocation, string functionName, address permissionManager) public;


	//** Allows a permission manager of a function to add a new permissionManager to the same function **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param newPermissionManager - a new address that will be able to create Permissiontemplates for this function
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping for thing function. Meaning only current permission managers can call this function.
	function addPermissionManager (address functionLocation, string functionName, address newPermissionManager, uint myAddressLocation) public;


	//** Allows a permission manager of a function to remove another permissionManager from the same function **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param removeFromLocation - the PermissionManager array location to remove
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
	function removePermissionManager (address functionLocation, string functionName, uint removeFromLocation, uint myAddressLocation) public ;


	//** Allows a permission manager to revoke all associated permissions of this function **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
	function RevokeAllFunctionPermission(address functionLocation, string functionName, uint myAddressLocation) public;

	//** Allows a permission manager to create a new PermissionTemplate **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param start - the block number when this PermissionTemplate starts being valid
    // @param end - the block number when this PermissionTemplate stops being valid
	// @returns - the id number of this new PermissionTemplate	
	function createPermissionTemplate(address functionLocation, string functionName, uint myAddressLocation,uint40 start, uint40 end) public returns(uint);


	//** Allows a permission manager to move the status of the PermissionTemplate forward (from created -> ongoing -> revoked) but NEVER backwards **//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to edit the status of
	// @param newStatus - the new status for the PermissionTemplate.	
	function ChangePermissionTemplateStatus(uint myAddressLocation, uint PermID, PermissionStatus newStatus) public;
	


	//** Allows a PermissionManager to add bools to the PermissionTemplate definition.  **//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to add allowable bools to
	// @param boolId - Which boolean variable of the PermissionTemplate to add the following bool options too
	// @param bool1 - The first allowed bool value for this bool variable
	// @param bool2 - The second allowed bool value for this bool variable
	// IMPORTANT NOTE due to two options only (T & F), if only one is allowed (e.g. T), then you need to pass true through to both bool1 and bool2
	function addBooleansToPermissionTemplate(uint myAddressLocation, uint PermID, uint boolId, bool bool1, bool bool2)  public;

	
	

	//** Allows a permission manager to add uints to the PermissionTemplate definition **//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to add allowable uints to
	// @param uintId - Which uint variable of the PermissionTemplate to add the following uint options too
	// @param uintIdId - Which option number for uint variable start at (you may have already added some options)
	// @param validUints - The set of valid uints that you want to add to the PermissionTemplate
	// IMPORTANT NOTE depending on how often this is used, the 5 variable for the array can be highered or lowered. If this occurs REMEMBER to change the 5 number in the for loop
	// IMPORTANT NOTE if the PermissionManager has less than the array number of validUints to add, then the PermissionManager should leave empty spots at the end of the array with 0 in them.
	function addUintsToPermissionTemplate(uint myAddressLocation, uint PermID, uint uintId, uint uintIdId, uint[5] validUints)  public;


	//** Allows a permission manager to add ints to the PermissionTemplate definition **//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to add allowable ints to
	// @param intId - Which int variable of the PermissionTemplate to add the following int options too
	// @param intIdId - Which option number for int variable start at (you may have already added some options)
	// @param validInts - The set of valid ints that you want to add to the PermissionTemplate
	// IMPORTANT NOTE depending on how often this is used, the 5 variable can be for the array highered or lowered. If this occurs REMEMBER to change the 5 number in the for loop
	// IMPORTANT NOTE if the PermissionManager has less than the array number of validInts to add, then the PermissionManager should leave empty spots at the end of the array with 0 in them.
	function addIntsToPermissionTemplate(uint myAddressLocation, uint PermID, uint intId, uint intIdId, int[5] validInts)  public;

	//** Allows a permission manager to add bytes32 to the PermissionTemplate definition (where bytes32 could of been packed from any data type, e.g. string, address, class)**//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to add allowable bytes32 to
	// @param bytes32Id - Which bytes32 variable of the PermissionTemplate to add the following bytes32 options too
	// @param bytes32IdId - Which option number for bytes32 variable start at (you may have already added some options)
	// @param validbytes32 - The set of valid bytes32 that you want to add to the PermissionTemplate
	// IMPORTANT NOTE depending on how often this is used, the 5 variable can be for the array highered or lowered. If this occurs REMEMBER to change the 5 number in the for loop
	// IMPORTANT NOTE if the PermissionManager has less than the array number of validBytes32 to add, then the PermissionManager should leave empty spots at the end of the array with 0 in them.
	function addBytes32ToPermissionTemplate(uint myAddressLocation, uint PermID, uint bytes32Id, uint bytes32IdId, bytes32[5] validBytes32)  public;


	//** Allows anyone to create a PermissionInstance in an attempt to get it approved by a PermissionManager**//
	// @param relatedPermID - the ID of the PermissionTemplate that this PermissionInstance is related too - this must be valid otherwise it is a possible manipulation attempt
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param owner - The nominated individual address to have this permission assigned to.
    // @param shareClassOwner - The nominated shareClass who will have control of this permission  
	// @returns - the id number of this new PermissionInstance	
	function createPermissionInstance(uint relatedPermID, address functionLocation, string functionName, address owner, uint shareClassOwner) public returns(uint);
	
	//** Allows the owner of the permission to set the maximum number of times in can be used - within the time limits set in the Permission Template**//
	// @param PermInstId - the ID of the permission instance you want to change
	// @numberOfTimes - the number of times that the permission instance can be used.
	function changeNumberOfPermissionUses(uint PermInstId, uint numberOfTimes) public;

	
	//** Allows the PermissionInstance creator to add bools to it**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to add this bool too
	// @param ParamId - which bool parameter for the permission function that bool1 will be used for.
	// @param boolPointer - the pointers to what part of the corresponding PermissionTemplate the passed through bools link to   
    // @param bool1 - the bool value the creator of this PermissionInstance wants permission to run  
	function addbooleansToPermissionInstance(uint PermInstId, uint ParamId, uint boolPointer, bool bool1) public;

	//** Allows the PermissionInstance creator to add uints to it**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to add this uint too
	// @param ParamId - which uint parameter for the permission function that uint1 will be used for.
	// @param uintPointer - the pointers to what part of the corresponding PermissionTemplate the passed through uint link to   
    // @param uint1 - the uint value the creator of this PermissionInstance wants permission to run  
	function adduintsToPermissionInstance(uint PermInstID, uint ParamId, uint uintPointer,uint uint1) public;

	//** Allows the PermissionInstance creator to add ints to it**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to add this int too
	// @param ParamId - which int parameter for the permission function that int1 will be used for.
	// @param intPointer - the pointers to what part of the corresponding PermissionTemplate the passed through int link to   
    // @param int1 - the int value the creator of this PermissionInstance wants permission to run 
	function addintsToPermissionInstance(uint PermInstID,  uint ParamId, uint intPointer,  int int1) public;

	//** Allows the PermissionInstance creator to add bytes32 to it**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to add this bytes32 too
	// @param ParamId - which bytes32 parameter for the permission function that bytes321 will be used for.
	// @param bytes32Pointer - the pointers to what part of the corresponding PermissionTemplate the passed through bytes32 link to   
    // @param bytes321 - the bytes32 value the creator of this PermissionInstance wants permission to run 
    // @param bytes32Type - that bytes32 type (e.g. bytes32, address, string,...). Used so that others can decode the bytes into their correct class 
	function addbytes32ToPermissionInstance(uint PermInstID,  uint ParamId, uint bytes32Pointer, bytes32 bytes321, Bytes32Type bytes32Type) public;


	//** Allows a PermissionManager to approve a PermissionInstance**//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve
	function approvePermissionInstance (uint myAddressLocation, uint PermInstID) public;

    //** Allows a PermissionManager to approve a bool value in a PermissionInstance**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve the bool of
	// @param pos - the position of the bool that the PermissionManager wants to approve
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // IMPORTANT: Note that the bools of this PermissionInstance must be checked in order, i.e. the bool at position PermissionInstance[x].boolsToUse[Y] must be analysedand approved before the bool at position PermissionInstance[x].boolsToUse[Y+1]
	function setPermissionInstanceBoolAnalysed(uint PermInstID, uint pos, uint myAddressLocation)  public;
	
    //** Allows a PermissionManager to approve a int value in a PermissionInstance**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve the int of
	// @param pos - the position of the int that the PermissionManager wants to approve
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // IMPORTANT: Note that the ints of this PermissionInstance must be checked in order, i.e. the bool at position PermissionInstance[x].intsToUse[Y] must be analysedand approved before the bool at position PermissionInstance[x].intsToUse[Y+1]
	function setPermissionInstanceIntAnalysed(uint PermInstID, uint pos, uint myAddressLocation) public;
	
    //** Allows a PermissionManager to approve an uint value in a PermissionInstance**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve the uint of
	// @param pos - the position of the uint that the PermissionManager wants to approve
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // IMPORTANT: Note that the uints of this PermissionInstance must be checked in order, i.e. the uint at position PermissionInstance[x].uintsToUse[Y] must be analysedand approved before the uint at position PermissionInstance[x].uintsToUse[Y+1]
	function setPermissionInstanceUintAnalysed(uint PermInstID, uint pos, uint myAddressLocation) public;
	
    //** Allows a PermissionManager to approve a Bytes32 value in a PermissionInstance**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve the Bytes32 of
	// @param pos - the position of the Bytes32 that the PermissionManager wants to approve
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // IMPORTANT: Note that the Bytes32 of this PermissionInstance must be checked in order, i.e. the Bytes32 at position PermissionInstance[x].Bytes32ToUse[Y] must be analysedand approved before the Bytes32 at position PermissionInstance[x].Bytes32ToUse[Y+1]
	function setPermissionInstanceBytes32Analysed(uint PermInstID, uint pos, uint myAddressLocation) public;
	
    //** Allows anyone to check if any PermissionInstance is currently valid. Makes sure that: 
    //(i) the PermissionManagers have approved all of the variables in the PermissionInstance;
    //(ii) the the related PermissionTemplate is currently ongoing
    //(iii) the related FunctionPermission is active
    //(iv) the related PermissionTemplate was created after the related FunctionPermission was last made active
    //(v) that the approved variables in the PermissionInstance matches the number expected according to the PermissionTemplate
    //**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to check the validity of
	function IsPermissionInstanceValid(uint PermInstID) public view returns(bool);
	
	//**Allows a permissionManager to say that a permission instance has been used
	function PermissionInstanceHasBeenUsed(uint PermInstID, uint myAddressLocation) public;
	

	/******** End of Functions  *********/    
	
	/******** Start of Getters  *********/
	
	//** Returns the owner of the contract**//
	// @returns - the address of the smart contract owner (who is the person who put this contract onto the blockchain)
	function GetOwner() constant public returns(address);
	
	//** Returns the location of the PermissionCheck smart contract**//
	// @returns - the address of the smart contract
	function GetPermissionCheckContr() constant public returns(address) ;
	
	function GetMaxNumberOfPermissionTemplates() constant external returns(uint);
	
		
	function GetMaxNumberOfPermissionInstances() constant external returns(uint);

    //**********START OF FUNCTIONPERMISSION LEVEL GETTERS**********/

	//** Returns the number of PermissionManagers for a certain function**//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that you are enquirying over
	// @returns - the number of PermissionManagers
	function getNumOfFunctionPermManagers(address functionLocation, string functionName) constant public returns(uint);

	//** Returns a certain PermissionManager for a certain function**//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that you are enquirying over
	// @param id - the id of the PermissionManager that you are enquirying over
	// @returns - the address of PermissionManager
	function getFunctionPermissionManager(address functionLocation, string functionName, uint id) constant public returns(address) ;

	//** Returns the block number that the FunctionPermission was last activated on**//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that you are enquirying over
	// @returns - the block number
	function getFunctionPermissionActiveFromBlock(string functionName, address functionLocation) constant public returns(uint);

	//** Returns if the FunctionPermission is currently active**//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that you are enquirying over
	// @returns - whether this function is active or not
	function IsFunctionPermissionActive(string functionName, address functionLocation) constant public returns(bool);


    //**********END OF FUNCTIONPERMISSION LEVEL GETTERS**********/

    //**********START OF PERMISSIONTEMPLATE LEVEL GETTERS**********/

	//** Returns the PermissionTemplate status (created, ongoing, revoked)**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - whether this function is active or not
	function getPermissionTemplateStatus( uint PermId) constant public returns(uint);

	//** Returns the possible bool values for a certain bool variable in a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @param boolID - The bool variable number that you are enquirying over
	// @returns - the possible bool values for boolID
	function getPermissionTemplateBooleans(uint PermId, uint boolID) constant public returns(bool[2]);

	//** Returns a possible uint value for a certain uint variable in a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @param uintID - The uint variable number that you are enquirying over
	// @param uintOption - The number of a particular uint value for uintID 
	// @returns - this possible uint value
	function getPermissionTemplateUints(uint PermId, uint uintID, uint uintOption) constant public returns(uint);

	//** Returns a possible int value for a certain int variable in a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @param intID - The int variable number that you are enquirying over
	// @param intOption - The number of a particular int value for intID 
	// @returns - this possible int value
	function getPermissionTemplateInts(uint PermId, uint intID, uint intOption) constant public returns(int);
	
	//** Returns a possible bytes32 value for a certain bytes32 variable in a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @param bytes32ID - The bytes32 variable number that you are enquirying over
	// @param bytes32Option - The number of a particular bytes32 value for bytes32ID 
	// @returns - this possible bytes32 value
	function getPermissionTemplateBytes32( uint PermId, uint bytes32ID, uint bytes32Option) constant public returns(bytes32);
	
	//** Returns the function name of a  PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - the function name	
	function getPermissionTemplateFunctionName(uint PermId) constant public returns(bytes32);

	//** Returns the address of where the function of a PermissionTemplate is located**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - the address
	function getPermissionTemplateFunctionLocation(uint PermId) constant public returns(address);


	//** Returns the block start time of a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - the starting block number	
	function getPermissionTemplateStartTime(uint PermId) constant public returns(uint40);

	//** Returns the block end time of a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - the ending block number	
	function getPermissionTemplateEndTime(uint PermId) constant public returns(uint40) ;
	
	function getTotalPermissionTemplateParameters(uint PermId) constant external returns(uint,uint,uint,uint);

    function getTotalPermissionInstanceParameters(uint PermInstId) constant external returns(uint,uint,uint,uint);

    //**********END OF PERMISSIONTEMPLATE LEVEL GETTERS**********/

    //**********START OF PERMISSIONINSTANCE LEVEL GETTERS**********/

	//** Returns the owner of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the owner's address
	function getPermissionInstanceOwner(uint PermInstId) constant public returns(address);
	
	//** Returns the share class owner of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the share class id according to the related company definition contract
	function getPermissionInstanceShareClass(uint PermInstId) constant public returns(uint);

	//** Returns if a permissionInstance is approved**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - if it is approved
	function isPermissionInstanceApproved(uint PermInstId) constant public returns(bool);

	//** Returns the ID of the related PermissionTemplate of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the PermissionTemplate ID
	function getPermissionInstanceRelatedID(uint PermInstId) constant public returns(uint);

	//** Returns the bool value at a certain position of the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The bool position you are enquirying over
	// @returns - the bool value
	function getPermissionInstanceBoolAtPosition(uint PermInstId, uint pos) constant public returns(bool);
	
	//** Returns the int value at a certain position of the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The int position you are enquirying over
	// @returns - the int value
	function getPermissionInstanceIntAtPosition(uint PermInstId, uint pos) constant public returns(int);

	//** Returns the uint value at a certain position of the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The uint position you are enquirying over
	// @returns - the uint value
	function getPermissionInstanceUintAtPosition(uint PermInstId, uint pos) constant public returns(uint);

	//** Returns the Bytes32 value at a certain position of the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The Bytes32 position you are enquirying over
	// @returns - the Bytes32 value
	function getPermissionInstanceBytes32AtPosition(uint PermInstId, uint pos) constant public returns(bytes32);
	
	//** Returns the ID of the related PermissionTemplate and a pointer to corresponding part of the bool array of the PermissionTemplate, from the requested position of the bool array in the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The Bytes32 position you are enquirying over
	// @returns - (the id of the related PermissionTemplate, and the pointer)
	function getPermissionInstanceBoolPointer(uint PermInstId, uint pos) constant public returns(uint, uint);
	
	//** Returns - the ID of the related PermissionTemplate, a pointer to corresponding part of the int array of the PermissionTemplate, the possible lower range acceptable int value and the possible upper range acceptable int value - from the requested position of the int array in the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The int position you are enquirying over
	// @returns - (the id of the related PermissionTemplate, the pointer, possible low range, possible high range)
	// IMPORTANT - the low and high range should only be considered if the pointer is set to 0.
	function getPermissionInstanceIntPointer(uint PermInstId, uint pos) constant public returns(uint, uint, int, int);
	
	//** Returns - the ID of the related PermissionTemplate, a pointer to corresponding part of the uint array of the PermissionTemplate, the possible lower range acceptable uint value and the possible upper range acceptable uint value - from the requested position of the uint array in the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The uint position you are enquirying over
	// @returns - (the id of the related PermissionTemplate, the pointer, possible low range, possible high range)
	// IMPORTANT - the low and high range should only be considered if the pointer is set to 0.
	function getPermissionInstanceUintPointer(uint PermInstId, uint pos) constant public returns(uint, uint, uint, uint);
	
	//** Returns the ID of the related PermissionTemplate and a pointer to corresponding part of the byte32 array of the PermissionTemplate, from the requested position of the bytes32 array in the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The Bytes32 position you are enquirying over
	// @returns - (the id of the related PermissionTemplate, and the pointer)
	function getPermissionInstanceBytes32Pointer(uint PermInstId, uint pos) constant public returns(uint, uint);
	
	//** Returns the analysed count of the bool array of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the analysed count
	function getPermissionInstanceBoolAnalysed(uint PermInstId) constant public returns(uint);
	
	//** Returns the analysed count of the int array of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the analysed count
	function getPermissionInstanceIntAnalysed(uint PermInstId) constant public returns(uint);
	
	//** Returns the analysed count of the uint array of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the analysed count
	function getPermissionInstanceUintAnalysed(uint PermInstId) constant public returns(uint);
	
	//** Returns the analysed count of the byte32 array of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the analysed count
	function getPermissionInstanceBytes32Analysed(uint PermInstId) constant public returns(uint);
	
	function hasPermissionInstanceExpired(uint PermInstId)  public returns(bool);
	
	    //**********END OF PERMISSIONINSTANCE LEVEL GETTERS**********/


	/******** End of Getters  *********/
    


}
	

     
