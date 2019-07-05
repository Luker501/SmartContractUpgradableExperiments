

pragma solidity ^0.4.21;

//import "browser/ProxyBase.sol";
import "browser/PermissionListAbstract.sol";
import "browser/PermissionCheckAbstract.sol";
import "browser/WhitePagesDataAbstract.sol";

//** Creator = Luke Riley
//** This white pages smart contract is used to hold a list of smart contracts used in the system.

//TO DO:
//sort out permission based access controls

contract WhitePagesLogic {
    
	WhitePagesDataAbstract DataStoreCont;
    PermissionListAbstract PermListCont;
    PermissionCheckAbstract PermCheckCont;
    
    //EVENT
    event contractAddressChange(string explanation, address newAddress);

    //MODIFIER
    //** any function containing this modifier, only allows...**//
	modifier PermInstChecks(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont){
	    
		if ((PermCheckCont.hasOwnershipOfPermissionInstance(msg.sender, PermInstId, shareClassUsed,  ShareClassIdSRCont) == false)){
            revert("Error");
        } else if (PermListCont.isPermissionInstanceApproved(PermInstId)){
            revert("Error");
        }else{
		    _; //means continue on the functions that called it
		}
		
    }


    constructor(address dataStore, address permList) public {
        // initialize contract state variables here
        if ((dataStore!=address(0))&&(permList!=address(0))) {
            
            PermListCont = PermissionListAbstract(permList);
            address PermCheckAddr = PermListCont.GetPermissionCheckContr();
            if (PermCheckAddr!=address(0)){
                PermCheckCont = PermissionCheckAbstract(PermCheckAddr);
            } else {
                revert("PermCheckAddr variable looked up from permList contract is set to nothing");
            }
            DataStoreCont = WhitePagesDataAbstract(dataStore);

        } else {
            revert("datastore or permList input variable set to nothing");
        }
    }


    
    //SETTERS
    

    
	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addSmartContractPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public returns(uint){
        
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
                //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
                    string memory contractName = bytes32ToString(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 0));
                    address contractAddress = bytes32ToAddress(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 1));
                    address permissionListAddr = bytes32ToAddress(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 2));
                    address dataStoreAddr = bytes32ToAddress(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 3));
        	        string memory smartContractLink = bytes32ToString(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 1));
        	        uint version = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
        	        
    	            //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    //call the function
                    return addSmartContract(contractName, contractAddress, permissionListAddr, dataStoreAddr, smartContractLink, version);
    	       
    	    }
    }
    
    //IMPORTANT NEEDS TO RETURN TO PRIVATE BEFORE DEPLOYMENT
    function addSmartContract(string contractName, address contractAddress, address permissionListAddr, address dataStoreAddr, string smartContractLink, uint version) public returns(uint) {
        
        //add the contract to the data store
        uint contractID = DataStoreCont.addNewSmartContract(contractName, contractAddress, permissionListAddr, dataStoreAddr, smartContractLink);
        //and set the version correctly if needed
        if (version > 1){
            DataStoreCont.setSmartContractVersion( contractID, version);
        }
        
        return contractID;
        
    }
    
    
    	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addParamsToSmartContractFunctionPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {
        
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
                //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
            //        uint contractId = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
        	  //      uint functionId = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 1);
        	       // bytes32[5] memory paramNames;
    	           // uint count = 0;
    	           /// while (count < 5){
    	            //    paramNames[count] = PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, count);
    	            //    count +=1;
    	            //}
    	            //record that this permission instance has been used
    	           // PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    //call the function
                 //   return addParamsToSmartContractFunction(contractId, functionId, paramNames);
    	       
    	    }
    }
    
        //IMPORTANT NEEDS TO RETURN TO PRIVATE BEFORE DEPLOYMENT
    function addParamsToSmartContractFunction(uint contractId, uint functionId, bytes32[5] paramNames) public {
        
        //check that the contract and function id exist
        if ((DataStoreCont.getMaxNumOfContracts() > contractId)||(DataStoreCont.getNumOfFunctionsInContract(contractId) > functionId)){
            revert("The contractId and the functionId need to be in range");
        } else {
            DataStoreCont.addParamsToSmartContractFunction(contractId, functionId, paramNames);
        }
        
    }
    

    
        	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function deleteSmartContractPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function
                    uint contractID = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);

                    //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
                    deleteSmartContract(contractID);
    	       
    	    }

    }

    //IMPORTANT NEEDS TO RETURN TO PRIVATE BEFORE DEPLOYMENT    
    function deleteSmartContract(uint contractID) public {
        
         DataStoreCont.deleteSmartContract(contractID);
        
    }
    

	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractAddrPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
                    uint contractID = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
                    address contractAddress = bytes32ToAddress(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 0));

                    //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
                    setSmartContractAddr(contractID, contractAddress);
    	       
    	    }

    }
    
    function setSmartContractAddr(uint contractID, address contractAddr) private {
        
         DataStoreCont.setSmartContractAddress(contractID, contractAddr);
        
    }

	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractPermListAddrPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
                    uint contractID = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
                    address permListAddress = bytes32ToAddress(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 0));

                    //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
                    setSmartContractPermListAddr(contractID, permListAddress);
    	       
    	    }
        
    }
    
    function setSmartContractPermListAddr(uint contractID, address permListAddr) private {
        
         DataStoreCont.setSmartContractPermListAddress(contractID, permListAddr);
        
    }
    
    	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractDataStoreAddrPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
                    uint contractID = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
                    address dataStoreAddr = bytes32ToAddress(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 0));

                    //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
                    setSmartContractDataStoreAddr(contractID, dataStoreAddr);
    	       
    	    }
        
    }
    
    function setSmartContractDataStoreAddr(uint contractID, address dataStoreAddr) private {
        
         DataStoreCont.setSmartContractDataStoreAddress(contractID, dataStoreAddr);
        
    }
    
    	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function setSmartContractVersionPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
                    uint contractID = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
                    uint version = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 1);

                    //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
                    setSmartContractVersionAddr(contractID, version);
    	       
    	    }
        
    }
    
    function setSmartContractVersionAddr(uint contractID, uint version) private {
        
         DataStoreCont.setSmartContractVersion(contractID, version);
        
    }
    
        	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addPermTemplateToFunctionPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
