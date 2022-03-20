// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/token/ERC20/ERC20.sol";
import "IrisOracle.sol";

contract IrisToken is ERC20 {

    address public owner;
    address public oracle;
    mapping(uint256 => bool) rewardIsClaimed;

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    constructor(uint256 initialSupply) ERC20("Iris Token", "IRIS") {
        owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    function setOracleAddress(address oracleAddress) public onlyOwner {
        oracle = oracleAddress;
    }

    function claimReward(uint256 rewardId) public {
        require(rewardIsClaimed[rewardId] == false);
        rewardIsClaimed[rewardId] = true;

        IrisOracle oracleContract = IrisOracle(oracle);

        address recipient; uint256 amount; uint timestamp;
        (recipient, amount, timestamp) = oracleContract.getReward(rewardId);

        if (amount > 0) {
            _mint(recipient, amount);
        }
    }
}
