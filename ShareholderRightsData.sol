//Solidity online complier: https://remix.ethereum.org/

pragma solidity ^0.4.21;
import "browser/ShareholderRightsDataAbstract.sol";

//** This contract holds information on a company's shareholder rights, currently:
// - Who the shareholders are (by blockchain address and name)
// - What share classes they own
// - How many of each share class they own
// - If a shareholder can vote
// - How many votes a shareholder has
//**

contract ShareholderRightsData is ShareholderRightsDataAbstract {

    address public Owner;					//holds the address of the contract creator
//    address permissionList;
    mapping (address => Voter) voters;		//keeps track of all the voters in the system
    uint TotalVotingShares = 0;				//keeps track of all the total voting shares for this company
    string RicardianContract = "";	
    string CompName = "";
    //how many classes added to this array
    uint ClassCounter = 0;	
    //all of the classes
    mapping(uint => ShareClass) classes;
    
    /******** Start of blockchain events *********/
	
	//event fires when the contract has been added to the blockchain
	event Initialised(string s, address a, address owner, address ComDefCont);
	
	//event fires when a shareholder has been added or changed
	event Shareholder(string s,  address shareHolder, string shareholderName, string class, uint shares, bool canVote, uint votingShares, uint arrayCounter);

	//event fires when a shareholder's name has been changed or the shareholder has been deleted
	event ShareholderName(string s, address shareHolder, string shareholderName);


	//event fires when the company name is changed			
	event CompanyName(string s, address a, string name);

	//event fires when a new share class has been added or modified	
	event ShareClassEvent(string s, address a, string shareClass, bool votingRights, uint TotalShares, uint arrayID);

	//event fires the Ricardian contract hash is changed
	event RicContract(string s, address a, string ric);	
				

	
    /******** End of blockchain events *********/
    
    /******** Start of Structures *********/
    
    struct Voter {
        string name;
        mapping (uint => uint) numOfShares;
        bool CanVote;
        uint VotingShares;
        uint totalShares;
        mapping (uint => uint) permissionInstances; 
        uint totalPermissionInstances;
    }
    
    struct ShareClass {
        
        string name;
        bool votingRights;
        uint totalShares;
        mapping (uint => uint) permissionInstances; 
        uint totalPermissionInstances;
    }
    
    /******** End of Structures *********/
    
    /******** Start of modifiers *********/
	
	//** any function containing this modifier, only allows the contract owner to call it**//
	modifier ifOwner(){
        if(Owner != msg.sender){
            revert("Not the contract owner");
        }else{
            _; //means continue on the functions that called it
        }
    }

	
	/******** End of Modifiers  *********/
	

	
	
	/******** Start of Functions  *********/

	//** The constructor sets the smart contract owner as the address/node that put this contract onto the blockchain and sets the link to the CompanyDefinition.sol contract**//
	// @param - the address link to the CompanyDefinition.sol smart contract
    constructor () public {
    
		//only allow the contract to be constructed if a non-empty address was passed through
            Owner = msg.sender;
            
    }    
    
    	//** This function initialises the company information. **//
	// @param name - the name of the company
	// @param class - the first share class name for the company
	// @param right - the voting rights for the first share class, can they vote (true) or not (false)
	// @param hash - the string value representing the Ricardian contract hash
    function AddComDef (string name, string hash) external ifOwner{
        
			CompName = name;
			emit CompanyName("The company name has been set to:", msg.sender, CompName);		//***EVENT: Company Name
			RicardianContract = hash;
			emit RicContract("The Ricardian Contract hash has been set to:", msg.sender, RicardianContract);	//***EVENT: Ricardian Contract

	}
	
		
	//** This function allows the owner of the contract to add another share class**//
	// @param class - the name of the new class to add
	// @param right - the voting rights for the first share class, can they vote (true) or not (false)
	function AddNewShareClass(string class, bool rights) external ifOwner {
	    

			ClassCounter +=1;
			classes[ClassCounter].name = class;
			classes[ClassCounter].votingRights = rights;
			classes[ClassCounter].totalShares = 0;
			classes[ClassCounter].totalPermissionInstances = 0;
			
			emit ShareClassEvent("A new share class has been added:", msg.sender, class, rights, 0, ClassCounter);	//***EVENT: ShareClass
			
	}
	
		//** This function allows the owner of the contract to edit the company name**//
	// @param newName - this is the new name of the company
	function EditComName (string newName) external ifOwner {
	    
	    //Edit the current company name IF a new name variable was passed through
			CompName = newName;
			emit CompanyName("The company name has been changed to:", msg.sender, CompName);		//***EVENT: Company Name

	}
	
		//** This function allows the owner of the contract to edit the ricardian contract hash value**//
	// @param newHash - this is the new hash value of the ricardian contract
	function EditRicContract(string newHash) external ifOwner {
	    
		//Edit the current Ricardian Contract hash value IF a new hash variable was passed through
			RicardianContract = newHash;
			emit RicContract("The Ricardian Contract hash has been set to:", msg.sender, RicardianContract);	//***EVENT: Ricardian Contract

	}
	
	function addPermissionInstanceToShareClass (uint permInstId, uint shareClassId) external ifOwner {
	    
	        classes[shareClassId].totalPermissionInstances +=1;
	        classes[shareClassId].permissionInstances[classes[shareClassId].totalPermissionInstances] = permInstId;

	}
	
		//** This function allows the shareholder rights smart contract to add (and remove) registered shares from the platform**//
	// @param class - the name of the share class to add/remove shares from
	// @param number - the number of shares to add/remove from the designed share class
	function ChangeNumberOfSharesInShareClass(uint classID, uint number, bool minusShares) public ifOwner {
	
	        if (minusShares == false){
	            classes[classID].totalShares += number;    
	        } else if ((minusShares == true)&&(number < classes[classID].totalShares)){
	            classes[classID].totalShares -= number;
	        } else {
	           classes[classID].totalShares = 0;
	        }
		    

	}
	

	//** Allows the contract owner to add a new share holder, only if all the variables are non-empty, the shareholder is NOT already present, and the share class does exist**//
	// @param name - the name of the new shareholder
	// @param add - the blockchain address linked to the new shareholder
	// @param class - the first share class that this shareholder owns
	// @param shares - how many shares of this share class does this shareholder own
	// @param ArrayNum - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
    function AddNewShareholder(string name, address add, string class, uint shares, uint classId) ifOwner external {

 
            bool votingRights = GetShareClassVotingRights(classId);	//get the voting rights associated with this share class
            
			//set the variables associated with this shareholder
            voters[add].name = name;
  //          voters[add].shareClasses[classId] = class;
            voters[add].numOfShares[classId] = shares;
            voters[add].totalShares = shares;
            voters[add].CanVote = votingRights;
            voters[add].totalPermissionInstances = 0;
            
			if (votingRights == true){
                voters[add].VotingShares = shares;
                TotalVotingShares += shares; //changes the total voting shares for all shareholders
            }

			//add the shares to the counter in the CompanyDefinition.sol smart contract
			ChangeNumberOfSharesInShareClass(classId, shares, false); //IMPORTANT NOTE that I am assuming if this call reverts, the current function also reverts. (Otherwise there could be an issue)
            emit Shareholder("A new shareholder has been added:",  add, name, class, shares, votingRights, shares,  classId);  // EVENT: Shareholder

    }
    
    	
	function addPermissionInstanceToShareholder (uint permInstId, address shareholderAddr) external ifOwner {
	    
	        voters[shareholderAddr].totalPermissionInstances +=1;
	        voters[shareholderAddr].permissionInstances[voters[shareholderAddr].totalPermissionInstances] = permInstId;
	    
	}
	
    
    //** Allows the contract owner to add a new share class for a shareholder, only if all the variables are non-empty, the shareholder IS already present, and the share class does exist**//
	// @param name - the name of the current shareholder
	// @param add - the blockchain address linked to the current shareholder
	// @param class - the new class that this current shareholder owns
	// @param shares - how many shares of this share class does this shareholder own
	// @param ArrayNum - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
	//
	// NOTE THAT THIS FUNCTION SHOULD NOT BE USED IF YOU ARE ADDING SHARES TO A SHARE CLASS THAT THE SHAREHOLDER ALREADY OWNS, FOR THIS USE THE AddSharesToShareholder function
//    function AddNewShareClassForShareholder(string name, address add, string newClass, uint newShares, uint ArrayNum, uint classId) public {
        

  //          uint tempCount = voters[add].arrayCounter;
    //        bool votingRights = GetShareClassVotingRights(classId);		//get the voting rights associated with this share class
            
			//set the new share class variables
      //      voters[add].shareClasses[tempCount] = newClass;
        //    voters[add].totalShares[tempCount] = newShares;
          //  voters[add].arrayCounter++;
			
//            if (votingRights == true){
  //              voters[add].CanVote = votingRights; 		//if == false, do not change this as the voter may have another class of shares that can allow him to vote
    //            voters[add].VotingShares = voters[add].VotingShares + newShares;
      //          TotalVotingShares = TotalVotingShares + newShares; 		//changes the total voting shares for all shareholders
        //    }
          //   uint tempVoting = voters[add].VotingShares;
        
			//update the company definition contract on the number of shares held
//            AddShares(classId, newClass, newShares); //IMPORTANT NOTE that I am assuming if this call reverts, the current function also reverts. (Otherwise there could be an issue)
  //          emit Shareholder("A new share class has been added to a shareholder:", add, name, newClass, newShares, votingRights, tempVoting,tempCount+1);  // EVENT: Shareholder
            
//    }
	

    //** Allows the contract owner to add/take-away new shares to a share class that a current shareholder already holds, only if all the variables are non-empty, the shareholder IS already present, and the share class does exist**//
    // @param name - the current shareholder name
	// @param add - the blockchain address linked to the current shareholder
	// @param class - the current class that this current shareholder is adding/removing shares from
	// @param shares - how many shares of this share class will be added or removed
	// @param ArrayNum - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
	// @param shareholderArrayNum - the ID of the class in the current shareholders shareClass list
	function AddSharesToShareholder(string name, address add, string class, uint shares, uint classId) ifOwner  external {
        

			//gets the voting rights of the current share class
            bool votingRights = GetShareClassVotingRights(classId);		
            
			//adds or removes the shares
            voters[add].numOfShares[classId] += shares;
            voters[add].totalShares += shares;
            
			if (votingRights == true){
			
				//if this share class has voting rights then will also need to add/remove votes from this shareholder
                voters[add].VotingShares = voters[add].VotingShares + shares;
                TotalVotingShares = TotalVotingShares + shares; //changes the total voting shares for all shareholders
            }
             uint tempVoting = voters[add].VotingShares;
        
			//we need to update the CompanyDefinition.sol smart contract
            ChangeNumberOfSharesInShareClass(classId, shares, false); //IMPORTANT NOTE that I am assuming if this call reverts, the current function also reverts. (Otherwise there could be an issue)
            emit Shareholder("Shares have been added to a shareholder:", add, name, class, shares, votingRights, tempVoting,classId);  // EVENT: Shareholder
            

    }



    //** Allows the contract owner to add/take-away new shares to a share class that a current shareholder already holds, only if all the variables are non-empty, the shareholder IS already present, and the share class does exist**//
    // @param name - the current shareholder name
	// @param add - the blockchain address linked to the current shareholder
	// @param class - the current class that this current shareholder is adding/removing shares from
	// @param shares - how many shares of this share class will be added or removed
	// @param ArrayNum - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
	// @param shareholderArrayNum - the ID of the class in the current shareholders shareClass list
	function RemoveSharesFromShareholder(string name, address add, string class, uint shares, uint classId) ifOwner  external {
        

			//gets the voting rights of the current share class
            bool votingRights = GetShareClassVotingRights(classId);		
            
			//adds or removes the shares
			if (voters[add].numOfShares[classId] < shares){
			    voters[add].numOfShares[classId] = 0;
			} else{
			    voters[add].numOfShares[classId] -= shares;
			}
            if (voters[add].totalShares < shares){
			    voters[add].totalShares = 0;
			} else{
			    voters[add].totalShares -= shares;
			}
            
			if (votingRights == true){
			
				//if this share class has voting rights then will also need to add/remove votes from this shareholder
                voters[add].VotingShares = voters[add].VotingShares + shares;
                if (voters[add].VotingShares < shares){
    			    voters[add].VotingShares = 0;
    			} else{
    			    voters[add].VotingShares -= shares;
    			}
    			if (TotalVotingShares < shares){
    			    TotalVotingShares = 0;
    			} else{
    			    TotalVotingShares -= shares;
    			}
            }
             uint tempVoting = voters[add].VotingShares;
        
			//we need to update the shareClass smart contract
            ChangeNumberOfSharesInShareClass(classId, shares, false); //IMPORTANT NOTE that I am assuming if this call reverts, the current function also reverts. (Otherwise there could be an issue)
            emit Shareholder("Shares have been added to a shareholder:", add, name, class, shares, votingRights, tempVoting,classId);  // EVENT: Shareholder
            

    }

    
    //** This function allows the contract owner to edit the shareholder name**//
    // @param oldName - the current name of the shareholder
	// @param newName - the new name of the shareholder
	// @param add - the address of the shareholder
	function EditShareholderName( string newName, address add) ifOwner  external {

            voters[add].name = newName;
            emit ShareholderName("The shareholder's name has been edited:", add, voters[add].name);  // EVENT: Shareholder

    }
    
        //** Allows the contract owner to delete a shareholder. This function connects to the CompanyDefinition smart contract to keep the total number of registered shares up to date**//
	// @param name - the name of the current shareholder
	// @param add - the blockchain address linked to the current shareholder
    function DeleteShareholder(address add) ifOwner  external {
        voters[add].name = "";
        voters[add].CanVote = false;
        voters[add].VotingShares = 0;
        voters[add].totalShares = 0;
        voters[add].totalPermissionInstances = 0;

    }
    
    function transferOwnership (address newOwner) ifOwner external {
        Owner = newOwner;
    }
    
//    function changePermissionList (address permList)  ifOwner external {
//        permissionList = permList;
//    }
    
    	//** This function allows the user to check that the given class was or was not added as the ArrayNum'th class	**//
	// @param class - the name of the class to check
	// @param ArrayNum - the number to check
	// @return bool - returns whether class was (true) or was not (false) the ArrayNum'th share class added to this smart contract
	function CheckShareClass(string class, uint classId) constant public returns(bool) {
        
        if (keccak256(classes[classId].name) == keccak256(class)){
            return true;
        } else {
            return false;
        }
        
    }
    
    function deleteAPermissionInstanceFromShareholder (address add, uint permInstId) ifOwner external {
        voters[add].permissionInstances[permInstId] = 0;
    }
    
    function deleteAPermissionInstanceFromShareClass (uint classID, uint permInstId) ifOwner external {
        classes[classID].permissionInstances[permInstId] = 0;
    }
    
	/******** End of Functions  *********/    
	
	/******** Start of Getters  *********/
	
	//** Returns the owner of the contract**//
	function GetOwner() constant public returns(address) {
        return Owner; 
    }
    
//    function GetPermissionList() constant public returns(address) {
//        return permissionList; 
//    }
    
    	//** Returns the company name**//
    function GetCompanyName() constant public returns(string) {
        return CompName; 
    }
    
    	//** Returns the ArrayNum'th share class added to this smart contract**//
	// @param ArrayNum - the number to check
	function GetShareClassNumber() constant public returns(uint) {
        return ClassCounter; 
    }
    
    	//** Returns the ArrayNum'th share class added to this smart contract**//
	// @param ArrayNum - the number to check
	function GetShareClassName(uint ArrayNum) constant public returns(string) {
        return classes[ArrayNum].name; 
    }
    
        	//** Returns the ArrayNum'th share class added to this smart contract**//
	// @param ArrayNum - the number to check
	function GetShareClassVotingRights(uint ArrayNum) constant public returns(bool) {
        return classes[ArrayNum].votingRights; 
    }
	
	    	//** Returns the ArrayNum'th share class added to this smart contract**//
	// @param ArrayNum - the number to check
	function GetShareClassTotalShares(uint ArrayNum) constant public returns(uint) {
        return classes[ArrayNum].totalShares; 
    }
    
    	//** Returns the ricardian contract hash**//	
	function GetRicContract() constant public returns(string) {
        return RicardianContract; 
    }

	
	//** returns the shareholder name of the given address **//
	function GetShareholderName(address add) constant public returns(string) {
        return voters[add].name; 
    }

	//** returns the number of shares of the ArrayNum'th share class added to the shareholder at the given address **//	
	function GetShareholderCanVote(address add) constant public returns(bool) {
        return voters[add].CanVote; 
    }


	//** returns the number of shares of the ArrayNum'th share class added to the shareholder at the given address **//	
	function GetShareholderTotalShares(address add) constant public returns(uint) {
        return voters[add].totalShares; 
    }
    
    	//** returns the number of shares of the ArrayNum'th share class added to the shareholder at the given address **//	
	function GetShareholderTotalVotingShares(address add) constant public returns(uint) {
        return voters[add].VotingShares; 
    }
    
        	//** returns the number of shares of the ArrayNum'th share class added to the shareholder at the given address **//	
	function GetShareholderNumOfPermInst(address add) constant public returns(uint) {
        return voters[add].totalPermissionInstances; 
    }
    
            	//** returns the number of shares of the ArrayNum'th share class added to the shareholder at the given address **//	
	function GetShareholderNumOfSharesOfclass(address add, uint classId) constant public returns(uint) {
        return voters[add].numOfShares[classId]; 
    }
    
        
            	//** returns the number of shares of the ArrayNum'th share class added to the shareholder at the given address **//	
	function GetShareholderPermInst(address add, uint permInstId) constant public returns(uint) {
	    if (permInstId > voters[add].totalPermissionInstances){
	        revert("This is not a valid permission instance");
	    } else {
            return voters[add].permissionInstances[permInstId]; 
	    }
    }
    
	//** returns the total number of voting shares in this smart contract **//
    function GetTotalVotingShares() constant public returns(uint) {
        return TotalVotingShares; 
    }

	
	//** returns how many votes the shareholder of the given address has **//
	function HowManyShareholderVotes(address add) constant public returns(uint) {
        return voters[add].VotingShares; 
    }
	
	
	/******** End of Getters  *********/
    

}
	

     