//                    uint contractID = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
  //                  uint version = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 1);

                    //record that this permission instance has been used
    //	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
     //               addPermTemplateToFunction(uint contractID, uint functionID, uint PermInstId);
    	       
    	    }
        
    }
    
    //TO DO ABOVE AND SET AS PRIVATE HERE
    function addPermTemplateToFunction(uint contractID, uint functionID, uint PermTemplateId) public {
        
        if (functionID <= DataStoreCont.getNumOfFunctionsInContract(contractID)){
             DataStoreCont.connectPermTemplateToFunction(contractID, functionID, PermTemplateId);
            
        } else {
            revert("The contractID is invalid");
        }
        
    }
    
            	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addPermInstanceToPermTemplatePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
  //                  uint contractID = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
    //                uint version = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 1);

                    //record that this permission instance has been used
    //	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
      //              setSmartContractVersionAddr(contractID, version);
    	       
    	    }
        
    }
    
    //TO DO SET AS PRIVATE AND DO ABOVE FUNCTION
    function addPermInstanceToPermTemplate(uint contractID, uint permTemplateId, uint PermInstId) public {
        
         DataStoreCont.connectPermInstanceToPermTemplate(contractID, permTemplateId, PermInstId);
        
    }
    
    
                	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function addSmartContractFunctionNamePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function and convert them from bytes32 if necessary
  //                  uint contractID = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 0);
    //                uint version = PermListCont.getPermissionInstanceUintAtPosition(PermInstId, 1);

                    //record that this permission instance has been used
    //	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
      //              setSmartContractVersionAddr(contractID, version);
    	       
    	    }
        
    }
    
    //TO DO SET AS PRIVATE AND DO ABOVE FUNCTION
    function addSmartContractFunctionName(uint contractID, string functionName, bool permissioned) public {
        
        DataStoreCont.addSmartContractFunction(contractID, functionName, permissioned);
        
    }
    
    //UPGRADE FUNCTIONS
    //upgrade permissionListAddr

        	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function upgradePermissionListPerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function
                    address permListAddr = bytes32ToAddress(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 0));

                    //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
                    upgradePermissionList(permListAddr);
    	       
    	    }

    }
    
    function upgradePermissionList(address newPermListAddr) private {
         
        PermListCont = PermissionListAbstract(newPermListAddr);
        address PermCheckAddr = PermListCont.GetPermissionCheckContr();
        if (PermCheckAddr!=address(0)){
            PermCheckCont = PermissionCheckAbstract(PermCheckAddr);
        } else {
            revert();
        }
        
    }
    
    //upgrade whitepages
	//** Allows a user to add a contract to the whitelist or modify a contract on the whitelist**//
	// @param PermInstId - The permissionInstance you want to use in this function call
	// @param shareClassUsed - whether this permissionInstance is owned by a shareclass (true) or an individual (false)
	// @param ShareClassIdSRCont - If a shareClass is the owner, then this will be the ID of that shareClass in the associated ShareholderRights contract
    function upgradeWhitePagesDataStorePerm(uint PermInstId, bool shareClassUsed, uint ShareClassIdSRCont) PermInstChecks(PermInstId, shareClassUsed, ShareClassIdSRCont) public {

            //get the associated permission template
    	    if (PermListCont.hasPermissionInstanceExpired(PermInstId) == false) {
    	        //if the permission instance has been used within its allotted time, then...

    	           //load the required variables to call the function
                    address newDataStoreAddr = bytes32ToAddress(PermListCont.getPermissionInstanceBytes32AtPosition(PermInstId, 0));

                    //record that this permission instance has been used
    	            PermCheckCont.PermissionHasBeenUsed(PermInstId);
                    
                    //call the function
                    upgradeWhitePagesDataStore(newDataStoreAddr);
    	       
    	    }

    }
    
    //CHANGE THIS IN THE FUTURE AS WELL
    function upgradeWhitePagesDataStore(address newDataStoreAddr) public {
         
            DataStoreCont = WhitePagesDataAbstract(newDataStoreAddr);
        
    }
    
    
    //GETTERS--the rest of the getters are held in the WhitePagesLogic contract.
    function getWhitePagesDataStoreAddress() public view returns(address) {
        
        return address(DataStoreCont);
        
    }
    
    function getPermissionListAddress() public view returns(address) {
        
        return address(PermListCont);
        
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
