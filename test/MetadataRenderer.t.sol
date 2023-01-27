// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { NounsBuilderTest } from "./utils/NounsBuilderTest.sol";
import { MetadataRendererTypesV1 } from "../src/token/metadata/types/MetadataRendererTypesV1.sol";
import { MetadataRendererTypesV2 } from "../src/token/metadata/types/MetadataRendererTypesV2.sol";
import { MetadataRendererTypesV3 } from "../src/token/metadata/types/MetadataRendererTypesV3.sol";

import { Base64URIDecoder } from "./utils/Base64URIDecoder.sol";
import "forge-std/console2.sol";

contract MetadataRendererTest is NounsBuilderTest, MetadataRendererTypesV1, MetadataRendererTypesV3 {
    function setUp() public virtual override {
        super.setUp();

        deployWithoutMetadata();
    }

    function testRevert_MustAddAtLeastOneItemWithProperty() public {
        string[] memory names = new string[](2);
        names[0] = "test";
        names[1] = "more test";

        ItemParam[] memory items = new ItemParam[](0);

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "BASE_URI", artExtension: "EXTENSION", audioExtension: "EXTENSION" });

        vm.prank(founder);
        vm.expectRevert(abi.encodeWithSignature("ONE_PROPERTY_AND_ITEM_REQUIRED()"));
        metadataRenderer.addProperties(names, items, ipfsGroup);

        // Attempt to mint token #0
        vm.prank(address(token));
        bool response = metadataRenderer.onMinted(0, false);

        assertFalse(response);
    }

    function testRevert_MustAddAtLeastOnePropertyWithItem() public {
        string[] memory names = new string[](0);

        ItemParam[] memory items = new ItemParam[](2);
        items[0] = ItemParam({ propertyId: 0, name: "failure", isNewProperty: false });
        items[1] = ItemParam({ propertyId: 0, name: "failure", isNewProperty: true });

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "BASE_URI", artExtension: "EXTENSION", audioExtension: "EXTENSION" });

        vm.prank(founder);
        vm.expectRevert(abi.encodeWithSignature("ONE_PROPERTY_AND_ITEM_REQUIRED()"));
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        bool response = metadataRenderer.onMinted(0, false);
        assertFalse(response);
    }

    function testRevert_MustAddItemForExistingProperty() public {
        string[] memory names = new string[](1);
        names[0] = "testing";

        ItemParam[] memory items = new ItemParam[](2);
        items[0] = ItemParam({ propertyId: 0, name: "failure", isNewProperty: true });
        items[1] = ItemParam({ propertyId: 2, name: "failure", isNewProperty: false });

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "BASE_URI", artExtension: "EXTENSION", audioExtension: "EXTENSION" });

        vm.prank(founder);
        vm.expectRevert(abi.encodeWithSignature("INVALID_PROPERTY_SELECTED(uint256)", 2));
        metadataRenderer.addProperties(names, items, ipfsGroup);

        // 0th token minted
        vm.prank(address(token));
        bool response = metadataRenderer.onMinted(0, false);
        assertFalse(response);
    }

    function test_AddNewPropertyWithItems() public {
        string[] memory names = new string[](1);
        names[0] = "testing";

        ItemParam[] memory items = new ItemParam[](2);
        items[0] = ItemParam({ propertyId: 0, name: "failure1", isNewProperty: true });
        items[1] = ItemParam({ propertyId: 0, name: "failure2", isNewProperty: true });

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "BASE_URI", artExtension: "EXTENSION", audioExtension: "EXTENSION" });

        vm.prank(founder);
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        bool response = metadataRenderer.onMinted(0, false);
        assertTrue(response);
    }

    function testRevert_CannotExceedMaxProperties() public {
        string[] memory names = new string[](16);

        MetadataRendererTypesV1.ItemParam[] memory items = new MetadataRendererTypesV1.ItemParam[](16);

        for (uint256 j; j < 16; j++) {
            names[j] = "aaa"; // Add random properties

            items[j].name = "aaa"; // Add random items
            items[j].propertyId = uint16(j); // Make sure all properties have items
            items[j].isNewProperty = true;
        }

        MetadataRendererTypesV1.IPFSGroup memory group = MetadataRendererTypesV1.IPFSGroup("aaa", "aaa", "aaa");

        vm.prank(founder);
        vm.expectRevert(abi.encodeWithSignature("TOO_MANY_PROPERTIES()"));
        metadataRenderer.addProperties(names, items, group);
    }

    function test_deleteAndRecreateProperties() public {
        string[] memory names = new string[](1);
        names[0] = "testing";

        ItemParam[] memory items = new ItemParam[](2);
        items[0] = ItemParam({ propertyId: 0, name: "failure1", isNewProperty: true });
        items[1] = ItemParam({ propertyId: 0, name: "failure2", isNewProperty: true });

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "BASE_URI", artExtension: "EXTENSION", audioExtension: "EXTENSION" });

        vm.prank(founder);
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        bool response = metadataRenderer.onMinted(0, false);
        assertTrue(response);

        names = new string[](1);
        names[0] = "testing upsert";

        items = new ItemParam[](2);
        items[0] = ItemParam({ propertyId: 0, name: "UPSERT1", isNewProperty: true });
        items[1] = ItemParam({ propertyId: 0, name: "UPSERT2", isNewProperty: true });

        ipfsGroup = IPFSGroup({ baseUri: "NEW_BASE_URI", artExtension: "EXTENSION", audioExtension: "EXTENSION" });

        vm.prank(founder);
        metadataRenderer.deleteAndRecreateProperties(names, items, ipfsGroup);

        vm.prank(address(token));
        response = metadataRenderer.onMinted(0, false);
        assertTrue(response);
    }

    function test_ContractURI() public {
        /**
            base64 -d
            eyJuYW1lIjogIk1vY2sgVG9rZW4iLCJkZXNjcmlwdGlvbiI6ICJUaGlzIGlzIGEgbW9jayB0b2tlbiIsImltYWdlIjogImlwZnM6Ly9RbWV3N1RkeUduajZZUlVqUVI2OHNVSk4zMjM5TVlYUkQ4dXhvd3hGNnJHSzhqIiwiZXh0ZXJuYWxfdXJsIjogImh0dHBzOi8vbm91bnMuYnVpbGQifQ==
            {"name": "Mock Token","description": "This is a mock token","image": "ipfs://Qmew7TdyGnj6YRUjQR68sUJN3239MYXRD8uxowxF6rGK8j","external_url": "https://nouns.build"}
        */
        assertEq(
            token.contractURI(),
            "data:application/json;base64,eyJuYW1lIjogIk1vY2sgVG9rZW4iLCJkZXNjcmlwdGlvbiI6ICJUaGlzIGlzIGEgbW9jayB0b2tlbiIsImltYWdlIjogImlwZnM6Ly9RbWV3N1RkeUduajZZUlVqUVI2OHNVSk4zMjM5TVlYUkQ4dXhvd3hGNnJHSzhqIiwiZXh0ZXJuYWxfdXJsIjogImh0dHBzOi8vbm91bnMuYnVpbGQifQ=="
        );
    }

    function test_UpdateMetadata() public {
        assertEq(metadataRenderer.description(), "This is a mock token");
        assertEq(metadataRenderer.projectURI(), "https://nouns.build");

        vm.startPrank(founder);
        metadataRenderer.updateDescription("new description");
        metadataRenderer.updateProjectURI("https://nouns.build/about");
        vm.stopPrank();

        assertEq(metadataRenderer.description(), "new description");
        assertEq(metadataRenderer.projectURI(), "https://nouns.build/about");
    }

    function test_AddAdditionalPropertiesWithAddress() public {
        string[] memory names = new string[](1);
        names[0] = "mock-property";

        ItemParam[] memory items = new ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = "mock-item";
        items[0].isNewProperty = true;

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "https://nouns.build/api/test/", artExtension: ".json", audioExtension: ".mp3" });

        vm.prank(founder);
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(auction));
        token.mint();

        MetadataRendererTypesV2.AdditionalTokenProperty[] memory additionalTokenProperties = new MetadataRendererTypesV2.AdditionalTokenProperty[](2);
        additionalTokenProperties[0] = MetadataRendererTypesV2.AdditionalTokenProperty({ key: "testing", value: "HELLO", quote: true });
        additionalTokenProperties[1] = MetadataRendererTypesV2.AdditionalTokenProperty({
            key: "participationAgreement",
            value: "This is a JSON quoted participation agreement.",
            quote: true
        });
        vm.prank(founder);
        metadataRenderer.setAdditionalTokenProperties(additionalTokenProperties);

        /**
            Token URI additional properties result:

            {
                "name": "Mock Token #0",
                "description": "This is a mock token",
                "image": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json",
                "properties": {
                    "mock-property": "mock-item"
                },
                "testing": "HELLO",
                "participationAgreement": "This is a JSON quoted participation agreement."
            }
        
        */

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(0));

        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","animation_url": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&audios=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.mp3","properties": {"mock-property": "mock-item"},"testing": "HELLO","participationAgreement": "This is a JSON quoted participation agreement."}'
        );
    }

    function test_AddAndClearAdditionalPropertiesWithAddress() public {
        string[] memory names = new string[](1);
        names[0] = "mock-property";

        ItemParam[] memory items = new ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = "mock-item";
        items[0].isNewProperty = true;

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "https://nouns.build/api/test/", artExtension: ".json", audioExtension: ".mp3" });

        vm.prank(founder);
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(auction));
        token.mint();

        MetadataRendererTypesV2.AdditionalTokenProperty[] memory additionalTokenProperties = new MetadataRendererTypesV2.AdditionalTokenProperty[](2);
        additionalTokenProperties[0] = MetadataRendererTypesV2.AdditionalTokenProperty({ key: "testing", value: "HELLO", quote: true });
        additionalTokenProperties[1] = MetadataRendererTypesV2.AdditionalTokenProperty({
            key: "participationAgreement",
            value: "This is a JSON quoted participation agreement.",
            quote: true
        });
        vm.prank(founder);
        metadataRenderer.setAdditionalTokenProperties(additionalTokenProperties);

        string memory withAdditionalTokenProperties = token.tokenURI(0);

        MetadataRendererTypesV2.AdditionalTokenProperty[] memory clearedTokenProperties = new MetadataRendererTypesV2.AdditionalTokenProperty[](0);
        vm.prank(founder);
        metadataRenderer.setAdditionalTokenProperties(clearedTokenProperties);

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(0));

        // Ensure no additional properties are sent
        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","animation_url": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&audios=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.mp3","properties": {"mock-property": "mock-item"}}'
        );

        assertTrue(keccak256(bytes(withAdditionalTokenProperties)) != keccak256(bytes(token.tokenURI(0))));
    }

    function test_UnicodePropertiesWithAddress() public {
        string[] memory names = new string[](1);
        names[0] = unicode"mock-⌐ ◨-◨-.∆property";

        ItemParam[] memory items = new ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = unicode" ⌐◨-◨ ";
        items[0].isNewProperty = true;

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "https://nouns.build/api/test/", artExtension: ".json", audioExtension: ".mp3" });

        vm.prank(founder);
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(auction));
        token.mint();

        MetadataRendererTypesV2.AdditionalTokenProperty[] memory additionalTokenProperties = new MetadataRendererTypesV2.AdditionalTokenProperty[](2);
        additionalTokenProperties[0] = MetadataRendererTypesV2.AdditionalTokenProperty({ key: "testing", value: "HELLO", quote: true });
        additionalTokenProperties[1] = MetadataRendererTypesV2.AdditionalTokenProperty({
            key: "participationAgreement",
            value: "This is a JSON quoted participation agreement.",
            quote: true
        });
        vm.prank(founder);
        metadataRenderer.setAdditionalTokenProperties(additionalTokenProperties);

        string memory withAdditionalTokenProperties = token.tokenURI(0);

        MetadataRendererTypesV2.AdditionalTokenProperty[] memory clearedTokenProperties = new MetadataRendererTypesV2.AdditionalTokenProperty[](0);
        vm.prank(founder);
        metadataRenderer.setAdditionalTokenProperties(clearedTokenProperties);

        // Ensure no additional properties are sent

        // result: {"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0xa37a694f029389d5167808761c1b62fcef775288&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.json","properties": {"mock-⌐ ◨-◨-.∆property": " ⌐◨-◨ "}}
        // JSON parse:
        // {
        //   name: 'Mock Token #0',
        //   description: 'This is a mock token',
        //   image: 'http://localhost:5000/render?contractAddress=0xa37a694f029389d5167808761c1b62fcef775288&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.json',
        //   properties: { 'mock-⌐ ◨-◨-.∆property': ' ⌐◨-◨ ' }
        // }
        // > decodeURIComponent('https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.json')
        // 'https://nouns.build/api/test/mock-⌐ ◨-◨-.∆property/ ⌐◨-◨ .json'

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(0));

        assertEq(
            json,
            unicode'{"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.json","animation_url": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&audios=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-%e2%8c%90%20%e2%97%a8-%e2%97%a8-.%e2%88%86property%2f%20%e2%8c%90%e2%97%a8-%e2%97%a8%20.mp3","properties": {"mock-⌐ ◨-◨-.∆property": " ⌐◨-◨ "}}'
        );

        assertTrue(keccak256(bytes(withAdditionalTokenProperties)) != keccak256(bytes(token.tokenURI(0))));
    }

    function test_TokenURIWithAddress() public {
        string[] memory names = new string[](1);
        names[0] = "mock-property";

        ItemParam[] memory items = new ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = "mock-item";
        items[0].isNewProperty = true;

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "https://nouns.build/api/test/", artExtension: ".json", audioExtension: ".mp3" });

        vm.prank(founder);
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(auction));
        token.mint();

        /**
        TokenURI Result Pretty JSON:
        {
            "name": "Mock Token #0",
            "description": "This is a mock token",
            "image": "http://localhost:5000/render?contractAddress=0xa37a694f029389d5167808761c1b62fcef775288&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json",
            "properties": {
                "mock-property": "mock-item"
            }
        }
         */

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(0));

        assertEq(
            json,
            '{"name": "Mock Token #0","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","animation_url": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=0&audios=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.mp3","properties": {"mock-property": "mock-item"}}'
        );
    }

    function test_AddCustomToken() public {
        string[] memory names = new string[](1);
        names[0] = "mock-property";

        ItemParam[] memory items = new ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = "mock-item";
        items[0].isNewProperty = true;

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "https://nouns.build/api/test/", artExtension: ".json", audioExtension: ".mp3" });

        vm.prank(founder);
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(auction));
        token.mint();

        vm.prank(address(treasury));

        CustomToken memory mockToken = CustomToken(
            "string image",
            "string animation_url",
            "string external_url",
            "string description",
            "string name",
            "string attributes",
            "string properties",
            block.timestamp,
            0,
            address(0)
        );
        metadataRenderer.addToReleaseStack(mockToken);

        (
            string memory image,
            string memory animation_url,
            string memory external_url,
            string memory description,
            string memory name,
            string memory attributes,
            string memory properties,
            uint256 timestamp,
            uint256 royalty,
            address royaltyRecipient
        ) = metadataRenderer.releaseStack(0);

        assertEq(image, "string image");
        assertEq(animation_url, "string animation_url");
        assertEq(external_url, "string external_url");
        assertEq(description, "string description");
        assertEq(name, "string name");
        assertEq(attributes, "string attributes");
        assertEq(properties, "string properties");
        assertEq(timestamp, block.timestamp);

        vm.prank(address(auction));
        skip(3600);
        uint256 tokenId = token.mint();

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(tokenId));

        assertEq(
            json,
            '{"name": "Mock Token #3","description": "string description","image": "string image","properties": "string properties","attributes": "string attributes","animation_url": "string animation_url","external_url": "string external_url"}'
        );

        vm.prank(address(auction));
        tokenId = token.mint();

        json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(tokenId));

        assertEq(
            json,
            '{"name": "Mock Token #4","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=4&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","animation_url": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=4&audios=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.mp3","properties": {"mock-property": "mock-item"}}'
        );
    }

    function test_AddCustomTokenWithLaterRelease() public {
        string[] memory names = new string[](1);
        names[0] = "mock-property";

        ItemParam[] memory items = new ItemParam[](1);
        items[0].propertyId = 0;
        items[0].name = "mock-item";
        items[0].isNewProperty = true;

        IPFSGroup memory ipfsGroup = IPFSGroup({ baseUri: "https://nouns.build/api/test/", artExtension: ".json", audioExtension: ".mp3" });

        vm.prank(founder);
        metadataRenderer.addProperties(names, items, ipfsGroup);

        vm.prank(address(auction));
        token.mint();

        vm.prank(address(treasury));
        CustomToken memory mockToken = CustomToken(
            "string image",
            "string animation_url",
            "string external_url",
            "string description",
            "string name",
            "string attributes",
            "string properties",
            7200,
            0,
            address(0)
        );
        metadataRenderer.addToReleaseStack(mockToken);

        (
            string memory image,
            string memory animation_url,
            string memory external_url,
            string memory description,
            string memory name,
            string memory attributes,
            string memory properties,
            uint256 timestamp,
            uint256 royalty,
            address royaltyRecipient
        ) = metadataRenderer.releaseStack(0);

        assertEq(image, "string image");
        assertEq(animation_url, "string animation_url");
        assertEq(external_url, "string external_url");
        assertEq(description, "string description");
        assertEq(name, "string name");
        assertEq(attributes, "string attributes");
        assertEq(properties, "string properties");
        assertEq(timestamp, 7200);

        vm.prank(address(auction));
        uint256 tokenId = token.mint();

        string memory json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(tokenId));

        assertEq(
            json,
            '{"name": "Mock Token #3","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=3&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","animation_url": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=3&audios=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.mp3","properties": {"mock-property": "mock-item"}}'
        );
        skip(3600);
        vm.prank(address(auction));
        tokenId = token.mint();

        json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(tokenId));

        assertEq(
            json,
            '{"name": "Mock Token #4","description": "This is a mock token","image": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=4&images=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.json","animation_url": "http://localhost:5000/render?contractAddress=0x3c9d4dcc85e6b58559ccfedce34f7b31b4a70cf6&tokenId=4&audios=https%3a%2f%2fnouns.build%2fapi%2ftest%2fmock-property%2fmock-item.mp3","properties": {"mock-property": "mock-item"}}'
        );

        skip(3600);
        vm.prank(address(auction));
        tokenId = token.mint();

        json = Base64URIDecoder.decodeURI("data:application/json;base64,", token.tokenURI(tokenId));

        assertEq(
            json,
            '{"name": "Mock Token #5","description": "string description","image": "string image","properties": "string properties","attributes": "string attributes","animation_url": "string animation_url","external_url": "string external_url"}'
        );
    }
}
