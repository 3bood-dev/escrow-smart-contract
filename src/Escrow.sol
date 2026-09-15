// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Escrow {
    // Custom Errors
    error Escrow__OnlyBuyer();
    error Escrow__OnlySeller();
    error Escrow__OnlyArbiter();
    error Escrow__OnlyBuyerOrSeller();
    error Escrow__ReleaseFundsFailed();
    error Escrow__NoDisputeRaised();

    address public buyer;
    address public seller;
    address public arbiter;

    uint256 public amount;

    bool public buyerApproved;
    bool public sellerApproved;

    bool public isDisputeRaised;

    constructor(address _buyer, address _seller, address _arbiter) payable {
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;

        amount = msg.value;
    }

    function approveByBuyer() external {
        if (msg.sender != buyer) revert Escrow__OnlyBuyer();
        buyerApproved = true;
        raiseIfAgreed();
    }

    function approveBySeller() external {
        if (msg.sender != seller) revert Escrow__OnlySeller();
        sellerApproved = true;
        raiseIfAgreed();
    }

    function resolveDispute(bool _approveForSeller) external {
        if (msg.sender != arbiter) revert Escrow__OnlyArbiter();
        if (!isDisputeRaised) revert Escrow__NoDisputeRaised();

        if (_approveForSeller) {
            (bool success,) = payable(seller).call{value: amount}("");
            if (!success) revert Escrow__ReleaseFundsFailed();
        } else {
            (bool success,) = payable(buyer).call{value: amount}("");
            if (!success) revert Escrow__ReleaseFundsFailed();
        }
    }

    function raiseIfAgreed() internal {
        if (buyerApproved && sellerApproved && !isDisputeRaised) {
            (bool success,) = payable(seller).call{value: amount}("");
            if (!success) revert Escrow__ReleaseFundsFailed();
        }
    }

    function raiseDispute() external {
        // require(msg.sender == buyer || msg.sender == seller, "only buyer or seller can raise dispute");
        if (msg.sender != buyer && msg.sender != seller) revert Escrow__OnlyBuyerOrSeller();
        isDisputeRaised = true;
    }
}
