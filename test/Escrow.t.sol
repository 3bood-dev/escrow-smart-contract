// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    address public buyer = makeAddr("buyer");
    address public seller = makeAddr("seller");
    address public arbitur = makeAddr("arbitur");

    uint256 public AMOUNT = 1 ether;
    function setUp() public {
        escrow = new Escrow{value: AMOUNT}(buyer, seller, arbitur);
    }

    
}
