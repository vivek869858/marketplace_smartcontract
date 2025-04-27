// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    struct Product {
        uint256 id;
        string name;
        string description;
        uint256 price;
        address payable seller;
        bool sold;
    }

    struct Order {
        uint256 id;
        uint256 productId;
        address buyer;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(uint256 => Product) public products;
    mapping(uint256 => Order) public orders;
    Counters.Counter private _productIds;
    Counters.Counter private _orderIds;

    event ProductListed(
        uint256 indexed productId,
        string name,
        uint256 price,
        address indexed seller
    );
    event ProductSold(
        uint256 indexed productId,
        address indexed buyer,
        uint256 amount
    );
    event OrderCreated(
        uint256 indexed orderId,
        uint256 indexed productId,
        address indexed buyer,
        uint256 amount
    );
    event Withdrawal(address indexed to, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function listProduct(
        string memory name,
        string memory description,
        uint256 price
    ) public {
        _productIds.increment();
        uint256 productId = _productIds.current();
        products[productId] = Product(
            productId,
            name,
            description,
            price,
            payable(msg.sender),
            false
        );
        emit ProductListed(productId, name, price, msg.sender);
    }

    function buyProduct(uint256 productId) public payable {
        require(
            products[productId].seller != address(0),
            "Product does not exist"
        );
        require(!products[productId].sold, "Product is already sold");
        Product storage product = products[productId];
        uint256 price = product.price;
        require(msg.value >= price, "Insufficient Ether sent");

        product.sold = true;

        _orderIds.increment();
        uint256 orderId = _orderIds.current();
        orders[orderId] = Order(
            orderId,
            productId,
            msg.sender,
            price,
            block.timestamp
        );

        (bool success, ) = product.seller.call{value: price}("");
        require(success, "Transfer failed");

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }

        emit ProductSold(productId, msg.sender, price);
        emit OrderCreated(orderId, productId, msg.sender, price);
    }

    function withdraw(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = to.call{value: balance}("");
        require(success, "Transfer failed");

        emit Withdrawal(to, balance);
    }

    function getProduct(uint256 productId)
        public
        view
        returns (Product memory)
    {
        return products[productId];
    }

    function getOrder(uint256 orderId) public view returns (Order memory) {
        return orders[orderId];
    }

    function getProductCount() public view returns (uint256) {
        return _productIds.current();
    }

    function getOrderCount() public view returns (uint256) {
        return _orderIds.current();
    }
}
