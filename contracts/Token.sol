// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TaxableTokenWithCheckpoint is ERC20, Ownable {
    uint256 public taxPercentage;
    uint256 public totalTaxCollected; // Total tax accumulated in the pool
    uint256 public totalRewardsPerToken; // Accumulated rewards per token
    mapping(address => uint256) public lastClaimedRewardsPerToken; // Track user's last claim
    
    mapping(address => uint256) public unclaimedRewards; // Track unclaimed rewards for users

    constructor(uint256 _initialSupply, uint256 _taxPercentage) ERC20("TaxableToken", "TAX") Ownable(msg.sender) {
        _mint(msg.sender, _initialSupply * (10 ** decimals()));
        taxPercentage = _taxPercentage;
    }

    function transfer(address sender, address recipient, uint256 amount) external  {
        uint256 taxAmount = (amount * taxPercentage) / 100;
        uint256 amountAfterTax = amount - taxAmount;

        // Update the user's unclaimed rewards before transferring
        _updateRewards(sender);
        _updateRewards(recipient);

        super._transfer(sender, recipient, amountAfterTax);
        _accumulateTax(sender, taxAmount);
    }

    // Accumulate tax in the pool and update rewards per token
    function _accumulateTax(address sender, uint256 taxAmount) private {
        totalTaxCollected += taxAmount;
        totalRewardsPerToken += (taxAmount * 1e18) / totalSupply(); // Normalize to avoid rounding issues
        _burn(sender, taxAmount); // Optionally burn the taxed amount
    }

    // Update unclaimed rewards for a user
    function _updateRewards(address account) internal {
        if (balanceOf(account) > 0) {
            uint256 userReward = calculateClaimable(account);
            unclaimedRewards[account] += userReward;
        }
        // Update the checkpoint to the current rewards per token
        lastClaimedRewardsPerToken[account] = totalRewardsPerToken;
    }

    // Calculate how much the user can claim based on the time they held the tokens
    function calculateClaimable(address account) public view returns (uint256) {
        uint256 rewardPerTokenDifference = totalRewardsPerToken - lastClaimedRewardsPerToken[account];
        return (balanceOf(account) * rewardPerTokenDifference) / 1e18;
    }

    // Users can manually claim their rewards
    function claimRewards() external returns (uint claimable) {
        _updateRewards(msg.sender); // Ensure their rewards are updated
        claimable = unclaimedRewards[msg.sender];
        require(claimable > 0, "No rewards to claim");

        unclaimedRewards[msg.sender] = 0; // Reset claimable amount
        _transfer(owner(), msg.sender, claimable); // Transfer rewards from the pool
    }

    // Allow the owner to update the tax percentage
    function setTaxPercentage(uint256 _taxPercentage) external onlyOwner {
        taxPercentage = _taxPercentage;
    }
}
