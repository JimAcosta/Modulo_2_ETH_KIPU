// SPDX-License-Identifier: MIT
// Jimmy Acosta

pragma solidity ^0.8.0;

contract Auction {
    address public owner;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    uint256 public totalCommission;

    struct Bid {
        uint256 amount;
        bool withdrawn;
    }

    mapping(address => Bid[]) public bids;
    address[] public bidders;

    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    modifier onlyDuringAuction() {
        require(block.timestamp < auctionEndTime, "Auction ended");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(uint256 durationInSeconds) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + durationInSeconds;
    }

    /// @notice Place a bid. It must be at least 5% higher than the current highest bid.
    function placeBid() external payable onlyDuringAuction {
        require(msg.value > 0, "Bid must be greater than 0");

        uint256 totalBid = getTotalBid(msg.sender) + msg.value;
        require(
            highestBidder == address(0) || totalBid >= highestBid + (highestBid * 5) / 100,
            "Bid must be at least 5% higher than the current highest"
        );

        if (auctionEndTime - block.timestamp <= 10 minutes) {
            auctionEndTime += 10 minutes;
        }

        if (bids[msg.sender].length == 0) {
            bidders.push(msg.sender); // Track unique bidders
        }

        bids[msg.sender].push(Bid(msg.value, false));
        highestBidder = msg.sender;
        highestBid = totalBid;

        emit NewBid(msg.sender, totalBid);
    }

    /// @notice Returns the winner of the auction and the amount.
    function getWinner() external view returns (address, uint256) {
        require(block.timestamp >= auctionEndTime, "Auction still active");
        return (highestBidder, highestBid);
    }

    /// @notice Returns all the bids made by a specific bidder.
    function getBids(address bidder) external view returns (Bid[] memory) {
        return bids[bidder];
    }

    /// @notice Allows losing bidders to withdraw all their funds.
    function refundLosingBidders() external onlyOwner {
        require(block.timestamp >= auctionEndTime, "Auction still active");

        for (uint i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];

            if (bidder == highestBidder) {
                continue;
            }

            uint256 refundAmount = 0;
            uint256 len = bids[bidder].length;

            for (uint j = 0; j < len; j++) {
                if (!bids[bidder][j].withdrawn) {
                    refundAmount += bids[bidder][j].amount;
                    bids[bidder][j].withdrawn = true;
                }
            }

            if (refundAmount > 0) {
                uint256 fee = (refundAmount * 2) / 100;
                totalCommission += fee;
                payable(bidder).transfer(refundAmount - fee);
            }
        }
    }

    /// @notice Allows the winner to withdraw any surplus funds beyond the winning bid.
    function withdrawSurplus() external {
        uint256 surplus = 0;
        uint256 total = 0;
        uint256 len = bids[msg.sender].length;

        for (uint i = 0; i < len; i++) {
            if (!bids[msg.sender][i].withdrawn) {
                total += bids[msg.sender][i].amount;
            }
        }

        if (msg.sender == highestBidder) {
            require(total > highestBid, "No surplus to withdraw");
            surplus = total - highestBid;
        } else {
            surplus = total;
        }

        require(surplus > 0, "Nothing to withdraw");

        for (uint i = 0; i < len; i++) {
            bids[msg.sender][i].withdrawn = true;
        }

        uint256 fee = (surplus * 2) / 100;
        totalCommission += fee;

        payable(msg.sender).transfer(surplus - fee);
    }

    /// @notice Finalizes the auction, marking the winner's bids as withdrawn.
    function finalizeAuction() external onlyOwner {
        require(block.timestamp >= auctionEndTime, "Auction still active");

        uint256 len = bids[highestBidder].length;
        for (uint i = 0; i < len; i++) {
            bids[highestBidder][i].withdrawn = true;
        }

        emit AuctionEnded(highestBidder, highestBid);
    }

    /// @notice Emergency withdrawal for the owner after the auction ends.
    function emergencyWithdraw() external onlyOwner {
        require(block.timestamp >= auctionEndTime, "Auction still active");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Nothing to withdraw");

        payable(owner).transfer(contractBalance);
    }

    /// @notice Returns the total amount a bidder has bid so far.
    /// @param bidder The address of the bidder.
    /// @return total The total bid amount.
    function getTotalBid(address bidder) internal view returns (uint256 total) {
        uint256 len = bids[bidder].length;
        for (uint i = 0; i < len; i++) {
            if (!bids[bidder][i].withdrawn) {
                total += bids[bidder][i].amount;
            }
        }
    }
}