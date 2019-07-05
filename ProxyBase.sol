pragma solidity ^0.4.21;

import "browser/ProxyInterface.sol";
/*
 * @title ProxyBase
 * @author Luke Riley
 * @notice ProxyBase contracts hold links to the latest version of a certain contract. ProxyBase contracts by themselves are not meant to be upgradeable.
 *
 * @dev Both the Proxy and Upgradeable need to hae the target and initialized state variables stored in the exact
 * same storage location, which is why they must both inherit from Proxied. Defining them in the saparate contracts
 * does not work.
 *
 * @param target - This stores the current address of the target Upgradeable contract, which can be modified by
 * calling upgradeTo()
 *
 * @param initialized - This mapping records which targets have been initialized with the Upgradeable.initialize()
 * function. Target Upgradeable contracts can only be intitialed once.
 */
contract ProxyBase is ProxyInterface {
    
        //the name of the group of upgradeable contracts that this contract is proxying for 
      string proxyName;
        //the current main target of this proxy
      address public target;
        //whether a certain contract has had its variables initialized or not
      mapping (address => bool) public initialized;
        //the owner of this proxy
        address upgrader;
    
    //MODIFIERS
    modifier ifUpgrader(){
		if(msg.sender != upgrader){
		   revert();
		}else{
		    _; //means continue on the functions that called it
		}
    }
    
    
    //EVENTS
    
        //when a contract has been upgraded
      event EventUpgrade(address indexed newTarget, address indexed oldTarget, address indexed admin);
        //when a contract has been initialized
      event EventInitialized(address indexed target);
        //Owner change
      event UpgraderChanged(string explanation, address newUpgrader);
    
    
    //CONSTRUCTOR  
          /*
     * @notice Constructor sets the target and emmits an event with the first target
     * @param _target - The target Upgradeable contracts address
     */
    constructor(address _target) public {
        upgrader = msg.sender;
        upgradeTo(_target);
        emit UpgraderChanged("The owner of this contract has been initialised as:", upgrader);
    }


    //FUNCTIONS 
    
    function transferUpgradeCapability(address newUpgrader) ifUpgrader() public {
        upgrader = newUpgrader;
        emit UpgraderChanged("The upgrader of this contract has been initialised as:", upgrader);
    }
    
    /*
     * @notice Upgrades the contract to a different target that has a changed logic.
     * @dev See https://github.com/jackandtheblockstalk/upgradeable-proxy for what can and cannot be done in Upgradeable
     * contracts
     * @param _target - The target Upgradeable contracts address
     */
    function upgradeTo(address _target) ifUpgrader() public {
        assert(target != _target);

        address oldTarget = target;
        target = _target;

        emit EventUpgrade(_target, oldTarget, msg.sender);
    }

    /*
     * @notice Performs an upgrade and then executes a transaction. Intended use to upgrade and initialize atomically
     */
    function upgradeTo(address _target, bytes _data) public {
        upgradeTo(_target);
        assert(target.delegatecall(_data));
    }

    /*
     * @notice Fallback function that will execute code from the target contract to process a function call.
     * @dev Will use the delegatecall opcode to retain the current state of the Proxy contract and use the logic
     * from the target contract to process it.
     */
    function () payable public {
        bytes memory data = msg.data;
        address impl = target;

        assembly {
            let result := delegatecall(gas, impl, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    
        /*
     * @notice Performs an upgrade and then executes a transaction. Intended use to upgrade and initialize atomically
     */
    function getUpgrader() public view returns(address) {
        
        return upgrader;
    }
    
            /*
     * @notice Performs an upgrade and then executes a transaction. Intended use to upgrade and initialize atomically
     */
    function getTarget() public view returns(address) {
        
        return target;
    }
}
