// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title MetadataRendererTypesV1
/// @author Iain Nash & Rohan Kulkarni
/// @notice The Metadata Renderer custom data types
interface MetadataRendererTypesV1 {
    struct ItemParam {
        uint256 propertyId;
        string name;
        bool isNewProperty;
    }

    struct IPFSGroup {
        string baseUri;
        string artExtension;
        string audioExtension;
    }

    struct Item {
        uint16 referenceSlot;
        string name;
    }

    struct Property {
        string name;
        Item[] items;
    }

    struct Settings {
        address token;
        address treasury;
        string projectURI;
        string description;
        string contractImage;
        string rendererBase;
    }
}
