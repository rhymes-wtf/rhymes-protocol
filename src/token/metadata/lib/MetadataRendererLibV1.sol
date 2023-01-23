// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { MetadataRendererTypesV3 } from "../types/MetadataRendererTypesV3.sol";
import { MetadataRendererStorageV3 } from "../storage/MetadataRendererStorageV3.sol";

import { MetadataBuilder } from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import { MetadataJSONKeys } from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";

/// @title MetadataRendererLibV1
/// @author Aditya Veer parmar
/// @notice The Metadata Renderer lib contract
library MetadataRendererLibV1 {
    function getCustomTokenURI(
        string memory name,
        string memory description,
        string memory image,
        string memory attributes,
        string memory properties,
        string memory animationUrl,
        string memory externalUrl
    ) external pure returns (string memory) {
        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](7);
        items[0] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyName, value: name, quote: true });
        items[1] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyDescription, value: description, quote: true });
        items[2] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyImage, value: image, quote: true });
        items[3] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyProperties, value: properties, quote: true });
        items[4] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyAttributes, value: attributes, quote: true });
        items[5] = MetadataBuilder.JSONItem({ key: MetadataJSONKeys.keyAnimationURL, value: animationUrl, quote: true });
        items[6] = MetadataBuilder.JSONItem({ key: "external_url", value: externalUrl, quote: true });

        return MetadataBuilder.generateEncodedJSON(items);
    }
}
