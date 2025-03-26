// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMessageRecipient} from "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";
import {TypeCasts} from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";
import {IMailbox, IPostDispatchHook} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

/**
 * @title Rebaser
 * @notice Contract for rebasing ecoDollar across multiple chains
 * @dev makes the assumption that one of the chains being rebased is the local chain
 */

contract Rebaser is Ownable, IMessageRecipient {
    using TypeCasts for bytes32;

    uint256 public constant BASE = 1e18; // 1.0 initial scaling factor
    // The local Hyperlane mailbox address, set once in the constructor (immutable).
    address public immutable MAILBOX;

    bytes32 public immutable POOL;

    bytes32 public immutable TOKEN;

    address public immutable RELAYER; // relayer?

    // mint rate for ecoDollar. Divided by BASE
    uint256 public protocolRate;

    uint256 public rebaserRate;

    uint32[] public chains;

    /**
     * @notice Mapping of chain ID to the Hyperlane mailbox address for that chain.
     *         If the value is non-zero, the chain is considered valid.
     *         If zero, the chain is considered invalid.
     */
    mapping(uint32 => bool) public validChainIDs;

    //TODO: combine these as a struct
    // Counter with current number of chains that have sent in rebase values
    uint256 private currentChainCount;
    // current shares total
    uint256 private sharesTotal;
    // current balances total
    uint256 private balancesTotal;

    uint256 private currentMultiplier;

    event RebaseSent(uint256 _newMuliplier, uint32 _chainId);

    event ReceivedRebaseInformation(uint256 _chainId);

    event protocolRateChanged(uint256 _newRate);

    error InvalidprotocolRate();

    error RebasePropagationFailed(uint32 _chainId);

    /**
     * @dev Constructor. Sets the local MAILBOX address.
     * @param _mailbox The Hyperlane mailbox contract address on this chain.
     */
    constructor(
        address _owner,
        address _mailbox,
        bytes32 _pool,
        bytes32 _token,
        address _relayer,
        uint256 _protocolRate,
        uint256 _rebaserRate,
        uint32[] memory _chainIds
    ) Ownable(_owner) {
        MAILBOX = _mailbox;
        POOL = _pool;
        TOKEN = _token;
        RELAYER = _relayer;
        protocolRate = _protocolRate;
        rebaserRate = _rebaserRate;
        uint256 chainCount = _chainIds.length;
        for (uint256 i = 0; i < chainCount; i++) {
            _setChainIdStatus(_chainIds[i], true);
        }
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
        uint32 _chainId,
        bool _isValid
    ) external onlyOwner {
        _setChainIdStatus(_chainId, _isValid);
    }

    /**
     * @notice Change the mint rate for ecoDollar
     * @param _newprotocolRate The new mint rate
     */
    function changeprotocolRate(uint256 _newprotocolRate) external onlyOwner {
        require(_newprotocolRate <= BASE, InvalidprotocolRate());
        protocolRate = _newprotocolRate;
        emit protocolRateChanged(_newprotocolRate);
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

        require(_sender == POOL, "sender is not the pool contract");

        // Check that the origin chain is valid (non-zero mailbox address)
        require(validChainIDs[_origin], "Invalid origin chain");
        (uint256 shares, uint256 balances) = abi.decode(
            _message,
            (uint256, uint256)
        );
        currentChainCount++;
        sharesTotal += shares;
        balancesTotal += balances;

        emit ReceivedRebaseInformation(_origin);

        uint256 chainCount = chains.length;

        if (currentChainCount == chainCount) {
            // Rebase the token
            uint256 netNewBalances = balancesTotal -
                (sharesTotal * currentMultiplier) /
                BASE;
            uint256 protocolShare = ((netNewBalances * protocolRate) / BASE);
            currentMultiplier =
                ((balancesTotal - protocolShare) * BASE) /
                sharesTotal;

            uint256 protocolMintRate = (protocolShare * BASE) / sharesTotal;

            currentChainCount = 0;
            sharesTotal = 0;
            balancesTotal = 0;

            // do the send
            for (uint256 i = 0; i < chainCount; i++) {
                // is there a way to optimize this
                uint32 chain = chains[i];
                require(
                    propagateRebase(chain, protocolMintRate),
                    RebasePropagationFailed(chain)
                );
            }
        }
        // You can add any additional logic here, e.g., decode _message, verify _sender, etc.
    }

    function propagateRebase(
        uint32 _chainId,
        uint256 _protocolMintRate
    ) public returns (bool success) {
        uint256 fee = IMailbox(MAILBOX).quoteDispatch(
            _chainId,
            TOKEN,
            abi.encode(currentMultiplier, _protocolMintRate),
            "", // metadata for relayer
            IPostDispatchHook(RELAYER)
        );
        IMailbox(MAILBOX).dispatch{value: fee}(
            _chainId,
            TOKEN,
            abi.encode(currentMultiplier, _protocolMintRate),
            "", // metadata for relayer
            IPostDispatchHook(RELAYER)
        );
        return true;
    }

    function _setChainIdStatus(uint32 _chainId, bool _isValid) internal {
        if (validChainIDs[_chainId] != _isValid) {
            if (_isValid) {
                chains.push(_chainId);
            } else {
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
}
