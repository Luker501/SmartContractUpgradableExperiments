//Solidity online complier: https://remix.ethereum.org/

pragma solidity ^0.4.22;

//** This contract holds information on a company's shareholder rights, currently:
// - Who the shareholders are (by blockchain address and name)
// - What share classes they own
// - How many of each share class they own
// - If a shareholder can vote
// - How many votes a shareholder has
//**

contract ShareholderRightsLogicAbstract {

    address private Owner;					//holds the address of the contract creator

    /******** Start of blockchain events *********/
	
    /******** End of blockchain events *********/
    

	/******** Start of Functions  *********/


    	//** This function initialises the company information. **//
	// @param name - the name of the company
	// @param class - the first share class name for the company
	// @param right - the voting rights for the first share class, can they vote (true) or not (false)
	// @param hash - the string value representing the Ricardian contract hash
    function AddComDef (string name, string hash) public;
	
		
	//** This function allows the owner of the contract to add another share class**//
	// @param class - the name of the new class to add
	// @param right - the voting rights for the first share class, can they vote (true) or not (false)
	function AddNewShareClass(string class, bool rights) public;
	
		//** This function allows the owner of the contract to edit the company name**//
	// @param newName - this is the new name of the company
	function EditComName (string newName) public;
	
		//** This function allows the owner of the contract to edit the ricardian contract hash value**//
	// @param newHash - this is the new hash value of the ricardian contract
	function EditRicContract(string newHash) public;
	
	function addPermissionInstanceToShareClass (uint permInstId, uint shareClassId) public;
	
		//** This function allows the shareholder rights smart contract to add (and remove) registered shares from the platform**//
	// @param class - the name of the share class to add/remove shares from
	// @param number - the number of shares to add/remove from the designed share class
	function AddShares(uint classId, string class, uint number) public;

	

	//** Allows the contract owner to add a new share holder, only if all the variables are non-empty, the shareholder is NOT already present, and the share class does exist**//
	// @param name - the name of the new shareholder
	// @param add - the blockchain address linked to the new shareholder
	// @param class - the first share class that this shareholder owns
	// @param shares - how many shares of this share class does this shareholder own
	// @param ArrayNum - the ID of the class (used to check that a typo has not been made in the class variable)
    function AddNewShareholder(string name, address add, string class, uint shares, uint classId) public ;
    
    	
	function addPermissionInstanceToShareholder (uint permInstId, address shareholderAddr) public;
	
    
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
	function AddSharesToShareholder(string name, address add, string class, uint shares, uint classId) public;


    
    //** This function allows the contract owner to edit the shareholder name**//
    // @param oldName - the current name of the shareholder
	// @param newName - the new name of the shareholder
	// @param add - the address of the shareholder
	function EditShareholderName(string oldname, string newName, address add)  public;
    
    function RemoveSharesFromShareholder(string name, address add, string class, uint shares, uint classId)  public;
    
        //** Allows the contract owner to delete a shareholder. This function connects to the CompanyDefinition smart contract to keep the total number of registered shares up to date**//
	// @param name - the name of the current shareholder
	// @param add - the blockchain address linked to the current shareholder
    function DeleteShareholder(string name, address add) public;
    
    function transferOwnership (address newOwner) external;
    
    function changePermissionList (address permList)  external;
    
	/******** End of Functions  *********/    
	
	/******** Start of Getters  *********/
	
	//** Returns the owner of the contract**//
	function GetOwner() constant public returns(address);
    
    function GetDataStore() constant external returns(address);
	
	/******** End of Getters  *********/
    

}
	

     
