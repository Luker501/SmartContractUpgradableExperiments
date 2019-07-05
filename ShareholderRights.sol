//Solidity online complier: https://remix.ethereum.org/

pragma solidity ^0.4.4;
import "browser/CompanyDefinition.sol";

//** This contract holds information on a company's shareholder rights, currently:
// - Who the shareholders are (by blockchain address and name)
// - What share classes they own
// - How many of each share class they own
// - If a shareholder can vote
// - How many votes a shareholder has
//**

contract ShareholderRights {

    address public Owner;					//holds the address of the contract creator
    ComDef ComDefCont;						//holds the address of the associated CompanyDefinition.sol contract
    mapping (address => Voter) voters;		//keeps track of all the voters in the system
    uint TotalVotingShares = 0;				//keeps track of all the total voting shares for this company
    
    /******** Start of blockchain events *********/
	
	//event fires when the contract has been added to the blockchain
	event Initialised(string s, address a, address owner, address ComDefCont);
	
	//event fires when a shareholder has been added or changed
	event Shareholder(string s,  address shareHolder, string shareholderName, string class, uint shares, bool canVote, uint votingShares, uint arrayCounter);

	//event fires when a shareholder's name has been changed or the shareholder has been deleted
	event ShareholderName(string s, address shareHolder, string shareholderName);
	
    /******** End of blockchain events *********/
    
    /******** Start of Structures *********/
    
    struct Voter {
        string name;
        mapping (uint => string) shareClasses;
        mapping (uint => uint) totalShares;
        uint arrayCounter;
        bool CanVote;
        uint VotingShares;
    }
    
    /******** End of Structures *********/
    
    /******** Start of modifiers *********/
	
	//** any function containing this modifier, only allows the contract owner to call it**//
	modifier ifOwner(){
        if(Owner != msg.sender){
            throw;
        }else{
            _; //means continue on the functions that called it
        }
    }
	
	//** any function containing this modifier, only allows the function to be called if the given address IS NOT used by a shareholder**//	 
	modifier shareholderNotPresent(address add){
        if (keccak256(voters[add].name) != keccak256("")) {
            throw;
        }else{
            _; //means continue on the functions that called it
        }
    }

	//** any function containing this modifier, only allows the function to be called if the given address IS used by a shareholder**//	     
    modifier shareholderPresent(address add){
        if (keccak256(voters[add].name) == keccak256("")) {
            throw;
        }else{
            _; //means continue on the functions that called it
        }
    }

	//** any function containing this modifier, only allows the function to be executed if all given variables have been assigned**//
    modifier varibleChecks(string name, address add, string class, uint shares){
        if (keccak256(name) == keccak256("")) {
            throw;
        }else if (keccak256(class) == keccak256("")) {
            throw;
        }else if (add==address(0)) {
            throw;
        }else if (shares <= 0) {
            throw;
        }else{
            _; //means continue on the functions that called it
        }
    }
    
	
	/******** End of Modifiers  *********/
	
	
	/******** Start of Functions  *********/

	//** The constructor sets the smart contract owner as the address/node that put this contract onto the blockchain and sets the link to the CompanyDefinition.sol contract**//
	// @param - the address link to the CompanyDefinition.sol smart contract
    function ShareholderRights (address ComDefAdd) public {
        
		//only allow the contract to be constructed if a non-empty address was passed through
        if (ComDefAdd!=address(0)){
            
            Owner = msg.sender;
            ComDefCont = ComDef(ComDefAdd);
            Initialised("The ShareholderRights contract has been initialised:", msg.sender, Owner, ComDefAdd);	//***EVENT: Owner
            
        } else {
           
           throw;
           
        }
        
    }    

	//** Allows the contract owner to add a new share holder, only if all the variables are non-empty, the shareholder is NOT already present, and the share class does exist**//
	// @param name - the name of the new shareholder
	// @param add - the blockchain address linked to the new shareholder
	// @param class - the first share class that this shareholder owns
	// @param shares - how many shares of this share class does this shareholder own
	// @param ArrayNum - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
    function AddNewShareholder(string name, address add, string class, uint shares, uint ArrayNum) ifOwner varibleChecks(name, add, class, shares) shareholderNotPresent(add)  public {

        if (ComDefCont.CheckShareClass(class, ArrayNum)){ //check arrayNum is correct for class name according to the CompanyDefinition.sol contract

            bool votingRights = ComDefCont.GetVotingRights(class);	//get the voting rights associated with this share class
            
			//set the variables associated with this shareholder
            voters[add].name = name;
            voters[add].shareClasses[0] = class;
            voters[add].totalShares[0] = shares;
            voters[add].arrayCounter = 1;
            voters[add].CanVote = votingRights;
            
			if (votingRights == true){
                voters[add].VotingShares = shares;
                TotalVotingShares = TotalVotingShares + shares; //changes the total voting shares for all shareholders
            }

			//add the shares to the counter in the CompanyDefinition.sol smart contract
			ComDefCont.AddShares(class, shares); //IMPORTANT NOTE that I am assuming if this call reverts, the current function also reverts. (Otherwise there could be an issue)
            Shareholder("A new shareholder has been added:",  add, name, class, shares, votingRights, shares,  1);  // EVENT: Shareholder

        } else {
            throw;
        }

    }
	
    
    //** Allows the contract owner to add a new share class for a shareholder, only if all the variables are non-empty, the shareholder IS already present, and the share class does exist**//
	// @param name - the name of the current shareholder
	// @param add - the blockchain address linked to the current shareholder
	// @param class - the new class that this current shareholder owns
	// @param shares - how many shares of this share class does this shareholder own
	// @param ArrayNum - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
	//
	// NOTE THAT THIS FUNCTION SHOULD NOT BE USED IF YOU ARE ADDING SHARES TO A SHARE CLASS THAT THE SHAREHOLDER ALREADY OWNS, FOR THIS USE THE AddSharesToShareholder function
    function AddNewShareClassForShareholder(string name, address add, string newClass, uint newShares, uint ArrayNum) ifOwner varibleChecks(name, add, newClass, newShares) shareholderPresent(add) public {
        
        //only add a new share class if the contract owner has correctly matched the arrayNum for the className AND the shareholdername with the address
        if ((ComDefCont.CheckShareClass(newClass, ArrayNum))&&(keccak256(voters[add].name) == keccak256(name))){
            
            uint tempCount = voters[add].arrayCounter;
            bool votingRights = ComDefCont.GetVotingRights(newClass);		//get the voting rights associated with this share class
            
			//set the new share class variables
            voters[add].shareClasses[tempCount] = newClass;
            voters[add].totalShares[tempCount] = newShares;
            voters[add].arrayCounter++;
			
            if (votingRights == true){
                voters[add].CanVote = votingRights; 		//if == false, do not change this as the voter may have another class of shares that can allow him to vote
                voters[add].VotingShares = voters[add].VotingShares + newShares;
                TotalVotingShares = TotalVotingShares + newShares; 		//changes the total voting shares for all shareholders
            }
             uint tempVoting = voters[add].VotingShares;
        
			//update the company definition contract on the number of shares held
            ComDefCont.AddShares(newClass, newShares); //IMPORTANT NOTE that I am assuming if this call reverts, the current function also reverts. (Otherwise there could be an issue)
            Shareholder("A new share class has been added to a shareholder:", add, name, newClass, newShares, votingRights, tempVoting,tempCount+1);  // EVENT: Shareholder
            
        } else{
            throw;
        }
            
    }
	

    //** Allows the contract owner to add/take-away new shares to a share class that a current shareholder already holds, only if all the variables are non-empty, the shareholder IS already present, and the share class does exist**//
    // @param name - the current shareholder name
	// @param add - the blockchain address linked to the current shareholder
	// @param class - the current class that this current shareholder is adding/removing shares from
	// @param shares - how many shares of this share class will be added or removed
	// @param ArrayNum - the ID of the class in the CompanyDefinition.sol contract (used to check that a typo has not been made in the class variable)
	// @param shareholderArrayNum - the ID of the class in the current shareholders shareClass list
	function AddSharesToShareholder(string name, address add, string class, uint shares, uint classArrayNum, uint shareholderArrayNum) ifOwner varibleChecks(name, add, class, shares) shareholderPresent(add) public {
        
        //only add a new share class if the contract owner has correctly matched the arrayNum for the className AND the shareholdername with the address AND the shareholderArrayNum with the class name
        if ((ComDefCont.CheckShareClass(class, classArrayNum))&&(keccak256(voters[add].name) == keccak256(name))&&(keccak256(voters[add].shareClasses[shareholderArrayNum-1]) == keccak256(class))){
            
			//gets the voting rights of the current share class
            bool votingRights = ComDefCont.GetVotingRights(class);		
            
			//adds or removes the shares
            voters[add].totalShares[shareholderArrayNum-1] = voters[add].totalShares[shareholderArrayNum-1] + shares;
            
			if (votingRights == true){
			
				//if this share class has voting rights then will also need to add/remove votes from this shareholder
                voters[add].VotingShares = voters[add].VotingShares + shares;
                TotalVotingShares = TotalVotingShares + shares; //changes the total voting shares for all shareholders
            }
             uint tempVoting = voters[add].VotingShares;
        
			//we need to update the CompanyDefinition.sol smart contract
            ComDefCont.AddShares(class, shares); //IMPORTANT NOTE that I am assuming if this call reverts, the current function also reverts. (Otherwise there could be an issue)
            Shareholder("More shares of a current class has been added to a shareholder:", add, name, class, shares, votingRights, tempVoting,shareholderArrayNum);  // EVENT: Shareholder
            
        } else{
            throw;
        }
            
    }


    
    //** This function allows the contract owner to edit the shareholder name**//
    // @param oldName - the current name of the shareholder
	// @param newName - the new name of the shareholder
	// @param add - the address of the shareholder
	function EditShareholderName(string oldname, string newName, address add) ifOwner shareholderPresent(add)  public {

		//only attempt to change the name if the current name matches the given oldname
        if (keccak256(voters[add].name) == keccak256(oldname)){
            voters[add].name = newName;
            ShareholderName("The shareholder's name has been edited:", add, voters[add].name);  // EVENT: Shareholder
        } else{
            
            throw;
        }
        
    }
    
        //** Allows the contract owner to delete a shareholder. This function connects to the CompanyDefinition smart contract to keep the total number of registered shares up to date**//
	// @param name - the name of the current shareholder
	// @param add - the blockchain address linked to the current shareholder
    function DeleteShareholder(string name, address add) ifOwner shareholderPresent(add) public {
        
        //only delete the shareholder if the contract owner has correctly matched the shareholdername with the address
        if (keccak256(voters[add].name) == keccak256(name)){
            
            uint numOfClasses = voters[add].arrayCounter;
            uint Count = 0;

            while (Count < numOfClasses){
                //remove the shares from the CompanyDefinition smart contract
                uint removeShares = 0 - voters[add].totalShares[Count];
                ComDefCont.AddShares(voters[add].shareClasses[Count], removeShares); //IMPORTANT NOTE that I am assuming if this call reverts, the current function also reverts. (Otherwise there could be an issue)
                
                //remove the shares from this contract
                TotalVotingShares = TotalVotingShares - removeShares;
                
                //now reset the share class variables in this smart contract
                voters[add].totalShares[Count] = 0;
                voters[add].shareClasses[Count] = "";
                Count = Count + 1;
            }
            
            //now reset the other variables for the shareholder
            voters[add].name = "";
            voters[add].CanVote = false;
            voters[add].arrayCounter = 0;
            voters[add].VotingShares = 0;
			
            ShareholderName("The following shareholder has been removed from the blockchain:", add, name); //EVENT SHAREHOLDER NAME
            
        } else{
            throw;
        }
            
    }
    
	/******** End of Functions  *********/    
	
	/******** Start of Getters  *********/
	
	//** Returns the owner of the contract**//
	function GetOwner() constant public returns(address) {
        return Owner; 
    }	
	
	//** returns the shareholder name of the given address **//
	function GetShareholderName(address add) constant public returns(string) {
        return voters[add].name; 
    }
	
	//** returns the ArrayNum'th share class name added to the shareholder at the given address **//
	function GetShareClass(address add, uint ArrayNum) constant public returns(string) {
        return voters[add].shareClasses[ArrayNum-1]; 
    }

	//** returns the number of shares of the ArrayNum'th share class added to the shareholder at the given address **//	
	function GetShareNumber(address add, uint ArrayNum) constant public returns(uint) {
        return voters[add].totalShares[ArrayNum-1]; 
    }
    
	//** returns the total number of voting shares in this smart contract **//
    function GetTotalVotingShares() constant public returns(uint) {
        return TotalVotingShares; 
    }

	//** returns if the shareholder of the given address can vote **//    
    function CanShareholderVote(address add) constant public returns(bool) {
        return voters[add].CanVote; 
    }
	
	//** returns how many votes the shareholder of the given address has **//
	function HowManyShareholderVotes(address add) constant public returns(uint) {
        return voters[add].VotingShares; 
    }
	
	//** returns how many share classes the shareholder of the given address has **//
	function HowManyShareClassesOwned(address add) constant public returns(uint) {
        return voters[add].arrayCounter; 
    }
	
	//** returns the associated CompanyDefinition.sol address **//
	function GetCompanyDefinitionAdd() constant public returns(address){
        return ComDefCont;
    }
	
	/******** End of Getters  *********/
    
    /******** Destroy Contract ********/
    function remove() ifOwner public {
        selfdestruct(msg.sender);
    }

}
	

     
