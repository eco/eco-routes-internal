// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

interface IEcoDollar {
    event Rebased(uint256 scalingFactor);

    error RewardMultiplierTooLow(uint256 _rewardMultiplier, uint256 _minRewardMultiplier);

    error InvalidSender();

    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function rebase(uint256 supplyChange) external;
}
