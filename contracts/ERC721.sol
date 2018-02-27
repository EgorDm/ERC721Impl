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

    function balanceOf(address owner) public view returns (uint256) {return balances[owner];}

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

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = ownerships[tokenId];
        require(owner != address(0));
        return owner;
    }

    function isApproved(address claimant, uint256 tokenId) public view returns (bool) {
        return approvals[tokenId] == claimant;
    }

    function approve(address to, uint256 tokenId) public owns(msg.sender, tokenId) {
        approvals[tokenId] = to;
        Approval(msg.sender, to, tokenId);
    }

    function takeOwnership(uint256 tokenId) public approved(msg.sender, tokenId) {
        _uncheckedTransfer(ownerOf(tokenId), msg.sender, tokenId);
    }

    function transfer(address to, uint256 tokenId) public approved(msg.sender, tokenId) addressNotNull(to) {
        _uncheckedTransfer(ownerOf(tokenId), to, tokenId);
    }

    function createToken(uint256 metaData) public isCEO(msg.sender) {
        createTokenFor(msg.sender, metaData);
    }

    function createTokenFor(address to, uint256 metaData) public isCEO(msg.sender) {
        Token memory token = Token({meta : metaData});
        uint256 tokenId = tokens.push(token) - 1;

        _uncheckedTransfer(address(0), to, tokenId);
    }

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