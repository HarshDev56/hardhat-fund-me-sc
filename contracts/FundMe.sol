/*
1. Get Funds from users.
2. withdraw funds.
3. set a minimum funding value in USD.
*/

//pragma

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//imports
import "./PriceConvertor.sol";

//Error code
error FundMe__NotOwner();

// interfaces, libraries , contracts

/**
 * @title A contract for crowd funding
 * @author Harsh Fichadiya
 * @notice this contract is a sample funding contract
 * @dev this implements pricefeed as out library
 */
contract FundMe {
    // type declaration
    using PriceConvertor for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address private immutable i_owner;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender is not owner!");
        _;
    }

    /* function order 
    constructor

    receive function (if exists)

    fallback function (if exists)

    external

    public

    internal

    private

    view/pure
    */
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    address[] private s_funders;

    // state variables
    mapping(address => uint256) private s_addressToAmountFunded;

    function fund() public payable {
        // want to able to set a minimum fund amount in USD
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        ); // 1e18 == 1*10**18 == 1000000000000000000
        // 18 decimal
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the funders
        s_funders = new address[](0);

        // // withdraw fund has three ways
        // // 1. transfer
        // // msg.sender = address
        // // payable(msg.sender) = payable address
        // payable(msg.sender).transfer(address(this).balance);
        // // 2. send
        // bool transferSucess =  payable(msg.sender).send(address(this).balance);
        // require(transferSucess,"Send Failed");

        // 3. call
        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "Send Failed");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mapping can't be in memory
        for (
            uint funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
            s_funders = new address[](0);
            (bool sucess, ) = i_owner.call{value: address(this).balance}("");
            require(sucess);
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }
}
