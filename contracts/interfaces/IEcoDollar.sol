// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

interface IEcoDollar is IERC20, IERC20Errors {
    event Rebased(uint256 _rewardMultiplier);
    event RewardMultiplierUpdated(uint256 _oldMultiplier, uint256 _newMultiplier);

    error RewardMultiplierTooLow(
        uint256 _rewardMultiplier,
        uint256 _minRewardMultiplier
    );

    error InvalidRebase();
    error UnauthorizedMultiplierUpdate(address caller);

    function getTotalShares() external view returns (uint256);
    function rewardMultiplier() external view returns (uint256);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function rebase(uint256 _newMultiplier) external;
    function updateRewardMultiplier(uint256 _newMultiplier) external;
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}
