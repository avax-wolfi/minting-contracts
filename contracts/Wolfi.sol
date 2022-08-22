/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@pangolindex/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinPair.sol";

interface ICalculatePrice {
    function getWolfiPriceInAvax()
        external
        view
        returns (uint256 wolfiPriceAvax);
}

contract ERC721Metadata is ERC721Enumerable, Ownable {
    using Strings for uint256;

    // Base URI
    string private baseURI;
    string public baseExtension = ".json";
    uint256 private _maxNftSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 maxNftSupply_
    ) ERC721(name_, symbol_) {
        setBaseURI(baseURI_);

        _maxNftSupply = maxNftSupply_;
    }

    function setBaseURI(string memory baseURI_) private onlyOwner {
        require(
            keccak256(abi.encodePacked((baseURI))) !=
                keccak256(abi.encodePacked((baseURI_))),
            "ERC721Metadata: existed baseURI"
        );
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            tokenId <= _maxNftSupply,
            "ERC721Metadata: URI query for nonexistent token"
        );

        require(_exists(tokenId), "This Token doesn't exist");

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), baseExtension)
                )
                : "";
    }
}

/// @title Wolfi
contract Wolfi is ERC721Metadata {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public constant MAX_NFT_SUPPLY = 5000;

    bool public paused = true;
    uint256 public pendingCount = MAX_NFT_SUPPLY;

    mapping(uint256 => address) public _minters;
    mapping(address => uint256) public _mintedByWallet;

    // Admin wallet
    address private _admin;

    uint256 private _totalSupply;
    uint256[5001] private _pendingIDs;

    address public priceCalculatorAddress;

    // Giveaway winners
    uint256 private _giveawayMax = 50;
    mapping(uint256 => address) private _giveaways;
    Counters.Counter private _giveawayCounter;

    constructor(
        string memory baseURI_,
        address admin_,
        address _priceCalculatorAddress
    ) ERC721Metadata("WOLFI", "WOLFI", baseURI_, MAX_NFT_SUPPLY) {
        _admin = admin_;
        priceCalculatorAddress = _priceCalculatorAddress;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev This function collects all the token IDs of a wallet.
    /// @param owner_ This is the address for which the balance of token IDs is returned.
    /// @return an array of token IDs.
    function walletOfOwner(address owner_)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(owner_);
        uint256[] memory tokenIDs = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIDs[i] = tokenOfOwnerByIndex(owner_, i);
        }
        return tokenIDs;
    }

    function mint(uint256 counts_) external payable {
        require(pendingCount > 0, "Wolfi: All minted");
        require(counts_ > 0, "Wolfi: Counts cannot be zero");
        require(
            totalSupply().add(counts_) <= MAX_NFT_SUPPLY,
            "Wolfi: sale already ended"
        );
        require(!paused, "Wolfi: The contract is paused");

        uint256 priceAvax = ICalculatePrice(priceCalculatorAddress)
            .getWolfiPriceInAvax();

        uint256 upperBound = msg.value * 115 / 100;
        uint256 lowerBound = msg.value * 90 / 100;

        require(
            priceAvax.mul(counts_) <= upperBound ,
            "Wolfi: ether value exceeds current price"
        );
        require(
            priceAvax.mul(counts_) >= lowerBound,
            "Wolfi: ether value is not enough"
        );

        for (uint256 i = 0; i < counts_; i++) {
            _randomMint(_msgSender());
            _totalSupply += 1;
        }

        payable(_admin).transfer(msg.value);
    }

    function _randomMint(address to_) private returns (uint256) {
        require(to_ != address(0), "Wolfi: zero address");

        require(totalSupply() < MAX_NFT_SUPPLY, "Wolfi: max supply reached");

        uint256 randomIn = _getRandom().mod(pendingCount).add(1);

        uint256 tokenID = _popPendingAtIndex(randomIn);

        _minters[tokenID] = to_;
        _mintedByWallet[to_] += 1;

        _safeMint(to_, tokenID);

        return tokenID;
    }

    function _popPendingAtIndex(uint256 index_) private returns (uint256) {
        uint256 tokenID = _pendingIDs[index_].add(index_);

        if (index_ != pendingCount) {
            uint256 lastPendingID = _pendingIDs[pendingCount].add(pendingCount);
            _pendingIDs[index_] = lastPendingID.sub(index_);
        }

        pendingCount -= 1;
        return tokenID;
    }

    function _getRandom() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        pendingCount
                    )
                )
            );
    }

    function pause(bool state_) public onlyOwner {
        paused = state_;
    }

    function setPriceCalculatorAddress(address _priceCalculatorAddress)
        public
        onlyOwner
    {
        priceCalculatorAddress = _priceCalculatorAddress;
    }

    function setAdmin(address newAdmin) public onlyOwner {
        _admin = newAdmin;
    }

    function addToGiveawayMax(uint256 giveawayMax_)
        external onlyOwner {
        require(
            giveawayMax_ >= 0 && giveawayMax_ <= MAX_NFT_SUPPLY,
            "Wolfi: invalid max value"
        );

        _giveawayMax += giveawayMax_;
    }

    function randomGiveaway(address[] memory winners_)
        external onlyOwner {
        require(
            _giveawayCounter
                .current()
                .add(winners_.length) <= _giveawayMax,
            "Wolfi: overflow giveaways");

        for(uint i = 0; i < winners_.length; i++) {
            uint256 tokenID = _randomMint(winners_[i]);
            _giveaways[tokenID] = winners_[i];
            _giveawayCounter.increment();
        }

        _totalSupply = _totalSupply
            .add(winners_.length);
    }
}
