// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe_NotOwner();

contract FundMe{
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;

    address public immutable i_owner;

    // constructor gets called immediately when we deploy our contract
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }


    function fund() public payable  {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Need to send more ETH"); // 1e18 wei = 1 ETH = 1*10^18 , client must send 1 ETH
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public  onlyOwner{

        // for loop
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++)
        {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the array
        s_funders = new address[](0);

        // actually withdraw the funds


        // transfer (2300 gas, throws error)
        // send (2300 gas, returns bool)
        // call (forward all gas or set gas, returns bool)



        //transfer
        //msg.sender = address
        //payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance);
        //send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess,"send failed");
        //call
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"Call failed");
    }


    function getVersion() public view returns (uint256){
        return s_priceFeed.version();
    }
    
    //Modifier
    modifier onlyOwner(){
        // require(msg.sender == i_owner,"Sender is not owner");
        if(msg.sender != i_owner) {revert FundMe_NotOwner();}
        _;
    }

    // What happens when someone dends this contract ETH without calling the fund function, will their address gets stored? No
    // so to resolve this we will use
    // receive
    // fallback

    receive() external payable {
        fund();
     }
     fallback() external payable {
        fund();
      }

    /**
     * View/pure function (Getters)
     */
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256){
        return s_addressToAmountFunded[fundingAddress];
    }
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

}