// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Escrow} from "../src/Escrow.sol";

/// @dev this contract is just simulation to a bad senario that
///      if the seller was a contract that dosnt have a receive
///      function or fallback function
contract RejectEther {
    // empty contract just for testing senario
}

contract EscrowTest is Test {
    Escrow public escrow;
    address public buyer = makeAddr("buyer");
    address public seller = makeAddr("seller");
    address public arbiter = makeAddr("arbier");

    uint256 public AMOUNT = 1 ether;

    function setUp() public {
        escrow = new Escrow{value: AMOUNT}(buyer, seller, arbiter);
    }

    function test_Constructor() public view {
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

    function test_Revert_approveByBuyer() public {
        vm.prank(seller);
        vm.expectRevert(Escrow.Escrow__OnlyBuyer.selector);
        escrow.approveByBuyer();
    }

    function test_approveByBuyer() public {
        vm.prank(buyer);
        escrow.approveByBuyer();
        assertTrue(escrow.buyerApproved());
        assertEq(address(escrow).balance, AMOUNT);
        assertEq(seller.balance, 0);
    }

    // ══════════════════════════════════════════════════
    // approveBySeller
    // ══════════════════════════════════════════════════
    function test_Revert_approveBySeller() public {
        vm.prank(buyer);
        vm.expectRevert(Escrow.Escrow__OnlySeller.selector);
        escrow.approveBySeller();
    }

    function test_approveBySeller() public {
        vm.prank(seller);
        escrow.approveBySeller();
        assertTrue(escrow.sellerApproved());
        assertEq(address(escrow).balance, AMOUNT);
        assertEq(seller.balance, 0);
    }

    // ══════════════════════════════════════════════════
    //raiseIfAgreed
    // ══════════════════════════════════════════════════
    function test_raiseIfAgreed_whenBuyerApproveThenSeller() public {
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

    function test_raiseIfAgreed_whenSellerApproveThenBuyer() public {
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
    function test_raiseDispute_noRelease_normalSenario() public {
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

    function test_revert_whenSellerIsContractThatDoesntHaveReceiveOrFallbackFunction() public {
        RejectEther badContract = new RejectEther();
        address badSeller = address(badContract);

        Escrow badEscrow = new Escrow{value: AMOUNT}(buyer, badSeller, arbiter);

        vm.prank(buyer);
        badEscrow.approveByBuyer();

        vm.prank(badSeller);
        vm.expectRevert(Escrow.Escrow__ReleaseFundsFailed.selector);
        badEscrow.approveBySeller();

        assertEq(address(badEscrow).balance, AMOUNT);
        assertEq(badSeller.balance, 0);
    }
    // ══════════════════════════════════════════════════
    //raiseDispute
    // ══════════════════════════════════════════════════

    function test_revert_raiseDispute_onlyBuyerOrSeller() public {
        vm.prank(arbiter);
        vm.expectRevert(Escrow.Escrow__OnlyBuyerOrSeller.selector);
        escrow.raiseDispute();
    }

    function test_raiseDispute_byBuyer() public {
        vm.prank(buyer);
        escrow.raiseDispute();
        assertTrue(escrow.isDisputeRaised());
    }

    function test_raiseDispute_bySeller() public {
        vm.prank(seller);
        escrow.raiseDispute();
        assertTrue(escrow.isDisputeRaised());
    }
    // ══════════════════════════════════════════════════
    //resolveDispute
    // ══════════════════════════════════════════════════

    function test_revert_resolveDispute_ifNotArbiter() public {
        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(buyer);
        vm.expectRevert(Escrow.Escrow__OnlyArbiter.selector);
        escrow.resolveDispute(false);
    }

    function test_revert_resolveDispute_ifNoDisputeRaised() public {
        vm.prank(arbiter);
        vm.expectRevert(Escrow.Escrow__NoDisputeRaised.selector);
        escrow.resolveDispute(true);
    }

    //normal senario
    function test_resolveDispute_ifBuyer() public {
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter);
        escrow.resolveDispute(false);

        assertEq(address(escrow).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore + AMOUNT);
        assertEq(seller.balance, sellerBalanceBefore);
    }

    function test_resolveDispute_ifSeller() public {
        uint256 buyerBalanceBefore = buyer.balance;
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(buyer);
        escrow.raiseDispute();

        vm.prank(arbiter);
        escrow.resolveDispute(true);

        assertEq(address(escrow).balance, 0);
        assertEq(buyer.balance, buyerBalanceBefore);
        assertEq(seller.balance, sellerBalanceBefore + AMOUNT);
    }

    // revert if the (buyer or seller) is a contract dose't have receive function or fallback function
    function test_revert_resolveDispute_ifBuyerIsContractThatDosentHaveReceiveOrFallbackFunction() public {
        RejectEther badContract = new RejectEther();
        address badAddress = address(badContract);

        Escrow badEscrow = new Escrow{value: 1 ether}(badAddress, seller, arbiter);

        uint256 buyerBalanceBefore = badAddress.balance;
        uint256 sellerBalanceBefore = seller.balance;

        vm.prank(badAddress);
        badEscrow.raiseDispute();

        vm.prank(arbiter);
        vm.expectRevert(Escrow.Escrow__ReleaseFundsFailed.selector);
        badEscrow.resolveDispute(false);

        assertEq(address(escrow).balance, AMOUNT);
        assertEq(badAddress.balance, buyerBalanceBefore);
        assertEq(seller.balance, sellerBalanceBefore);
    }

    function test_revert_resolveDispute_ifSellerIsContractThatDosentHaveReceiveOrFallbackFunction() public {
        RejectEther badContract = new RejectEther();
        address badAddress = address(badContract);

        Escrow badEscrow = new Escrow{value: 1 ether}(buyer, badAddress, arbiter);

        uint256 buyerBalanceBefore = buyer.balance;
        uint256 sellerBalanceBefore = badAddress.balance;

        vm.prank(buyer);
        badEscrow.raiseDispute();

        vm.prank(arbiter);
        vm.expectRevert(Escrow.Escrow__ReleaseFundsFailed.selector);
        badEscrow.resolveDispute(true);

        assertEq(address(escrow).balance, AMOUNT);
        assertEq(buyer.balance, buyerBalanceBefore);
        assertEq(badAddress.balance, sellerBalanceBefore);
    }
}
