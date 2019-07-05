//Solidity online complier: https://remix.ethereum.org/

import "browser/CompanyDefinition.sol";
import "browser/PermissionCheck.sol";
pragma solidity ^0.4.20;


//** Creator = Luke Riley
//** This contract can be used as a permission based system for smart contract functions.
//** To do this, it details:
//**    - which functions have permissions (detailed through the FunctionList mapping of FunctionPermission classes). These are created by the contract owner (who is the contract creator)
//**    - who controls the permissions of each function (detailed through the PermissionManagers mapping in the FunctionPermission class). These are created by the contract owner or other PermissionManagers.
//**    - what can be a valid permission for each function (detailed through the PermissionTemplate class of the PermissionsAvailable mapping). These are created by the PermissionManagers.
//**    - Who can use a permission (detailed by the PermissionInstance class of the PermissionInstances mapping). These can be created by anyone but must be approved by a permission manager.

contract PermissionList {


    //holds the address of the contract creator
	address private Owner;
	//holds the address of the associated CompanyDefinition.sol contract. This is to hold an explicit link to the share classes that can 
	//be given permissions
	ComDef ComDefCont;	
	//holds the address of the associated PermissionCheck.sol contract. This contract checks the validity of the permissions held in this contract
	PermissionCheck PermCheckCont;	
	//keeps track of which functions in what smart contracts are protected by permissions (using a class called FunctionPermission) 
	mapping (address => mapping (string => FunctionPermission)) private functionList;	
	//keeps track of the different types of permissions available for the protected functions (using a class called Permission)
	mapping (uint => PermissionTemplate) private PermissionsAvailable;		
	//Keeps track of the number of Permission templates available. The count starts at 1 as 0 will be used for error checking
	uint private PermAvailCount = 1; 
	//keeps track of the instances of an attempt to use a permission (using a class called UsePermission)
	mapping (uint => PermissionInstance)	private permissionInstances;	
	//Keeps track of the number of Permission instances available. The count starts at 1 as 0 will be used for error checking
	uint private permInstCount = 1; 
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
    
    //constructs the class - sets the owner as the address that put the contract on the blockchain
    //Also links to the CompanyDefinition contract at the beginning
    constructor (address ComDefAdd) public{
        if (ComDefAdd!=address(0x0)){
            
            Owner = msg.sender;
            ComDefCont = ComDef(ComDefAdd);

        } else {
           
           revert();
           
        }
    }
    
    /******** Start of Structures *********/

    //** A class that maps an address and function to information on whether this address and function has been setup to be protected by permissions
    // (see the revoked and initialised variables). If this function has been setup for permissions, then the PermissionManagers detail who can: 
    // (i) add new permission types for this function (in the form of the Permission class); and (ii) approve or disapprove instances of these permissions
    // that have been requested by other addresses (in the form of the usePermission class).
	struct FunctionPermission {

        //permissionManager(s) for this function - any one of the addresses listed here can approve permission requests associated with this smart contract function
		mapping (uint => address) PermissionManagers;			
		//Keeps track of the next available free position in the PermissionManagers mapping to place another address
		uint PermManagersCount;
		//this indicates when this version of the permission became active, This allows all related PermissionTemplates (and associated permissionInstances) to be revoked and stay revoked, even if the FunctionPermission is made active again.
		uint ActiveFromBlock;	
		//this is used to make sure that we do not reinstaniate an active FunctionPermission instance
		bool Active;						

	}

    
    //** A class that defines what a permission is for a particular smart contract's function. (There can be many different permissions for the 
    // same smart contract function, which are possibly assigned to different groups of people.)
    //A class of this type can only be created by the permissionManager of the related FunctionPermission class
	struct PermissionTemplate {
		//This is the start time of the permission that has to be >= ActiveFromBlock
		uint40 startTime; 
		//This is the start time of the permission, which also has to be >= ActiveFromBlock
		uint40 endTime; 							//What is the end time of this permission
		//This is the address of the smart contract that has the function that will be wrapped in permissions
		address functionLocation;
		//This is the name of the function that will be wrapped in permissions at the functionLocation address
		string functionName;
		//this indicates when this version of the permission became active - it must be greater than the value in the corresponding FunctionPermission class to work. This allows all related PermissionTemplates (and associated permissionInstances) to be revoked and stay revoked when a FunctionPermission is set to inactive, even if the FunctionPermission is made active again. This is more efficient than performing a search through the mapping and individually revoking each permission
		uint ActiveFromBlock;
		
		//Now the following is where we outline the valid parameters in this Permission Template.
		//The function that this Permission Template relates to, has a certain number of parameters of the following types: bool, int, uint, bytes32 (where bytes32 can be mapped onto address, string,...etc)
		// But each parameter in the function could have a few valid inputs, hence why we have a 2D array
		// the values at bytes32Variables[Y][1] to bytes32Variables[Y][X] (where bytes32Variables[Y][X] is the first default bytes32 value since [Y][1]) detail all the possible explict bytes32 parameters that can be passed to the Y'th non bool,non int or non uint variable of the function
		// if the default value of bytes32 is a valid parameter for variable Y of this function, it must be declared at position [Y][1] only and [Y][0] must be set NOT to the default bytes32 value
		// if any values are allowed then [Y][0] and [Y][1] must both be set to default
		// Note that NOT logic is not implemented, as in theory it would require a search over a dynamic run time number of explicit values which could cause errors
	    // For ints or uints:
		// If uintVariables[Y][1] is the default value (0) and uintVariables[Y][0] is not the default value, then the default value is an explicit allowed parameter of the Y'th variable 
        // If uintVariables[Y][0] is set to 1, that means a range has been set. 
        // If uintVariables[Y][1] and uintVariables[Y][0] are set to the default value (0), then any value is allowed for this Y'th value
		// If uintVariables[Y][0] is being pointed to by the Permission Instance (see below) then we know that:
		// if uintVariables[Y][1] and uintVariables[Y][2] hold different values then a lower and upper range has been set respectively (but always perform a check to confirm [0][1] is less than [0][2] otherwise runtime errors can occur)
		// if uintVariables[Y][0], uintVariables[Y][1] and uintVariables[Y][2] are all zeros then any uint is allowed
		// if uintVariables[Y][1] and uintVariables[Y][2] are both zeros but uintVariables[Y][0] is not then only 0 is the allowed value of this function
		// if uintVariables[Y][1] is a zero but uintVariables[Y][2] are both zeros but uintVariables[Y][0] is not then only 0 is the allowed value of this function
        //Regarding the boolVariables, as there are only two options, if you put [T,T] then only T is allowed (resp F), otherwise if any combination of T and F is stated then either is allowed
		
		//ROADMAP for adding NOT -> pick a value to represent NOT for each type. For parameter Y, if [Y][0] is set to the default NOT value then NOT logic is used. Note that this means every parameter being checked in permissionCheck smart contract needs to check for the NOT logic first
		//ROADMAP for the user to not have to declare the correct variables initially when asking for permission. PermissionCheck (or related contract) has a function(s) that takes a permission templateID and two permissionInstances. The first permInst needs to give the caller access to this function. Then the owner of the second permissionInstance must also be the caller of this function, then the function should check all the params are within range of the related PermTemplate and if so it will automatically approve the second permissionInstance
        //ROADMAP for adding longer bytes than bytes32. In this case, [Y][0] can denote how many bytes32 are grouped together, e.g. if [Y][0] = 2, then [Y][1] and [Y][2] can be combined to make 
		
		//What bool variables can be used for each bool variable of the related function
		mapping (uint => bool[2]) boolVariables;			
		//What uint variables can be used for each uint variable of the related function
		mapping (uint => mapping (uint => uint)) uintVariables;				
		//What int variables can be used for each int variable of the related function
		mapping (uint => mapping (uint => int)) intVariables;
		//What bytes32 variables can be used for each bytes32 variable of the related function
		mapping (uint => mapping (uint => bytes32)) bytes32Variables;	
		//What is the current status of this permission (created, ongoing, revoked)
		//A permission can only be used when it is in the ongoing state
		//A permission can only be added too when it is in the created state
		PermissionStatus Status;						
        //records the number of different bools added to this permission template
		uint boolsCount;
        //records the number of different uints added to this permission template
		uint uintsCount;
		//records the number of different ints added to this permission template
        uint intsCount;
        //records the number of different bytes32 added to this permission template
        uint bytes32Count;
	}
	
	//This is a request to use one of the Permissions outlined by a permission manager.
	//Anyone can create one of these classes
	//The requestor can then detail what parameters of each type they want to use and provide a pointer link to a part of the PermissionTemplate that shows this variable is valid
	// - note that if they point at TypeVariables[X][0] the requestor is pointing to a range detailed in TypeVariables[X][1] and TypeVariables[X][2]. Note that the PermissionCheck smart contract will have to check that [X][1] and [X][2] are different values
	// - note that if the requestor wants to use the type default value, the only place that is valid to point at is at TypeVariable[X][1]. If this occurs, the PermissionCheck smart contract needs to confirm that TypeVariable[X][0] != default value - which indicates the default value has been explicitly denoted
    // - note that if the requestor wants to use any value, the only place that is valid to point at is TypeVariable[X][1]. If this occurs, TypeVariable[X][1] must be equal to the default value and TypeVariable[X][0] must ALSO be equal to the default value. 	
	struct PermissionInstance {

        //the explicity Permission instance this relates too
		uint relatedPermissionID; 
		//The individual address that can run this function
		//(NOTE I HAVE NOT DONE A MAPPING OF POSSIBLE OWNERS BECAUSE IT WOULD BE VERY COMP INTENSIVE TO CHECK)
        address Owner;
        //Or the individual share class that can run this function, according to the array numbers of the linked company definition smart contract
        uint ShareClassOwner;    
        //the approved PermissionManager's ID
        uint approvedPM;
        //now we list the explicit parameters that the requestor would like to have a permission to execute (or a range of parameters, or full access for that parameter)
        //we use the Pointer class to have consistency between all type mappings 
		//The count pointers are used to keep track of how many variables are in the mappings. 
		//An external contract will not be able to access parts of the mapping that are higher than the counts
		//The Analysed counts are used to keep track of the check variables in this usePermission instance. The analysedCounts are reset if the related Permission is found changed it's status
		mapping (uint => Pointer) boolsToUse;
		uint boolsCount;
        uint boolsAnalysed;
		mapping (uint => Pointer) uintsToUse;
		uint uintsCount;
        uint uintsAnalysed; 
		mapping (uint => Pointer) intsToUse;
		uint intsCount;
        uint intsAnalysed; 
		mapping (uint => Pointer) bytes32ToUse;
		uint bytes32Count;
        uint bytes32Analysed; 
        //how many uses this permission instance will be allowed for
        uint numberOfUses;
        //If this permission has been approved for use by a permission manager for the related function
		bool approvedForUse;    

	}
	
	
	//A generic pointer to connect the PermissionInstance to certain parts of a PermissionTemplate to indicate 
	//what exact parts of the PermissionTemplate this user is requesting to have access to.
	struct Pointer {

        //This pointer will placed in the toUse mappings of a PermissionInstance class
        
        //points to where in the permissionTemplate, the requestors belives should give him permission to use one of the following variables
        uint realPointer;
        //If this Pointer is in boolsToUse, then this will be filled in
        bool realBool;
        //If this Pointer is in uintsToUse, then this will be filled in
        uint realUint;
        //If this Pointer is in intsToUse, then this will be filled in
        int realInt;
        //If this Pointer is in bytes32ToUse, then this will be filled in
        bytes32 realBytes32;
        //If this Pointer is in bytesToUse, then the real type will be indicated by the following
        Bytes32Type bytes32Type;

	}
	
	//**PROTOCOL notes:
	// Owner creates a functionPermission
	// Owner can assign others to be a permissionManager of this function
	// A PermissionManager can create a PermissionTemplate for this function
	// Any one (known as the PermissionRequestor) can use these PermissionTemplates to create a PermissionInstance for this function
	// A permissionManager is required to check this PermissionInstance to make sure the variables are within the bounds of the PermissionTemplates
	// Once checked, a PermissionManager needs to decide whether to approve this PermissionInstance for use
	// The PermissionRequestor can use the PermissionInstance before the endTime of it (the endTime condition needs to be checked in the contract of the corresponding function)
    
    //POSSIBLE MANIPULATION ATTEMPTS -> WHAT I HAVE DONE TO STOP THEM:
    //  - Use the PermissionTemplate before it is completed -> cannot do this as the PermissionTemplate has a status, one for editing (created) and one for using (ongoing).
    //  - The Requestor attempts to create a PermissionInstance using a Permissiontemplate not assocated to the function she wants to call -> The ID of the linked PermissionTemplate is viewable in the the PermissionInstance. It is therefore up to the PermissionManager to check that these correctly match before approving the PermissionInstance
    //  - Someone who is not a PermissionManager can add to a PermissionTemplate -> This is impossible because of the uint myAddressLocation variable that the caller of all functions to modify the Permission Template must provide. It needs to link to the ID of this user in the PermissionManager array otherwise the function will revert
    //  - Requestor can add variables that are not in the Permissiontemplate -> this is the job of a PermissionManager to catch, they are in this position because presumably the contract owner thinks they are reliable     
    //  - A PermissionManager does not check all variables -> (see previous response). Also a PermissionManager is forced to approve one-by-one each variable. A permission manager is only allowed to approve the PermissionInstance once she has approved each individual variable
    //  - The Requestor can attempt to use the PermissionInstance after its endTime -> the responsibility is moved to the smart contract detailing the function protected by the permission - the smart contract should check the timings just before execution
    //  - The Requestor attempts to create a PermissionInstance based on a Permissiontemplate that has been revoked -> Then the permissionManager will not be able to approve the PermissionInstance due to the Permissiontemplate not being in the Ongoing state ((Perm.Status == PermissionStatus.Ongoing)) 
    //  - The Requestor attempts to use a PermissionInstance of a Permissiontemplate of a FunctionPermission that is currently in the revoked state -> Then the permissionManager will not be able to approve the PermissionInstance due to the FunctionPermission's Active bool being set equal to false
    //  - A user attempts to approve a PermissionInstance where she is not an associated PermissionManager -> impossible according to the approvePermissionInstance function that requires the PermissionInstance ID and then links back to the correct FunctionPermission to make sure the sender is a PermissionManager
    //  - A user attempts to add to a PermissionInstance where she is not the PermissionInstance creator -> impossible according to the ifPermissionInstanceOwnerAnyNotApproved modifiers attached to all functions that add new variables to the PermissionInstance
    //  - An old PermissionManager (before the FunctionPermission was reset) attempts to make PermissionManager level edits -> impossible as every function that requires the potential PermissionManager to pass in its ID (as mmyAddressLocation) has a check to make sure that (myAddressLocation < PermManagersCount), where PermManagersCount is reset when a FunctionPermission is reinitialised
    //  - The Requestor attempts to get a PermissionInstance approved when the related FunctionPermission is cancelled -> cannot happen as FunctionPermission.Active == true is required for approved
    //  - The requestor gets a PermissionInstance approved - then either the related Permissiontemplate or FunctionPermission is cancelled but the requestor still attempts to use the PermissionInstance -> it is on the contract where the related function is kept to check it is still valid, this contract provides the IsPermissionInstanceValid function for other contracts to have real time checks
    //  - attacker trys to modify a Permissiontemplate before it has been created -> always check that the Permissiontemplate ID is a valid one, when someone is attempting to modify a permissionTemplate
    //  - attacker trys to change a permissionInstance after it is approved -> added a check to make sure that no variables can be added to the PermissionInstance after approval. Also note that a PM needs to analyse all parameters in the PI for it to be valid. Approval can only occur if the PI is valid at that specific moment of approval 
    //  - an permission instance has been validated by a permissionManager who has been removed -> added a property in the PermissionInstance that links to the approved PM, if he has been removed then it cannot be used
    //  - a user sets a permission instance intToUse or uintToUse value to point to the range indicator in the Permission Template, when no range has been set -> This attempted manipulation will be caught because the PM needs to set the range indicator to 1 to indicate a range is being displayed 
    
    //TO DO:
    // add events!
    //Also analyse for solidity style attacks and write them in possible manipulations
    // make sure that the default variables for the mapping are only read in the [0][1] position

    /******** End of Structures *********/
    
    /******** Start of modifiers *********/
	
	//** any function containing this modifier, only allows the contract owner to call it**//
	modifier ifContractOwner(){
		if(Owner != msg.sender){
		    revert();
		}else{
		    _; //means continue on the functions that called it
		}
    }
	
		//** any function containing this modifier, only allows the original permissionInstance creator to call it**//
	modifier ifPermissionInstanceOwnerAndNotApproved(uint PermInstID){
		PermissionInstance storage permInst = permissionInstances[PermInstID];
		if((permInst.Owner != msg.sender)||(permInst.approvedForUse == true)){
		    revert();
		}else{
		    _; //means continue on the functions that called it
		}
    }
    
    //** any function containing this modifier, only allows the a valid PermissionTemplate to be called**//
	modifier validPermissionTemplate(uint PermID){
		if(PermID >= PermAvailCount){
		    revert();
		}else{
		    _; //means continue on the functions that called it
		}
    }

	
	/******** End of Modifiers  *********/
	
	
	/******** Start of Functions  *********/
	
	//** This function allows the contract owner to set the smart contract responsible for checking the permissioned saved in this contract **//
	//IMPORTANT - note that if this is changed, the old PermCheckCont smart contract will still be set as a permission manager of FunctionPermissions previously initialised
	function connectAPermissionCheckCont(address PermCheckAdd) ifContractOwner public {
	
	   PermCheckCont = PermissionCheck(PermCheckAdd);

	}

	//** Allows the smart contract owner to create details on a new function that will be protected by permissions described in this contract **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param permissionManager - an address that will be able to create Permissiontemplates for this function
	function createFunctionPermission (address functionLocation, string functionName, address permissionManager) ifContractOwner public {

        //loading the related FunctionPermission
        FunctionPermission storage funPerm = functionList[functionLocation][functionName];
        //check if this is already active
		if (funPerm.Active == true) {
			//do nothing because the functionPermission has already been created
			revert();
		} else {
			//Otherwise make this active and set (or reset the PermissionManagers)
			funPerm.PermissionManagers[0] = permissionManager;
			funPerm.PermissionManagers[1] = PermCheckCont;      //check the checking contract as a permissionManager
			PermCheckCont.SetPermissionManagerID(functionLocation, functionName, 1);
			funPerm.PermManagersCount = 2;
			funPerm.ActiveFromBlock = block.number;			
			funPerm.Active = true;
            emit FunctionPermissionEvent("A new FunctionPermission has been added with two PermissionManagers", functionLocation, functionName);

		}
	}


	//** Allows a permission manager of a function to add a new permissionManager to the same function **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param newPermissionManager - a new address that will be able to create Permissiontemplates for this function
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping for thing function. Meaning only current permission managers can call this function.
	function addPermissionManager (address functionLocation, string functionName, address newPermissionManager, uint myAddressLocation) public {

        //loading the related FunctionPermission
        FunctionPermission storage funPerm = functionList[functionLocation][functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)||(funPerm.Active == false)) {
			//if an invalid myAddressLocation was given then revert. 
			//Also revert if the FunctionPermission is not active
			revert();
		} else {
			//add the address to the permission managers list
			funPerm.PermissionManagers[funPerm.PermManagersCount] = newPermissionManager;
			//increment the number of valid PermissionManagers mapping locations
			funPerm.PermManagersCount+=1;
            emit FunctionPermissionEvent("The following FunctionPermission has had a new PermissionManager added", functionLocation, functionName);

		}

	}


	//** Allows a permission manager of a function to remove another permissionManager from the same function **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param removeFromLocation - the PermissionManager array location to remove
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
	function removePermissionManager (address functionLocation, string functionName, uint removeFromLocation, uint myAddressLocation) public {

        //loading the related FunctionPermission
        FunctionPermission storage funPerm = functionList[functionLocation][functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)||(funPerm.Active == false)) {
			//if an invalid myAddressLocation was given then revert. 
			//Also revert if the FunctionPermission is not active
			revert();
		} else {
            emit FunctionPermissionEvent("The following FunctionPermission has had a PermissionManager deleted", functionLocation, functionName);
			//remove the address from the permission managers list by setting this address to be the empty one
			funPerm.PermissionManagers[removeFromLocation] = address(0x0);
			//Do NOT decrement PermManagersCount as that keeps a track of the definite next available position in the mapping to put another address in

		}

	}


	//** Allows a permission manager to revoke all associated permissions of this function **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
	function RevokeAllFunctionPermission(address functionLocation, string functionName, uint myAddressLocation) public {

        //loading the related FunctionPermission
        FunctionPermission storage funPerm = functionList[functionLocation][functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)||(funPerm.Active == false)) {
			//if an invalid myAddressLocation was given then revert. 
			//Also revert if the FunctionPermission is not active
			revert();
		} else {
			//set the FunctionPermission to not active. Note that a permissionInstance can only get approved if this is active
			funPerm.Active = false;
			emit FunctionPermissionEvent("The following FunctionPermission has now been revoked", functionLocation, functionName);
		}

	}

	//** Allows a permission manager to create a new PermissionTemplate **//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param start - the block number when this PermissionTemplate starts being valid
    // @param end - the block number when this PermissionTemplate stops being valid
	// @returns - the id number of this new PermissionTemplate	
	function createPermissionTemplate(address functionLocation, string functionName, uint myAddressLocation,uint40 start, uint40 end) public returns(uint){

        //loading the related FunctionPermission
        FunctionPermission storage funPerm = functionList[functionLocation][functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)) {
			//if an invalid myAddressLocation was given then revert. 
			revert();
		} else {
			//create a new PermissionTemplate and add it
			
			//load the next available space in the PermissionsAvailable mapping
			PermissionTemplate storage Perm = 	PermissionsAvailable[PermAvailCount];
			//Set the status to Created. I.e. we will not let people use this permission until it is fully built and move into the Ongoing status
			Perm.Status = PermissionStatus.Created; 
			//set the functionName and the functionLocation the same as what we use to load the correct FunctionPermission
		    Perm.functionName = functionName;
		    Perm.functionLocation = functionLocation;
		    //set the block numbers correctly
		   	Perm.startTime = start;
		    Perm.endTime = end;
		    //note do NOTE set the ActiveFromBlock parameter here as we will set it when the status moves into Ongoing
		    //increment the PermAvailCount, so that we are ready for the next PermissionTemplate to be created
			PermAvailCount += 1;
			//but return the counter that relates to the permission we just created
			//set all the counts to zero
			Perm.boolsCount = 0;
		    Perm.uintsCount = 0;
            Perm.intsCount = 0;
            Perm.bytes32Count = 0;
			return PermAvailCount-1;
		}

	}


	//** Allows a permission manager to move the status of the PermissionTemplate forward (from created -> ongoing -> revoked) but NEVER backwards **//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to edit the status of
	// @param newStatus - the new status for the PermissionTemplate.	
	function ChangePermissionTemplateStatus(uint myAddressLocation, uint PermID, PermissionStatus newStatus) validPermissionTemplate(PermID) public {

        //loading the required PermissionTemplate and the related FunctionPermission
        PermissionTemplate storage Perm = PermissionsAvailable[PermID];
        FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)||(funPerm.Active == false)||(funPerm.ActiveFromBlock == 0)||(newStatus <= Perm.Status)) {
			//if an invalid myAddressLocation was given then revert. 
			//Also revert if the FunctionPermission is not active
			//Also revert if the FunctionPermission has not been actived
			//Also revert if this is an attempt to set the status to a previous one
			revert();
		} else {
			//change the permission's status
			Perm.Status = newStatus;
		    emit PermissionTemplateStatusEvent(Perm.functionLocation, Perm.functionName, PermID);

		}

	}
	


	//** Allows a PermissionManager to add bools to the PermissionTemplate definition.  **//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to add allowable bools to
	// @param boolId - Which boolean variable of the PermissionTemplate to add the following bool options too
	// @param bool1 - The first allowed bool value for this bool variable
	// @param bool2 - The second allowed bool value for this bool variable
	// IMPORTANT NOTE due to two options only (T & F), if only one is allowed (e.g. T), then you need to pass true through to both bool1 and bool2
	function addBooleansToPermissionTemplate(uint myAddressLocation, uint PermID, uint boolId, bool bool1, bool bool2)  validPermissionTemplate(PermID) public {

        //loading the required PermissionTemplate and the related FunctionPermission
        PermissionTemplate storage Perm = PermissionsAvailable[PermID];
        FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)||(Perm.Status != PermissionStatus.Created)||(funPerm.Active == false)||(funPerm.ActiveFromBlock == 0)) {
			//if an invalid myAddressLocation was given then revert. 
			//Also revert if the PermissionTemplate status is not Created
			//Also revert if the FunctionPermission is not active
			//Also revert if the FunctionPermission has not been actived
			//Also revert if this is an attempt to set the status to a previous one
			revert();
		} else {
			
			//this section exists to force the user to add bools in the correct order
			if ((boolId < Perm.boolsCount)||(boolId > Perm.boolsCount + 1)) {
			    revert();
			} else if (boolId == Perm.boolsCount + 1){
			    Perm.boolsCount +=1; 
			}
			//if ok then set the allowed boolean values
			Perm.boolVariables[boolId][0] = bool1;
			Perm.boolVariables[boolId][1] = bool2;

		}

	}
	

	//** Allows a permission manager to add uints to the PermissionTemplate definition **//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to add allowable uints to
	// @param uintId - Which uint variable of the PermissionTemplate to add the following uint options too
	// @param uintIdId - Which option number for uint variable start at (you may have already added some options)
	// @param validUints - The set of valid uints that you want to add to the PermissionTemplate
	// IMPORTANT NOTE depending on how often this is used, the 5 variable for the array can be highered or lowered. If this occurs REMEMBER to change the 5 number in the for loop
	// IMPORTANT NOTE if the PermissionManager has less than the array number of validUints to add, then the PermissionManager should leave empty spots at the end of the array with 0 in them.
	function addUintsToPermissionTemplate(uint myAddressLocation, uint PermID, uint uintId, uint uintIdId, uint[5] validUints)  validPermissionTemplate(PermID) public {

        //loading the required PermissionTemplate and the related FunctionPermission
        PermissionTemplate storage Perm = PermissionsAvailable[PermID];
        FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)||((Perm.Status != PermissionStatus.Created))||(funPerm.Active == false)|| (funPerm.ActiveFromBlock == 0)) {

			//if an invalid myAddressLocation was given then revert. 
			//Also revert if the PermissionTemplate status is not Created
			//Also revert if the FunctionPermission is not active
			//Also revert if the FunctionPermission has not been actived
			//Also revert if this is an attempt to set the status to a previous one
			revert();
		} else {
		
		
			//this section exists to force the user to add uints in the correct order
			if ((uintId < Perm.uintsCount)||(uintId > Perm.uintsCount + 1)) {
			    revert();
			} else if (uintId == Perm.uintsCount + 1){
			    Perm.uintsCount +=1; 
			}
			
			//if ok then set the allowed uint values
		    for (uint8 c = 0; c < 5; c++) {
		        if ((c > 0)&&(validUints[c] == 0)){
		            //if a default value is found not in the first position then stop adding because the PermissionManager has run out of new variables to add
		            c = 5;
		        } else {
                    //start adding from the uintIdId position, just incase the PermissionManager has already added allowed variables to this uint position
    		        Perm.uintVariables[uintId][uintIdId + c] = validUints[c];
		        }
		        
		    }

		}

	}


	//** Allows a permission manager to add ints to the PermissionTemplate definition **//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to add allowable ints to
	// @param intId - Which int variable of the PermissionTemplate to add the following int options too
	// @param intIdId - Which option number for int variable start at (you may have already added some options)
	// @param validInts - The set of valid ints that you want to add to the PermissionTemplate
	// IMPORTANT NOTE depending on how often this is used, the 5 variable can be for the array highered or lowered. If this occurs REMEMBER to change the 5 number in the for loop
	// IMPORTANT NOTE if the PermissionManager has less than the array number of validInts to add, then the PermissionManager should leave empty spots at the end of the array with 0 in them.
	function addIntsToPermissionTemplate(uint myAddressLocation, uint PermID, uint intId, uint intIdId, int[5] validInts)  validPermissionTemplate(PermID) public {

        //loading the required PermissionTemplate and the related FunctionPermission
        PermissionTemplate storage Perm = PermissionsAvailable[PermID];
        FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)||(Perm.Status != PermissionStatus.Created)||(funPerm.Active == false)||(funPerm.ActiveFromBlock == 0)) {
			//if an invalid myAddressLocation was given then revert. 
			//Also revert if the PermissionTemplate status is not Created
			//Also revert if the FunctionPermission is not active
			//Also revert if the FunctionPermission has not been actived
			//Also revert if this is an attempt to set the status to a previous one
			revert();
		} else {
			
			//this section exists to force the user to add bools in the correct order
			if ((intId < Perm.intsCount)||(intId > Perm.intsCount + 1)) {
			    revert();
			} else if (intId == Perm.intsCount + 1){
			    Perm.intsCount +=1; 
			}
			
			//if ok then set the allowed int values
		    for (uint8 c = 0; c < 5; c++) {
		        if ((c > 0)&&(validInts[c] == 0)){
		            //if a default value is found not in the first position then stop adding because the PermissionManager has run out of new variables to add
		            c = 5;
		        } else {
                    //start adding from the intIdId position, just incase the PermissionManager has already added allowed variables to this int position
    		        Perm.intVariables[intId][intIdId + c] = validInts[c];
		        }
		        
		    }

		} 

	}

	//** Allows a permission manager to add bytes32 to the PermissionTemplate definition (where bytes32 could of been packed from any data type, e.g. string, address, class)**//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // @param PermID - The ID number of the PermissionTemplate that the PermissionManager wants to add allowable bytes32 to
	// @param bytes32Id - Which bytes32 variable of the PermissionTemplate to add the following bytes32 options too
	// @param bytes32IdId - Which option number for bytes32 variable start at (you may have already added some options)
	// @param validbytes32 - The set of valid bytes32 that you want to add to the PermissionTemplate
	// IMPORTANT NOTE depending on how often this is used, the 5 variable can be for the array highered or lowered. If this occurs REMEMBER to change the 5 number in the for loop
	// IMPORTANT NOTE if the PermissionManager has less than the array number of validBytes32 to add, then the PermissionManager should leave empty spots at the end of the array with 0 in them.
	function addBytes32ToPermissionTemplate(uint myAddressLocation, uint PermID, uint bytes32Id, uint bytes32IdId, bytes32 validBytes32)  validPermissionTemplate(PermID) public {

        //loading the required PermissionTemplate and the related FunctionPermission
        PermissionTemplate storage Perm = PermissionsAvailable[PermID];
        FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)||(Perm.Status != PermissionStatus.Created)||(funPerm.Active == false)||(funPerm.ActiveFromBlock == 0)) {
			//if an invalid myAddressLocation was given then revert. 
			//Also revert if the PermissionTemplate status is not Created
			//Also revert if the FunctionPermission is not active
			//Also revert if the FunctionPermission has not been actived
			//Also revert if this is an attempt to set the status to a previous one
			revert();
		} else {
			
			
			//this section exists to force the user to add bools in the correct order
			if ((bytes32Id < Perm.bytes32Count)||(bytes32Id > Perm.bytes32Count + 1)) {
			    revert();
			} else if (bytes32Id == Perm.bytes32Count + 1){
			    Perm.bytes32Count +=1; 
			}
			
			//if ok then set the allowed bytes32 values
		    for (uint8 c = 0; c < 5; c++) {
		        if ((c > 0)&&(validBytes32[c] == 0)){
		            //if a default value is found not in the first position then stop adding because the PermissionManager has run out of new variables to add
		            c = 5;
		        } else {
                    //start adding from the intIdId position, just incase the PermissionManager has already added allowed variables to this bytes32 position
    		        Perm.bytes32Variables[bytes32Id][bytes32IdId + c] = validBytes32[c];
		        }
		        
		    }

		}

	}


	//** Allows anyone to create a PermissionInstance in an attempt to get it approved by a PermissionManager**//
	// @param relatedPermID - the ID of the PermissionTemplate that this PermissionInstance is related too - this must be valid otherwise it is a possible manipulation attempt
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that requires permission controls managed by this contract
	// @param owner - The nominated individual address to have this permission assigned to.
    // @param shareClassOwner - The nominated shareClass who will have control of this permission  
	// @returns - the id number of this new PermissionInstance	
	function createPermissionInstance(uint relatedPermID, address functionLocation, string functionName, address owner, uint shareClassOwner) validPermissionTemplate(relatedPermID) public returns(uint){

        //loading the related PermissionTemplate 
        PermissionTemplate storage Perm = PermissionsAvailable[relatedPermID];	
	    if ((Perm.Status != PermissionStatus.Ongoing)||(Perm.functionLocation != functionLocation)||(keccak256(Perm.functionName) != keccak256(functionName))){
            //Revert if the related PermissionTemplate is not ongoing
            //Also revert if the PermissionTemplate we are attempting to link to does not have the same functionName and/or functionLocation
			revert();
		}
		//else create the PermissionInstance and set the variables
		PermissionInstance memory PermInst;
		PermInst.relatedPermissionID = relatedPermID;
	    PermInst.Owner = owner;
	    PermInst.ShareClassOwner = shareClassOwner;
	    PermInst.approvedForUse = false;
		//we have not set the counts of the permissionInstance because they will be defaulting to zero
		//now set the class to be in the next position of the mapping
		permissionInstances[permInstCount] = PermInst;
	    //increment the PermInstCount, so that we are ready for the next permissionInstance to be created
		permInstCount = permInstCount + 1;
		//but return the counter that relates to the permission we just created
		//set all counts to empty
		PermInst.boolsCount = 0;
        PermInst.boolsAnalysed = 0;
		PermInst.uintsCount = 0;
        PermInst.uintsAnalysed = 0; 
		PermInst.intsCount = 0;
        PermInst.intsAnalysed = 0; 
		PermInst.bytes32Count = 0;
        PermInst.bytes32Analysed = 0; 
        PermInst.numberOfUses = 0;
		return permInstCount-1;
		
	}
	
	//** Allows the owner of the permission to set the maximum number of times in can be used - within the time limits set in the Permission Template**//
	// @param PermInstId - the ID of the permission instance you want to change
	// @numberOfTimes - the number of times that the permission instance can be used.
	function changeNumberOfPermissionUses(uint PermInstId, uint numberOfTimes) ifPermissionInstanceOwnerAndNotApproved(PermInstId) public {
	    
	    //loading the related PermissionInstance
		PermissionInstance storage PermInst = permissionInstances[PermInstId];
		
		//can only change the number of times to be used, before the approval

	        PermInst.numberOfUses = numberOfTimes;

	}

	
	//** Allows the PermissionInstance creator to add bools to it**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to add this bool too
	// @param ParamId - which bool parameter for the permission function that bool1 will be used for.
	// @param boolPointer - the pointers to what part of the corresponding PermissionTemplate the passed through bools link to   
    // @param bool1 - the bool value the creator of this PermissionInstance wants permission to run  
	function addbooleansToPermissionInstance(uint PermInstId, uint ParamId, uint boolPointer, bool bool1) ifPermissionInstanceOwnerAndNotApproved(PermInstId) public {

        //loading the related PermissionInstance
		PermissionInstance storage PermInst = permissionInstances[PermInstId];
		//the if statement forces this PermissionInstance owner to add bools one after another with no gaps
		if (PermInst.boolsCount == ParamId){

            //create a Pointer object for this specific bool value use request
    		Pointer memory point;
    		//point at the part of the PermissionTemplate that you claim allows you to use the bool1 value
    		point.realPointer = boolPointer;
    		//set the bool1 value as the value you are requesting to use
    		point.realBool = bool1;
    		//now set the pointer object to the correct part of the PermissionInstance
    		PermInst.boolsToUse[ParamId] = point; 
    		//increment the counter accordingly
		    PermInst.boolsCount +=1;

		}
	}

	//** Allows the PermissionInstance creator to add uints to it**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to add this uint too
	// @param ParamId - which uint parameter for the permission function that uint1 will be used for.
	// @param uintPointer - the pointers to what part of the corresponding PermissionTemplate the passed through uint link to   
    // @param uint1 - the uint value the creator of this PermissionInstance wants permission to run  
	function adduintsToPermissionInstance(uint PermInstID, uint ParamId, uint uintPointer,uint uint1) ifPermissionInstanceOwnerAndNotApproved(PermInstID) public {

        //loading the related PermissionInstance
		PermissionInstance storage PermInst = permissionInstances[PermInstID];
		//the if statement forces this PermissionInstance owner to add uints one after another with no gaps
		if (PermInst.uintsCount == ParamId){
            
            //create a Pointer object for this specific uint value use request
    		Pointer memory point;
    		//point at the part of the PermissionTemplate that you claim allows you to use the uint1 value
    		point.realPointer = uintPointer;
    		//set the uint1 value as the value you are requesting to use
    		point.realUint = uint1;
    		//now set the pointer object to the correct part of the PermissionInstance    		
    		PermInst.uintsToUse[ParamId] = point; 
    		//increment the counter accordingly
		    PermInst.uintsCount +=1;

        }
	}

	//** Allows the PermissionInstance creator to add ints to it**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to add this int too
	// @param ParamId - which int parameter for the permission function that int1 will be used for.
	// @param intPointer - the pointers to what part of the corresponding PermissionTemplate the passed through int link to   
    // @param int1 - the int value the creator of this PermissionInstance wants permission to run 
	function addintsToPermissionInstance(uint PermInstID,  uint ParamId, uint intPointer,  int int1) ifPermissionInstanceOwnerAndNotApproved(PermInstID) public {

        //loading the related PermissionInstance
		PermissionInstance storage PermInst = permissionInstances[PermInstID];
		//the if statement forces this PermissionInstance owner to add ints one after another with no gaps
		if (PermInst.intsCount == ParamId){

            //create a Pointer object for this specific int value use request
    		Pointer memory point;
    		//point at the part of the PermissionTemplate that you claim allows you to use the int1 value
    		point.realPointer = intPointer;
    		//set the int1 value as the value you are requesting to use
    		point.realInt = int1;
    		//now set the pointer object to the correct part of the PermissionInstance
    		PermInst.intsToUse[ParamId] = point;
    		//increment the counter accordingly
		    PermInst.intsCount +=1;

		}

	}

	//** Allows the PermissionInstance creator to add bytes32 to it**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to add this bytes32 too
	// @param ParamId - which bytes32 parameter for the permission function that bytes321 will be used for.
	// @param bytes32Pointer - the pointers to what part of the corresponding PermissionTemplate the passed through bytes32 link to   
    // @param bytes321 - the bytes32 value the creator of this PermissionInstance wants permission to run 
    // @param bytes32Type - that bytes32 type (e.g. bytes32, address, string,...). Used so that others can decode the bytes into their correct class 
	function addbytes32ToPermissionInstance(uint PermInstID,  uint ParamId, uint bytes32Pointer, bytes32 bytes321, Bytes32Type bytes32Type) ifPermissionInstanceOwnerAndNotApproved(PermInstID) public {

        //loading the related PermissionInstance
		PermissionInstance storage PermInst = permissionInstances[PermInstID];
		//the if statement forces this PermissionInstance owner to add ints one after another with no gaps
		if (PermInst.bytes32Count == ParamId){

            //create a Pointer object for this specific int value use request
    		Pointer memory point;
    		//point at the part of the PermissionTemplate that you claim allows you to use the bytes321 value
    		point.realPointer = bytes32Pointer;
    		//set the bytes321 value as the value you are requesting to use
    		point.realBytes32 = bytes321;
    		//the class type of these bytes
    		point.bytes32Type = bytes32Type;
    		//now set the pointer object to the correct part of the PermissionInstance
    		PermInst.bytes32ToUse[ParamId] = point;
    		//increment the counter accordingly
		    PermInst.intsCount +=1;

		}

	}


	//** Allows a PermissionManager to approve a PermissionInstance**//
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve
	function approvePermissionInstance (uint myAddressLocation, uint PermInstID) public {
        
        //loading the PermissionInstance that the called wants to approve
        //Also the connected PermissionTemplate and the connected FunctionPermission are loaded
        PermissionInstance storage PermInst = permissionInstances[PermInstID];
        PermissionTemplate storage Perm =  PermissionsAvailable[PermInst.relatedPermissionID];
        FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
        //only a permission manager can approve an instance
		if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)) {
			//if an invalid myAddressLocation was given then revert. 
			revert();
			//now the IsIsPermissionInstanceValid function checks if all of the values in the permissionInstance have been approved, if the related PermissionTemplate is ongoing and the related FunctionPermission is active
		} else if (IsPermissionInstanceValid(PermInstID) == true){
	    	
	    	//approve for use
	         PermInst.approvedForUse = true;
	         PermInst.approvedPM = myAddressLocation;

		} else {
		    //reset counts - this is a punishment for an invalid attempt at approving the permissionInstance
		    PermInst.boolsAnalysed = 0;
		    PermInst.intsAnalysed = 0;
		    PermInst.uintsAnalysed = 0;
		    PermInst.bytes32Analysed = 0;
		}
		
	}

    //** Allows a PermissionManager to approve a bool value in a PermissionInstance**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve the bool of
	// @param pos - the position of the bool that the PermissionManager wants to approve
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // IMPORTANT: Note that the bools of this PermissionInstance must be checked in order, i.e. the bool at position PermissionInstance[x].boolsToUse[Y] must be analysedand approved before the bool at position PermissionInstance[x].boolsToUse[Y+1]
	function setPermissionInstanceBoolAnalysed(uint PermInstID, uint pos, uint myAddressLocation)  public {

        //loading the PermissionInstance that the caller wants to approve
        //Also the connected PermissionTemplate and the connected FunctionPermission are loaded 
	   PermissionInstance storage PermInst = permissionInstances[PermInstID];
	   PermissionTemplate storage Perm =  PermissionsAvailable[PermInst.relatedPermissionID];
	   FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
	   if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)) {
	       //if an invalid myAddressLocation was given then revert. 
	       revert();
	   }else if (PermInst.boolsAnalysed != pos) {
	   	    //revert if the bool being approved is not the next bool to be approved (we force the PermissionManagers to approve in order - without skipping a value)
	   	    revert();
	   	}else {

    	    //We implicity approve the bool by moving on the analysed counter to point to the next bool
    	    PermInst.boolsAnalysed = pos+1;

	   	}
	

	}
	
    //** Allows a PermissionManager to approve a int value in a PermissionInstance**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve the int of
	// @param pos - the position of the int that the PermissionManager wants to approve
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // IMPORTANT: Note that the ints of this PermissionInstance must be checked in order, i.e. the bool at position PermissionInstance[x].intsToUse[Y] must be analysedand approved before the bool at position PermissionInstance[x].intsToUse[Y+1]
	function setPermissionInstanceIntAnalysed(uint PermInstID, uint pos, uint myAddressLocation) public {

        //loading the PermissionInstance that the caller wants to approve
        //Also the connected PermissionTemplate and the connected FunctionPermission are loaded 
	   PermissionInstance storage PermInst = permissionInstances[PermInstID];
	   PermissionTemplate storage Perm =  PermissionsAvailable[PermInst.relatedPermissionID];
	   FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
	   if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)) {
	       	//if an invalid myAddressLocation was given then revert. 
	       revert();
	   } else if (PermInst.intsAnalysed != pos) {
	   	    //revert if the int being approved is not the next int to be approved (we force the PermissionManagers to approve in order - without skipping a value)
	   	    revert();
	   	} else {
    	    //We implicity approve the int by moving on the analysed counter to point to the next int
    	    PermInst.intsAnalysed = pos+1;	   	    

	   	}
	
	}
	
    //** Allows a PermissionManager to approve an uint value in a PermissionInstance**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve the uint of
	// @param pos - the position of the uint that the PermissionManager wants to approve
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // IMPORTANT: Note that the uints of this PermissionInstance must be checked in order, i.e. the uint at position PermissionInstance[x].uintsToUse[Y] must be analysedand approved before the uint at position PermissionInstance[x].uintsToUse[Y+1]
	function setPermissionInstanceUintAnalysed(uint PermInstID, uint pos, uint myAddressLocation) public {

        //loading the PermissionInstance that the caller wants to approve
        //Also the connected PermissionTemplate and the connected FunctionPermission are loaded 
	   PermissionInstance storage PermInst = permissionInstances[PermInstID];
	   PermissionTemplate storage Perm =  PermissionsAvailable[PermInst.relatedPermissionID];
	   FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
	   if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)) {
	       //if an invalid myAddressLocation was given then revert. 
	       revert();
	   } else if (PermInst.uintsAnalysed != pos) {
	   	    //revert if the uint being approved is not the next uint to be approved (we force the PermissionManagers to approve in order - without skipping a value)
	   	    revert();
	   	} else {
	
    	    //We implicity approve the uint by moving on the analysed counter to point to the next uint
    	    PermInst.uintsAnalysed = pos+1;

	   	}
	
	}
	
    //** Allows a PermissionManager to approve a Bytes32 value in a PermissionInstance**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to approve the Bytes32 of
	// @param pos - the position of the Bytes32 that the PermissionManager wants to approve
	// @param myAddressLocation - the array number of the sender's address location in the PermissionManager mapping. Meaning only current permission managers can call this function.
    // IMPORTANT: Note that the Bytes32 of this PermissionInstance must be checked in order, i.e. the Bytes32 at position PermissionInstance[x].Bytes32ToUse[Y] must be analysedand approved before the Bytes32 at position PermissionInstance[x].Bytes32ToUse[Y+1]
	function setPermissionInstanceBytes32Analysed(uint PermInstID, uint pos, uint myAddressLocation) public {

        //loading the PermissionInstance that the caller wants to approve
        //Also the connected PermissionTemplate and the connected FunctionPermission are loaded 
	   PermissionInstance storage PermInst = permissionInstances[PermInstID];
	   PermissionTemplate storage Perm =  PermissionsAvailable[PermInst.relatedPermissionID];
	   FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
	   if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)) {
	       //if an invalid myAddressLocation was given then revert.
	       revert();
	   } else if (PermInst.bytes32Analysed != pos) {
	   	    //revert if the Bytes32 being approved is not the next Bytes32 to be approved (we force the PermissionManagers to approve in order - without skipping a value)
	   	    revert();
	   	} else {
    	    //We implicity approve the Bytes32 by moving on the analysed counter to point to the next Bytes32
    	    PermInst.bytes32Analysed = pos+1;

	   	}
    
	}
	
    //** Allows anyone to check if any PermissionInstance is currently valid. Makes sure that: 
    //(i) the PermissionManagers have approved all of the variables in the PermissionInstance;
    //(ii) the the related PermissionTemplate is currently ongoing
    //(iii) the related FunctionPermission is active
    //(iv) the related PermissionTemplate was created after the related FunctionPermission was last made active
    //(v) that the approved variables in the PermissionInstance matches the number expected according to the PermissionTemplate
    //**//
	// @param PermInstID - the ID of the PermissionInstance the caller wants to check the validity of
	function IsPermissionInstanceValid(uint PermInstID) public view returns(bool){

        //loading the PermissionInstance that the caller wants to approve and the connected PermissionTemplate 	    
	    PermissionInstance storage PermInst = permissionInstances[PermInstID];
	    PermissionTemplate storage Perm =  PermissionsAvailable[PermInst.relatedPermissionID];
	    FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
	    if ((PermInst.boolsCount < PermInst.boolsAnalysed)||(PermInst.intsCount < PermInst.intsAnalysed)||(PermInst.uintsCount < PermInst.uintsAnalysed)||(PermInst.bytes32Count < PermInst.bytes32Analysed)){
	       //if the PermissionManager has not approved all the variables then we cannot be sure they are valid
	        return false;
	    }else if ((Perm.Status != PermissionStatus.Ongoing)||(funPerm.Active == false)||(Perm.ActiveFromBlock < funPerm.ActiveFromBlock)){
	        //if the related PermissionTemplate is not currently ongoing then this PermissionInstance is not valid
	        //if the related FunctionPermission is not active then this PermissionInstance is not valid
	        //if the related PermissionTemplate was created before the related FunctionPermission was last made active, then this permissionInstance is not valid (as setting the FunctionPermission to inactive revokes everything that is related forever)
	        //if the permissionManager that approved this permissionInstance has been deleted
	        return false;
	    } else if ((PermInst.boolsCount != Perm.boolsCount)||(PermInst.intsCount != Perm.intsCount)||(PermInst.uintsCount != Perm.uintsCount)||(PermInst.intsCount != Perm.intsCount)||(PermInst.bytes32Count != Perm.bytes32Count)) {
	        //if the permission instance has less variables than expected according to hte Permission template, then the permission instance is not valid
	        return false;
	    } else {
	        //otherwise this is acceptable
	        return true;
	    }
	}
	
	//**Allows a permissionManager to say that a permission instance has been used
	function PermissionInstanceHasBeenUsed(uint PermInstID, uint myAddressLocation) public {
        //loading the PermissionInstance that has just been used   
       PermissionInstance storage PermInst = permissionInstances[PermInstID]; 
	   PermissionTemplate storage Perm =  PermissionsAvailable[PermInst.relatedPermissionID];
	   FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
	   if ((funPerm.PermManagersCount < myAddressLocation)||(funPerm.PermissionManagers[myAddressLocation] != msg.sender)) {
	       	//if an invalid myAddressLocation was given then revert. 
	       revert();
	   }
	   PermInst.numberOfUses -=1;

	}
	

	/******** End of Functions  *********/    
	
	/******** Start of Getters  *********/
	
	//** Returns the owner of the contract**//
	// @returns - the address of the smart contract owner (who is the person who put this contract onto the blockchain)
	function GetOwner() constant public returns(address) {
		return Owner; 
	}
	
	//** Returns the location of the CompanyDefinition smart contract**//
	// @returns - the address of the smart contract
	function GetCompanyDefinitionContr() constant public returns(address) {
		return address(ComDefCont); 
	}	
	
	//** Returns the location of the PermissionCheck smart contract**//
	// @returns - the address of the smart contract
	function GetPermissionCheckContr() constant public returns(address) {
		return address(PermCheckCont); 
	}	

    //**********START OF FUNCTIONPERMISSION LEVEL GETTERS**********/

	//** Returns the number of PermissionManagers for a certain function**//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that you are enquirying over
	// @returns - the number of PermissionManagers
	function getNumOfFunctionPermManagers(address functionLocation, string functionName) constant public returns(uint) {

	    return functionList[functionLocation][functionName].PermManagersCount;

	}

	//** Returns a certain PermissionManager for a certain function**//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that you are enquirying over
	// @param id - the id of the PermissionManager that you are enquirying over
	// @returns - the address of PermissionManager
	function getFunctionPermissionManager(address functionLocation, string functionName, uint id) constant public returns(address) {

         return functionList[functionLocation][functionName].PermissionManagers[id];
         
	}

	//** Returns the block number that the FunctionPermission was last activated on**//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that you are enquirying over
	// @returns - the block number
	function getFunctionPermissionActiveFromBlock(string functionName, address functionLocation) constant public returns(uint) {

        return functionList[functionLocation][functionName].ActiveFromBlock;

	}

	//** Returns if the FunctionPermission is currently active**//
	// @param functionLocation - the address of the smart contract that the function is located in
	// @param functionName - the name of the function that you are enquirying over
	// @returns - whether this function is active or not
	function IsFunctionPermissionActive(string functionName, address functionLocation) constant public returns(bool) {

        return functionList[functionLocation][functionName].Active;

	}


    //**********END OF FUNCTIONPERMISSION LEVEL GETTERS**********/

    //**********START OF PERMISSIONTEMPLATE LEVEL GETTERS**********/

	//** Returns the PermissionTemplate status (created, ongoing, revoked)**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - whether this function is active or not
	function getPermissionTemplateStatus( uint PermId) constant public returns(uint) {

	    return uint(PermissionsAvailable[PermId].Status);
	}

	//** Returns the possible bool values for a certain bool variable in a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @param boolID - The bool variable number that you are enquirying over
	// @returns - the possible bool values for boolID
	function getPermissionTemplateBooleans(uint PermId, uint boolID) constant public returns(bool[2]) {

            return PermissionsAvailable[PermId].boolVariables[boolID];

	}

	//** Returns a possible uint value for a certain uint variable in a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @param uintID - The uint variable number that you are enquirying over
	// @param uintOption - The number of a particular uint value for uintID 
	// @returns - this possible uint value
	function getPermissionTemplateUints(uint PermId, uint uintID, uint uintOption) constant public returns(uint) {

            return PermissionsAvailable[PermId].uintVariables[uintID][uintOption];

	}

	//** Returns a possible int value for a certain int variable in a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @param intID - The int variable number that you are enquirying over
	// @param intOption - The number of a particular int value for intID 
	// @returns - this possible int value
	function getPermissionTemplateInts(uint PermId, uint intID, uint intOption) constant public returns(int) {

    	    return PermissionsAvailable[PermId].intVariables[intID][intOption];
        
	}
	
	//** Returns a possible bytes32 value for a certain bytes32 variable in a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @param bytes32ID - The bytes32 variable number that you are enquirying over
	// @param bytes32Option - The number of a particular bytes32 value for bytes32ID 
	// @returns - this possible bytes32 value
	function getPermissionTemplateBytes32( uint PermId, uint bytes32ID, uint bytes32Option) constant public returns(bytes32) {

    	    return PermissionsAvailable[PermId].bytes32Variables[bytes32ID][bytes32Option];
        
	}
	
	//** Returns the function name of a  PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - the function name	
	function getPermissionTemplateFunctionName(uint PermId) constant public returns(bytes32) {

	    return stringToBytes32(PermissionsAvailable[PermId].functionName);

	}

	//** Returns the address of where the function of a PermissionTemplate is located**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - the address
	function getPermissionTemplateFunctionLocation(uint PermId) constant public returns(address) {

	    return PermissionsAvailable[PermId].functionLocation;

	}


	//** Returns the block start time of a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - the starting block number	
	function getPermissionTemplateStartTime(uint PermId) constant public returns(uint40) {

          return PermissionsAvailable[PermId].startTime;
	}

	//** Returns the block end time of a PermissionTemplate**//
	// @param PermId - The PermissionTemplate you are enquirying over
	// @returns - the ending block number	
	function getPermissionTemplateEndTime(uint PermId) constant public returns(uint40) {

          return PermissionsAvailable[PermId].endTime;

	}


    //**********END OF PERMISSIONTEMPLATE LEVEL GETTERS**********/

    //**********START OF PERMISSIONINSTANCE LEVEL GETTERS**********/

	//** Returns the owner of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the owner's address
	function getPermissionInstanceOwner(uint PermInstId) constant public returns(address) {

        return permissionInstances[PermInstId].Owner;

	}
	
	//** Returns the share class owner of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the share class id according to the related company definition contract
	function getPermissionInstanceShareClass(uint PermInstId) constant public returns(uint){

        return permissionInstances[PermInstId].ShareClassOwner;
	}

	//** Returns if a permissionInstance is approved**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - if it is approved
	function isPermissionInstanceApproved(uint PermInstId) constant public returns(bool) {

        //loading the PermissionInstance that the caller wants to approve and the connected PermissionTemplate 	    
	    PermissionInstance storage PermInst = permissionInstances[PermInstId];
	    PermissionTemplate storage Perm =  PermissionsAvailable[PermInst.relatedPermissionID];
	    FunctionPermission storage funPerm = functionList[Perm.functionLocation][Perm.functionName];
	    
        if ((Perm.Status != PermissionStatus.Ongoing)||(funPerm.Active == false)||(Perm.ActiveFromBlock < funPerm.ActiveFromBlock)){
	        //if the related PermissionTemplate is not currently ongoing then this PermissionInstance is not valid
	        //if the related FunctionPermission is not active then this PermissionInstance is not valid
	        //if the related PermissionTemplate was created before the related FunctionPermission was last made active, then this permissionInstance is not valid (as setting the FunctionPermission to inactive revokes everything that is related forever
	        return false;
	    }   else if ((PermInst.approvedForUse == false)||(funPerm.PermissionManagers[PermInst.approvedPM] == address(0x0))){
	        //permissionInstance is only approved if a PM has approved it AND this PM has not been removed
                return false;
            } else {
                return true;
            }
          
	}

	//** Returns the ID of the related PermissionTemplate of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the PermissionTemplate ID
	function getPermissionInstanceRelatedID(uint PermInstId) constant public returns(uint) {

          return permissionInstances[PermInstId].relatedPermissionID;
          
	}

	//** Returns the bool value at a certain position of the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The bool position you are enquirying over
	// @returns - the bool value
	function getPermissionInstanceBoolAtPosition(uint PermInstId, uint pos) constant public returns(bool){
	    
	    if (pos >= permissionInstances[PermInstId].boolsCount){
            //this is to make sure that a default mapping value is not returned!
            revert();
        } else{
            return permissionInstances[PermInstId].boolsToUse[pos].realBool;
        }
	     
	}
	
	//** Returns the int value at a certain position of the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The int position you are enquirying over
	// @returns - the int value
	function getPermissionInstanceIntAtPosition(uint PermInstId, uint pos) constant public returns(int){
	 
	    if (pos >= permissionInstances[PermInstId].intsCount){
            //this is to make sure that a default mapping value is not returned!
            revert();
        } else{
	        return permissionInstances[PermInstId].intsToUse[pos].realInt;
        }   
	
	}

	//** Returns the uint value at a certain position of the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The uint position you are enquirying over
	// @returns - the uint value
	function getPermissionInstanceUintAtPosition(uint PermInstId, uint pos) constant public returns(uint){
	    
	    if (pos >= permissionInstances[PermInstId].uintsCount){
            //this is to make sure that a default mapping value is not returned!
            revert();
        } else{
	        return permissionInstances[PermInstId].uintsToUse[pos].realUint;
        }
	
	}

	//** Returns the Bytes32 value at a certain position of the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The Bytes32 position you are enquirying over
	// @returns - the Bytes32 value
	function getPermissionInstanceBytes32AtPosition(uint PermInstId, uint pos) constant public returns(bytes32){
	    
	    if (pos >= permissionInstances[PermInstId].boolsCount){
            revert();
        } else{
	        return permissionInstances[PermInstId].bytes32ToUse[pos].realBytes32;
        }
	
	}
	
	//** Returns the ID of the related PermissionTemplate and a pointer to corresponding part of the bool array of the PermissionTemplate, from the requested position of the bool array in the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The Bytes32 position you are enquirying over
	// @returns - (the id of the related PermissionTemplate, and the pointer)
	function getPermissionInstanceBoolPointer(uint PermInstId, uint pos) constant public returns(uint, uint){
	    
	     return (permissionInstances[PermInstId].relatedPermissionID, permissionInstances[PermInstId].boolsToUse[pos].realPointer);
	
	}
	
	//** Returns - the ID of the related PermissionTemplate, a pointer to corresponding part of the int array of the PermissionTemplate, the possible lower range acceptable int value and the possible upper range acceptable int value - from the requested position of the int array in the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The int position you are enquirying over
	// @returns - (the id of the related PermissionTemplate, the pointer, possible low range, possible high range)
	// IMPORTANT - the low and high range should only be considered if the pointer is set to 0.
	function getPermissionInstanceIntPointer(uint PermInstId, uint pos) constant public returns(uint, uint, int, int){

        PermissionInstance storage PermInst = permissionInstances[PermInstId];
	    uint point = PermInst.intsToUse[pos].realPointer;
	    PermissionTemplate storage Perm = PermissionsAvailable[point];
	    return (PermInst.relatedPermissionID, point, Perm.intVariables[pos][0],Perm.intVariables[pos][1]);
	
	}
	
	//** Returns - the ID of the related PermissionTemplate, a pointer to corresponding part of the uint array of the PermissionTemplate, the possible lower range acceptable uint value and the possible upper range acceptable uint value - from the requested position of the uint array in the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The uint position you are enquirying over
	// @returns - (the id of the related PermissionTemplate, the pointer, possible low range, possible high range)
	// IMPORTANT - the low and high range should only be considered if the pointer is set to 0.
	function getPermissionInstanceUintPointer(uint PermInstId, uint pos) constant public returns(uint, uint, uint, uint){

        PermissionInstance storage PermInst = permissionInstances[PermInstId];
	    uint point = PermInst.uintsToUse[pos].realPointer;
	    PermissionTemplate storage Perm = PermissionsAvailable[point];
        return (PermInst.relatedPermissionID, point, Perm.uintVariables[pos][0],Perm.uintVariables[pos][1]);
	
	}
	
	//** Returns the ID of the related PermissionTemplate and a pointer to corresponding part of the byte32 array of the PermissionTemplate, from the requested position of the bytes32 array in the permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @param pos - The Bytes32 position you are enquirying over
	// @returns - (the id of the related PermissionTemplate, and the pointer)
	function getPermissionInstanceBytes32Pointer(uint PermInstId, uint pos) constant public returns(uint, uint){
	    
	     return (permissionInstances[PermInstId].relatedPermissionID,permissionInstances[PermInstId].bytes32ToUse[pos].realPointer);
	
	}
	
	//** Returns the analysed count of the bool array of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the analysed count
	function getPermissionInstanceBoolAnalysed(uint PermInstId) constant public returns(uint){
	    
	     return permissionInstances[PermInstId].boolsAnalysed;
	
	}
	
	//** Returns the analysed count of the int array of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the analysed count
	function getPermissionInstanceIntAnalysed(uint PermInstId) constant public returns(uint){
	    
	     return permissionInstances[PermInstId].intsAnalysed;
	
	}
	
	//** Returns the analysed count of the uint array of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the analysed count
	function getPermissionInstanceUintAnalysed(uint PermInstId) constant public returns(uint){
	    
	     return permissionInstances[PermInstId].uintsAnalysed;
	
	}
	
	//** Returns the analysed count of the byte32 array of a permissionInstance**//
	// @param PermInstId - The permissionInstance you are enquirying over
	// @returns - the analysed count
	function getPermissionInstanceBytes32Analysed(uint PermInstId) constant public returns(uint){
	    
	     return permissionInstances[PermInstId].bytes32Analysed;
	
	}
	
	    //**********END OF PERMISSIONINSTANCE LEVEL GETTERS**********/


	/******** End of Getters  *********/
    

    /******** Destroy Contract ********/
  //  function remove() ifOwner public {
//        selfdestruct(msg.sender);
  //  }
  
  /************ helper functions ************/
  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

}
	

     
