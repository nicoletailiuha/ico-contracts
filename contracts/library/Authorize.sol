pragma solidity 0.4.24;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/access/rbac/RBAC.sol";
import "zeppelin-solidity/contracts/access/Whitelist.sol";

contract Authorize is Ownable, RBAC {
    string public constant ROLE_WHITELISTED = "whitelist";
    string public constant ROLE_ADMIN = "admin";

    address[] public dependencies;

    /** WHITELIST */

    /**
     * @dev Throws if operator is not whitelisted.
     * @param _operator address
     */
    modifier onlyIfWhitelisted(address _operator) {
        checkRole(_operator, ROLE_WHITELISTED);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param _operator address
     */
    function addAddressToWhitelist(address _operator)
        public
        onlyIfAdminOrOwner(msg.sender)
    {
        addRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev getter to determine if address is in whitelist
     */
    function whitelist(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev add addresses to the whitelist
     * @param _operators addresses
     */
    function addAddressesToWhitelist(address[] _operators)
        public
        onlyIfAdminOrOwner(msg.sender)
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToWhitelist(_operators[i]);
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param _operator address
     */
    function removeAddressFromWhitelist(address _operator)
        public
        onlyIfAdminOrOwner(msg.sender)
    {
        removeRole(_operator, ROLE_WHITELISTED);
    }

    /**
     * @dev remove addresses from the whitelist
     * @param _operators addresses
     */
    function removeAddressesFromWhitelist(address[] _operators)
        public
        onlyIfAdminOrOwner(msg.sender)
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromWhitelist(_operators[i]);
        }
    }

    /** ADMIN */

    /**
     * @dev Throws if operator is not admin.
     * @param _operator address
     */
    modifier onlyIfAdmin(address _operator) {
        checkRole(_operator, ROLE_ADMIN);
        _;
    }

    /**
     * @dev Throws if operator is not admin nor the owner.
     * @param _operator address
     */
    modifier onlyIfAdminOrOwner(address _operator) {
        require(hasRole(_operator, ROLE_ADMIN) || _operator == owner, "NotAdminNorOwner");
        _;
    }

    /**
     * @dev Add authorize dependency contract
     * @param _dependency Dependency whitelist contract address
     */
    function addAuthorizeDependency(address _dependency)
        public
        onlyOwner
    {
        dependencies.push(_dependency);
    }

    /**
     * @dev add an address to the admin
     * @param _operator address
     */
    function addAddressToAdmins(address _operator)
        public
        onlyOwner
    {
        addRole(_operator, ROLE_ADMIN);

        for (uint256 j = 0; j < dependencies.length; j++) {
            Whitelist _whitelist = Whitelist(dependencies[j]);
            _whitelist.addAddressToWhitelist(_operator);
        }
    }

    /**
     * @dev getter to determine if address is in admin
     */
    function admin(address _operator)
        public
        view
        returns (bool)
    {
        return hasRole(_operator, ROLE_ADMIN);
    }

    /**
     * @dev add addresses to the admin
     * @param _operators addresses
     */
    function addAddressesToAdmins(address[] _operators)
      public
      onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            addAddressToAdmins(_operators[i]);
        }

        for (uint256 j = 0; j < dependencies.length; j++) {
            Whitelist _whitelist = Whitelist(dependencies[j]);
            _whitelist.addAddressesToWhitelist(_operators);
        }
    }

    /**
     * @dev remove an address from the admin
     * @param _operator address
     */
    function removeAddressFromAdmins(address _operator)
        public
        onlyOwner
    {
        removeRole(_operator, ROLE_ADMIN);

        for (uint256 j = 0; j < dependencies.length; j++) {
            Whitelist _whitelist = Whitelist(dependencies[j]);
            _whitelist.removeAddressFromWhitelist(_operator);
        }
    }

    /**
     * @dev remove addresses from the admin
     * @param _operators addresses
     */
    function removeAddressesFromAdmins(address[] _operators)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _operators.length; i++) {
            removeAddressFromAdmins(_operators[i]);
        }
        
        for (uint256 j = 0; j < dependencies.length; j++) {
            Whitelist _whitelist = Whitelist(dependencies[j]);
            _whitelist.removeAddressesFromWhitelist(_operators);
        }
    }
}
