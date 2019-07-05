//Solidity online complier: https://remix.ethereum.org/

pragma solidity ^0.4.22;
import "browser/ShareholderRightsDataAbstract.sol";
import "browser/ShareholderRightsLogicAbstract.sol";

//** This contract holds information on a company's shareholder rights, currently:
// - Who the shareholders are (by blockchain address and name)
// - What share classes they own
// - How many of each share class they own
// - If a shareholder can vote
// - How many votes a shareholder has
//**

contract ShareholderRightsLogic is ShareholderRightsLogicAbstract {

    address private Owner;					//holds the address of the contract creator
    ShareholderRightsDataAbstract dataStore;
    
    /******** Start of blockchain events *********/
	
    /******** End of blockchain events *********/
    
    /******** Start of modifiers *********/
	
	//** any function containing this modifier, only allows the contract owner to call it**//
	modifier ifOwner(){
        if(Owner != msg.sender){
            revert("Not the contract owner");
        }else{
            _; //means continue on the functions that called it
        }
    }
	
	

	//** any function containing this modifier, only allows the function to be executed if all given variables have been assigned**//
    modifier varibleChecks(string name, address add, string class, uint shares){
        if (keccak256(name) == keccak256("")) {
            revert("Name is empty");
        }else if (keccak256(class) == keccak256("")) {
            revert("Class name is empty");
        }else if (add==address(0)) {
            revert("Address is empty");
        }else if (shares <= 0) {
            revert("shares is empty");
        }else{
            _; //means continue on the functions that called it
        }
    }
    
	
	//** any function containing this modifier, only allows the function to be executed if all given variables have been assigned**//
    modifier nameHashCheck(string name,  string hash){
        if (keccak256(name) == keccak256("")) {
            revert("Name is empty");
        }else if (keccak256(hash) == keccak256("")) {
            revert("Hash is empty");
        }else{
            _; //means continue on the functions that called it
        }
    }
    
    	
	//** any function containing this modifier, only allows the function to be called if the given address IS NOT used by a shareholder**//	 
	modifier shareholderNotPresent(address add){
        if (keccak256(dataStore.GetShareholderName(add)) != keccak256("")) {
            revert("Shareholder is present");
        }else{
            _; //means continue on the functions that called it
        }
    }

	//** any function containing this modifier, only allows the function to be called if the given address IS used by a shareholder**//	     
    modifier shareholderPresent(address add){
        if (keccak256(dataStore.GetShareholderName(add)) == keccak256("")) {
            revert("Shareholder is not present");
        }else{
            _; //means continue on the functions that called it
        }
    }
    
	
	/******** End of Modifiers  *********/
	

	
	
	/******** Start of Functions  *********/

	//** The constructor sets the smart contract owner as the address/node that put this contract onto the blockchain and sets the link to the CompanyDefinition.sol contract**//
	// @param - the address link to the CompanyDefinition.sol smart contract
    constructor (address ShareholderData) public {
            
        if (ShareholderData!=address(0)){
            
            Owner = msg.sender;
            dataStore = ShareholderRightsDataAbstract(ShareholderData);

        }else{
            revert("variables are required");
        }
            
    }    
    
    	//** This function initialises the company information. **//
	// @param name - the name of the company
	// @param class - the first share class name for the company
	// @param right - the voting rights for the first share class, can they vote (true) or not (false)
	// @param hash - the string value representing the Ricardian contract hash
    function AddComDef (string name, string hash) public ifOwner nameHashCheck(name, hash){
        
	    //If arrayCounters is > 0 then this company will have already been initialised.
		if (keccak256(name) == keccak256("")) {
			revert("Name has already been set");
		} else {
			//Firstly we set the more simple variables
		    dataStore.AddComDef(name, hash);
		
		}
	}
	
		
	//** This function allows the owner of the contract to add another share class**//
	// @param class - the name of the new class to add
	// @param right - the voting rights for the first share class, can they vote (true) or not (false)
	function AddNewShareClass(string class, bool rights) public ifOwner {
	    
	    //Add the new share class IF both the class and the rights variable have been passed through and the arrayCounter is > 0. If arrayCounters = 0 then the company needs to be initialised
		if (keccak256(class) == keccak256("")) {

            revert("A shareClass name is required");			

		} else {

			dataStore.AddNewShareClass(class, rights);

		}
		
	}
	
		//** This function allows the owner of the contract to edit the company name**//
	// @param newName - this is the new name of the company
	function EditComName (string newName) public ifOwner {
	    
	    //Edit the current company name IF a new name variable was passed through
		if (keccak256(newName) == keccak256("")) {
			//if no change was made then throw error
		    revert("New name needs to be something");

		} else {

			dataStore.EditComName(newName);
		}
		
	}
	
		//** This function allows the owner of the contract to edit the ricardian contract hash value**//
	// @param newHash - this is the new hash value of the ricardian contract
	function EditRicContract(string newHash) public ifOwner {
	    
		//Edit the current Ricardian Contract hash value IF a new hash variable was passed through
		if (keccak256(newHash) == keccak256("")){
		    //if no change was made then throw error
		    revert();
		} else{
            dataStore.EditRicContract(newHash);
		}
		
	}
	
	function addPermissionInstanceToShareClass (uint permInstId, uint shareClassId) public ifOwner() {
	    
	        dataStore.addPermissionInstanceToShareClass(permInstId, shareClassId);

	}
	
		//** This function allows the shareholder rights smart contract to add (and remove) registered shares from the platform**//
	// @param class - the name of the share class to add/remove shares from
	// @param number - the number of shares to add/remove from the designed share class
	function AddShares(uint classId, string class, uint number) public {
	
		if (keccak256(dataStore.GetShareClassName(classId)) != keccak256(class)){
		   revert("class name needs to match");
		} else {
		   dataStore.ChangeNumberOfSharesInShareClass(classId, number, false);
		}
		
	}


	

	//** Allows the contract owner to add a new share holder, only if all the variables are non-empty, the shareholder is NOT already present, and the share class does exist**//
	// @param name - the name of the new shareholder
	// @param add - the blockchain address linked to the new shareholder
	// @param class - the first share class that this shareholder owns
	// @param shares - how many shares of this share class does this shareholder own
	// @param ArrayNum - the ID of the class (used to check that a typo has not been made in the class variable)
    function AddNewShareholder(string name, address add, string class, uint shares, uint classId) ifOwner varibleChecks(name, add, class, shares) shareholderNotPresent(add)  public {

        if (dataStore.CheckShareClass(class, classId)==false){ //check arrayNum is correct for class name according to the CompanyDefinition.sol contract
            revert("Share class name must be correct");
            
        } else {
            dataStore.AddNewShareholder(name, add, class, shares, classId);
            
        }

    }
    
    	
	function addPermissionInstanceToShareholder (uint permInstId, address shareholderAddr) public ifOwner() {
	    
	       dataStore.addPermissionInstanceToShareholder(permInstId,shareholderAddr);


	}
	
    
    //** Allows the contract owner to add a new share class for a shareholder, only if all the variables are non-empty, the shareholder IS already present, and the share class does exist**//
	// @param name - the name of the current shareholder
	// @param add - the blockchain address linked to the current shareholder
	// @param class - the new class that this current shareholder owns
	// @param shares - how many shares of this share class does this shareholder own
	// @param ArrayNum - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
	//
	// NOTE THAT THIS FUNCTION SHOULD NOT BE USED IF YOU ARE ADDING SHARES TO A SHARE CLASS THAT THE SHAREHOLDER ALREADY OWNS, FOR THIS USE THE AddSharesToShareholder function
//    function AddNewShareClassForShareholder(string name, address add, string newClass, uint newShares,  uint classId) ifOwner varibleChecks(name, add, newClass, newShares) shareholderPresent(add) public {
        
        //only add a new share class if the contract owner has correctly matched the arrayNum for the className AND the shareholdername with the address
//        if ((dataStore.CheckShareClass(newClass, classId)==false)||(keccak256(dataStore.GetShareholderName(add)) != keccak256(name))){
//            revert("share class and shareholder name must be correct");            
//        } else{

//            dataStore.AddNewShareClassForShareholder(name, add, newClass, newShares, classId);          

  //      }
            
    //}
	

    //** Allows the contract owner to add/take-away new shares to a share class that a current shareholder already holds, only if all the variables are non-empty, the shareholder IS already present, and the share class does exist**//
    // @param name - the current shareholder name
	// @param add - the blockchain address linked to the current shareholder
	// @param class - the current class that this current shareholder is adding/removing shares from
	// @param shares - how many shares of this share class will be added or removed
	// @param classId - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
	// @param shareholderArrayNum - the ID of the class in the current shareholders shareClass list
	function AddSharesToShareholder(string name, address add, string class, uint shares, uint classId) ifOwner varibleChecks(name, add, class, shares) shareholderPresent(add) public {
        
        //only add a new share class if the contract owner has correctly matched the arrayNum for the className AND the shareholdername with the address AND the shareholderArrayNum with the class name
        if ((dataStore.CheckShareClass(class, classId)==false)||(keccak256(dataStore.GetShareholderName(add)) != keccak256(name))){
            revert("Share name and shareholder name must be correct");
			
        } else {
            
            dataStore.AddSharesToShareholder(name, add, class, shares, classId);
            
        }
        
	}


    
    //** This function allows the contract owner to edit the shareholder name**//
    // @param oldName - the current name of the shareholder
	// @param newName - the new name of the shareholder
	// @param add - the address of the shareholder
	function EditShareholderName(string oldname, string newName, address add) ifOwner shareholderPresent(add)  public {

		//only attempt to change the name if the current name matches the given oldname
        if (keccak256(dataStore.GetShareholderName(add)) != keccak256(oldname)){
            revert("Old name must be correct");
        } else{
            dataStore.EditShareholderName(newName, add);
        }
        
    }
    
    function RemoveSharesFromShareholder(string name, address add, string class, uint shares, uint classId) ifOwner shareholderPresent(add)  public {
    
        if ((keccak256(dataStore.GetShareholderName(add)) != keccak256(name))||(dataStore.CheckShareClass(class, classId)==false)){
            revert("shareholder and share class name must be correct");
        } else{
            dataStore.RemoveSharesFromShareholder(name, add, class, shares, classId);
        }
        
    }
    
        //** Allows the contract owner to delete a shareholder. This function connects to the CompanyDefinition smart contract to keep the total number of registered shares up to date**//
	// @param name - the name of the current shareholder
	// @param add - the blockchain address linked to the current shareholder
    function DeleteShareholder(string name, address add) ifOwner shareholderPresent(add) public {
        
        //only delete the shareholder if the contract owner has correctly matched the shareholdername with the address
        if ((keccak256(dataStore.GetShareholderName(add)) != keccak256(name))||(dataStore.GetShareholderTotalShares(add)>0)){

           revert("shareholder name must be accurate");
            
        } else{
            
            dataStore.DeleteShareholder(add);

        }
            
    }
    
    function transferOwnership (address newOwner) ifOwner external {
        Owner = newOwner;
    }
    

    
	/******** End of Functions  *********/    
	
	/******** Start of Getters  *********/
	
	//** Returns the owner of the contract**//
	function GetOwner() constant public returns(address) {
        return Owner; 
    }
    
    function GetDataStore() constant external returns(address){
        return dataStore;
    }
	
	/******** End of Getters  *********/
    

}
	

     
