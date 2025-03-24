// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEcoDollar} from "./interfaces/IEcoDollar.sol";
// import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

contract EcoDollar is IEcoDollar, Ownable {
    uint256 public constant BASE = 1e18; // 1.0 initial scaling factor

    string private _name = "EcoDollar";
    string private _symbol = "eUSD";
    uint8 private _decimals = 6;

    uint256 public rewardMultiplier;

    uint256 public totalShares;

    address public immutable INTENTSOURCE;

    // in shares
    mapping(address => uint256) private _shares;

    // in tokens
    mapping(address => mapping(address => uint256)) private _allowances;

    event Rebased(uint256 newTotalSupply, uint256 rewardMultiplier);

    //owner is the pool
    constructor(address _pool, address _intentSource) Ownable(_pool) {
        INTENTSOURCE = _intentSource;
        rewardMultiplier = BASE;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return convertToTokens(totalShares);
    }

    function getTotalShares() external view override returns (uint256) {
        return totalShares;
    }

    /**
     * @notice Converts an amount of _shares to tokens.
     * @param _shares The amount of _shares to convert.
     * @return The equivalent amount of tokens.
     */
    function convertToTokens(uint256 _shares) public view returns (uint256) {
        return (_shares * rewardMultiplier) / BASE;
    }

    /**
     * @notice Converts an amount of _shares to tokens.
     * @param _tokens The amount of _shares to convert.
     * @return The equivalent amount of tokens.
     */
    function convertToShares(uint256 _tokens) public view returns (uint256) {
        return (_tokens * BASE) / rewardMultiplier;
    }

    function balanceOf(
        address _account
    ) public view override returns (uint256) {
        return (_shares[_account] * rewardMultiplier) / BASE;
    }

    function rebase(uint256 _newMultiplier) external onlyOwner {
        //already guaranteed that newMultiplier is greater than current multiplier
        rewardMultiplier = _newMultiplier;
    }

    function mint(address _account, uint256 _tokens) public {
        require(msg.sender == INTENTSOURCE || msg.sender == owner(), "only intentSource and pool can mint");
        if (_account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), _account, _tokens);
    }

    function burn(address _account, uint256 _tokens) public onlyOwner {
        if (_account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(_account, address(0), _tokens);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transferFrom(msg.sender, recipient, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(
            _allowances[sender][msg.sender] >= amount,
            ERC20InsufficientAllowance(sender, amount, _shares[sender])
        );
        return _transferFrom(sender, recipient, amount);
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        require(from != address(0), ERC20InvalidReceiver(from));
        require(to != address(0), ERC20InvalidReceiver(to));

        _update(from, to, amount);
    }

    function _update(address from, address to, uint256 amount) private {
        uint256 shares = convertToShares(amount);
        if (from == address(0)) {
            // mint
            // Overflow check required: The rest of the code assumes that totalShares never overflows
            totalShares += shares;
        } else {
            uint256 fromShares = _shares[from];
            if (fromShares < shares) {
                uint256 fromBalance = convertToTokens(fromShares);
                revert ERC20InsufficientBalance(
                    from,
                    fromBalance,
                    amount - fromBalance
                );
            }
            unchecked {
                // Overflow not possible: shares <= fromShares <= totalSupply.
                _shares[from] = fromShares - shares;
            }
        }

        if (to == address(0)) {
            unchecked {
                // burn
                // Underflow not possible: shares <= totalShares.
                totalShares -= shares;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _shares[to] += shares;
            }
        }

        emit Transfer(from, to, amount);
    }
}
