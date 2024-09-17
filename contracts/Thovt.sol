// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

contract ThovtToken is ERC20Pausable, Ownable {
    uint256 public treasuryTaxRate = 3; // 3%
    uint256 public dividendTaxRate = 1; // 1%
    uint256 public operationsTaxRate = 1; // 1%

    address public treasuryAddress;
    address public operationsAddress;
    

    mapping(address => bool) private _isExcludedFromTax;


    event TaxRatesUpdated(uint256 treasuryRate, uint256 dividendRate, uint256 operationsRate);
    event DistributeDivident(address indexed receiver, uint amount);
    event OperationsAddressUpdated (address operationsAddress);
    event TreasuryAddressUpdated (address treasuryAddress);

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address _treasuryAddress,
        address _operationsAddress
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _isExcludedFromTax[msg.sender] = true;
        _mint(msg.sender, initialSupply);
        treasuryAddress = _treasuryAddress;
        operationsAddress = _operationsAddress;
    }


    function setTaxRates(uint256 _treasuryRate, uint256 _dividendRate, uint256 _operationsRate) external onlyOwner {
        treasuryTaxRate = _treasuryRate;
        dividendTaxRate = _dividendRate;
        operationsTaxRate = _operationsRate;
        emit TaxRatesUpdated(_treasuryRate, _dividendRate, _operationsRate);
    }


    function transfer(address to, uint256 value) public override returns(bool) {
        address sender = msg.sender;
        uint256 totalTax = _isExcludedFromTax[to] ? 0 :  treasuryTaxRate + dividendTaxRate + operationsTaxRate;
        uint256 taxAmount = (value * totalTax) / 100;
        uint256 amountAfterTax = value - taxAmount;

        _transfer(sender, to, amountAfterTax);
        
        

        if (taxAmount > 0) {
            uint256 treasuryAmount = (taxAmount * treasuryTaxRate) / totalTax;
            // uint256 dividendAmount = (taxAmount * dividendTaxRate) / totalTax;
            uint256 operationsAmount = (taxAmount * operationsTaxRate) / totalTax;
            if (treasuryAmount > 0) _transfer(sender, treasuryAddress, treasuryAmount);
            if (operationsAmount > 0) _transfer(sender, operationsAddress, operationsAmount);
        }
        return true;

        }
    
    
    function toggleisExcludedFromTax (address addr, bool state) external onlyOwner() {
        _isExcludedFromTax[addr] = state;
    }


    function isExcludedFromTax (address addr) external view returns(bool) {
        return _isExcludedFromTax[addr];
    }

    function updateTreasuryAddress (address _newTreasuryAddress) external onlyOwner() {
        treasuryAddress = _newTreasuryAddress;
        emit TreasuryAddressUpdated(_newTreasuryAddress);
        
    }

    function updateOperationsAddress (address _newOperationsAddress) external onlyOwner() {
        operationsAddress = _newOperationsAddress;
        emit OperationsAddressUpdated(_newOperationsAddress);
    }    





}
