// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IExecutor, IHook} from "@kernel/interfaces/IERC7579Modules.sol";
import {IERC7579Account, ExecMode} from "@kernel/interfaces/IERC7579Account.sol";
import {MODULE_TYPE_EXECUTOR, MODULE_TYPE_HOOK} from "@kernel/types/Constants.sol";

struct ExecutorStorage {
    address owner;
}

/**
 * @title Executor
 * @dev The executor module is used to execute calls on a kernel wallet 3.1+ as
 * an Executor. Each kernel wallet can only have one account registred as an executor.
 */
contract Executor is IExecutor, IHook {
    event OwnerRegistered(address indexed kernel, address indexed owner);
    mapping(address => ExecutorStorage) public executorStorage;

    /**
     * Called by the kernel wallet durring module installation.
     * Sets the owner linked to that wallet for the executor.
     *
     * @param _data The data passed to the module during installation.
     */
    function onInstall(bytes calldata _data) external payable override {
        address owner = address(bytes20(_data[0:20]));
        executorStorage[msg.sender].owner = owner;
        emit OwnerRegistered(msg.sender, owner);
    }

    function onUninstall(bytes calldata) external payable override {
        if (!_isInitialized(msg.sender)) revert NotInitialized(msg.sender);
        delete executorStorage[msg.sender];
    }

    function isModuleType(
        uint256 typeID
    ) external pure override returns (bool) {
        return typeID == MODULE_TYPE_EXECUTOR || typeID == MODULE_TYPE_HOOK;
    }

    function isInitialized(
        address smartAccount
    ) external view override returns (bool) {
        return _isInitialized(smartAccount);
    }

    function _isInitialized(address smartAccount) internal view returns (bool) {
        return executorStorage[smartAccount].owner != address(0);
    }

    /**
     * @notice Pre-check hook for the executor module.
     * @dev The pre-check hook is called before the execution of a call on the account as an executor.
     * It will revert if the caller of the account is not this module contract
     *
     * @notice interface params ignored
     */
    function preCheck(
        address,
        uint256,
        bytes calldata
    ) external payable override returns (bytes memory) {
        require(
            msg.sender == address(this),
            "Executor: sender is not this executor"
        );
        return hex"";
    }

    function postCheck(bytes calldata hookData) external payable override {}

    /**
     * @notice Executes a call on the account as an executor. The caller must be the owner of the account in
     * this executor module.
     * @dev The call is executed on the account as an executor.
     * @param account The account to execute the call on.
     * @param mode The execution mode to use.
     * @param executionCalldata The calldata to use for the execution.
     * @return The return data of the execution.
     */
    function executeAsExecutor(
        IERC7579Account account,
        ExecMode mode,
        bytes calldata executionCalldata
    ) external payable returns (bytes[] memory) {
        address owner = executorStorage[address(account)].owner;
        require(msg.sender == owner, "Executor: sender is not account owner");
        return account.executeFromExecutor(mode, executionCalldata);
    }
}
