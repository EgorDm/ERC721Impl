pragma solidity ^0.4.1;


contract ERC721 {
    struct Token {
        uint256 meta;
    }

    string internal _name;
    string internal _symbol;
    address internal _ceo;

    Token[] public tokens;

    mapping(uint256 => address) public ownerships;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) public approvals;

    function ERC721(string name, string symbol) public {
        _name = name;
        _symbol = symbol;
        _ceo = msg.sender;
    }

    function name() public view returns (string) {return _name;}

    function symbol() public view returns (string) {return _symbol;}

    function totalSupply() public view returns (uint256) {return tokens.length;}

    /**@dev Query someones balance
     * @param owner An address for whom to query the balance
     * @return The number of tokens owned by owner, possibly zero
     */
    function balanceOf(address owner) public view returns (uint256) {return balances[owner];}

    /**@dev Get token ids of tokens someone owns
     * note: This can and should not be called by a contract since this implementation loops over all coins. This can
     * be a little bit pricey. Read warning for another solution.
     * @param owner An address for whom the token ids should be returned of
     * @return An array of tokenIds
     */
    function tokensOf(address owner) external view returns (uint256[]) {
        uint256 balance = balanceOf(owner);
        if (balance == 0) return new uint256[](0);

        uint256[] memory result = new uint256[](balance);
        uint256 totalCount = totalSupply();
        uint256 resultIdx = 0;

        // WARNING: we iterate over all tokens. If you plan having a lot of them then make a
        // adress -> uint256[] mapping and take only tokens with idx > 0. Make sure to do same with other arrays
        for (uint256 tokenId = 0; tokenId < totalCount; ++tokenId) {
            if (ownerships[tokenId] != owner) continue;
            result[resultIdx] = tokenId;
            ++resultIdx;
        }

        return result;
    }

    /**@dev Get owner of a specific token by its id
     * @param tokenId An id of the token in question
     * @return Address of the owner or null
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = ownerships[tokenId];
        require(owner != address(0));
        return owner;
    }

    /**@dev Check wether the and address is approved to take ownership of the tokens
     * @param claimant Address in question
     * @return Bool specifying state of the approval
     */
    function isApproved(address claimant, uint256 tokenId) public view returns (bool) {
        return approvals[tokenId] == claimant;
    }

    /**@dev Approve an address to take the token in ownership
     * @param to Address in question
     * @param tokenId An id of the token in question
     */
    function approve(address to, uint256 tokenId) public owns(msg.sender, tokenId) {
        approvals[tokenId] = to;
        Approval(msg.sender, to, tokenId);
    }

    /**@dev Takes ownership of a token
     * @param tokenId An id of the token in question
     */
    function takeOwnership(uint256 tokenId) public approved(msg.sender, tokenId) {
        _uncheckedTransfer(ownerOf(tokenId), msg.sender, tokenId);
    }

    /**@dev Transfer a token to a given address.
     * @param to Address in question
     * @param tokenId An id of the token in question
     */
    function transfer(address to, uint256 tokenId) public approved(msg.sender, tokenId) addressNotNull(to) {
        _uncheckedTransfer(ownerOf(tokenId), to, tokenId);
    }

    /**@dev Creates a new token for the ceo. And we thought that we were done with central banks :S
     * @param metaData Data to be assigned to a token
     */
    function createToken(uint256 metaData) public isCEO(msg.sender) {
        createTokenFor(msg.sender, metaData);
    }

    /**@dev Creates a new token for the given address.
      * @param to Address in question
      * @param metaData Data to be assigned to a token
      */
    function createTokenFor(address to, uint256 metaData) public isCEO(msg.sender) {
        Token memory token = Token({meta : metaData});
        uint256 tokenId = tokens.push(token) - 1;

        _uncheckedTransfer(address(0), to, tokenId);
    }

    /**@dev Transfers a token from an address to another address.
     * note: This is for internal use and doesn't check for any privileges to access the token.
     * @param from Address to set as sender
     * @param to Address to transfer token to
     * @param tokenId An id of the token in question
     */
    function _uncheckedTransfer(address from, address to, uint256 tokenId) internal {
        require(from != to);
        delete approvals[tokenId];

        if (from != address(0)) {
            --balances[from];
        }

        ++balances[to];
        ownerships[tokenId] = to;
        Transfer(from, to, tokenId);
    }

    modifier owns(address claimant, uint256 tokenId) {
        require(ownerships[tokenId] == claimant);
        _;
    }

    modifier approved(address claimant, uint256 tokenId) {
        require(approvals[tokenId] == claimant || ownerships[tokenId] == claimant);
        _;
    }

    modifier addressNotNull(address to) {
        require(to != address(0));
        _;
    }

    modifier isCEO(address claimant) {
        require(_ceo == claimant);
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}