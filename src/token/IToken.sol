// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IUUPS } from "../lib/interfaces/IUUPS.sol";
import { IERC721Votes } from "../lib/interfaces/IERC721Votes.sol";
import { IManager } from "../manager/IManager.sol";
import { TokenTypesV1 } from "./types/TokenTypesV1.sol";

/// @title IToken
/// @author Rohan Kulkarni
/// @notice The external Token events, errors and functions
interface IToken is IUUPS, IERC721Votes, TokenTypesV1 {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    event MintScheduled(uint256 baseTokenId, uint256 founderId, Founder founder);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    error INVALID_FOUNDER_PERCENTAGE();

    /// @dev Reverts if the caller was not the contract owner
    error ONLY_OWNER();

    /// @dev Reverts if the caller was not the auction contract
    error ONLY_AUCTION();

    /// @dev Reverts if no metadata was generated upon mint
    error NO_METADATA_GENERATED();

    /// @dev Reverts if the caller was not the contract manager
    error ONLY_MANAGER();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice Initializes a DAO's ERC-721 token
    /// @param founders The founding members to receive vesting allocations
    /// @param initStrings The encoded token and metadata initialization strings
    /// @param metadataRenderer The token's metadata renderer
    /// @param auction The token's auction house
    function initialize(
        IManager.FounderParams[] calldata founders,
        bytes calldata initStrings,
        address metadataRenderer,
        address auction
    ) external;

    /// @notice Mints tokens to the auction house for bidding and handles founder vesting
    function mint() external returns (uint256 tokenId);

    /// @notice Burns a token that did not see any bids
    /// @param tokenId The ERC-721 token id
    function burn(uint256 tokenId) external;

    /// @notice The URI for a token
    /// @param tokenId The ERC-721 token id
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// @notice The URI for the contract
    function contractURI() external view returns (string memory);

    /// @notice One of the DAO founders
    /// @param index The array index of founder
    function getFounder(uint256 index) external view returns (Founder memory);

    /// @notice All of the DAO founders
    function getFounders() external view returns (Founder[] memory);

    /// @notice The total supply of tokens
    function totalSupply() external view returns (uint256);

    /// @notice The token's auction house
    function auction() external view returns (address);

    /// @notice The token's metadata renderer
    function metadataRenderer() external view returns (address);

    /// @notice The owner of the token and metadata renderer
    function owner() external view returns (address);
}
