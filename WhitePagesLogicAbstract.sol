

pragma solidity ^0.4.21;


//** Creator = Luke Riley
//** This white pages smart contract is used to hold a list of smart contracts used in the system.

//TO DO:
//sort out permission based access controls

contract WhitePagesLogicAbstract {
    
    
    //EVENT
    event contractAddressChange(string explanation, address newAddress);



    
    //SETTERS
    

    
	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addSmartContractPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  public returns(uint);
    
    //IMPORTANT NEEDS TO RETURN TO PRIVATE BEFORE DEPLOYMENT
    function addSmartContract(string contractName, address contractAddress, address permissionListAddr, address dataStoreAddr, uint version) public returns(uint);
    
        	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function deleteSmartContractPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) public;

    //IMPORTANT NEEDS TO RETURN TO PRIVATE BEFORE DEPLOYMENT    
    function deleteSmartContract(uint contractID) public;
    
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractNamePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  public;
    

	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractAddrPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) public;
    
    
	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractPermListAddrPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  public;
    
    	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractDataStoreAddrPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) public;
    
    	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractVersionPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) public;
    
        	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addPermTemplateToFunctionPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  public;
    
    //TO DO ABOVE AND SET AS PRIVATE HERE
    function addPermTemplateToFunction(uint contractID, uint functionID, uint PermTemplateId) public;
    
            	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addPermInstanceToPermTemplatePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  public;
    
    //TO DO SET AS PRIVATE AND DO ABOVE FUNCTION
    function addPermInstanceToPermTemplate(uint contractID, uint functionID, uint PermInstId) public;
    
    
                	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addSmartContractFunctionNamePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  public;
    
    //TO DO SET AS PRIVATE AND DO ABOVE FUNCTION
    function addSmartContractFunctionName(uint contractID, string functionName, bool permissioned) public;
    
    //UPGRADE FUNCTIONS
    //upgrade permissionListAddr

        	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function upgradePermissionListPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  public;
    
    
    //upgrade whitepages
	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function upgradeWhitePagesDataStorePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont)  public;
    
    function addParamsToSmartContractFunction(uint contractId, uint functionId, bytes32[5] paramNames) public returns(uint);

    //CHANGE THIS IN THE FUTURE AS WELL
    function upgradeWhitePagesDataStore(address newDataStoreAddr) public;
    
    
    //GETTERS--the rest of the getters are held in the WhitePagesLogic contract.
    function getWhitePagesDataStoreAddress() public view returns(address);
    
    function getPermissionListAddress() public view returns(address);
    


}
