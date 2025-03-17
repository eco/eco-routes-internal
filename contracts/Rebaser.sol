// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageRecipient} from "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";

contract Rebaser is Ownable, IMessageRecipient {
    uint256 public constant BASE = 1e18; // 1.0 initial scaling factor
    // The local Hyperlane mailbox address, set once in the constructor (immutable).
    address public immutable MAILBOX;

    address public immutable POOL;

    address public immutable TOKEN;

    uint256[] public chains;

    /**
     * @notice Mapping of chain ID to the Hyperlane mailbox address for that chain.
     *         If the value is non-zero, the chain is considered valid.
     *         If zero, the chain is considered invalid.
     */
    mapping(uint256 => bool) public validChainIDs;

    //TODO: combine these as a struct
    // Counter to track the number of chains to rebase
    uint256 public validChainCount;
    // Counter with current number of chains that have sent in rebase values
    uint256 private currentChainCount;
    // current shares total
    uint256 private sharesTotal;
    // current balances total
    uint256 private balancesTotal;

    /**
     * @dev Constructor. Sets the local MAILBOX address.
     * @param _mailbox The Hyperlane mailbox contract address on this chain.
     */
    constructor(
        address _owner,
        address _mailbox,
        address _pool,
        address _token
    ) Ownable(_owner) {
        MAILBOX = _mailbox;
        POOL = _pool;
        TOKEN = _token;
    }

    /**
     * @dev Sets or clears the Hyperlane mailbox for a given chain ID.
     *
     *      - If `chainMailbox` is non-zero and was previously zero, the chain becomes valid (increment count).
     *      - If `chainMailbox` is zero and was previously non-zero, the chain becomes invalid (decrement count).
     *      - If both old and new values are non-zero or both zero, the count does not change.
     *
     * @param _chainId The chain ID to set.
     * @param _isValid True if the chain should be considered valid, false otherwise.
     */
    function setChainIdStatus(
        uint256 _chainId,
        bool _isValid
    ) external onlyOwner {
        if (validChainIDs[_chainId] != _isValid) {
            if (_isValid) {
                validChainCount++;
                chains.push(_chainId);
            } else {
                validChainCount--;

                uint256 index;
                uint256 length = chains.length;
                for (uint256 i = 0; i < length; i++) {
                    if (chains[i] == _chainId) {
                        index = i;
                        break;
                    }
                }
                chains[index] = chains[chains.length - 1];
                chains.pop();
            }
            validChainIDs[_chainId] = _isValid;
        }
    }

    /**
     * @dev Hyperlane "handle" method, called when a message is received.
     *      1) Caller must be the local MAILBOX
     *      2) The origin chain must have a valid (non-zero) mailbox address stored
     *
     * @param _origin  The chain ID from which the message was sent.
     * @param _sender  The address that sent this message on the origin chain, in 32-byte form.
     * @param _message The encoded message payload.
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable override {
        // Ensure only the local mailbox can call this
        require(msg.sender == MAILBOX, "Caller is not the local mailbox");

        // Check that the origin chain is valid (non-zero mailbox address)
        require(validChainIDs[uint256(_origin)], "Invalid origin chain");
        (uint256 shares, uint256 balances) = abi.decode(
            _message,
            (uint256, uint256)
        );
        currentChainCount++;
        sharesTotal += shares;
        balancesTotal += balances;

        if (currentChainCount == validChainCount) {
            // Rebase the token
            uint256 newMultiplier = (balancesTotal * BASE) / sharesTotal;
            emit RebaseSent(newMultiplier);
            currentChainCount = 0;
            sharesTotal = 0;
            balancesTotal = 0;

            // do the send
        }
        // You can add any additional logic here, e.g., decode _message, verify _sender, etc.
    }
}
