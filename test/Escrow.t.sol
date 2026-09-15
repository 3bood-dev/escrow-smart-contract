// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow public escrow;
    address public buyer = makeAddr("buyer");
    address public seller = makeAddr("seller");
    address public arbiter = makeAddr("arbier");

    uint256 public AMOUNT = 1 ether;
    function setUp() public {
        escrow = new Escrow{value: AMOUNT}(buyer, seller, arbiter);
    }

    function test_Constructor()public view{
        vm.assertEq(escrow.buyer(), buyer);
        vm.assertEq(escrow.seller(), seller);
        vm.assertEq(escrow.arbiter(), arbiter);
        vm.assertEq(escrow.amount(), AMOUNT);
        vm.assertEq(address(escrow).balance, AMOUNT);
        vm.assertFalse(escrow.buyerApproved());
        vm.assertFalse(escrow.sellerApproved());
        vm.assertFalse(escrow.isDisputeRaised());
    }
    // ══════════════════════════════════════════════════
    // approveByBuyer
    // ══════════════════════════════════════════════════
    
    function test_Revert_approveByBuyer()public {
        vm.prank(seller);
        vm.expectRevert(Escrow.Escrow__OnlyBuyer.selector);
        escrow.approveByBuyer();
    }
    function test_approveByBuyer()public {
        vm.prank(buyer);
        escrow.approveByBuyer();
        assertTrue(escrow.buyerApproved());
        assertEq(address(escrow).balance, AMOUNT);
        assertEq(seller.balance, 0);
    }
     // ══════════════════════════════════════════════════
    // approveBySeller
    // ══════════════════════════════════════════════════
     function test_Revert_approveBySeller()public {
        vm.prank(buyer);
        vm.expectRevert(Escrow.Escrow__OnlySeller.selector);
        escrow.approveBySeller();
    }
    function test_approveBySeller()public {
        vm.prank(seller);
        escrow.approveBySeller();
        assertTrue(escrow.sellerApproved());
         assertEq(address(escrow).balance, AMOUNT);
        assertEq(seller.balance, 0);
    }
    // ══════════════════════════════════════════════════
    //raiseIfAgreed
    // ══════════════════════════════════════════════════
    function test_raiseIfAgreed_whenBuyerApproveThenSeller()public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.approveByBuyer();

        assertEq(seller.balance, 0);
        assertEq(address(escrow).balance, AMOUNT);

        vm.prank(seller);
        escrow.approveBySeller();

        assertEq(seller.balance, sellerBalanceBefore + AMOUNT);
        assertEq(address(escrow).balance, 0);
    }

    function test_raiseIfAgreed_whenSellerApproveThenBuyer()public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(seller);
        escrow.approveBySeller();

        assertEq(seller.balance, 0);
        assertEq(address(escrow).balance, AMOUNT);

        vm.prank(buyer);
        escrow.approveByBuyer();

        assertEq(seller.balance, sellerBalanceBefore + AMOUNT);
        assertEq(address(escrow).balance, 0);
    }
    // ══════════════════════════════════════════════════
    // raiseDispute
    // ══════════════════════════════════════════════════
    function test_raiseDispute_noRelease_normalSenario()public {
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.approveByBuyer();

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(seller);
        escrow.approveBySeller();

        assertTrue(escrow.buyerApproved());
        assertTrue(escrow.sellerApproved());
        assertTrue(escrow.isDisputeRaised());
        assertEq(address(escrow).balance, AMOUNT);
        assertEq(seller.balance, sellerBalanceBefore);

    }
    
}
