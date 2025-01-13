/**
 * @title Semver Interface
 * @dev An interface for a contract that has a version
 */
interface ISemver {
    function version() external pure returns (string memory);
}
