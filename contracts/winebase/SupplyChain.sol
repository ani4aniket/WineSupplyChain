pragma solidity ^0.4.24;

import ".././wineaccesscontrol/ProducerRole.sol";
import ".././wineaccesscontrol/DistributorRole.sol";
import ".././wineaccesscontrol/RetailerRole.sol";
import ".././wineaccesscontrol/CustomerRole.sol";


contract SupplyChain is ProducerRole, DistributorRole, RetailerRole, CustomerRole {

    // Define 'owner'
    address owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
    uint  upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
    uint  sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
    mapping (uint => Item) items;

    address public constant emptyAddress = 0x00000000000000000000000000000000000000;

  // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash, 
  // that track its journey through the supply chain -- to be sent from DApp.
    mapping (uint => string[]) itemsHistory;
  
  // Define enum 'State' with the following values:
    enum State { Harvested, Processed, Packed, ForSale, Sold, Shipped, Received, Purchased }
    
    State constant defaultState = State.Harvested;

  // Define a struct 'Item' with the following fields:
    struct Item {
        uint    sku;  // Stock Keeping Unit (SKU)
        uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
        address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
        address originFarmerID; // Metamask-Ethereum address of the Farmer
        string  originFarmName; // Farmer Name
        string  originFarmInformation;  // Farmer Information
        string  originFarmLatitude; // Farm Latitude
        string  originFarmLongitude;  // Farm Longitude
        uint    productID;  // Product ID potentially a combination of upc + sku
        string  productNotes; // Product Notes
        uint    productPrice; // Product Price
        State   itemState;  // Product State as represented in the enum above
        address distributorID;  // Metamask-Ethereum address of the Distributor
        address retailerID; // Metamask-Ethereum address of the Retailer
        address consumerID; // Metamask-Ethereum address of the Consumer
    }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
    event Harvested(uint upc);
    event Processed(uint upc);
    event Packed(uint upc);
    event ForSale(uint upc);
    event Sold(uint upc);
    event Shipped(uint upc);
    event Received(uint upc);
    event Purchased(uint upc);

    // Define a modifer that checks to see if msg.sender == owner of the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner not found");
        _;
    }

    // Define a modifer that verifies the Caller
    modifier verifyCaller (address _address) {
        require(msg.sender == _address, "Caller not verified"); 
        _;
    }

    // Define a modifier that checks if the paid amount is sufficient to cover the price
    modifier paidEnough(uint _price) { 
        require(msg.value >= _price, "Not paid Enough"); 
        _;
    }
    
    // Define a modifier that checks the price and refunds the remaining balance
    modifier checkBuyValue(uint _upc) {
        _;
        uint _price = items[_upc].productPrice;
        uint amountToReturn = msg.value - _price;
        items[_upc].distributorID.transfer(amountToReturn);
    }

    modifier checkPurchaseValue(uint _upc) {
        _;
        uint _price = items[_upc].productPrice;
        uint amountToReturn = msg.value - _price;
        items[_upc].consumerID.transfer(amountToReturn);
    }

    // Define a modifier that checks if an item.state of a upc is Harvested
    modifier harvested(uint _upc) {
        require(items[_upc].itemState == State.Harvested, "Grapes not Harvested");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Processed
    modifier processed(uint _upc) {
        require(items[_upc].itemState == State.Processed, "Wine not Processed");
        _;
    }
    
    // Define a modifier that checks if an item.state of a upc is Packed
    modifier packed(uint _upc) {
        require(items[_upc].itemState == State.Packed, "Wine not Packed");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is ForSale
    modifier forSale(uint _upc) {
        require(items[_upc].itemState == State.ForSale, "Wine not for Sale");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Sold
    modifier sold(uint _upc) {
        require(items[_upc].itemState == State.Sold, "Wine not Sold");
        _;
    }
    
    // Define a modifier that checks if an item.state of a upc is Shipped
    modifier shipped(uint _upc) {
        require(items[_upc].itemState == State.Shipped, "Wine not Shipped");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Received
    modifier received(uint _upc) {
        require(items[_upc].itemState == State.Received, "Wine not Received");
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Purchased
    modifier purchased(uint _upc) {
        require(items[_upc].itemState == State.Purchased, "Wine not Purchased");
        _;
    }

    // In the constructor set 'owner' to the address that instantiated the contract
    // and set 'sku' to 1
    // and set 'upc' to 1
    constructor() public payable {
        owner = msg.sender;
        sku = 1;
        upc = 1;
    }

    // Define a function 'kill' if required
    function kill() public {
        if (msg.sender == owner) {
            selfdestruct(owner);
        }
    }

    // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
    function harvestItem(uint _upc, address _originFarmerID, string memory _originFarmName, string memory _originFarmInformation, string memory _originFarmLatitude, string memory _originFarmLongitude, string memory _productNotes) public {
        
        address producerAccount = msg.sender;
        
        if (!isProducer(producerAccount)) {
            addProducer(producerAccount);
        } else {
            // Increment sku
            uint _sku = sku + 1;
        // Emit the appropriate event
            items[_upc] = Item ({
                sku : _sku,
                upc : _upc,
                ownerID: producerAccount,
                originFarmerID: _originFarmerID,
                originFarmName: _originFarmName,
                originFarmInformation: _originFarmInformation,
                originFarmLatitude: _originFarmLatitude,
                originFarmLongitude: _originFarmLongitude,
                productID: sku + _upc,
                productNotes: _productNotes,
                productPrice: 0,
                itemSate: State.Harvested,
                distributorID: emptyAddress,
                retailerID: emptyAddress,
                consumerID: emptyAddress
            });
        
            emit Harvested(_upc);
        }


        
    }

    // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
    function processItem(uint _upc) public harvested(_upc) verifyCaller(msg.sender) onlyProducer() {
        // Update the appropriate fields
        items[_upc].itemState = State.Processed;
        // Emit the appropriate event
        emit Processed(_upc);
    }

    // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
    function packItem(uint _upc) public processed(_upc) verifyCaller(msg.sender) onlyProducer() {
        // Update the appropriate fields
        items[_upc].itemState = State.Packed;
        // Emit the appropriate event
        emit Packed(_upc);
    }

    // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
    function sellItem(uint _upc, uint _price) public packed(_upc) verifyCaller(msg.sender) onlyProducer() {
        // Update the appropriate fields
        items[_upc].itemState = State.ForSale;
        items[_upc].productPrice = _price;
        // Emit the appropriate event
        emit ForSale(_upc);
    }

    // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
    // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
    // and any excess ether sent is refunded back to the buyer
    function buyItem(uint _upc) public payable forSale(_upc) paidEnough(items[_upc].productPrice) checkBuyValue(_upc) {
        
        if (!isDistributor(msg.sender)) {
            addDistributor(msg.sender);
        } else {
            address distributor = msg.sender;
            uint price = items[_upc].productPrice;
            // Update the appropriate fields - ownerID, distributorID, itemState
            items[_upc].ownerID = distributor;
            items[_upc].distributorID = distributor;
            items[_upc].itemState = State.Sold;
            // Transfer money to farmer
            items[_upc].originFarmerID.transfer(price);
            // emit the appropriate event
            emit Sold(_upc);
        }
    }
    // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
    // Use the above modifers to check if the item is sold
    function shipItem(uint _upc) public sold(_upc) verifyCaller(msg.sender) onlyDistributor() {
        // Update the appropriate fields
        items[_upc].itemState = State.Shipped;
        // Emit the appropriate event
        emit Shipped(_upc);
    }

    // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
    // Use the above modifiers to check if the item is shipped
    function receiveItem(uint _upc) public shipped(_upc) {

        address retailer = msg.sender;
        
        if (!isRetailer(retailer)) {
            addRetailer(retailer);
        } else {
            items[_upc].ownerID = retailer;
            items[_upc].retailerID = retailer;
            items[_upc].itemState = State.Received;
             // Emit the appropriate event
            emit Received(_upc);
        }
    }  

    // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
    // Use the above modifiers to check if the item is received
    function purchaseItem(uint _upc) public received(_upc) {
        address consumer = msg.sender;

        // Access Control List enforced by calling Smart Contract / DApp
        // Update the appropriate fields - ownerID, consumerID, itemState
        if (!isCustomer(consumer)) {
            addCustomer(consumer);
        } else {
            items[_upc].ownerID = consumer;
            items[_upc].consumerID = consumer;
            items[_upc].itemState = State.Purchased;
            // Emit the appropriate event
            emit Purchased(_upc);
        }
    }
    

    // Define a function 'fetchItemBufferOne' that fetches the data
    function fetchItemBufferOne(uint _upc) public view returns (uint itemSKU, uint itemUPC, address ownerID, address originFarmerID, string memory originFarmName, string memory originFarmInformation, string memory originFarmLatitude, string memory originFarmLongitude) {
    // Assign values to the 8 parameters
        itemSKU = items[_upc].sku;
        itemUPC = items[_upc].upc;
        ownerID = items[_upc].ownerID;
        originFarmerID = items[_upc].originFarmerID;
        originFarmName = items[_upc].originFarmName;
        originFarmInformation = items[_upc].originFarmInformation;
        originFarmLatitude = items[_upc].originFarmLatitude;
        originFarmLongitude = items[_upc].originFarmLongitude;
        
        return (itemSKU, itemUPC, ownerID, originFarmerID, originFarmName, originFarmInformation, originFarmLatitude, originFarmLongitude);
    }

    // Define a function 'fetchItemBufferTwo' that fetches the data
    function fetchItemBufferTwo(uint _upc) public view returns (uint itemSKU, uint itemUPC, uint productID, string memory productNotes, uint productPrice, uint itemState, address distributorID, address retailerID, address consumerID) {
        // Assign values to the 9 parameters
    
        itemSKU = items[_upc].sku;
        itemUPC = items[_upc].upc;
        productID = items[_upc].productID;
        productNotes = items[_upc].productNotes;
        productPrice = items[_upc].productPrice;
        itemState = uint(items[_upc].itemState);
        distributorID = items[_upc].distributorID;
        retailerID = items[_upc].retailerID;
        consumerID = items[_upc].consumerID;

        return (itemSKU, itemUPC, productID, productNotes, productPrice, itemState, distributorID, retailerID, consumerID);
    }
}