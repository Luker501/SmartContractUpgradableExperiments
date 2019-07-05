

pragma solidity ^0.4.21;

import "browser/PermissionListAbstract.sol";
import "browser/WhitePagesDataAbstract.sol";

//** Creator = Luke Riley
//** This contract is used to store the data of the white pages logic smart contract.

contract WhitePagesData is WhitePagesDataAbstract {
    
    uint smartContractCount = 0;
    mapping (uint => contractInstance) contracts;
    address Owner;
    address permissionList;
    
    //EVENTS

    //makes sure that blockchain users can know when a new contract has been added    
    event ContractAddedEvent(uint contractID, string name, address contractAddr, address permListAddr, address datastoreAddr);
    
    //makes sure that blockchain users can know about when a contract has a parameter modified
    event ContractEvent(string explanation, uint contractID);
    
    //MODIFIERS
    	//** any function containing this modifier, only allows the contract owner to call it**//
	modifier ifOwner(){
        if(Owner != msg.sender){
            revert("Not the contract owner");
        }else{
            _; //means continue on the functions that called it
        }
    }
    
    //STRUCTURES
    
    //contract contractInstance
    
    struct contractInstance {
        
        string name;
        string smartContractLink; //i.e. not bytecode
        address location;
        address permList;
        address dataStore;
        uint version;
        uint functionCount;
        uint permTemplateCount;
        mapping (uint => functionInContract) functions;
        mapping (uint => permTemplatesInContract) permTemplates; 
    }
    
    struct functionInContract {
        string name;
        bool permissioned;
        uint permTemplatesCount;
        uint paramCount;
        mapping (uint => string) paramNames;
        mapping (uint => uint) permTemplates; //holds the uint of the permTemplate in the contract instance
    }
    
    struct permTemplatesInContract {
        uint realId;
        uint permInstancesCount;
        mapping (uint => uint) permInstances;
    }
    
    constructor (address permList) public {
        if (permList!=address(0)){
            
            Owner = msg.sender;
            permissionList = permList;
         //   Initialised("The ShareholderRights contract has been initialised:", msg.sender, Owner, ComDefAdd);	//***EVENT: Owner
            
        }
 
    }
    
    //SETTERS

    //** Allows the current whitepages logic smart contract to tell the whitepages data contract that it is upgrading **//
	// @param whitePagesLogicAddr - the new address of the upgraded whitepages data contract
    // IMPORTANT NOTE - THIS REQUIRES THE WHITEPAGES LOGIC CONTRACT TO HAVE THE CAPABILITY TO UPGRADE
    function setWhitePagesAddress(address whitePagesLogicAddr) ifOwner() public returns(address)  {
        Owner = whitePagesLogicAddr;
    }
    
    //** Allows the current whitepages logic smart contract to set its related permission system **//
	// @param permList - the new address of the permissionList smart contract that holds the permissions for these white pages
    function setPermListAddress(address permList) ifOwner() public returns (address){
        permissionList = permList;
    }

    //** Allows the current whitepages logic smart contract to add details of a smart contract to the system **//
	// @param name - the name of the smart contract that is being added
	// @param location - the location of the smart contract that is being added
	// @param permList - the location of the smart contracts related permission system
    function addNewSmartContract(string name, address location, address permList, address dataStore, string smartContractLink) ifOwner() public returns(uint){
        smartContractCount  += 1;
        contracts[smartContractCount].name = name;
        contracts[smartContractCount].location = location;
        contracts[smartContractCount].permList = permList;
        contracts[smartContractCount].dataStore = dataStore;
        contracts[smartContractCount].smartContractLink = smartContractLink;
        contracts[smartContractCount].version = 1;
    }
    
    //** Allows the current whitepages logic smart contract to delete a smart contract from the system**//
    // @param contractID - the ID of the contract to be deleted
    function deleteSmartContract(uint contractID) ifOwner()  public {
        contracts[contractID].name = "";
        contracts[contractID].location = address(0x0);
        contracts[contractID].permList = address(0x0);
        contracts[contractID].dataStore = address(0x0);
    }

    //** Allows the current whitepages logic smart contract to change the name of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the name of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractName(uint contractID, string name) ifOwner() public{
        contracts[contractID].name = name;
    }

    //** Allows the current whitepages logic smart contract to change the address of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the address of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractAddress(uint contractID, address contractAddr) ifOwner() public{
        contracts[contractID].location = contractAddr;
    }

    //** Allows the current whitepages logic smart contract to change the permission system address of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the permission system address of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractPermListAddress(uint contractID, address permListAddr) ifOwner() public{
        contracts[contractID].permList = permListAddr;
    }
    
    
    //** Allows the current whitepages logic smart contract to change the dataStore address of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the dataStore address of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractDataStoreAddress(uint contractID, address dataStoreAddr) ifOwner() public{
        contracts[contractID].dataStore = dataStoreAddr;
    }

    //** Allows the current whitepages logic smart contract to change the version of a smart contract previously recorded**//
    // @param contractID - the ID of the contract to change the version of
    //NOTE - the given contractID must be an ID of an initialised contract
    function setSmartContractVersion(uint contractID, uint version) ifOwner() public{
    
        contracts[contractID].version = version;
        
    }

    function addSmartContractFunction(uint contractID, string functionName, bool permissioned) ifOwner() public returns (uint){
       
       contracts[contractID].functionCount += 1;
       contracts[contractID].functions[contracts[contractID].functionCount].name = functionName;
       contracts[contractID].functions[contracts[contractID].functionCount].permissioned = permissioned;
       
    }
    
    //we will go 5 at a time
    function addParamsToSmartContractFunction(uint contractId, uint functionId, bytes32[5] paramNames) ifOwner() external {
        
        uint count = 0;
        string memory paramToAdd;
        do {
        
            paramToAdd = bytes32ToString(paramNames[count]);
            if (keccak256(paramToAdd) == keccak256("")){
                return;
            } else {
                //add it to the 
                contracts[contractId].functions[functionId].paramCount += 1;
                contracts[contractId].functions[functionId].paramNames[contracts[contractId].functions[functionId].paramCount] = paramToAdd;
            }
            count +=1;
        } while (count < 5);
        
    }

    
    function connectPermTemplateToFunction(uint contractID, uint functionID, uint PermTemplateId) ifOwner() public returns (uint){
       
        contracts[contractID].functions[functionID].permTemplatesCount += 1;
        contracts[contractID].permTemplateCount += 1;
        contracts[contractID].functions[functionID].permTemplates[contracts[contractID].functions[functionID].permTemplatesCount] = contracts[contractID].permTemplateCount;
        contracts[contractID].permTemplates[contracts[contractID].permTemplateCount].realId = PermTemplateId;
        
    }
    
    function deletePermTemplateFromFunction(uint contractID, uint functionID, uint PermTemplateArrayID) ifOwner() public{

        contracts[contractID].functions[functionID].permTemplates[PermTemplateArrayID] = 0;
        
    }

    function connectPermInstanceToPermTemplate(uint contractID, uint PermTemplateId, uint PermInstId) ifOwner() public returns (uint){
        
        contracts[contractID].permTemplates[PermTemplateId].permInstancesCount +=1;
        contracts[contractID].permTemplates[PermTemplateId].permInstances[contracts[contractID].permTemplates[PermTemplateId].permInstancesCount] = PermInstId;

    }
    
    function deletePermInstanceFromPermTemplate(uint contractID, uint PermTemplateId, uint PermInstId) ifOwner() public{
        contracts[contractID].permTemplates[PermTemplateId].permInstances[PermInstId] = 0;
    }

    //GETTERS

    //**Allows anyone to get the address of the controlling white pages logic smart contract**//
    function getWhiteListLogicAddress() public view returns(address){
        return Owner;
    }

    //**Allows anyone to get the address of the permission system smart contract**//
    function getPermListAddress() public view returns(address){
        return permissionList;
    }
    

    //**Allows anyone to get the address of next position available in the mapping that holds the smart contract list**//
    //NOTE - this note the total number of smart contracts in the system as some may have been deleted.
    function getMaxNumOfContracts() public view returns(uint){
        return smartContractCount;
    }

    //**Allows anyone to access the name of a smart contract**//
    // @param contractID - the ID of the contract to get the name of
    function getSmartContractName(uint contractID) public view returns(string){
        return contracts[contractID].name;
    }

    //**Allows anyone to access the address of a smart contract**//
    // @param contractID - the ID of the contract to get the address of
    function getSmartContractAddress(uint contractID) public view returns(address){
        return contracts[contractID].location;
    }
    
    //**Allows anyone to access the permission system of a smart contract**//
    // @param contractID - the ID of the contract to get the permission system address of
    function getSmartContractPermissionListAddress(uint contractID) public view returns(address){
        return contracts[contractID].permList;
    }

    //**Allows anyone to access the permission system of a smart contract**//
    // @param contractID - the ID of the contract to get the permission system address of
    function getSmartContractDataStoreAddress(uint contractID) public view returns(address){
        return contracts[contractID].dataStore;
    }

    //**Allows anyone to access the version of a smart contract**//
    // @param contractID - the ID of the contract to get the version of
    function getSmartContractVersion(uint contractID) public view returns(uint){
        return contracts[contractID].version;
    }
    
    
    function getNumOfFunctionsInContract(uint contractID) public view returns (uint){
        return contracts[contractID].functionCount;
    }
    
    function getFunctionName(uint contractID, uint functionID) public view returns (string){
        return contracts[contractID].functions[functionID].name;
    }
    
    function isFunctionProtectedByPermissions(uint contractID, uint functionID) public view returns (bool){
        return contracts[contractID].functions[functionID].permissioned;
    }
    
    function getNumOfParamsInFunction(uint contractID, uint functionID) external view returns (uint) {
        return contracts[contractID].functions[functionID].paramCount;
    }
    
    function getParamInFunction(uint contractID, uint functionID, uint paramID) external view returns (string) {
        return contracts[contractID].functions[functionID].paramNames[paramID];
    }
    
    function getPermTemplateOfFunction(uint contractID, uint functionID, uint counter) public view returns (uint){
        return contracts[contractID].functions[functionID].permTemplates[counter];
    }
    
    function getRealPermTemplateID(uint contractID, uint permTemplateId) public view returns (uint){
        return contracts[contractID].permTemplates[permTemplateId].realId;
    }
    
    function getNumOfPermTemplatesInFunction(uint contractID, uint functionID) public view returns (uint){
        return contracts[contractID].functions[functionID].permTemplatesCount;
    }

    function getNumOfPermInstInTemplate(uint contractID, uint permTempId) public view returns (uint){
        return contracts[contractID].permTemplates[permTempId].permInstancesCount;
    }
    
    function getPermInstFromTemplate(uint contractID, uint permTempId, uint counter) public view returns (uint){
        return contracts[contractID].permTemplates[permTempId].permInstances[counter];
    }
    
    //HELPER FUNCTIONS
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
