//Solidity online complier: https://remix.ethereum.org/

pragma solidity ^0.4.4;
import "browser/CompanyDefinition.sol";
import "browser/ShareholderRights.sol";

//** This contract holds information on a company's shareholder voting platform, currently:
// - If there an ongoing election/vote
// - What is the vote question
// - How many votes have there been since the creation of this smart contract
// - What are the alternatives/options in this vote
// - Is this vote a special resolution or not
// - Who has voted so far
// - What alternative has a voter voted for
//**

contract ShareholderVoting {
    
    string Question = "";
    uint QuestionNumber = 0;
    address Owner;									//holds the address of the contract creator
    bool voteOngoing = false;
    bool SpecialResolution = false;
    mapping (uint => Alternative) Alternatives;
    uint AlternativeCount = 0;
    ComDef ComDefCont;								//holds the address of the associated CompanyDefinition.sol contract
    ShareholderRights RightsCont;					//holds the address of the associated ShareholderRights.sol contract
    mapping (address => Voter) voters;

    /******** Start of blockchain events *********/

	//event fires when the contract has been added to the blockchain
	event Initialised(string s, address a, address owner, address ComDefCont, address ShareRightsCont);

	//event fires when the another alternative has been added to the election
	event ElectionAlt(string mess, string question, address contractOwner, string alternativeName, uint voteCount, uint ArrayNum);

	//event fires when the an election has been created or more alternatives have been added
	event ElectionSetup(string mess,string question,  uint QuestionNum, bool SpecialResolution, bool voteOngoing, uint alts);

	//event fires when the an election has completed and the final totals are known
	event ElectionResult(string mess, string question, string alternativeName, uint voteCount, uint ArrayNum, bool pass);

	//event fires when a voter has cast their vote
	event Voted(string mess,string question, string altName, uint voteTotal, uint voteChange, address voter);

/******** End of blockchain events *********/

/******** Start of Structures *********/
 
    struct Alternative {
        string name;
        uint voteCount;
    }
    
    struct Voter {
        uint lastVote;
        uint alt;
        uint votesCast;
    }
    
    /******** End of Structures *********/
    
    /******** Start of Modifiers *********/
    
	//** any function containing this modifier, only allows the contract owner to call it**//
    modifier ifOwner(){
         if(Owner != msg.sender){
             throw;
        }else{
            _; //means continue on the functions that called it
         }
     }

	//** any function containing this modifier, only allows the function to be called if there is no ongoing vote**//	 
    modifier NoOngoingVote(){
     if(voteOngoing == true){
         throw;
     }else{
         _; //means continue on the functions that called it
     }
    }

	//** any function containing this modifier, only allows the function to be called if there is an ongoing vote**//	 
     modifier OngoingVote(){
         if(voteOngoing == false){
             throw;
         }else{
             _; //means continue on the functions that called it
         }
     }
     

     
/******** End of Modifiers *********/
     
/******** Start of Functions *********/

    //** The constructor sets the smart contract owner as the address/node that put this contract onto the blockchain and
	//	sets the link to the CompanyDefinition.sol contract and the ShareholderRights.sol contract **//
	// @param - the address link to the CompanyDefinition.sol smart contract
	// @param - the address link to the ShareholderRights.sol smart contract
     function ShareholderVoting (address ComDefAdd, address RightsAdd) public{
        
		Owner = msg.sender;
        
		//only allow the contract to be constructed if non-empty addresses were passed through
		if ((ComDefAdd != address(0))&&(RightsAdd != address(0))){
            
            Owner = msg.sender;
            ComDefCont = ComDef(ComDefAdd);
            RightsCont = ShareholderRights(RightsAdd);
            Initialised("The ShareholderVoting contract has been initialised:", msg.sender, Owner, ComDefAdd, RightsCont); //***EVENT: Owner
            
        } else {
           
           throw;
           
        }
     }
 
	  //** This function allows the contract owner to set up a new vote - if a vote is not currently ongoing**//
	  // @param q - the vote question
	  // @param altOne - the first alternative for the vote
	  // @param altTwo - the second alternative for the vote
	  // @param startnow - whether to start the election immediately (true) or wait (false)
	  // @param specRes - whether this vote is a specialResolution and so needs 75% of all cast votes to pass (true) or only 50% of all cast votes to pass (false)
     function SetUpNewVote(string q, string altOne, string altTwo, bool startnow, bool specRes) ifOwner NoOngoingVote() public {
    
         //only set up the vote if there is not a currently ongoing one AND two alternatives are present
        if ((keccak256(altOne) != keccak256(""))&&((keccak256(altTwo) != keccak256("")))) {
    
			//set the election parameters
            Question = q;
            SpecialResolution = specRes;
            QuestionNumber++; //we give the elections an id
            ElectionSetup("A new election is being created:", q, QuestionNumber, specRes, startnow, AlternativeCount);
            Alternatives[0].name = altOne;
            Alternatives[0].voteCount = 0;
            Alternatives[1].name = altTwo;
            Alternatives[1].voteCount = 0;
            AlternativeCount = 2;
            ElectionAlt("A new alternative has been added to the election:",q,  msg.sender, altOne, 0, 1);
            ElectionAlt("A new alternative has been added to the election:",q,  msg.sender, altTwo, 0, 2);
            voteOngoing = startnow;
            if (voteOngoing == true){
 
                ElectionSetup("The election is commencing:", q, QuestionNumber, specRes, startnow, AlternativeCount);
            }

        } else {

            throw;

        }
 
    }

	//** This function allows the contract owner to add a new alternative to be added to the current vote, if 
	//		there is no ongoing vote, but the election has been set up through the SetUpNewVote function	**//
	// @param q - must match the question of the currently setup vote
	// @param altNew - the new alternative to be added as an option to the currently setup vote
	// @param startnow - whether the vote should commence as soon as this new alternative has been added (true) or not (false)
    function AddNewAlternative(string q, string altNew, bool startnow) ifOwner NoOngoingVote() public {

        //can only add a new alternative if:
        //(i) the new alternative is not equal to nothing, (ii) a new vote has been set up, (iii) the passed through q is equal to the question, 
        // and (iv) the new alternative is not currently an option
        if (((keccak256(altNew) != keccak256(""))&&((AlternativeCount >= 2)))&&(keccak256(Question) == keccak256(q))&&(checkForPreviousAlt(altNew) == false)) {
 
            Alternatives[AlternativeCount].name = altNew;
            Alternatives[AlternativeCount].voteCount = 0;
            ElectionAlt("A new alternative has been added to the election",q, msg.sender, altNew, 0, AlternativeCount);
            AlternativeCount++;
            voteOngoing = startnow;
            
            if (voteOngoing == true){

                ElectionSetup("The election is commencing:", q, QuestionNumber, SpecialResolution, startnow, AlternativeCount);

            }

        } else{
            throw;
        }

    }
    
	//** This function allows a shareholder to vote only if there is an ongoing vote. 
	// Note that in this function we pick up the voters address with msg.sender **//
	// @param alt - the alternative selected by the shareholder
    function Vote(string alt) OngoingVote() public returns(string) {

        //check that the alternative alt is valid
        uint ID = GetAlternativeID(alt);
        if (ID == 0){
            return "ID is not valid";
        }

        //need to check that this voter can vote -> by checking the associated ShareholderRights.sol contract
        if (RightsCont.CanShareholderVote(msg.sender) == true){
            
			//If the shareholder can vote...
			//then they need to find this voter's weight -> by checking the associated ShareholderRights.sol contract
            uint ShareWeight = RightsCont.HowManyShareholderVotes(msg.sender);
            
			if (ShareWeight <= 0){
                return "Share weight is not valid";
            }
            
			//check to see if this voter has already voted in this election
            if (voters[msg.sender].lastVote != QuestionNumber){
				
				//if here, we know that this voter has not previously voted in this election so
                //we can register the vote for the first time
                Alternatives[ID-1].voteCount = Alternatives[ID-1].voteCount + ShareWeight; //must use ID-1 here as the GetAlternativeID function always returns an extra 1 on the ID
                voters[msg.sender].lastVote = QuestionNumber; //make sure that we tag this voter as voting in this election
                voters[msg.sender].alt = ID; //This tag is set so we know where this voter's votes have been cast (make sure to -1 later if used)
                voters[msg.sender].votesCast = ShareWeight; //This tag records how many votes were cast by the user in the last vote. Note that the voter could have bought more shares since the last time 
                //she voted, hence the reason we are not relying on the voters local variable, but calling the ShareholderRights.sol contract to set ShareWeight.
                
				Voted("Voter has placed a new vote:",Question, alt, Alternatives[ID-1].voteCount, ShareWeight, msg.sender);
                return "Voter has placed a new vote";
				
            } else{
               
			   //if here, we know that this voter previously voted in this election so
			   //we have to change the voter's registered vote, and edit the tallies accordingly 
               uint IDtoChange = voters[msg.sender].alt;
               uint votesToMinus = voters[msg.sender].votesCast;	//how many votes should we take away from this voter's previously selected option?
               Alternatives[IDtoChange-1].voteCount = Alternatives[IDtoChange-1].voteCount - votesToMinus;
               
			   //now increase the newly selected option by the correct amount
			   Alternatives[ID-1].voteCount = Alternatives[ID-1].voteCount + ShareWeight; //must use ID-1 here as the GetAlternativeID function always returns an extra 1 on the ID
               
			   voters[msg.sender].lastVote = QuestionNumber; //make sure that we tag this voter as voting in this election
               voters[msg.sender].alt = ID; //This tag is set so we know where this voters votes have been cast (make sure to -1 later if used)
               voters[msg.sender].votesCast = ShareWeight; //This tag records how many votes were cast by the user in the last vote. Note that the voter could have bought more shares since the last time 
               
			   Voted("Voter has removed votes:",Question, Alternatives[IDtoChange-1].name, Alternatives[IDtoChange-1].voteCount, votesToMinus, msg.sender);
               Voted("Voter has modified his/her vote::",Question, alt, Alternatives[ID-1].voteCount, ShareWeight, msg.sender);
				return "Voter has modified his vote";
			
			}
        
		} else{
            return "Shareholder cannot vote";
        }
        
    }
    
	//**This function allows the contract owner to start or stop the ongoing election **//
	// @param startnow - this indicates whether to start the election (true) or stop it (false)
    function ChangeElectionStatus(bool startnow) ifOwner public {

        bool resolutionPassed;
        uint totalVotes;
        
		//only perform a change to the election status, if the election status is not equal to the currently desired status
		if (voteOngoing != startnow) {

            voteOngoing = startnow;
     
             if (voteOngoing == true){
 
				//if we have started the election, there is nothing left to do about from alert voters via this blockchain event
                 ElectionSetup("The following election has begun:", Question, QuestionNumber, SpecialResolution, startnow, AlternativeCount);
    
            } else{
 
                //the election has ended so lets print the results and reset everything
                ElectionSetup("The following election has ended:", Question, QuestionNumber, SpecialResolution, startnow, AlternativeCount);
                 uint tempCount = 0; 
               totalVotes = RightsCont.GetTotalVotingShares();

			   //loop through all of the alternatives and print each alternative's final vote count
			   //at the same time, highlight if any alternative passed (according to the special resolution or normal resolution count) 
                while (tempCount < AlternativeCount){
 
                    resolutionPassed = false;
                    if ((SpecialResolution == true)&&(totalVotes*75 <= Alternatives[tempCount].voteCount*100)){ 
                        //modified the maths so that there are no decimals involved as I'm not sure how solidity deals with them
                        resolutionPassed = true;
                    } else if ((SpecialResolution == false)&&(totalVotes*50 <= Alternatives[tempCount].voteCount*100)){
                        //modified the maths so that there are no decimals involved as I'm not sure how solidity deals with them
                        resolutionPassed = true;
                    }
                    ElectionResult("The final total for the alternative in this election is:", Question, Alternatives[tempCount].name, Alternatives[tempCount].voteCount, tempCount+1,resolutionPassed);

					//now reset the alternative name and count
                    Alternatives[tempCount].name = "";
                    Alternatives[tempCount].voteCount = 0;
                    tempCount++;
 
                 }
 
             Question = "";

         }

     } else{
	 
         throw;
		 
     }
 
 }
 
 /******** End of Main Functions *********/
 
 /******** Helper functions **************/

	//** This function allows the user to find the ID of the given alternative**//
	// @param altName - the alternative name to search for the ID
    function GetAlternativeID(string altName) private constant returns(uint) {
        
         uint tempCount = 0; 

        while (tempCount < AlternativeCount){
            if (keccak256(Alternatives[tempCount].name) == keccak256(altName)){
                return tempCount+1; //we need to +1 to all correct returns
            }
            tempCount++;
        }
        
        return 0; //return will not allow -1 so 0 is our error return indicator
    }

	//** This function allows the user to check if the given alternative has already been been listed as an option for the election (true) or not (false)**//
    // @param alt - the alternative to check if it has already been listed
	function checkForPreviousAlt(string alt) private returns(bool) {
	
		uint tempCount = 0;
		while (tempCount < AlternativeCount){
            if (keccak256(Alternatives[tempCount].name) == keccak256(alt)){
                return true;
            }
            tempCount++;
        }
	
		return false;
		
	}
 
 /******** End of helper functions *******/
 
 	/******** Start of Getters  *********/
	
	//** Returns the owner of the contract**//
	function GetOwner() constant public returns(address) {
        return Owner; 
    }
	
	//** Returns the current vote question**//
	function GetVoteQuestion() constant public returns(string) {
        return Question; 
    }

	//** Returns the current question number**//
    function GetQuestionNumber() constant public returns(uint) {
        return QuestionNumber; 
    }
    
	//** Returns the current election status**//	
    function GetElectionStatus() constant public returns(bool) {
        return voteOngoing; 
    }
    
	//** Returns whether the current election is for a special resolution (true) or not (false)**//	
    function GetSpecialResolution() constant public returns(bool) {
        return SpecialResolution; 
    }
    
	//** Returns the current total number of alternatives**//	
    function GetTotalAlternatives() constant public returns(uint) {
        return AlternativeCount; 
    }
	
	//** Returns AltNum'th alternative**//
	function GetAlternativeName(uint AltNum) constant public returns(string) {
        return Alternatives[AltNum-1].name; 
    }

	//** Returns AltNum'th vote count**//    
    function GetAlternativeVoteCount(uint AltNum) constant public returns(uint) {
        return Alternatives[AltNum-1].voteCount; 
    }
	
	//** Returns the shareholder's selected alternative**//
	// @param add - the address of the shareholder
	function GetVotersSelection(address add) constant public returns(uint) {
        
			return voters[add].lastVote; 
		
    }

	//** Returns the shareholder's vote weight for this specific question**//
	// @param add - the address of the shareholder	
	function GetShareholdersLastVote(address add) constant public returns(uint) {
        
		//if voter has voted on this question...
		if (voters[add].lastVote == QuestionNumber){
			//then return the number of votes cast
			return voters[add].votesCast; 
		} else{
			return 0;
		}
		
    }
    
    	//** Returns the last vote this shareholder participated in**//
	// @param add - the address of the shareholder	
	function GetVotersWeight(address add) constant public returns(uint) {
        
	
			return voters[add].votesCast; 
		
    }
    
	//** returns the associated CompanyDefinition.sol address **//
    function GetCompanyDefinitionAdd() constant public returns(address){
        return ComDefCont;
    }
	
	//** returns the associated ShareholderRights.sol address **//
	function GetShareholdersRightsAdd() constant public returns(address){
        return RightsCont;
    }

	/******** End of Getters  *********/


    /******** Destroy Contract ********/
    function remove() ifOwner public {
        selfdestruct(msg.sender);
    }
    
}
