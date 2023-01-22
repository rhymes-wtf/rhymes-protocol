// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { MetadataRendererTypesV3 } from "../types/MetadataRendererTypesV3.sol";

/// @title MetadataRendererStorageV3
/// @author Aditya Veer parmar
/// @notice The Metadata Renderer storage contract
contract MetadataRendererStorageV3 is MetadataRendererTypesV3 {
    /// @notice The release stack of custom tokens
    CustomToken[] public releaseStack;

    /// @notice The 1/1 custom tokens mapping
    mapping(uint256 => CustomToken) public customTokens;
}
