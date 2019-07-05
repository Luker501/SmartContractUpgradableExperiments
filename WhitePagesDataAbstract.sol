

pragma solidity ^0.4.21;


//** Creator = Luke Riley
//** This contract is used to store the data of the white pages logic smart contract.

contract WhitePagesDataAbstract {
    
    //EVENTS

    //makes sure that blockchain users can know when a new contract has been added    
    event ContractAddedEvent(uint contractID, string name, address contractAddr, address permListAddr, address datastoreAddr);
    
    //makes sure that blockchain users can know about when a contract has a parameter modified
    event ContractEvent(string explanation, uint contractID);
    

    //SETTERS

    //** Allows the current whitepages logic smart contract to tell the whitepages data contract that it is upgrading **//
	// @param whitePagesLogicAddr - the new address of the upgraded whitepages data contract
    // IMPORTANT NOTE - THIS REQUIRES THE WHITEPAGES LOGIC CONTRACT TO HAVE THE CAPABILITY TO UPGRADE
    function setWhitePagesAddress(address whitePagesLogicAddr) public returns(address);
    
    //** Allows the current whitepages logic smart contract to set its related permission system **//
	// @param permList - the new address of the permissionList smart contract that holds the permissions for these white pages
    function setPermListAddress(address permList) public returns (address);

    //** Allows the current whitepages logic smart contract to add details of a smart contract to the system **//
	// @param name - the name of the smart contract that is being added
	// @param location - the location of the smart contract that is being added
	// @param permList - the location of the smart contracts related permission system
    function addNewSmartContract(string name, address location, address permList, address dataStore, string smartContractLink) public returns(uint);
    
    //** Allows the current whitepages logic smart contract to delete a smart contract from the system**//
    // @param contractID - the ID of the contract to be deleted
    function deleteSmartContract(uint contractID) public;

    //** Allows the current whitepages logic smart contract to change the name of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the name of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractName(uint contractID, string name) public;

    //** Allows the current whitepages logic smart contract to change the address of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the address of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractAddress(uint contractID, address contractAddr) public;

    //** Allows the current whitepages logic smart contract to change the permission system address of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the permission system address of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractPermListAddress(uint contractID, address permListAddr) public;
    
    
    //** Allows the current whitepages logic smart contract to change the dataStore address of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the dataStore address of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractDataStoreAddress(uint contractID, address dataStoreAddr) public;

    //** Allows the current whitepages logic smart contract to change the version of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the version of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractVersion(uint contractID, uint version) public;

    function addSmartContractFunction(uint contractID, string functionName, bool permissioned) public returns (uint);
    
    //we will go 5 at a time
    function addParamsToSmartContractFunction(uint contractId, uint functionId, bytes32[5] paramNames) external;

    
    function connectPermTemplateToFunction(uint contractID, uint functionID, uint PermTemplateId) public returns (uint);
    
    function deletePermTemplateFromFunction(uint contractID, uint functionID, uint PermTemplateArrayID) public;

    function connectPermInstanceToPermTemplate(uint contractID, uint PermTemplateId, uint PermInstId) public returns (uint);
    
    function deletePermInstanceFromPermTemplate(uint contractID, uint PermTemplateId, uint PermInstId) public;

    //GETTERS

    //**Allows anyone to get the address of the controlling white pages logic smart contract**//
    function getWhiteListLogicAddress() public view returns(address);

    //**Allows anyone to get the address of the permission system smart contract**//
    function getPermListAddress() public view returns(address);

    //**Allows anyone to get the address of next position available in the mapping that holds the smart contract list**//
    //NOTE - this note the total number of smart contracts in the system as some may have been deleted.
    function getMaxNumOfContracts() public view returns(uint);

    //**Allows anyone to access the name of a smart contract**//
    // @param contractID - the ID of the contract to get the name of
    function getSmartContractName(uint contractID) public view returns(string);

    //**Allows anyone to access the address of a smart contract**//
    // @param contractID - the ID of the contract to get the address of
    function getSmartContractAddress(uint contractID) public view returns(address);
    
    //**Allows anyone to access the permission system of a smart contract**//
    // @param contractID - the ID of the contract to get the permission system address of
    function getSmartContractPermissionListAddress(uint contractID) public view returns(address);

    //**Allows anyone to access the permission system of a smart contract**//
    // @param contractID - the ID of the contract to get the permission system address of
    function getSmartContractDataStoreAddress(uint contractID) public view returns(address);

    //**Allows anyone to access the version of a smart contract**//
    // @param contractID - the ID of the contract to get the version of
    function getSmartContractVersion(uint contractID) public view returns(uint);
    
    
    function getNumOfFunctionsInContract(uint contractID) public view returns (uint);
    
    function getFunctionName(uint contractID, uint functionID) public view returns (string);
    
    function isFunctionProtectedByPermissions(uint contractID, uint functionID) public view returns (bool);
    
    function getNumOfParamsInFunction(uint contractID, uint functionID) external view returns (uint);
    
    function getParamInFunction(uint contractID, uint functionID, uint paramID) external view returns (string);
    
    function getPermTemplateOfFunction(uint contractID, uint functionID, uint counter) public view returns (uint);
    
    function getNumOfPermTemplatesInFunction(uint contractID, uint functionID) public view returns (uint);

    function getNumOfPermInstInTemplate(uint contractID, uint permTempId) public view returns (uint);
    
    function getPermInstFromTemplate(uint contractID, uint permTempId, uint counter) public view returns (uint);
    
}
