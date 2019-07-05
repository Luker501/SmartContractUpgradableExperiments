 //Solidity online complier: https://remix.ethereum.org/

pragma solidity ^0.4.4;

//** This contract holds information on a company's definition, currently:
// - It's name
// - The share classes it has
// - The voting rights each share class has
// - The ricardian contract hash value linking to the legal contract represented by this smart contract 
//**

contract ComDef {

    string CompName = "";
	mapping(uint => string) ShareClasses;   //keeps track of all the share classes in the system
	mapping(uint => bool) VotingRights;		//keeps track of all the voting right of the share class with the same uint
	mapping(uint => uint) TotalShares;		//keeps track of the number of shares of the share class with the same uint
	string RicardianContract = "";			//holds the ricardian contract hash value
    address Owner;							//holds the address of the contract creator
    address ShareholderRightsCont;			//holds the address of the associated ShareholderRights.sol contract
	uint ArrayCounters = 0;					//Holds the counter regarding how many classes have been added to this contract
    
	/******** Start of blockchain events *********/
	
	//event fires when the contract has been added to the blockchain 
	event ContractOwner(string s, address a, address owner);	

	//event fires when the company name is changed			
	event CompanyName(string s, address a, string name);

	//event fires when a new share class has been added or modified	
	event ShareClass(string s, address a, string shareClass, bool votingRights, uint TotalShares, uint arrayID);

	//event fires the Ricardian contract hash is changed
	event RicContract(string s, address a, string ric);	

	//event fires when the ShareholderRights.sol contract address is changed
	event ShareholderRightsContract(string s, address ContractOwner, address ShareHolderRightsCont);				
	/******** End of blockchain events *********/
	
	/******** Start of modifiers *********/
	
	//** any function containing this modifier, only allows the contract owner to call it**//
	modifier ifOwner(){
        if(Owner != msg.sender){
            throw;
        }else{
            _; //means continue on the functions that called it
        }
    }
    
	//** any function containing this modifier, only allows the ShareholderRights contract to call it**//
    modifier ifShareholderRightsContract(){
        if(ShareholderRightsCont != msg.sender){
            throw;
        }else{
            _; //means continue on the functions that called it
        }
    }
	
	//** any function containing this modifier, only allows the function to be executed if all given variables have been assigned**//
    modifier varibleChecks(string name, string class, bool right, string hash){
        if (keccak256(name) == keccak256("")) {
            throw;
        }else if (keccak256(class) == keccak256("")) {
            
        }else if (keccak256(right) == keccak256("")) {
            
        }else if (keccak256(hash) == keccak256("")) {
            
        }else{
            _; //means continue on the functions that called it
        }
    }
    
	
	/******** End of Modifiers  *********/
	
	
	/******** Start of Functions  *********/
	
	//** The constructor sets the smart contract owner as the address/node that put this contract onto the blockchain**//
	function ComDef () public {
		//The creator of the contract is now the owner of this contract
	    Owner = msg.sender;
	    ContractOwner("The CompanyDefinition contract owner has been declared:", msg.sender, Owner);	//***EVENT: Owner
		return;
	}
	
	//** This function initialises the company information. **//
	// @param name - the name of the company
	// @param class - the first share class name for the company
	// @param right - the voting rights for the first share class, can they vote (true) or not (false)
	// @param hash - the string value representing the Ricardian contract hash
    function AddComDef (string name, string class, bool right, string hash) public ifOwner varibleChecks(name, class, right, hash){
        
	    //If arrayCounters is > 0 then this company will have already been initialised.
		if ((ArrayCounters> 0)) {
			throw;
		} else {
			//Firstly we set the more simple variables
			CompName = name;
			CompanyName("The company name has been set to:", msg.sender, CompName);		//***EVENT: Company Name
			RicardianContract = hash;
			RicContract("The Ricardian Contract hash has been set to:", msg.sender, RicardianContract);	//***EVENT: Ricardian Contract
			
			//now add the first share class. Including the initialisation of the TotalShares array.
		
			ShareClasses[0] = class;
			VotingRights[0] = right;
			TotalShares[0] = 0;
			ShareClass("The first share class has been added:", msg.sender, ShareClasses[0], VotingRights[0], 0, 1);	//***EVENT: ShareClass
			ArrayCounters = 1; 
				
		}
	}
	
	//** This function allows the owner of the contract to add another share class**//
	// @param class - the name of the new class to add
	// @param right - the voting rights for the first share class, can they vote (true) or not (false)
	function AddNewShareClass(string class, bool rights) public ifOwner {
	    
	     uint tempCounter = 0; //counter for searching the arrays
	     
	    //Add the new share class IF both the class and the rights variable have been passed through and the arrayCounter is > 0. If arrayCounters = 0 then the company needs to be initialised
		if (keccak256(class) != keccak256("")&&(keccak256(rights) != keccak256(""))&&(ArrayCounters>0)) {
			
			//search for the correct class
    		while (tempCounter < ArrayCounters){
    		    //make sure we are not adding a share class with the same name
    		    if (keccak256(class) == keccak256(ShareClasses[tempCounter])){
    		        throw;
    		    }
    		    tempCounter++;    
    		}
			
			//now add the next share class. Including the initialisation of the TotalShares array.
			ShareClasses[ArrayCounters] = class;
			VotingRights[ArrayCounters] = rights;
			TotalShares[ArrayCounters] = 0;
			ShareClass("A new share class has been added:", msg.sender, ShareClasses[ArrayCounters], VotingRights[ArrayCounters], TotalShares[ArrayCounters], ArrayCounters+1);	//***EVENT: ShareClass
			ArrayCounters++;
			
		} else {
		    //if no change was made then throw error
		    throw;
		}
		
	}
	

	//** This function allows the owner of the contract to edit the company name**//
	// @param newName - this is the new name of the company
	function EditComName (string newName) public {
	    
	    //Edit the current company name IF a new name variable was passed through
		if (keccak256(newName) != keccak256("")) {
			CompName = newName;
			CompanyName("The company name has been changed to:", msg.sender, CompName);		//***EVENT: Company Name
		} else {
		    //if no change was made then throw error
		    throw;
		}
		
	}
	
	//** This function allows the owner of the contract to edit the ricardian contract hash value**//
	// @param newHash - this is the new hash value of the ricardian contract
	function EditRicContract(string newHash) public ifOwner {
	    
		//Edit the current Ricardian Contract hash value IF a new hash variable was passed through
		if (keccak256(newHash) != keccak256("")){
			RicardianContract = newHash;
			RicContract("The Ricardian Contract hash has been set to:", msg.sender, RicardianContract);	//***EVENT: Ricardian Contract
		} else{
		    //if no change was made then throw error
		    throw;
		}
		
	}
	
	//** This function allows the contract owner to set the link to the associated ShareholderRights.sol smart contract, so that later the ShareholderRights smart contract can also call functions of this contract**//
	//@param SRcontract - the address of the shareholder rights smart contract
	function AddShareholderRightsContractAddress(address SRcontract) public ifOwner {
	     
	   	    ShareholderRightsCont = SRcontract;
    	    ShareholderRightsContract("The address of the ShareholderRights smart contract has been changed to:", msg.sender, ShareholderRightsCont);
	    
	}

	//** This function allows the shareholder rights smart contract to add (and remove) registered shares from the platform**//
	// @param class - the name of the share class to add/remove shares from
	// @param number - the number of shares to add/remove from the designed share class
	function AddShares(string class, uint number) public ifShareholderRightsContract {
	
		bool EditOccured = false; //keeps track of if a change has been made
		uint tempCounter = 0; //counter for searching the arrays
		
		//search for the correct class
		while (tempCounter < ArrayCounters){
				
			if (keccak256(ShareClasses[tempCounter]) == keccak256(class)){
			
				//when the correct class has been found...
				if (TotalShares[tempCounter] < number){
				    TotalShares[tempCounter] = 0;
				} else {
				    TotalShares[tempCounter] = TotalShares[tempCounter] + number;		//modify the share number (note you can add or minus)
				}
				ShareClass("The share number has changed:", msg.sender, ShareClasses[tempCounter], VotingRights[tempCounter], TotalShares[tempCounter], tempCounter+1);	//***EVENT: ShareClass
				tempCounter = ArrayCounters;
				EditOccured = true;
				
			}

			tempCounter++;
			
		}
		
		//If no change was made (because the class was not found) then throw error
		if(EditOccured == false){
            throw;
        }
		
	}
	
	//** This function allows the user to check that the given class was or was not added as the ArrayNum'th class	**//
	// @param class - the name of the class to check
	// @param ArrayNum - the number to check
	// @return bool - returns whether class was (true) or was not (false) the ArrayNum'th share class added to this smart contract
	function CheckShareClass(string class, uint ArrayNum) constant public returns(bool) {
        
        if (keccak256(ShareClasses[ArrayNum-1]) == keccak256(class)){
            return true;
        } else {
            return false;
        }
        
    }
	
	/******** End of Functions  *********/
    
	
	/******** Start of Getters  *********/

	//** Returns the owner of the contract**//
    function GetOwner() constant public returns(address) {
        return Owner; 
    }	
	
	//** Returns the company name**//
    function GetCompanyName() constant public returns(string) {
        return CompName; 
    }
	
	//** Returns the ArrayNum'th share class added to this smart contract**//
	// @param ArrayNum - the number to check
	function GetShareClasses(uint ArrayNum) constant public returns(string) {
        return ShareClasses[ArrayNum-1]; 
    }
	
	//** Returns the voting rights of the given share class**//
	// @param the share class to check
	function GetVotingRights(string class) constant public returns(bool) {
        
        uint tempCounter = 0; //counter for searching the arrays
		
		//search for the correct class
		while (tempCounter < ArrayCounters){
		 
		    if (keccak256(ShareClasses[tempCounter]) == keccak256(class)){
		        return VotingRights[tempCounter];       
		    }
		    tempCounter++;   
		}
        return false;
    }
	
	//** Returns the total number of shares of the given share class**//
	// @param the share class to check
	function GetTotalNumOfShares(string class) constant public returns(uint) {
        
        uint tempCounter = 0; //counter for searching the arrays
		
		//search for the correct class
		while (tempCounter < ArrayCounters){
		 
		    if (keccak256(ShareClasses[tempCounter]) == keccak256(class)){
		        return TotalShares[tempCounter];       
		    }
		    tempCounter++;   
		}
        return 0;
         
    }

	//** Returns the ricardian contract hash**//	
	function GetRicContract() constant public returns(string) {
        return RicardianContract; 
    }

	//** Returns the number of share classes on this smart contract**//
    function GetNumOfShareClasses() constant public returns(uint) {
        return ArrayCounters; 
    }
    
	//** Returns the connected shareholderRights.sol address**//
    function GetShareholdersRightsAdd() constant public returns(address){
        return ShareholderRightsCont;
    }
	
	/******** End of Getters  *********/

	/******** Destroy Contract ********/
    function remove() ifOwner public {
        selfdestruct(msg.sender);
    }
}
	

     
