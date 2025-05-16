
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title RealEstateToken
 * @dev Implements ERC1155 token standard for fractional real estate ownership
 */
contract RealEstateToken is ERC1155, Ownable {
    using Strings for uint256;
    
    // Property struct to store property details
    struct Property {
        string name;
        string location;
        uint256 totalFractions;
        uint256 pricePerFraction;
        uint256 availableFractions;
        bool isActive;
    }
    
    // Maps propertyId to Property struct
    mapping(uint256 => Property) public properties;
    
    // Counter for property IDs
    uint256 private _propertyIdCounter;
    
    // Events
    event PropertyAdded(uint256 indexed propertyId, string name, string location, uint256 totalFractions, uint256 pricePerFraction);
    event FractionsPurchased(address indexed buyer, uint256 indexed propertyId, uint256 amount);
    event PropertyStatusChanged(uint256 indexed propertyId, bool isActive);
    
    /**
     * @dev Constructor that initializes the ERC1155 token with base URI
     */
    constructor() ERC1155("https://tokenized-realestate.example/api/token/") Ownable(msg.sender) {
        _propertyIdCounter = 1;
    }
    
    /**
     * @dev Adds a new property with specified details
     * @param name Name of the property
     * @param location Location details of the property
     * @param totalFractions Total number of fractions for the property
     * @param pricePerFraction Price per fraction in wei
     */
    function addProperty(
        string memory name,
        string memory location,
        uint256 totalFractions,
        uint256 pricePerFraction
    ) external onlyOwner {
        require(totalFractions > 0, "Fractions must be greater than zero");
        require(pricePerFraction > 0, "Price must be greater than zero");
        
        uint256 propertyId = _propertyIdCounter;
        
        properties[propertyId] = Property({
            name: name,
            location: location,
            totalFractions: totalFractions,
            pricePerFraction: pricePerFraction,
            availableFractions: totalFractions,
            isActive: true
        });
        
        _propertyIdCounter++;
        
        emit PropertyAdded(propertyId, name, location, totalFractions, pricePerFraction);
    }
    
    /**
     * @dev Allows users to purchase fractions of property
     * @param propertyId ID of the property to purchase fractions from
     * @param amount Number of fractions to purchase
     */
    function purchaseFractions(uint256 propertyId, uint256 amount) external payable {
        Property storage property = properties[propertyId];
        
        require(property.isActive, "Property is not active");
        require(property.availableFractions >= amount, "Not enough fractions available");
        require(msg.value >= property.pricePerFraction * amount, "Insufficient funds sent");
        
        // Update available fractions
        property.availableFractions -= amount;
        
        // Mint tokens to buyer
        _mint(msg.sender, propertyId, amount, "");
        
        emit FractionsPurchased(msg.sender, propertyId, amount);
    }
    
    /**
     * @dev Toggle property active status
     * @param propertyId ID of the property to toggle
     * @param isActive New status for the property
     */
    function setPropertyStatus(uint256 propertyId, bool isActive) external onlyOwner {
        require(propertyId < _propertyIdCounter, "Property does not exist");
        
        properties[propertyId].isActive = isActive;
        
        emit PropertyStatusChanged(propertyId, isActive);
    }
    
    /**
     * @dev Returns the URI for token metadata
     * @param tokenId The ID of the token
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId < _propertyIdCounter, "Property does not exist");
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }
}





