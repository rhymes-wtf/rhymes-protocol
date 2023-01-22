// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title MetadataRendererTypesV3
/// @author Aditya Veer Parmar
/// @notice The Metadata Renderer custom token types
interface MetadataRendererTypesV3 {
    struct CustomToken {
        string image;
        string animation_url;
        string external_url;
        string description;
        string name;
        string attributes;
        string properties;
        uint256 releaseTimestamp;
    }
}
